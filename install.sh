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

detect_platform
log "platform: $GEARUP_OS ($GEARUP_PKG)  root: $GEARUP_ROOT"
[[ "$DRY_RUN" == "1" ]] && log "DRY RUN — nothing will be changed"

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

log "done. Open a NEW shell (or 'source ~/.bashrc' / 'source ~/.zshrc'), then try:"
log "  tmux         → prefix is Ctrl-a; Ctrl-a g opens the workspace switcher"
log "  ws           → fuzzy-jump to any project as its own tmux session"
log "  nvim         → Space is the leader; Space-f-f finds files"
log "see TUTORIAL.md for a guided tour using the demo/ workspace"
