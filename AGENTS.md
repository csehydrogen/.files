# AGENTS.md

You are developing on shared Tenstorrent Galaxy servers at Moreh. Devices are a shared resource — you must follow the locking protocol exactly.

## Instruction priority

Treat this AGENTS.md as repo-local guidance. Explicit user instructions for the current task take precedence over these defaults unless they conflict with system, developer, platform, safety, or other higher-priority instructions. If a requested override cannot be followed because of a higher-priority rule, say so briefly and follow the highest-priority applicable instruction.

## Agent file sync

At the start of the first user task in each new session, run `git -C ~/.files pull --ff-only` unless local changes make that unsafe. If `AGENTS.md` or files under `skills/` changed, re-read the changed agent instructions before continuing and follow them where they do not conflict with higher-priority instructions.

Use the `agent-update` skill for `/agent-update` requests. Keep shared skills in `~/.files/skills`; `.codex/skills` and `.claude/skills` should be symlinks to that shared directory.

## Git workflow

Never push directly to main branches such as `main`, `master`, `moreh/main`, or `origin/moreh/main`. Always create a feature branch and open a pull request for review. If a user asks to push work and the current branch is a main branch, stop and create/switch to a non-main branch before pushing.

Exception: for agent-instruction updates in the `~/.files` dotfiles repo, commit and push directly to `master`. Do not create a branch or pull request for `~/.files` agent updates.

When creating a feature branch, use the `heehoon/` prefix by default unless the user explicitly requests a different branch name.

## Device Locking

Only use the lock when you are working with https://github.com/moreh-dev/tt-metal and the hostname is supported by `moreh-lock` (for example, the Moreh Galaxy hosts configured in `tools/moreh_lock`).

Exception: `vllm-tt-moreh` test scripts acquire and release the device lock internally. When running those test scripts, do not acquire `moreh-lock` manually outside the script.

### Lock command to use

Use the CLI wrapper:

```bash
moreh-lock
```

Before running any command that touches Tenstorrent devices (for example, opening a TT device with `ttnn.open_device` / `ttnn.open_mesh_device`, running TT-backed pytest, profiling TT workloads, etc.), check lock status:

```bash
moreh-lock status
```

Prefer the CLI wrapper for device commands:

```bash
moreh-lock run --wait-timeout 3600 --max-hold <seconds> -m "<what you are doing and expected duration>" -- <command> <args>
```

For single-tray Galaxy work, use tray-scoped locking and restrict visibility to the same tray:

```bash
moreh-lock run --tray <1-4> --wait-timeout 3600 --max-hold <seconds> -m "<tray N work and expected duration>" -- bash -lc 'TT_VISIBLE_DEVICES=$(moreh-smi -glx_tray_env <1-4>) <command> <args>'
```

A command without `--tray` locks the whole host and conflicts with all tray locks. Tray locks for different trays may run concurrently; tray locks for the same tray conflict. See `tools/moreh_lock/README.md` for current tray-scoped locking semantics.

If the command needs shell features, wrap it with `bash -lc`:

```bash
moreh-lock run --wait-timeout 3600 --max-hold <seconds> -m "<what you are doing and expected duration>" -- bash -lc 'cd path/to/tests && FOO=1 pytest test.py -v 2>&1 | tee run.log'
```

Use manual hold only when you need an interactive lock window:

```bash
moreh-lock hold -m "<why you need the device>"
```

After a locked command exits, verify the lock was released:

```bash
moreh-lock status
```

Expected final output:

```text
Lock is free (... lock files)
```

Do not run device commands outside `moreh-lock run` unless a higher-level tool already acquires the lock for you. Do not manually kill another user's lock process.

When queued for `moreh-lock`, do not kill or cancel your own waiter merely because the lock is taking time; the lock is queue-based, and canceling loses your acquisition opportunity. Only cancel a queued waiter if the user explicitly asks, the command is no longer valid, or continuing would be unsafe.

Use `--wait-timeout` for lock acquisition timeout. Use `--max-hold` for command runtime timeout. Always set `--max-hold` to your best estimate of how long you need the device; do not omit it for non-interactive device commands.

If you are debugging or thinking and no command is actively using the device, release the lock immediately so others can use it.

### Docker / container note

Inside Docker, locking only works across processes if the container shares host IPC:

```bash
--ipc=host
```

Also set the real host/user via environment variables or CLI flags when needed:

```bash
export MOREH_LOCK_HOSTNAME=<host>
export MOREH_LOCK_USERNAME=<user>
```

## Building

Run `./build_metal.sh` to compile tt-metal. Never use cmake directly. After changing tt-metal source code, always run `./build_metal.sh -ce` before running tests or device workloads; do not rely on judging whether JIT compilation is sufficient.

## Heehoon's tt-metal Kernel Guide

These rules are intentionally stricter than necessary to reduce mistakes by AI agents.

### General kernel rules

