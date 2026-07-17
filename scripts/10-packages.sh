#!/usr/bin/env bash
# 10-packages.sh — system packages via the detected package manager.
# Sourced by install.sh; utils already loaded.

# Homebrew itself (macOS only)
if [[ "$GEARUP_OS" == "macos" ]] && ! has_cmd brew; then
  log "installing Homebrew"
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

pkg_update_index

# ensure_pkg <command> <apt> [dnf] [pacman] [brew]  (omitted = same as apt)
ensure_pkg git      git
ensure_pkg curl     curl
ensure_pkg tmux     tmux
ensure_pkg nvim     neovim
ensure_pkg rg       ripgrep
ensure_pkg fzf      fzf
ensure_pkg jq       jq
ensure_pkg htop     htop
ensure_pkg tree     tree
ensure_pkg make     make make base-devel make
ensure_pkg gcc      build-essential gcc gcc gcc      # cgo + treesitter builds
ensure_pkg unzip    unzip
ensure_pkg fd       fd-find fd-find fd fd
ensure_pkg bat      bat bat bat bat
ensure_pkg zoxide   zoxide
ensure_pkg delta    git-delta git-delta git-delta git-delta
ensure_pkg shellcheck shellcheck ShellCheck shellcheck shellcheck
ensure_pkg dig      dnsutils bind-utils bind dnsutils

# Debian/Ubuntu quirk: binaries are fdfind/batcat; expose canonical names.
if [[ "$GEARUP_PKG" == "apt" ]]; then
  run mkdir -p "$HOME/.local/bin"
  if has_cmd fdfind && ! has_cmd fd; then
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "aliased fdfind -> fd"
  fi
  if has_cmd batcat && ! has_cmd bat; then
    run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    ok "aliased batcat -> bat"
  fi
fi
