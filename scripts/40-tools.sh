#!/usr/bin/env bash
# 40-tools.sh — dev tools installed through Go, Cargo, and packages.
# One line per tool; contributors add tools here. Every install honors the
# GEARUP_ONLY allow-list (via gearup_selected), so the TUI can pick a subset.
# Whole tiers are grouped under headers so one can be deleted in a single edit.

# _go_install <bin> <module@version> [build-tags]  (_need lives in lib/utils.sh)
_go_install() {
  local bin=$1 mod=$2 tags=${3:-}
  _need "$bin" || return 0
  log "go install $mod"
  if [[ -n "$tags" ]]; then run go install -tags "$tags" "$mod"; else run go install "$mod"; fi
  ok "installed $bin"
}

# _pkg_or_cargo <cmd> <pkg-name> <crate-name>
# Prefer a system package (fast, on macOS this is the common path); fall back to
# building from source with cargo when the package manager doesn't have it.
_pkg_or_cargo() {
  local cmd=$1 pkg=$2 crate=$3
  _need "$cmd" || return 0
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "would install $cmd (system pkg '$pkg', else cargo '$crate')"
    return 0
  fi
  if pkg_install "$pkg" >/dev/null 2>&1 && has_cmd "$cmd"; then
    ok "installed $cmd ($pkg)"
  elif has_cmd cargo; then
    log "cargo install $crate (building from source, may take a minute)"
    run cargo install --locked "$crate"
    ok "installed $cmd (cargo)"
  else
    warn "$cmd: no system package and cargo missing — skipping"
  fi
}

# _pkg_soft <cmd> <pkg-name> — install via the package manager, but only warn
# (never abort) when the package isn't available on this platform.
_pkg_soft() {
  local cmd=$1 pkg=$2
  _need "$cmd" || return 0
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "would install $cmd (system pkg '$pkg')"
    return 0
  fi
  if pkg_install "$pkg" >/dev/null 2>&1 && has_cmd "$cmd"; then
    ok "installed $cmd ($pkg)"
  else
    warn "$cmd: no packaged install for this platform — install it manually"
  fi
}

# ============================================================ Go tools ======
if ! has_cmd go; then
  warn "go not on PATH — skipping go tools (rerun after opening a new shell)"
else
  # ---- core Go dev toolchain ------------------------------------------------
  _go_install gopls        golang.org/x/tools/gopls@latest
  _go_install golangci-lint github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
  _go_install dlv          github.com/go-delve/delve/cmd/dlv@latest
  _go_install air          github.com/air-verse/air@latest
  _go_install goose        github.com/pressly/goose/v3/cmd/goose@latest
  _go_install mockgen      go.uber.org/mock/mockgen@latest
  _go_install goimports    golang.org/x/tools/cmd/goimports@latest
  _go_install gofumpt      mvdan.cc/gofumpt@latest

  # ---- backend / API / protobuf --------------------------------------------
  _go_install grpcurl      github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
  _go_install grpcui       github.com/fullstorydev/grpcui/cmd/grpcui@latest
  _go_install evans        github.com/ktr0731/evans@latest
  _go_install buf          github.com/bufbuild/buf/cmd/buf@latest
  _go_install sqlc         github.com/sqlc-dev/sqlc/cmd/sqlc@latest
  _go_install protoc-gen-go      google.golang.org/protobuf/cmd/protoc-gen-go@latest
  _go_install protoc-gen-go-grpc google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
  _go_install hey          github.com/rakyll/hey@latest
  _go_install usql         github.com/xo/usql@latest
  # golang-migrate needs db drivers compiled in via build tags.
  _go_install migrate      github.com/golang-migrate/migrate/v4/cmd/migrate@latest 'postgres mysql sqlite3'

  # ---- git / TUIs -----------------------------------------------------------
  _go_install lazygit      github.com/jesseduffield/lazygit@latest
  _go_install lazydocker   github.com/jesseduffield/lazydocker@latest
  _go_install lazysql      github.com/jorgerojas26/lazysql@latest
  _go_install yq           github.com/mikefarah/yq/v4@latest

  # ---- devops / cloud (Go-installable; heavier CLIs live in 70-cloud.sh) -----
  _go_install k9s          github.com/derailed/k9s@latest
  _go_install terraform-docs github.com/terraform-docs/terraform-docs@latest
  _go_install dive         github.com/wagoodman/dive@latest
  _go_install cosign       github.com/sigstore/cosign/v2/cmd/cosign@latest

  # ---- VCS / CI / workflow --------------------------------------------------
  _go_install glab         gitlab.com/gitlab-org/cli/cmd/glab@latest
  _go_install act          github.com/nektos/act@latest
  _go_install gitleaks     github.com/gitleaks/gitleaks/v8@latest
  _go_install shfmt        mvdan.cc/sh/v3/cmd/shfmt@latest

  # ---- Charm UX -------------------------------------------------------------
  _go_install glow         github.com/charmbracelet/glow@latest
  _go_install gum          github.com/charmbracelet/gum@latest
fi

# ================================== Modern CLI tools (rust/go awesome) ======
# Fast, ergonomic replacements for classic Unix tools. Prefer a system package,
# fall back to cargo. bat/eza/zoxide/fd/ripgrep already come from 10-packages.sh.
_pkg_or_cargo dust      dust      du-dust      # nicer `du`
_pkg_or_cargo procs     procs     procs        # nicer `ps`
_pkg_or_cargo sd        sd        sd           # nicer `sed` for simple subs
_pkg_or_cargo hyperfine hyperfine hyperfine    # command benchmarking
_pkg_or_cargo tokei     tokei     tokei        # count lines of code
_pkg_or_cargo btm       bottom    bottom       # nicer `top` (binary: btm)
_pkg_or_cargo gitui     gitui     gitui        # git TUI (rust)
_pkg_or_cargo eza       eza       eza          # modern `ls`
_pkg_or_cargo xh        xh        xh           # friendly HTTP client

# ================================== VCS / CI / dev-workflow packages ========
ensure_pkg direnv  direnv                       # per-project env (.envrc)
_pkg_soft   gh     gh                            # GitHub CLI
_pkg_or_cargo just just just                     # command runner (Makefile-like)
_pkg_soft   mkcert mkcert                         # locally-trusted TLS certs

# ================================== Optional tier: DB clients ===============
ensure_pkg redis-cli redis-tools redis redis redis   # redis-cli
_pkg_soft   pgcli  pgcli                              # smart Postgres REPL
# usql, lazysql are Go-installable — see the Go tools section above.

# ================================== Optional tier: security scanners ========
_pkg_soft trivy    trivy                          # image / IaC / secret scanner
_pkg_soft hadolint hadolint                        # Dockerfile linter
# cosign is Go-installable — see the Go tools section above.

# ================================== Optional tier: API / proto extras =======
_pkg_or_cargo websocat  websocat  websocat        # WebSocket cURL
_pkg_or_cargo tldr      tealdeer  tealdeer         # fast, community man pages
_pkg_or_cargo jless     jless     jless            # JSON/YAML pager
_pkg_or_cargo watchexec watchexec watchexec-cli    # run a command on file change