- Never use `invalidate_l1_cache()`.
- Never use `noc_async_atomic_barrier()`.
- Align every NoC transaction to 32 bytes:
  - `src_addr % 32 == dst_addr % 32`
  - `size % 32 == 0`
- Semaphores are automatically initialized to their configured initial value at the start of the kernel. Do not set them again explicitly; doing so can create races, for example when another core has already sent an increment that then gets overwritten by a set.
- Calling `get_semaphore(id)` for a semaphore that is not allocated on the current core (only on other cores) is wrong.
- Be careful when accessing another core's circular buffer over NoC, especially when that CB is not allocated on the current core. TODO: clarify the correct way to obtain a remote core's CB address.
- For `NocUnicastAtomicIncFusedCommandHeader`, setting `flush = true` ensures receiver-side EDM acknowledgement of the write data, so the atomic increment is sent only after the data has arrived at the destination.
- `transpose_wh_dest` is face-wise transpose by default.
- With `matmul_block`, even when `transpose = true`, the B segment (`ct_dim * kt_dim`) is expected to occupy continuous CB slots; the A segment may use `kt_dim` stride.
- `pack_tile` and `pack_tile_block` auto-advance the output tile index by default.
  - For an arbitrary `output_tile_index`, pass `out_of_order_output = true` to `pack_tile`.
- Choose argument types as follows:
  - If values differ across cores, use runtime args.
  - If values are common across cores but can differ run-to-run (for example, tensor addresses), use common runtime args.
  - Otherwise, use compile-time args.
- Do not use a custom `compute_program_hash`. If possible, do not define one; rely on the default hash.

### Multicast

For multicast, use this pattern:

```cpp
noc_async_write_multicast(...);
noc_semaphore_set_multicast(...);
noc_async_write_barrier();
```

The write operations are ordered, so do not put a barrier between the data write and the semaphore write.

TODO: document virtual coordinates, physical coordinates, and the `noc0`/`noc1` reversal rules.

### Unit tests

When adding an op, implement these tests:

- `op_correctness`
- `op_performance`: use trace-replay-based measurement, not Tracy.
- `op_breakdown`: include an interleaved L1 debug tensor shaped like `[num_cores, num_slots]`; write values as `debug_l1[slot] = x`. Keep this simple; do not use a fancy `TensorAccessor` here.

### Circular buffers

- Never call `cb_push_back` or `cb_pop_front` from multiple threads. CB write/read pointers are not synchronized across threads (see the comment in `cb_api.h`).

### Accessing tensors

- Almost always use `TensorAccessor`.

### Compute kernels

- Never use `acquire_dst` or `release_dst`.
- Use `tile_regs_acquire`, `tile_regs_commit`, `tile_regs_wait`, and `tile_regs_release`.
- For FPU ops, always precede the operation with reconfiguration and init, for example:

```cpp
reconfig_data_format(cb_m_local, cb_m_local);
copy_tile_to_dst_init_short(cb_m_local);
copy_tile(cb_m_local, 0, 0);
```

- For SFPU ops, always precede the operation with init, for example:

```cpp
exp_tile_init</*approx=*/false, scale_fp32>();
exp_tile</*approx=*/false, /*scale_en=*/true>(0, static_cast<int>(VectorMode::RC), scale_bf16);
```

## Long-running experiments

When running long experiments, print process output intermittently so the user can distinguish progress from a hang.
Also never wait by sleeping with estimated time. The result should be checked immediately after the experiment ends.
Never wait with tail because it only print result after completion, so it makes you cannot check progress.

## Hang detection and device recovery

These hang-detection rules apply only while running TT device workloads (for example, long-running experiments after opening devices or launching device-backed tests). For ordinary host-side work such as `pip`/`uv` installs, dependency resolution, git operations, or other CPU-only commands, use task-appropriate judgment instead of device-hang recovery rules.

If no JIT compilation is running (no `cc1plus` process — only `python`) and there has been no output for more than a minute during an already-running TT device workload, assume the device may be hung. This rule does **not** apply while the process is still in device/runtime initialization (for example importing TTNN, opening devices, initializing Fabric, topology discovery, hugepage setup, or first-time test collection that probes devices). During initialization, wait for a clear runtime failure, a command timeout, or explicit evidence that initialization has stopped progressing before treating it as a device hang.

Do not reset underneath a live process that is still initializing or still owns UMD/device mappings. If a reset is needed for a hung TT workload, keep the lock held, stop or let the workload process exit (or run triage from the same lock context when appropriate), then reset and retry.

Also reset the device (without releasing the lock) whenever it appears to be in an invalid state during TT device usage.

Always reset after acquiring the lock to clear state modified by other users.

### Choosing the reset command

Always use `moreh-smi` for reset commands. Never use `tt-smi`.

