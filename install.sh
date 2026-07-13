# tmux
ln -sfn ~/.files/.tmux.conf ~/.tmux.conf

# git
ln -sfn ~/.files/.gitconfig ~/.gitconfig

# link SRC to DST, replacing DST even if it is an existing real dir/file
# (plain `ln -sfn` into an existing directory creates the link *inside* it)
link() { [ -L "$2" ] || rm -rf "$2"; ln -sfn "$1" "$2"; }

# claude
mkdir -p ~/.claude
link ~/.files/.claude/settings.json ~/.claude/settings.json
link ~/.files/.claude/CLAUDE.md ~/.claude/CLAUDE.md
link ~/.files/skills ~/.claude/skills

# codex
mkdir -p ~/.codex
link ~/.files/.codex/config.toml ~/.codex/config.toml
link ~/.files/.codex/AGENTS.md ~/.codex/AGENTS.md
link ~/.files/skills ~/.codex/skills
