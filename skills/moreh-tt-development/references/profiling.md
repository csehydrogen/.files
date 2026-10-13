# TT performance measurement

Follow the parent skill's environment, build, locking, reset, and recovery rules for every device-backed measurement.

## Individual ops: trace replay

Prefer trace replay over Tracy for repeated single-op latency measurements:

1. Run outside Tracy with `TT_METAL_DEVICE_PROFILER` unset and other profiler-enabling options disabled; instrumentation changes the measured latency. Prefer unsetting over `0`, because builds without Tracy support can reject this variable's presence even when its value is `0`.
2. Allocate enough trace-region space, run the op to trigger JIT/warmup, and retain captured input/output buffers. For stateful ops, verify that repeated replay is valid and define any required state-reset protocol.
3. Call `ttnn.begin_trace_capture`, execute a known number of the measured op, and close capture with `ttnn.end_trace_capture`. Use a consistent command queue for capture, replay, and synchronization.
4. Warm up replay and synchronize before the start timestamp. Execute the trace N times with **explicit `blocking=False`** (`ttnn.execute_trace` currently defaults to `True`), then synchronize before the end timestamp. Use a monotonic timer and the appropriate device/mesh synchronization API from the active checkout.
5. Divide elapsed time by **N × captured op executions per trace**. Report iteration count, units, shapes, dtypes, device/mesh configuration, and any state-reset or other work included in the timed region.
6. Use `finally` for cleanup: after queued execution completes, release any allocated trace with `ttnn.release_trace`, then release referenced buffers. If execution hangs, follow the locked recovery protocol rather than freeing resources or resetting beneath a live workload.

This is amortized trace-replay latency, not guaranteed pure kernel duration: residual host/dispatch overhead can still matter. Use enough work per trace to amortize it; check current trace signatures and queue behavior.

## Larger workloads: Tracy breakdown

```bash
python -m tracy -r -p -v main.py
```

Read the generated CSV path from the command output. Parse by header name (for example with `csv.DictReader`), never fixed column index. Relevant columns include:

- `OP CODE`, `OP TYPE`, `GLOBAL CALL COUNT`, `DEVICE ID`
- `DEVICE KERNEL DURATION [ns]`

`DEVICE FW DURATION [ns]` is a different metric. Check required headers and report missing ones instead of silently substituting columns. Filter device ID `0`/empty only for an explicitly chosen single-device view; preserve and identify all relevant devices for multi-device analysis. Blank device IDs do not prove a row is a device-kernel event.

Use only runtime/model-measured speculative acceptance metrics, not EvalScope's inferred `Spec. Accept Rate`.

## Verification

Checked on 2026-10-13 against `moreh-dev/tt-metal` default-branch commit `8953be5a52ddc306987c33601054814921a5e263`: [trace bindings and defaults](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/ttnn/cpp/ttnn-nanobind/operations/trace.cpp#L31-L70), [trace-latency benchmark](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tests/ttnn/unit_tests/operations/moreh/moreh_glm51_perf_utils.py#L199-L242), [profiler environment handling](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tt_metal/llrt/rtoptions.cpp#L816-L827), and [CSV headers](https://github.com/moreh-dev/tt-metal/blob/8953be5a52ddc306987c33601054814921a5e263/tools/tracy/process_ops_logs.py#L63-L84). Re-check the active checkout when APIs change.
