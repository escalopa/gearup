#!/usr/bin/env bash
# 40-tools.sh — dev tools installed through Go and Cargo.
# One line per tool; contributors add tools here.

# ---- Go tools: "<binary>=<module@version>" -------------------------------
GO_TOOLS=(
  "gopls=golang.org/x/tools/gopls@latest"                                  # Go LSP
  "golangci-lint=github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest" # linter
  "dlv=github.com/go-delve/delve/cmd/dlv@latest"                           # debugger
  "air=github.com/air-verse/air@latest"                                    # live reload
  "goose=github.com/pressly/goose/v3/cmd/goose@latest"                     # migrations
  "mockgen=go.uber.org/mock/mockgen@latest"                                # mocks
  "goimports=golang.org/x/tools/cmd/goimports@latest"                      # imports fmt
  "gofumpt=mvdan.cc/gofumpt@latest"                                        # stricter fmt
  "grpcurl=github.com/fullstorydev/grpcurl/cmd/grpcurl@latest"             # gRPC curl
  "lazygit=github.com/jesseduffield/lazygit@latest"                        # git TUI
  "yq=github.com/mikefarah/yq/v4@latest"                                   # YAML jq
)

# ---- Cargo tools (fallback when the distro package doesn't exist) --------
CARGO_TOOLS=(
  "eza"   # modern ls
  "xh"    # friendly HTTP client (httpie-like, single binary)
)

if ! has_cmd go; then
  warn "go not on PATH — skipping go tools (rerun after opening a new shell)"
else
  for entry in "${GO_TOOLS[@]}"; do
    bin="${entry%%=*}" mod="${entry#*=}"
    if has_cmd "$bin"; then
      skip "$bin"
    else
      log "go install $mod"
      run go install "$mod"
      ok "installed $bin"
    fi
  done
fi

if ! has_cmd cargo; then
  warn "cargo not on PATH — skipping cargo tools"
else
  for bin in "${CARGO_TOOLS[@]}"; do
    if has_cmd "$bin"; then
      skip "$bin"
    else
      # Prefer the system package when it exists; cargo builds from source.
      if pkg_install "$bin" 2>/dev/null; then
        ok "installed $bin (system package)"
      else
        log "cargo install $bin (building from source, may take a minute)"
        run cargo install --locked "$bin"
        ok "installed $bin (cargo)"
      fi
    fi
  done
fi
