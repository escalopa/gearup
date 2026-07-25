#!/usr/bin/env bash
# 45-zsh.sh — zsh, a curated set of plugins, and the starship prompt.
# Plugins are plain git clones (no framework) into ~/.config/gearup/zsh/plugins
# and are sourced by config/shell/gearup.sh when the shell is zsh. starship is
# initialized there too. We do NOT change your login shell — see the hint below.

# ---- zsh itself ------------------------------------------------------------
ensure_pkg zsh zsh

# ---- starship prompt (cross-platform) --------------------------------------
if gearup_selected starship; then
  if has_cmd starship; then
    skip "starship"
  elif [[ "$GEARUP_OS" == "macos" ]]; then
    pkg_install starship && ok "installed starship (brew)"
  elif pkg_install starship >/dev/null 2>&1 && has_cmd starship; then
    ok "installed starship (system package)"
  else
    run mkdir -p "$HOME/.local/bin"
    log "installing starship (official installer -> ~/.local/bin)"
    run sh -c 'curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"'
    ok "installed starship"
  fi
fi

# ---- zsh plugins (framework-free git clones) -------------------------------
ZSH_PLUGIN_DIR="$HOME/.config/gearup/zsh/plugins"
# name=repo-url
ZSH_PLUGINS=(
  "zsh-autosuggestions=https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-syntax-highlighting=https://github.com/zsh-users/zsh-syntax-highlighting"
  "zsh-completions=https://github.com/zsh-users/zsh-completions"
  "zsh-history-substring-search=https://github.com/zsh-users/zsh-history-substring-search"
)

if gearup_selected zsh-plugins; then
  run mkdir -p "$ZSH_PLUGIN_DIR"
  for entry in "${ZSH_PLUGINS[@]}"; do
    name="${entry%%=*}" url="${entry#*=}"
    dest="$ZSH_PLUGIN_DIR/$name"
    if [[ -d "$dest/.git" ]]; then
      skip "zsh plugin $name"
    else
      log "cloning zsh plugin $name"
      run git clone --depth 1 "$url" "$dest"
      ok "installed zsh plugin $name"
    fi
  done
fi

# ---- friendly nudge (never auto-chsh — that's a surprising system change) ---
if has_cmd zsh && [[ "${SHELL:-}" != *zsh ]]; then
  log "zsh is installed but not your login shell. To switch: chsh -s \"\$(command -v zsh)\""
fi
