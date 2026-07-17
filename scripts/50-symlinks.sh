#!/usr/bin/env bash
# 50-symlinks.sh — link every config from the repo into $HOME.
# Configs stay in the repo, so `git pull` updates every machine.
# Anything already in the way is backed up to ~/.gearup-backup/<timestamp>/.

ensure_symlink "$GEARUP_ROOT/config/tmux.conf"        "$HOME/.tmux.conf"
ensure_symlink "$GEARUP_ROOT/config/nvim"             "$HOME/.config/nvim"
ensure_symlink "$GEARUP_ROOT/config/gitconfig-gearup" "$HOME/.gitconfig-gearup"
ensure_symlink "$GEARUP_ROOT/config/editorconfig"     "$HOME/.editorconfig"

# The workspace switcher script, on PATH via ~/.local/bin.
run mkdir -p "$HOME/.local/bin"
ensure_symlink "$GEARUP_ROOT/bin/ws" "$HOME/.local/bin/ws"

# Include our gitconfig from the user's real ~/.gitconfig (sentinel-managed,
# so user settings are never touched).
ensure_block_in_file "$HOME/.gitconfig" '[include]
	path = ~/.gitconfig-gearup'
