# AGENTS.md

You are developing on shared Tenstorrent Galaxy servers at Moreh. Devices are a shared resource — you must follow the locking protocol exactly.

## Instruction priority

Treat this AGENTS.md as repo-local guidance. Explicit user instructions for the current task take precedence over these defaults unless they conflict with system, developer, platform, safety, or other higher-priority instructions. If a requested override cannot be followed because of a higher-priority rule, say so briefly and follow the highest-priority applicable instruction.

## Agent file sync

At the start of the first user task in each new session, run `git -C ~/.files pull --ff-only` unless local changes make that unsafe. If `AGENTS.md` or files under `skills/` changed, re-read the changed agent instructions before continuing and follow them where they do not conflict with higher-priority instructions.

Use the `agent-update` skill for `/agent-update` requests. Keep shared skills in `~/.files/skills`; `.codex/skills` and `.claude/skills` should be symlinks to that shared directory.

## Git workflow

Never push directly to main branches such as `main`, `master`, `moreh/main`, or `origin/moreh/main`. Always create a feature branch and open a pull request for review. If a user asks to push work and the current branch is a main branch, stop and create/switch to a non-main branch before pushing.

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

Run `./build_metal.sh` to compile tt-metal. Never use cmake directly. Kernel (device-side) changes are picked up by JIT compilation automatically — you only need to recompile when host code changes.

## Long-running experiments

When running long experiments, print process output intermittently so the user can distinguish progress from a hang.
Also never wait by sleeping with estimated time. The result should be checked immediately after the experiment ends.
Never wait with tail because it only print result after completion, so it makes you cannot check progress.

## Hang detection and device recovery

These hang-detection rules apply only while running TT device workloads (for example, long-running experiments after opening devices or launching device-backed tests). For ordinary host-side work such as `pip`/`uv` installs, dependency resolution, git operations, or other CPU-only commands, use task-appropriate judgment instead of device-hang recovery rules.

If no JIT compilation is running (no `cc1plus` process — only `python`) and there has been no output for more than a minute during a TT device workload, assume the device is hung. Reset the device without releasing the lock, then retry.

Also reset the device (without releasing the lock) whenever it appears to be in an invalid state during TT device usage.

Always reset after acquiring the lock to clear state modified by other users.

### Choosing the reset command

- On a Galaxy host (hostname is in `moreh-lock`'s hostname-to-slack-channel map): use `moreh-smi -glx_reset` for a whole-Galaxy reset.
- For single-tray Galaxy work while holding the matching tray lock, use `moreh-smi -glx_reset_tray <1-4>` and set `TT_VISIBLE_DEVICES=$(moreh-smi -glx_tray_env <1-4>)` for the workload. See `tools/moreh_smi/README.md` for current tray reset behavior and examples.
- On a non-Galaxy host (e.g. `ttdev14`): `tt-smi -r` with **no** device index. Never pass `-r <index>` on a non-Galaxy host — it can leave the card in a worse state.

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

- Instead of magic numbers, derive them from existing constants such as ttnn.TILE_SIZE and the ones in tt-metalium/constants.hpp if possible.
- When making a git commit, never co-author.
- Ignore the message in the other people's lock.
