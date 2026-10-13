# Shared agent instructions

These are personal defaults shared by Codex and Claude, not assumptions about every repository or host. Explicit user instructions for the current task take precedence over these defaults; follow applicable higher-priority instructions.

## Working agreements

- Never use Korean unless explicitly requested.
- Prefer CLIs/direct APIs for external services. Use a plugin only when those approaches are unavailable or inadequate.
- Run jobs on the current host and cluster unless the user explicitly requests remote execution. Do not move work elsewhere through SSH.
- Report unexpected errors in the next user-facing response: what failed, its impact, and recovery or remaining limitation.
- For long jobs, surface progress and monitor actual process completion. Do not wait by sleeping for a guessed duration or by using `tail` as a completion detector.
- Never print or commit credentials. Before invoking Claude from a subprocess, export its OAuth token without displaying it:

  ```bash
  export CLAUDE_CODE_OAUTH_TOKEN="$(<"$HOME/.claude/oauth-token")"
  ```

## Instruction maintenance

- At the first task of a session, inspect `~/.files` and run `git -C ~/.files pull --ff-only` unless local changes make it unsafe or the request is audit/re-read-only or forbids changes/sync. Re-read changed `AGENTS.md` and skill instructions before continuing.
- Use `agent-update` for shared instruction edits, audits, refreshes, and `/agent-update` requests. Keep canonical shared skills in `~/.files/skills`.
- Preserve working Codex/Claude instruction and skill links. Never replace a real skills directory or delete bundled `.system` skills to enforce a symlink layout. Consult current discovery paths when setting up a new host; do not migrate live links as an unrelated side effect.

## Git

- Use the primary checkout. Never create or use a linked Git worktree unless explicitly requested.
- Preserve existing work. Handle changes that are the task's intended input in place. Before a checkout-changing operation, stash unrelated changes (including relevant untracked files) or commit/push them to an appropriate branch only when authorized. Restore any stash when safe and report conflicts. Read-only inspection does not require a clean checkout or publishing unrelated work.
- Use `heehoon/` for new feature branches unless the user specifies otherwise.
- Never add co-author trailers to commits.
- For requested `~/.files` instruction updates, commit/push directly to `master`, not a branch or PR, unless the user requests local-only changes. Audits and rereads do not authorize edits or publication.

## TT work: mandatory specialized guidance

Before editing, reviewing, building, importing, testing, profiling, or running tt-metal, or using TT devices on a Moreh Guardian-protected host in any repository, read `~/.files/skills/moreh-tt-development/SKILL.md`. Read it directly if skill discovery is unavailable; it routes to kernel and profiling details only when needed.

On Moreh Guardian-protected hosts, device access requires an authorized job regardless of repository. Use `/usr/local/bin/moreh-lock`; for tt-metal, reset after acquisition and verify release afterward. Never bypass another user's lock, cancel a valid queued waiter just because it is slow, or reset beneath a live device-owning process. Do not assume vLLM scripts lock safely; the skill specifies how to verify the exact entry point and use one acquisition path.

When evaluating speculative decoding, never use EvalScope's inferred `Spec. Accept Rate` as runtime acceptance. Use acceptance metrics measured directly by the model/runtime.
