# gearup aliases — common shortcuts for the tools gearup installs.
# Sourced from config/shell/gearup.sh; works in bash and zsh. Tool-specific
# aliases are guarded so they only exist when the tool does. Aliases are
# interactive-only — scripts still call the real binaries.
# shellcheck shell=sh

# ---- files / listing -------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -la --git'
  alias la='eza -a'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -la'
  alias la='ls -A'
fi
command -v bat   >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v dust  >/dev/null 2>&1 && alias du='dust'
command -v procs >/dev/null 2>&1 && alias ps='procs'
command -v btm   >/dev/null 2>&1 && alias top='btm'
command -v tldr  >/dev/null 2>&1 && alias help='tldr'

# ---- editor / tmux ---------------------------------------------------------
command -v nvim >/dev/null 2>&1 && { alias v='nvim'; alias vi='nvim'; }
command -v tmux >/dev/null 2>&1 && { alias t='tmux'; alias ta='tmux attach || tmux new'; alias tl='tmux ls'; }

# ---- git -------------------------------------------------------------------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph -15'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias grb='git rebase'
alias gst='git stash'
alias gstp='git stash pop'
command -v lazygit    >/dev/null 2>&1 && alias lg='lazygit'
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'

# ---- go --------------------------------------------------------------------
if command -v go >/dev/null 2>&1; then
  alias gob='go build ./...'
  alias got='go test ./...'
  alias gor='go run .'
  alias gov='go vet ./...'
  alias gomt='go mod tidy'
fi

# ---- docker ----------------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  alias d='docker'
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dcu='docker compose up -d'
  alias dcd='docker compose down'
fi

# ---- kubernetes ------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
  alias kg='kubectl get'
  alias kgp='kubectl get pods'
  alias kgs='kubectl get svc'
  alias kd='kubectl describe'
  alias kaf='kubectl apply -f'
  alias kl='kubectl logs -f'
  alias kx='kubectl exec -it'
fi
command -v k9s  >/dev/null 2>&1 && alias k9='k9s'
command -v helm >/dev/null 2>&1 && alias hm='helm'

# ---- terraform -------------------------------------------------------------
if command -v terraform >/dev/null 2>&1; then
  alias tf='terraform'
  alias tfi='terraform init'
  alias tfp='terraform plan'
  alias tfa='terraform apply'
  alias tfd='terraform destroy'
  alias tff='terraform fmt -recursive'
  alias tfo='terraform output'
fi

# ---- yandex cloud ----------------------------------------------------------
command -v yc >/dev/null 2>&1 && alias ycl='yc'
