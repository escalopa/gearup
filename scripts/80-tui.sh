#!/usr/bin/env bash
# 80-tui.sh — build the gearup TUI (Go) and put it on PATH at ~/.local/bin/gearup.
# Runs last so the Go toolchain from 20-go.sh is available. Idempotent: rebuilds
# only when a source file is newer than the binary. Soft: a build failure warns
# (a fresh box still finishes the rest of the install).

_gearup_tui_bin="$HOME/.local/bin/gearup"

# Rebuild needed? true when the binary is missing or any source is newer.
_tui_needs_build() {
  [[ -x "$_gearup_tui_bin" ]] || return 0
  local newer
  newer=$(find "$GEARUP_ROOT/cmd" "$GEARUP_ROOT/internal" -name '*.go' -newer "$_gearup_tui_bin" 2>/dev/null)
  [[ -n "$newer" ]] && return 0
  [[ "$GEARUP_ROOT/go.mod" -nt "$_gearup_tui_bin" ]] && return 0
  [[ "$GEARUP_ROOT/go.sum" -nt "$_gearup_tui_bin" ]] && return 0
  return 1
}

if ! gearup_selected gearup; then
  : # not in the selected subset — nothing to do
elif ! has_cmd go; then
  warn "go not on PATH — skipping TUI build (rerun after opening a new shell)"
elif ! _tui_needs_build; then
  skip "gearup TUI (up to date)"
else
  run mkdir -p "$HOME/.local/bin"
  log "building gearup TUI"
  if (cd "$GEARUP_ROOT" && run go build -o "$_gearup_tui_bin" ./cmd/gearup); then
    ok "built gearup -> $_gearup_tui_bin"
  else
    warn "gearup TUI build failed — run 'make build' in $GEARUP_ROOT to see why"
  fi
fi
