#!/usr/bin/env bash
# uninstall.sh — remove gearup symlinks and rc blocks.
# Does NOT uninstall packages (they're useful on their own) and does NOT
# touch your backups in ~/.gearup-backup/.
set -euo pipefail

GEARUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils.sh
source "$GEARUP_ROOT/lib/utils.sh"

remove_link() {
  local dst=$1
  if [[ -L "$dst" && "$(readlink "$dst")" == "$GEARUP_ROOT"* ]]; then
    rm "$dst"
    ok "removed link $dst"
  else
    skip "$dst (not a gearup link)"
  fi
}

remove_block() {
  local file=$1
  local begin='# >>> gearup >>>' end='# <<< gearup <<<'
  if [[ -f "$file" ]] && grep -qF "$begin" "$file"; then
    local tmp
    tmp=$(mktemp)
    sed "/^$begin\$/,/^$end\$/d" "$file" > "$tmp"
    mv "$tmp" "$file"
    ok "removed gearup block from $file"
  else
    skip "$file (no gearup block)"
  fi
}

remove_link "$HOME/.tmux.conf"
remove_link "$HOME/.config/nvim"
remove_link "$HOME/.gitconfig-gearup"
remove_link "$HOME/.editorconfig"
remove_link "$HOME/.config/gearup/shell.sh"
remove_link "$HOME/.local/bin/ws"
remove_block "$HOME/.bashrc"
remove_block "$HOME/.zshrc"
remove_block "$HOME/.gitconfig"

log "uninstalled. Backups (if any) are still in ~/.gearup-backup/"
