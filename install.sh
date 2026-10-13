#!/bin/sh
# Isolate shell options and failures when invoked via `source install.sh`.
(
set -eu

fail() { printf '%s\n' "$*" >&2; exit 1; }

check_link() {
    [ -e "$1" ] || fail "Missing link source: $1"
    if [ ! -L "$2" ] && [ -e "$2" ]; then
        fail "Refusing to replace real file or directory: $2. Back it up or merge it manually, then retry."
    fi
}

# Keep the full destination list in one place for preflight and installation.
all_links() {
    "$1" "$HOME/.files/.tmux.conf" "$HOME/.tmux.conf"
    "$1" "$HOME/.files/.gitconfig" "$HOME/.gitconfig"
    "$1" "$HOME/.files/.claude/settings.json" "$HOME/.claude/settings.json"
    "$1" "$HOME/.files/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    "$1" "$HOME/.files/skills" "$HOME/.claude/skills"
    "$1" "$HOME/.files/.codex/config.toml" "$HOME/.codex/config.toml"
    "$1" "$HOME/.files/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    "$1" "$HOME/.files/skills" "$HOME/.codex/skills"
}

# Refuse collisions before changing any links, including tmux/git. In particular,
# ~/.codex/skills may contain bundled .system skills that must not be deleted.
for parent in "$HOME/.claude" "$HOME/.codex"; do
    if { [ -e "$parent" ] || [ -L "$parent" ]; } && [ ! -d "$parent" ]; then
        fail "Not a usable directory: $parent"
    fi
done
all_links check_link

link() {
    check_link "$1" "$2"
    # -n replaces symlinks to directories instead of creating links inside them;
    # -f also handles dangling symlinks. Never remove a real destination.
    ln -sfn "$1" "$2"
}

mkdir -p "$HOME/.claude" "$HOME/.codex"
all_links link
)
