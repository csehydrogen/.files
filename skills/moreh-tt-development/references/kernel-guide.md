# TT kernel guide

Read before writing or reviewing TT ops/kernels. Preserve these conservative Moreh conventions while checking the active checkout's APIs; version-specific names are not substitutes for source inspection.

API status checked on 2026-10-13 against Moreh `moreh/main` at `8953be5a52ddc306987c33601054814921a5e263` and local `f9e3274e0de`. Relevant API headers match between these commits. This is source verification, not device validation; re-check the active checkout rather than treating planned removal dates as completed removals.

## API, arguments, and allocation

- Write/modify data-movement kernels with Device 2.0 APIs under `tt_metal/hw/inc/api/`, following the checkout's `docs/source/tt-metalium/tt_metal/apis/kernel_apis/data_movement/device_api_migration_guide.md`. Use `Noc`, `CircularBuffer`, and endpoint APIs rather than copying legacy examples.
- Never use `invalidate_l1_cache()`.
- Use per-core runtime args for values differing across cores, common runtime args for values shared across cores but varying between runs (including tensor addresses), and compile-time args otherwise.
- Rely on the default program hash; do not define a custom `compute_program_hash`.
- Use `TensorAccessor` for actual tensors. Prefer `CircularBufferConfig` + `CreateCircularBuffer` for program-local L1 scratch/workspace, accessed by CB index/base pointer; these remain supported public APIs. Program-local CB storage does **not** persist across programs. Cross-program persistence needs an explicitly managed allocation/lifetime; use `CreateBuffer(config)` with `config.buffer_type = BufferType::L1` only for an intentional tensor-like/runtime buffer with a verified nearby pattern. See the [current CB API and lifetime contract](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tt_metal/api/tt-metalium/host_api.hpp#L194-L214).
- CB scratch is a Moreh preference, not the only valid allocation API. The experimental Metal 2.0 host API also supports `ScratchpadSpec` + device `Scratchpad<T>` for program-scope raw L1 memory. Use that alternative only with the matching host API/binding/lifetime model, not as a drop-in for existing CB-based programs; provide synchronization explicitly. See [ScratchpadSpec](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tt_metal/api/tt-metalium/experimental/metal2_host_api/scratchpad_spec.hpp#L18-L45).
- For manually managed non-tensor scratch, use raw address math from its CB/scratchpad base and explicit NoC coordinates, not `TensorAccessor`/`InterleavedAddrGen` bank mapping. A local CB pointer is not evidence of another core's CB address; verify the remote allocation and address.
- Derive dimensions, tile sizes, alignment, and header sizes from existing constants/helpers rather than magic numbers.

## NoC transactions and signaling

- After asynchronous writes, drain the applicable NoC with `Noc::async_write_barrier()` before kernel exit. After asynchronous atomics, including semaphore increments, use `Noc::async_atomic_barrier()`. Both barriers are required when both types were issued. These drain transactions issued by the current core on that NoC; they do not by themselves establish end-to-end completion of remote Fabric forwarding. Use the Fabric protocol's completion/acknowledgment mechanism when remote completion is required.
- Use ordered data-write-then-semaphore signaling (including multicast) without an unnecessary intervening barrier. Ordering depends on the same NoC and VC and the API's write/atomic ordering contract; verify these before relying on it. Different NoCs/VCs need an explicit ordering design, not this assumption. See the checkout's `data_movement/ordering.rst`.
- A fused `NocUnicastAtomicIncFusedCommandHeader` with `flush = true` waits for write data to depart before the atomic; it does not replace either final completion barrier.
- Keep the conservative 32-byte aligned-chunk default for ordinary data transfers, but derive the actual requirement from architecture, memory type, and direction. Matching source/destination offsets modulo the required alignment is essential: modulo 32 for Wormhole DRAM reads, modulo 64 for Blackhole DRAM reads. Prefer aligned chunks; a modulo-32 check alone is not portable. Semaphore/inline APIs have their own contracts.
- Prefer transfer sizes divisible by the required alignment, but intentional smaller transactions may be valid. For scalar fields, avoid tiny unaligned NoC transactions: read/write an aligned chunk into scratch and index locally. A 4-byte scalar read can silently access the wrong data. Do not overwrite unrelated fields when writing the chunk back.
- Verify logical/virtual/physical coordinate mapping and NoC0/NoC1 routing in the active API; do not infer remote coordinates from local ones.

## Semaphores and Fabric

- Program-local semaphores created with `CreateSemaphore` are initialized by dispatch for the program; do not redundantly set them at kernel entry and overwrite another core's increment. Global semaphore buffers instead need a deliberate creation/reset/reuse protocol; do not assume per-kernel initialization.
- Do not call `get_semaphore(id)` (or its Device 2.0 equivalent) for a semaphore allocated only on another core.
- Allocate/pass local and global semaphores on every participating core, including Fabric/link workers that read or increment them. A semaphore only on logical `(0,0)` is insufficient for a barrier executing on a separate Fabric row/column.
- Fabric packet-header CB pages must use exactly `tt::tt_fabric::get_tt_fabric_packet_header_size_bytes()`. Allocate enough pages for all simultaneously live headers; one suffices if one header/route is live at a time. `RawUInt32` is conventional; `UInt32` can work with exact page sizing. Before blaming dtype for a hang, isolate semaphore scope and header page/slot sizing.

## Circular buffers

- Never call push or pop for the same CB from multiple threads; their pointers are not synchronized across threads.
- Reserve/wait are counter-only credit checks: they do not advance pointers or promise physical contiguity. Counts up to total capacity may logically cross the wrap boundary. Repeated waits without a pop use cumulative counts.
- Push/pop advance physical pointers; a single call may reach the limit exactly and wrap, but must not pass it. Split accesses and pointer-advancing operations into boundary-safe chunks. Push/pop amounts over a complete cycle must sum exactly to CB size.
- A cross-boundary reserve/wait therefore does not authorize one contiguous memory access across the physical end.

## Compute

- Use `tile_regs_acquire`, `tile_regs_commit`, `tile_regs_wait`, and `tile_regs_release`, never `acquire_dst`/`release_dst`.
- Call `compute_kernel_hw_startup(...)` **exactly once, before any other compute API**, with CB IDs and source ordering matching the first operation. Use default `SrcOrder::Regular` except for matmul, which needs `compute_kernel_hw_startup<SrcOrder::Reverse>(in0, in1, out)` with natural operand order. Never rerun startup when switching operations; explicitly reconfigure/init each subsequent operation family instead of inheriting unpack/math/pack state. See the [startup contract](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tt_metal/hw/inc/api/compute/compute_kernel_hw_startup.h#L44-L83).
- Before FPU copy, reconfigure SrcA/input formats and call the matching copy init, such as `reconfig_data_format_srca(...)` followed by `copy_tile_to_dst_init_short(...)`. Before SFPU operations, use the matching init (for example `exp_tile_init` before `exp_tile`). Check current signatures/templates.
- Before packing, call `pack_reconfig_data_format(...)` for the destination CB. For tilize, use matching `tilize_init`/`tilize_block` and `tilize_uninit` before switching operations, with the correct formats and packer configuration.
- For untilize, prefer `pack_untilize_init` + `pack_untilize_block`, or `pack_untilize_dest_init` + `pack_untilize_dest` for data already in DST. Run `pack_untilize_uninit` before initializing another operation; check current signatures/templates. The unpack-based `untilize_init`/`untilize_block`/`untilize_uninit` APIs are [deprecated](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tt_metal/hw/inc/api/compute/untilize.h#L20-L38); the current [pack-untilize cleanup contract](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tt_metal/hw/inc/api/compute/pack_untilize.h#L314-L328) still applies despite its old planned-removal comment.
- `pack_tile` and `pack_block` auto-advance output positions. For an arbitrary tile index, use `pack_tile<true>` (`out_of_order_output = true`). `pack_tile_block` is a deprecated alias; prefer `pack_block`.
- Use `transpose_dest_init`/`transpose_dest`, not deprecated `transpose_wh_dest` names. On Wormhole/Blackhole, default `transpose_of_faces=true` performs a full tile transpose; `false` selects inner-face-only transpose. Do not assume the default is face-wise-only or generalize this flag behavior to other architectures without checking their implementation.
- On ordinary Wormhole/Blackhole `matmul_block` paths, preserve contiguous B segments (`ct_dim * kt_dim`) even when transpose is enabled; A may use `kt_dim` stride. Transposing tiles in B does not provide arbitrary CB-layout strides. Verify the active implementation when changing layouts; Quasar currently rejects nonzero `transpose` (and nonzero `idst`) in `matmul_block`.

## Tests

- New ops need `op_correctness` and trace-replay `op_performance` tests by default; follow [profiling](profiling.md) for measurement.
- Add `op_breakdown` and its L1 debug interface only when explicitly requested. Use a simple interleaved L1 debug tensor `[num_cores, num_slots]`, with local writes like `debug_l1[slot] = x`; avoid an elaborate TensorAccessor abstraction for this interface.
- Follow the parent skill's build/environment/locking requirements before running tests.
