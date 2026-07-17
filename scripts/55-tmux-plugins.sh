#!/usr/bin/env bash
# 55-tmux-plugins.sh — TPM (tmux plugin manager) + plugins, headlessly.
# Runs after symlinks so ~/.tmux.conf already points at our config.

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [[ -d "$TPM_DIR/.git" ]]; then
  skip "tpm"
else
  run git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "installed tpm"
fi

# Install any plugins declared in tmux.conf that aren't present yet.
# TPM's install_plugins is itself idempotent ("already installed" per plugin).
if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
  missing=0
  for plugin in tmux-sensible vim-tmux-navigator tmux-yank tmux-resurrect tmux-continuum; do
    [[ -d "$HOME/.tmux/plugins/$plugin" ]] || missing=1
  done
  if [[ "$missing" == "1" ]]; then
    log "installing tmux plugins (tpm)"
    run "$TPM_DIR/bin/install_plugins"
    ok "tmux plugins installed"
  else
    skip "tmux plugins"
  fi
fi
