---
name: agent-update
description: Update or synchronize shared agent instruction files in the user's ~/.files dotfiles repo. Use when the user invokes /agent-update, asks to edit AGENTS.md/CLAUDE.md/Codex or Claude agent files, wants to commit and push agent-file changes, wants to pull updated agent files from another machine, or asks the current AI agent to re-read updated agent instructions.
---

# Agent Update

Manage shared agent instructions from `~/.files` without helper scripts. Do the git/file work directly as the current agent.

## Locations

- Dotfiles repo: `~/.files` (or `/mnt/nvme0/heehoon/.files` on Moreh servers)
- Shared instruction file: `~/.files/AGENTS.md`
- Codex instruction symlink: `~/.files/.codex/AGENTS.md -> ../AGENTS.md`
- Claude instruction symlink: `~/.files/.claude/CLAUDE.md -> ../AGENTS.md`
- Shared skills directory: `~/.files/skills`
- Codex/Claude skill symlinks: `~/.files/.codex/skills -> ../skills`, `~/.files/.claude/skills -> ../skills`

## `/agent-update <request>` workflow

When the user provides update text:

1. Work in `~/.files`; inspect `git status --short --branch` first.
2. Pull before editing if the branch is clean enough to do so safely: `git pull --ff-only`.
3. Edit the shared agent file or shared skill files requested by the user.
4. Re-read the changed instruction files and ensure the new instructions are clear, scoped, and not duplicated.
5. Review `git diff`; stage only relevant files. Do not include unrelated local config changes unless explicitly requested.
6. Commit with a concise message, then push.
7. Re-read the updated agent file in the current session and follow it where it does not conflict with higher-priority instructions.
8. Summarize changed files, commit hash, and push result.

## `/agent-update` workflow

When the user gives no update text:

1. Work in `~/.files`; inspect `git status --short --branch`.
2. Run `git pull --ff-only` if local changes do not make that unsafe.
3. Determine whether `AGENTS.md` or files under `skills/` changed.
4. If changed, read the changed instruction/skill files and apply them for the rest of the session where they do not conflict with higher-priority instructions.
5. Report whether anything changed and what was re-read.

## Session-start refresh

If `AGENTS.md` instructs a new session to refresh dotfiles, perform a best-effort `git -C ~/.files pull --ff-only` at the start of the first user task, unless it would overwrite local work. If agent files changed, read them before continuing.

## Guardrails

- Do not create `agent_update.py` or another helper unless the user explicitly asks.
- Prefer direct agent edits and git commands.
- Never commit secrets, credentials, histories, caches, or unrelated local settings.
- Preserve symlinks for Codex/Claude entry points.
- Use normal prose for commits and PR-style summaries, even if another communication-mode skill is active.
