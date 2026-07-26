#!/usr/bin/env bash
# 50-symlinks.sh — link every config from the repo into $HOME.
# Configs stay in the repo, so `git pull` updates every machine.
# Anything already in the way is backed up to ~/.gearup-backup/<timestamp>/.

ensure_symlink "$GEARUP_ROOT/config/tmux.conf"        "$HOME/.tmux.conf"
ensure_symlink "$GEARUP_ROOT/config/nvim"             "$HOME/.config/nvim"
ensure_symlink "$GEARUP_ROOT/config/gitconfig-gearup" "$HOME/.gitconfig-gearup"
ensure_symlink "$GEARUP_ROOT/config/editorconfig"     "$HOME/.editorconfig"
ensure_symlink "$GEARUP_ROOT/config/starship.toml"    "$HOME/.config/starship.toml"
ensure_symlink "$GEARUP_ROOT/config/ghostty/config"   "$HOME/.config/ghostty/config"
ensure_symlink "$GEARUP_ROOT/config/shell/gearup.zsh" "$HOME/.config/gearup/shell.zsh"
ensure_symlink "$GEARUP_ROOT/config/shell/aliases.sh" "$HOME/.config/gearup/aliases.sh"
ensure_symlink "$GEARUP_ROOT/config/shell/completions.sh" "$HOME/.config/gearup/completions.sh"

# The workspace switcher script, on PATH via ~/.local/bin.
run mkdir -p "$HOME/.local/bin"
ensure_symlink "$GEARUP_ROOT/bin/ws" "$HOME/.local/bin/ws"

# Include our gitconfig from the user's real ~/.gitconfig (sentinel-managed,
# so user settings are never touched).
ensure_block_in_file "$HOME/.gitconfig" '[include]
	path = ~/.gitconfig-gearup'
