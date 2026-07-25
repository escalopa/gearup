#!/usr/bin/env bash
# lib/utils.sh — shared helpers for all gearup scripts.
# Every operation here is idempotent and honors DRY_RUN=1.

# ---------------------------------------------------------------- logging ---
# Colors only on a real terminal (keeps CI output grep-able).
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_BLUE=$'\033[1;34m' C_GREEN=$'\033[1;32m' C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m' C_DIM=$'\033[2m' C_OFF=$'\033[0m'
else
  C_BLUE='' C_GREEN='' C_YELLOW='' C_RED='' C_DIM='' C_OFF=''
fi

log()  { printf '%s[gearup]%s %s\n' "$C_BLUE" "$C_OFF" "$*"; }
ok()   { printf '  %sok%s   %s\n' "$C_GREEN" "$C_OFF" "$*"; }
skip() { printf '  %s--   %s (already done)%s\n' "$C_DIM" "$*" "$C_OFF"; }
warn() { printf '  %s!!%s   %s\n' "$C_YELLOW" "$C_OFF" "$*" >&2; }
die()  { printf '  %sFATAL%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

# Run a command, or just print it under --dry-run.
run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '  %swould run: %s%s\n' "$C_DIM" "$*" "$C_OFF"
  else
    "$@"
  fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------- install results ----
# When GEARUP_RESULTS names a file, the tool installers append one tab-separated
# line per tool: "<status>\t<name>" with status = installed | present | failed.
# install.sh prints a summary from it and the TUI reads it for a results screen.
record_result() {
  [[ -n "${GEARUP_RESULTS:-}" ]] || return 0
  printf '%s\t%s\n' "$1" "$2" >> "$GEARUP_RESULTS"
}

# gearup_summary — print a one-line tally plus the names of anything that failed.
# Uses log/warn (never the "ok"/"!!" tool prefixes) so it can't trip the CI
# "second run is a no-op" check.
gearup_summary() {
  [[ -n "${GEARUP_RESULTS:-}" && -s "${GEARUP_RESULTS:-/nonexistent}" ]] || return 0
  local n_inst n_pres n_fail verb="installed"
  read -r n_inst n_pres n_fail < <(awk -F'\t' '{c[$1]++} END{printf "%d %d %d\n", c["installed"], c["present"], c["failed"]}' "$GEARUP_RESULTS")
  [[ "${DRY_RUN:-0}" == "1" ]] && verb="would install"
  log "summary: $n_inst $verb, $n_pres already present, $n_fail failed"
  if [[ "$n_fail" -gt 0 ]]; then
    local failed
    failed=$(awk -F'\t' '$1=="failed"{print $2}' "$GEARUP_RESULTS" | sort -u | tr '\n' ' ')
    warn "failed: $failed"
    log "re-run just those with: gearup  (or ./install.sh <step>) and pick them again"
  fi
}

# ------------------------------------------------------------- tool filter ---
# GEARUP_ONLY is an optional space-separated allow-list of tool names. When it
# is empty/unset every tool installs (default; what the CLI and CI expect).
# When set, only the named tools are touched — the TUI uses this to install a
# user-picked subset. Keyed by command name (terraform, gh, dust, ...).
gearup_selected() {
  [[ -z "${GEARUP_ONLY:-}" ]] && return 0
  local want=$1 t
  for t in $GEARUP_ONLY; do
    [[ "$t" == "$want" ]] && return 0
  done
  return 1
}

# _need <cmd> — true when <cmd> is selected AND missing (so we should install
# it). Prints the "already done" skip line when it is already present. Shared by
# the tool/cloud steps so each can run standalone.
_need() {
  gearup_selected "$1" || return 1
  if has_cmd "$1"; then skip "$1"; record_result present "$1"; return 1; fi
  return 0
}

# ------------------------------------------------------------ OS detection ---
# Sets: GEARUP_OS (macos|linux), GEARUP_PKG (brew|apt|dnf|pacman)
detect_platform() {
  case "$(uname -s)" in
    Darwin) GEARUP_OS=macos ;;
    Linux)  GEARUP_OS=linux ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac

  if [[ "$GEARUP_OS" == "macos" ]]; then
    GEARUP_PKG=brew
  elif has_cmd apt-get; then
    GEARUP_PKG=apt
  elif has_cmd dnf; then
    GEARUP_PKG=dnf
  elif has_cmd pacman; then
    GEARUP_PKG=pacman
  else
    die "no supported package manager found (need apt, dnf, pacman, or brew)"
  fi
  export GEARUP_OS GEARUP_PKG
}

# Privilege helper: use sudo only when not root and it exists.
maybe_sudo() {
  if [[ "$(id -u)" == "0" ]]; then
    run "$@"
  elif has_cmd sudo; then
    run sudo "$@"
  else
    die "need root or sudo to run: $*"
  fi
}

# --------------------------------------------------------- package install ---
# pkg_install <manager-specific package name...>
pkg_install() {
  case "$GEARUP_PKG" in
    brew)   run brew install "$@" ;;
    apt)    maybe_sudo apt-get install -y "$@" ;;
    dnf)    maybe_sudo dnf install -y "$@" ;;
    pacman) maybe_sudo pacman -S --noconfirm --needed "$@" ;;
  esac
}

