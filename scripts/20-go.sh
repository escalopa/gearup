#!/usr/bin/env bash
# 20-go.sh — Go toolchain from official tarballs (Linux) or brew (macOS).

GO_INSTALL_DIR="/usr/local/go"

install_go_linux() {
  local version arch tarball
  version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)" # e.g. go1.24.5
  case "$(uname -m)" in
    x86_64)  arch=amd64 ;;
    aarch64) arch=arm64 ;;
    *) die "unsupported arch: $(uname -m)" ;;
  esac
  tarball="${version}.linux-${arch}.tar.gz"
  log "downloading $tarball"
  run curl -fsSL -o "/tmp/$tarball" "https://go.dev/dl/$tarball"
  maybe_sudo rm -rf "$GO_INSTALL_DIR"
  maybe_sudo tar -C /usr/local -xzf "/tmp/$tarball"
  run rm -f "/tmp/$tarball"
  ok "installed $version to $GO_INSTALL_DIR"
}

if has_cmd go; then
  skip "go ($(go version | awk '{print $3}'))"
else
  if [[ "$GEARUP_OS" == "macos" ]]; then
    pkg_install go
    ok "installed go (brew)"
  else
    install_go_linux
  fi
fi

# Make go visible for the rest of THIS install run (new shells get it
# from the gearup shell block in 60-shell.sh).
if ! has_cmd go && [[ -x "$GO_INSTALL_DIR/bin/go" ]]; then
  export PATH="$GO_INSTALL_DIR/bin:$PATH"
fi
export GOBIN="${GOBIN:-$HOME/go/bin}"
export PATH="$GOBIN:$PATH"
