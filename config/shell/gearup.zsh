# gearup zsh-only additions — sourced from config/shell/gearup.sh under zsh.
# Kept separate because it uses zsh syntax (fpath arrays, autoload, bindkey)
# that a POSIX-sh linter can't parse. Plugins are cloned by scripts/45-zsh.sh.

_gu_zsh="$HOME/.config/gearup/zsh/plugins"

# completions must be on fpath before compinit
[ -d "$_gu_zsh/zsh-completions/src" ] && fpath=("$_gu_zsh/zsh-completions/src" $fpath)
autoload -Uz compinit && compinit -u

[ -f "$_gu_zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
  && source "$_gu_zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

if [ -f "$_gu_zsh/zsh-history-substring-search/zsh-history-substring-search.zsh" ]; then
  source "$_gu_zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up 2>/dev/null
  bindkey '^[[B' history-substring-search-down 2>/dev/null
fi

# syntax-highlighting must be sourced LAST
[ -f "$_gu_zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
  && source "$_gu_zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset _gu_zsh
