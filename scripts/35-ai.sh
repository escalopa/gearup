#!/usr/bin/env bash
# 35-ai.sh — AI coding CLIs, installed through each provider's own distribution
# (Homebrew on macOS, npm elsewhere). No custom packaging — just the upstream
# channels.
#
# These live outside the system package manager and pull from npm/brew, so they
# are OPT-IN for a full `./install.sh`: they install when you pick them in the
# TUI, run `./install.sh ai`, or set GEARUP_AI=1. A plain full install skips them.

if [[ -z "${GEARUP_ONLY:-}" && "${GEARUP_EXPLICIT_STEPS:-0}" != "1" && "${GEARUP_AI:-0}" != "1" ]]; then
  skip "AI coding tools (opt-in: pick them in 'gearup', run './install.sh ai', or GEARUP_AI=1)"
else
  # npm-installed CLIs land in the global prefix bin; make sure has_cmd can see
  # freshly-installed ones for the idempotency check.
  export PATH="$HOME/.local/bin:$PATH"

  # Node/npm is the common distribution channel for these tools.
  _ai_ensure_node() {
    has_cmd npm && return 0
    [[ "${DRY_RUN:-0}" == "1" ]] && { log "would install node/npm"; return 0; }
    ensure_pkg npm npm npm npm node >/dev/null 2>&1 || true
    has_cmd npm
  }

  # _ai_install <cmd> <brew-formula|-> <npm-package>
  # Prefer Homebrew on macOS; otherwise use npm. Soft: warns, never aborts.
  _ai_install() {
    local cmd=$1 brewf=$2 npmpkg=$3
    _need "$cmd" || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      if [[ "$GEARUP_OS" == "macos" && "$brewf" != "-" ]]; then
        log "would install $cmd (brew '$brewf', else npm '$npmpkg')"
      else
        log "would install $cmd (npm '$npmpkg')"
      fi
      return 0
    fi
    if [[ "$GEARUP_OS" == "macos" && "$brewf" != "-" ]] && pkg_install "$brewf" >/dev/null 2>&1 && has_cmd "$cmd"; then
      ok "installed $cmd ($brewf)"; record_result installed "$cmd"
      return 0
    fi
    if _ai_ensure_node && run npm install -g "$npmpkg" && has_cmd "$cmd"; then
      ok "installed $cmd (npm $npmpkg)"; record_result installed "$cmd"
    else
      warn "$cmd: install failed — try 'npm install -g $npmpkg' (needs node), or brew '$brewf'"; record_result failed "$cmd"
    fi
  }

  # _ai_pip_install <cmd> <pypi-package>
  # Python-distributed tools: prefer uv, then pipx, then pip --user. Soft.
  _ai_pip_install() {
    local cmd=$1 pkg=$2 ok_flag=0
    _need "$cmd" || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "would install $cmd (uv/pipx/pip package '$pkg')"
      return 0
    fi
    # Ensure at least one Python installer exists (prefer pipx if we must add one).
    if ! has_cmd uv && ! has_cmd pipx && ! has_cmd pip3 && ! has_cmd pip; then
      if [[ "$GEARUP_OS" == "macos" ]]; then
        pkg_install pipx >/dev/null 2>&1 || true
      else
        ensure_pkg pipx pipx pipx python-pipx pipx >/dev/null 2>&1 || true
      fi
    fi
    if has_cmd uv; then
      if run uv tool install "$pkg"; then ok_flag=1; fi
    elif has_cmd pipx; then
      if run pipx install "$pkg"; then ok_flag=1; fi
    elif has_cmd pip3; then
      if run pip3 install --user "$pkg"; then ok_flag=1; fi
    elif has_cmd pip; then
      if run pip install --user "$pkg"; then ok_flag=1; fi
    fi
    if [[ "$ok_flag" == "1" ]] && has_cmd "$cmd"; then
      ok "installed $cmd ($pkg)"; record_result installed "$cmd"
    else
      warn "$cmd: install failed — try 'uv tool install $pkg' or 'pipx install $pkg'"; record_result failed "$cmd"
    fi
  }

  # command      brew formula   npm package
  _ai_install claude    -             @anthropic-ai/claude-code   # Claude Code (Anthropic)
  _ai_install codex     codex         @openai/codex               # Codex CLI (OpenAI)
  _ai_install opencode  opencode      opencode-ai                 # opencode (open source)
  _ai_install gemini    gemini-cli    @google/gemini-cli          # Gemini CLI (Google)

  # Python-distributed. PyPI package is "graphifyy" (double-y); binary is "graphify".
  # After install, run `graphify install` to register it with your AI assistant(s).
  _ai_pip_install graphify graphifyy
fi
