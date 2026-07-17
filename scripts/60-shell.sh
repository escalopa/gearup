#!/usr/bin/env bash
# 60-shell.sh — wire the gearup shell additions into bash and zsh.
# One sourced file works for both shells; rc files only get a small
# sentinel-managed block that sources it.

read -r -d '' RC_BLOCK <<'EOF' || true
[ -f "$HOME/.config/gearup/shell.sh" ] && . "$HOME/.config/gearup/shell.sh"
EOF

ensure_symlink "$GEARUP_ROOT/config/shell/gearup.sh" "$HOME/.config/gearup/shell.sh"

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  # Only touch rc files for shells the user actually has.
  case "$rc" in
    *zshrc) has_cmd zsh || continue ;;
  esac
  ensure_block_in_file "$rc" "$RC_BLOCK"
done
