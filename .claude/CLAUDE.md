# CLAUDE.md

You are developing on shared Tenstorrent Galaxy servers at Moreh. Devices are a shared resource — you must follow the locking protocol exactly.

## Device Locking

Only use the lock when you are working with https://github.com/moreh-dev/tt-metal and the hostname is in moreh_lock's hostname to slack channel id map.

You must acquire a `moreh_lock` before any device usage (e.g., calling `ttnn.open_mesh_device`) and release it afterward.

To acquire: create a file named exactly `SECRET` in a temporary directory with this content:

```python
import moreh_lock, signal
moreh_lock.lock(message=..., timeout=...)
signal.pause()
```

Run it as a background process: `python SECRET &`. The lock is blocking. Wait for "Lock acquired" in the output before proceeding.

Always set `timeout` to your best estimate of how long you need the device. Never omit it.

To release: send SIGTERM to the lock process (`kill <pid>`). Never use SIGKILL.

If you are interrupted or no longer need the device, always release the lock immediately so others can use it.

If the lock is already acquired, you don't need to acquire it again.

When you are debugging or thinking, always release the lock.

### Lock message format

The `message` parameter must be a Korean string (English technical terms are fine) with this exact structure:

```
*<summary of previous result> <status slack emoji> <reason for this device usage> <estimate of how long you need the device> :<claude-emoji>:*
```

- The outer `*...*` makes it bold in Slack markdown. Always include them.
- Start with a brief summary of the previous device session's result, with a Slack emoji representing the outcome (e.g., `:white_check_mark:`, `:x:`, `:warning:`).
- Then describe why you need the device this time.
- End with `by :claude:` or `by :claude-thinking:`, chosen randomly.

## Building

Run `./build_metal.sh` to compile tt-metal. Never use cmake directly. Kernel (device-side) changes are picked up by JIT compilation automatically — you only need to recompile when host code changes.

## Long-running experiments

When running long experiments, print process output intermittently so the user can distinguish progress from a hang.
Also never wait by sleeping with estimated time. The result should be checked immediately after the experiment ends.
Never wait with tail because it only print result after completion, so it makes you cannot check progress.

## Hang detection and device recovery

If no JIT compilation is running (no `cc1plus` process — only `python`) and there has been no output for more than a minute, assume the device is hung. Run `tt-smi -glx_reset` without releasing the lock, then retry.

Also run `tt-smi -glx_reset` (without releasing the lock) whenever the device appears to be in an invalid state.

Always run the reset after acquiring the lock to reset the device state modified by other users.

## Profiling with Tracy

Run: `python -m tracy -r -p -v main.py`. Tracy prints the path to a generated CSV on completion.

The CSV has these relevant columns: index 0 = OP CODE, 1 = OP TYPE, 2 = GLOBAL CALL COUNT, 3 = DEVICE ID, 18 = DEVICE KERNEL DURATION [ns]. When analyzing, filter to rows where DEVICE ID is `0` or empty, and extract those five columns. Write a parsing script as needed rather than using a fixed one.

## Misc.

- Instead of magic numbers, derive them from existing constants such as ttnn.TILE_SIZE and the ones in tt-metalium/constants.hpp if possible.
- When making a git commit, never co-author.
- Ignore the message in the other people's lock.