pkg_update_index() {
  case "$GEARUP_PKG" in
    apt)    maybe_sudo apt-get update -y ;;
    pacman) maybe_sudo pacman -Sy --noconfirm ;;
    *)      : ;; # brew/dnf resolve on install
  esac
}

# ensure_pkg <check-command> <apt-name> [dnf-name] [pacman-name] [brew-name]
# Installs the package only if <check-command> is missing.
# Omitted names default to the apt name.
ensure_pkg() {
  local cmd=$1 apt_name=$2
  local dnf_name=${3:-$apt_name} pacman_name=${4:-$apt_name} brew_name=${5:-$apt_name}
  gearup_selected "$cmd" || return 0
  if has_cmd "$cmd"; then
    skip "$cmd"
    record_result present "$cmd"
    return 0
  fi
  local name
  case "$GEARUP_PKG" in
    apt)    name=$apt_name ;;
    dnf)    name=$dnf_name ;;
    pacman) name=$pacman_name ;;
    brew)   name=$brew_name ;;
  esac
  pkg_install "$name"
  ok "installed $cmd ($name)"
  record_result installed "$cmd"
}

# ensure_brew <formula> [select-key]
# macOS only. Installs a Homebrew formula unless already present. Idempotent via
# `brew list --versions` (some formulae ship no command of their own — e.g. GNU
# coreutils — so a has_cmd probe is not enough). select-key defaults to the
# formula name and is what GEARUP_ONLY matches against.
ensure_brew() {
  local formula=$1 key=${2:-$1}
  gearup_selected "$key" || return 0
  [[ "$GEARUP_PKG" == "brew" ]] || { warn "ensure_brew $formula: not on brew, skipping"; return 0; }
  if brew list --versions "$formula" >/dev/null 2>&1; then
    skip "$formula"
    record_result present "$key"
    return 0
  fi
  run brew install "$formula"
  ok "installed $formula (brew)"
  record_result installed "$key"
}

# ---------------------------------------------------------------- symlinks ---
GEARUP_BACKUP_DIR="${GEARUP_BACKUP_DIR:-$HOME/.gearup-backup/$(date +%Y%m%d-%H%M%S)}"

# ensure_symlink <absolute-source-in-repo> <target-path>
# - no-op if the correct link already exists
# - backs up any real file/dir that is in the way, then links
ensure_symlink() {
  local src=$1 dst=$2
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    skip "link $dst"
    return 0
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    run mkdir -p "$GEARUP_BACKUP_DIR"
    run mv "$dst" "$GEARUP_BACKUP_DIR/"
    warn "existing $dst moved to $GEARUP_BACKUP_DIR/"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  ok "linked $dst -> $src"
}

# ----------------------------------------------------- sentinel rc editing ---
# ensure_block_in_file <file> <block-content>
# Writes content between sentinel markers; replaces the block on rerun
# instead of appending a duplicate.
ensure_block_in_file() {
  local file=$1 content=$2
  local begin='# >>> gearup >>>' end='# <<< gearup <<<'

  run touch "$file"
  if [[ "${DRY_RUN:-0}" == "1" && ! -f "$file" ]]; then
    printf '  %swould write gearup block into %s%s\n' "$C_DIM" "$file" "$C_OFF"
    return 0
  fi

  local desired
  desired=$(printf '%s\n%s\n%s' "$begin" "$content" "$end")

  if grep -qF "$begin" "$file" 2>/dev/null; then
    local current
    current=$(sed -n "/^$begin\$/,/^$end\$/p" "$file")
    if [[ "$current" == "$desired" ]]; then
      skip "gearup block in $file"
      return 0
    fi
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf '  %swould update gearup block in %s%s\n' "$C_DIM" "$file" "$C_OFF"
      return 0
    fi
    # Remove the old block, then append the new one.
    local tmp
    tmp=$(mktemp)
    sed "/^$begin\$/,/^$end\$/d" "$file" > "$tmp"
    mv "$tmp" "$file"
    printf '%s\n' "$desired" >> "$file"
    ok "updated gearup block in $file"
  else
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf '  %swould add gearup block to %s%s\n' "$C_DIM" "$file" "$C_OFF"
      return 0
    fi
    printf '\n%s\n' "$desired" >> "$file"
    ok "added gearup block to $file"
  fi
}
