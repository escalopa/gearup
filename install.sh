#!/usr/bin/env bash
# gearup — gear up any Linux or macOS box in one command.
# Idempotent: safe to run on a fresh machine or one that's half configured.
#
# Usage:
#   ./install.sh                # install everything
#   ./install.sh --dry-run      # show what would happen, change nothing
#   ./install.sh packages go    # run only the named steps
set -euo pipefail

GEARUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GEARUP_ROOT

# shellcheck source=lib/utils.sh
source "$GEARUP_ROOT/lib/utils.sh"

DRY_RUN=0
ONLY_STEPS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,9p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) ONLY_STEPS+=("$arg") ;;
  esac
done
export DRY_RUN

# Let steps tell "run everything" apart from "the user named specific steps".
GEARUP_EXPLICIT_STEPS=0
[[ ${#ONLY_STEPS[@]} -gt 0 ]] && GEARUP_EXPLICIT_STEPS=1
export GEARUP_EXPLICIT_STEPS

# Freshly-installed binaries must be visible to this run so the has_cmd checks
# that keep every step idempotent can see them on a re-run: user tools in
# ~/.local/bin, go-installed tools in ~/go/bin, and the Go toolchain itself in
# /usr/local/go/bin (the Linux tarball location — otherwise the 2nd run wouldn't
# find go and would reinstall it).
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"

detect_platform
log "platform: $GEARUP_OS ($GEARUP_PKG)  root: $GEARUP_ROOT"
[[ "$DRY_RUN" == "1" ]] && log "DRY RUN — nothing will be changed"

# Per-tool install results feed the end-of-run summary (and the TUI's results
# screen). If the caller (the TUI) provided a file we append to it and leave it
# for them to read; otherwise we own a temp file and clean it up.
_gearup_results_owned=0
if [[ -z "${GEARUP_RESULTS:-}" ]]; then
  GEARUP_RESULTS="$(mktemp)"; export GEARUP_RESULTS; _gearup_results_owned=1
fi

should_run() {
  [[ ${#ONLY_STEPS[@]} -eq 0 ]] && return 0
  local s
  for s in "${ONLY_STEPS[@]}"; do
    [[ "$s" == "$1" ]] && return 0
  done
  return 1
}

# Steps run in filename order; each is independently rerunnable.
for script in "$GEARUP_ROOT"/scripts/*.sh; do
  name="$(basename "$script" .sh)"; name="${name#[0-9][0-9]-}"
  if should_run "$name"; then
    log "step: $name"
    # shellcheck source=/dev/null
    source "$script"
  fi
done

gearup_summary
[[ "$_gearup_results_owned" == "1" ]] && rm -f "$GEARUP_RESULTS"

log "done. Open a NEW shell (or 'source ~/.bashrc' / 'source ~/.zshrc'), then try:"
log "  gearup       → the TUI; 'gearup doctor' reports what's installed vs missing"
log "  tmux         → prefix is Ctrl-a; Ctrl-a g opens the workspace switcher"
log "  ws           → fuzzy-jump to any project as its own tmux session"
log "  nvim         → Space is the leader; Space-f-f finds files"
log "see TUTORIAL.md for a guided tour using the demo/ workspace"