- On a Galaxy host (hostname is in `moreh-lock`'s hostname-to-slack-channel map): use `moreh-smi -glx_reset` for a whole-Galaxy reset.
- For single-tray Galaxy work while holding the matching tray lock, use `moreh-smi -glx_reset_tray <1-4>` and set `TT_VISIBLE_DEVICES=$(moreh-smi -glx_tray_env <1-4>)` for the workload. See `tools/moreh_smi/README.md` for current tray reset behavior and examples.
- On a non-Galaxy host (e.g. `ttdev14`): use `moreh-smi -r` with **no** device index. Never pass `-r <index>` on a non-Galaxy host — it can leave the card in a worse state.

## Profiling with Tracy

Run: `python -m tracy -r -p -v main.py`. Tracy prints the path to a generated CSV on completion.

The CSV has these relevant columns: index 0 = OP CODE, 1 = OP TYPE, 2 = GLOBAL CALL COUNT, 3 = DEVICE ID, 18 = DEVICE KERNEL DURATION [ns]. When analyzing, filter to rows where DEVICE ID is `0` or empty, and extract those five columns. Write a parsing script as needed rather than using a fixed one.

## Benchmarking individual ttnn ops

For measuring a single ttnn op's kernel time, prefer the **trace capture/execute** pattern over Tracy. Trace replay amortizes Python and dispatch overhead across many iterations, so wall-clock time over iterations closely approximates pure device kernel time.

Steps:

1. Run the op once to trigger JIT compilation.
2. Open `ttnn.begin_trace_capture` and run the op a few times inside to capture the trace.
3. Record start timestamp, execute the trace N times, synchronize, record end timestamp.
4. Divide elapsed time by total op executions → good approximation of kernel duration with minimal host overhead.

Reserve Tracy for cases where you need per-op breakdowns inside a larger workload.

## Misc.

- In TT dataflow kernels, avoid tiny unaligned NOC reads/writes for scalar fields in interleaved tensors or L1 buffers. Read/write an aligned 32-byte (or larger aligned) chunk into scratch, then index the scalar locally. For example, reading one int32 from `TensorAccessor::get_noc_addr(page, elem * sizeof(int32_t))` or an `InterleavedAddrGen` with a 4-byte size can silently fetch the wrong value on device; align the offset down and transfer at least 32 bytes.
- In TT ops, allocate internal L1 scratch/persistent workspace as circular buffers (`CircularBufferConfig` + `CreateCircularBuffer`) and pass/access them by CB index with `get_read_ptr`/`get_write_ptr`; do not allocate scratch L1 with `CreateBuffer(BufferType::L1)` unless you are intentionally creating a real tensor-like/runtime buffer and have verified the pattern in nearby ops. For manually managed L1 storage that is not a tensor, do raw address math from the CB base and explicit NOC coordinates; do not use `TensorAccessor`/`InterleavedAddrGen` on non-tensor scratch, because page/bank mapping can return garbage.
- In TT Fabric dataflow kernels, allocate packet-header CBs with exact fabric header page size `tt::tt_fabric::get_tt_fabric_packet_header_size_bytes()` (96 bytes on the current 2D torus route-buffer-size-35 path) and enough pages for every simultaneously live header. One page is sufficient when a core uses only one header/route at a time, such as a lane choosing either north or south; allocate multiple pages only when the same core keeps multiple headers live concurrently. `RawUInt32` matches common fabric examples, but `UInt32` also works when the page size is exact; do not infer a fabric hang is caused by dtype before isolating semaphore scope and header page/slot sizing.
- For TT Fabric barriers or fabric atomics that use global semaphores, create/pass the semaphore on every core that will read or increment it, including fabric/link-worker cores. Do not create a global semaphore only on logical `(0,0)` when the barrier runs on a separate fabric core row/column. For local semaphores from `CreateSemaphore`, use a `CoreRangeSet` that includes all participating cores.
- In TT dataflow kernels, when using NOC writes followed by a semaphore signal (unicast or multicast), issue the data writes first, then issue the semaphore increment/set, then run one `noc_async_write_barrier()`. Do not put `noc_async_write_barrier()` or `noc_async_atomic_barrier()` between the data write and semaphore signal; the intended ordering is `noc_async_write*`/`noc_async_write_multicast*` -> `noc_semaphore_inc`/`noc_semaphore_set_multicast` -> `noc_async_write_barrier()`.
- In TT compute kernels, initialize and reconfigure explicitly before every operation family. Put one whole-kernel init near the start (usually `compute_kernel_hw_startup(...)` plus `unary_op_init_common(...)`). Before `copy_tile`, reconfigure SrcA for the input CB and run the copy init (for example `reconfig_data_format_srca(...)`/`reconfig_data_format(...)` then `copy_tile_to_dst_init_short...`). Before `pack_tile`, call `pack_reconfig_data_format(...)` for the destination CB. Before `tilize_block`/`untilize_block`, run the matching `tilize_init...`/`untilize_init...` with the correct data formats and packer config; do not assume a previous op left unpack/math/pack state valid.
- Instead of magic numbers, derive them from existing constants such as ttnn.TILE_SIZE and the ones in tt-metalium/constants.hpp if possible.
- When making a git commit, never co-author.
- Ignore the message in the other people's lock.
