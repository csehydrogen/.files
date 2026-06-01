# tmux
ln -sfn ~/.files/.tmux.conf ~/.tmux.conf

# git
ln -sfn ~/.files/.gitconfig ~/.gitconfig

# claude
mkdir -p ~/.claude
ln -sfn ~/.files/.claude/settings.json ~/.claude/settings.json
ln -sfn ~/.files/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sfn ~/.files/skills ~/.claude/skills

# codex
mkdir -p ~/.codex
ln -sfn ~/.files/.codex/config.toml ~/.codex/config.toml
ln -sfn ~/.files/.codex/AGENTS.md ~/.codex/AGENTS.md
ln -sfn ~/.files/skills ~/.codex/skills
