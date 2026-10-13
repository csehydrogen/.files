---
name: agent-update
description: Audit, edit, sync, or re-read shared agent instructions and skills in $HOME/.files. Use for /agent-update or requests about these shared files, not ordinary project-local instructions.
---

# Agent Update

## Source of truth

- Repository: `$HOME/.files`; shared instructions: `AGENTS.md`; skills: `skills/`.
- Repository entry points `.codex/AGENTS.md` and `.claude/CLAUDE.md` link to `../AGENTS.md`; `.codex/skills` and `.claude/skills` link to `../skills`.
- Inspect installed links separately. Do not replace real skill directories or remove bundled `.system` skills to enforce a layout; installation changes need their own scope.

## Choose the requested mode

- **Audit or re-read:** inspect and report without editing, pulling, committing, or pushing unless requested. Validate volatile claims against installed tools, source code, or current primary documentation; distinguish obsolete guidance from unverified guidance. Do not infer skill usage from age.
- **Sync** (including `/agent-update` without arguments): inspect status, record HEAD, then run `git pull --ff-only` if safe. Read instruction files changed since the recorded HEAD and report what changed.
- **Edit:** inspect `git status --short --branch`, preserve unrelated work, and edit only the requested shared files. Keep triggers narrow, avoid duplication, and re-read/validate the result. Do not run the dotfiles installer as part of a text update.

For sync or edits, use `master` and pull before editing when safe; never switch branches or pull over conflicting local work. A local-only request leaves edits uncommitted and unpushed. Otherwise, agent-file updates follow the repository's direct-to-`master` workflow: review the diff, stage only task files, commit without co-authors, and push to `origin/master` (no feature branch or PR).

Never stage credentials, caches, or histories. Do not include unrelated settings or pre-existing user work without authorization. Apply re-read instructions only where they do not conflict with higher-priority instructions. Report changed files, validation, and whether changes are local or committed/pushed; use normal prose for commit messages.
