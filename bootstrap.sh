#!/usr/bin/env bash
# bootstrap.sh — install gearup with a single command on any fresh box:
#
#   curl -fsSL https://raw.githubusercontent.com/escalopa/gearup/main/bootstrap.sh | bash
#
# Clones (or updates) the repo into ~/.gearup and runs the installer.
# Safe to rerun: the clone is updated in place and install.sh is idempotent.
set -euo pipefail

REPO_URL="${GEARUP_REPO:-https://github.com/escalopa/gearup.git}"
DEST="${GEARUP_HOME:-$HOME/.gearup}"

command -v git >/dev/null 2>&1 || {
  echo "bootstrap: git is required. Install it first (apt/dnf/pacman/brew install git)." >&2
  exit 1
}

if [ -d "$DEST/.git" ]; then
  echo "[gearup] updating existing clone in $DEST"
  git -C "$DEST" pull --ff-only
else
  echo "[gearup] cloning $REPO_URL -> $DEST"
  git clone "$REPO_URL" "$DEST"
fi

exec bash "$DEST/install.sh" "$@"
