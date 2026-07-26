# gearup completions — shell command completion for the tools gearup installs.
# Sourced from config/shell/gearup.sh (under zsh: after compinit runs). Each tool
# has its own mechanism; every block is guarded so it only runs when the tool is
# present and stays quiet if generation fails. This is the single "autocomplete"
# section — add new tools here.
#
# Not POSIX sh (uses shell builtins like `complete`); linted by neither the sh
# check nor the bash check, so keep it defensive.
# shellcheck shell=bash disable=SC1090,SC1091,SC2296,SC3044,SC3057

if [ -n "${ZSH_VERSION:-}" ]; then
  _gu_shell=zsh
  # `complete -C` tools (terraform) need bash-style completion in zsh.
  autoload -U +X bashcompinit 2>/dev/null && bashcompinit 2>/dev/null
else
  _gu_shell=bash
fi

# ---- cobra-style: `<tool> completion <shell>` ------------------------------
for _gu_t in kubectl helm k9s yc buf docker cosign dive; do
  if command -v "$_gu_t" >/dev/null 2>&1; then
    eval "$("$_gu_t" completion "$_gu_shell" 2>/dev/null)" 2>/dev/null || true
  fi
done
unset _gu_t

# ---- GitHub / GitLab CLIs (use `-s <shell>`) -------------------------------
command -v gh   >/dev/null 2>&1 && { eval "$(gh   completion -s "$_gu_shell" 2>/dev/null)" 2>/dev/null || true; }
command -v glab >/dev/null 2>&1 && { eval "$(glab completion -s "$_gu_shell" 2>/dev/null)" 2>/dev/null || true; }

# ---- just (`--completions <shell>`) ----------------------------------------
command -v just >/dev/null 2>&1 && { eval "$(just --completions "$_gu_shell" 2>/dev/null)" 2>/dev/null || true; }

# ---- HashiCorp (terraform: `complete -C <bin> <bin>`) ----------------------
if command -v terraform >/dev/null 2>&1; then
  complete -o nospace -C "$(command -v terraform)" terraform 2>/dev/null || true
fi

# ---- Google Cloud SDK (source the SDK's own inc files) ---------------------
# gcloud ships completion.<shell>.inc and path.<shell>.inc; sourcing path.inc
# also puts gcloud/gsutil on PATH. Locations differ by install method.
for _gu_gc in \
  "$HOME/google-cloud-sdk" \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk" \
  "/usr/local/share/google-cloud-sdk" \
  "/usr/share/google-cloud-sdk"; do
  if [ -f "$_gu_gc/path.$_gu_shell.inc" ]; then
    . "$_gu_gc/path.$_gu_shell.inc" 2>/dev/null || true
    [ -f "$_gu_gc/completion.$_gu_shell.inc" ] && { . "$_gu_gc/completion.$_gu_shell.inc" 2>/dev/null || true; }
    break
  fi
done
unset _gu_gc

unset _gu_shell
