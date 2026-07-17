#!/usr/bin/env bash
# 30-rust.sh — Rust toolchain via rustup (non-interactive).
# Rust is here mainly as an installer: several great CLI tools ship via
# cargo when a distro's packages are old or missing.

if has_cmd cargo || [[ -x "$HOME/.cargo/bin/cargo" ]]; then
  skip "rust (cargo present)"
else
  log "installing rustup (non-interactive, default toolchain)"
  run bash -c 'curl --proto "=https" --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path'
  ok "installed rust via rustup"
fi

# Visible for the rest of this run; new shells get it from the shell block.
export PATH="$HOME/.cargo/bin:$PATH"
