# gearup shell additions — sourced from .bashrc AND .zshrc (keep it portable).
# shellcheck shell=sh disable=SC1091,SC3043

# ---- PATH ------------------------------------------------------------------
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":/usr/local/go/bin:"*) ;; *) PATH="/usr/local/go/bin:$PATH" ;; esac
case ":$PATH:" in *":$HOME/go/bin:"*) ;; *) PATH="$HOME/go/bin:$PATH" ;; esac
case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH" ;; esac
export PATH
export GOBIN="$HOME/go/bin"

# ---- GNU userland on macOS -------------------------------------------------
# Make sed/awk/find/date/tar/grep behave like on Linux servers by putting the
# Homebrew gnubin dirs first. Installed by scripts/15-gnu.sh. No subprocess per
# shell start — the prefix is a fixed path.
if [ "$(uname -s)" = "Darwin" ]; then
  _gu_brew="${HOMEBREW_PREFIX:-/opt/homebrew}"
  [ -d "$_gu_brew" ] || _gu_brew="/usr/local"
  for _gu_f in coreutils findutils gnu-sed gawk gnu-tar grep gnu-getopt make; do
    _gu_bin="$_gu_brew/opt/$_gu_f/libexec/gnubin"
    _gu_man="$_gu_brew/opt/$_gu_f/libexec/gnuman"
    [ -d "$_gu_bin" ] && case ":$PATH:" in *":$_gu_bin:"*) ;; *) PATH="$_gu_bin:$PATH" ;; esac
    [ -d "$_gu_man" ] && case ":${MANPATH:-}:" in *":$_gu_man:"*) ;; *) MANPATH="$_gu_man:${MANPATH:-}" ;; esac
  done
  export PATH MANPATH
  unset _gu_brew _gu_f _gu_bin _gu_man
fi

export EDITOR=nvim
export VISUAL=nvim

# ---- workspace roots (where `ws` looks for projects) -----------------------
# Colon-separated list of dirs whose CHILDREN are projects. Override in your rc
# BEFORE the gearup block, or export it here.
export WS_ROOTS="${WS_ROOTS:-$HOME/work:$HOME/projects:$HOME/src}"

# ---- aliases ----------------------------------------------------------------
alias v='nvim'
alias t='tmux'
alias ta='tmux attach || tmux new'
alias lg='lazygit'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph -15'
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -la --git'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -la'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
# modern replacements (interactive-only; scripts still call the real binaries)
command -v dust  >/dev/null 2>&1 && alias du='dust'
command -v procs >/dev/null 2>&1 && alias ps='procs'
command -v btm   >/dev/null 2>&1 && alias top='btm'
command -v tldr  >/dev/null 2>&1 && alias help='tldr'
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'
command -v k9s   >/dev/null 2>&1 && alias k='kubectl'
command -v terraform >/dev/null 2>&1 && alias tf='terraform'

# ---- functions ---------------------------------------------------------------
mkcd() { mkdir -p "$1" && cd "$1" || return; }

# grep the codebase and open the picked match in nvim at the right line
vg() {
  local pick
  pick=$(rg --line-number --no-heading --color=always "$@" |
    fzf --ansi --delimiter=: --preview 'bat --color=always --highlight-line {2} {1}') || return
  nvim "+${pick#*:}" "${pick%%:*}"
}

# ---- tool init (each guarded — fine if a tool is missing) --------------------
if command -v zoxide >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then eval "$(zoxide init zsh)"; else eval "$(zoxide init bash)"; fi
fi

if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.48 ships shell integration (Ctrl-R history, Ctrl-T files, Alt-C cd)
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(fzf --zsh 2>/dev/null)" || true
  else
    eval "$(fzf --bash 2>/dev/null)" || true
  fi
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border'
fi

command -v direnv >/dev/null 2>&1 && {
  if [ -n "${ZSH_VERSION:-}" ]; then eval "$(direnv hook zsh)"; else eval "$(direnv hook bash)"; fi
}

# ---- zsh-only: plugins (cloned by scripts/45-zsh.sh) -----------------------
# zsh-specific syntax (fpath arrays, autoload) lives in its own file so the
# POSIX-sh shellcheck of this file stays clean.
if [ -n "${ZSH_VERSION:-}" ] && [ -f "$HOME/.config/gearup/shell.zsh" ]; then
  . "$HOME/.config/gearup/shell.zsh"
fi

# ---- starship prompt (cross-shell; keep last so it wins the prompt) ---------
if command -v starship >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then eval "$(starship init zsh)"; else eval "$(starship init bash)"; fi
fi
