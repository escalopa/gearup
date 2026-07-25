# Changelog

Release notes are generated automatically from commit history by GoReleaser and
published at https://github.com/escalopa/gearup/releases. This file captures the
high-level story; see the Releases page for the per-version detail.

## Unreleased

- **`gearup` TUI** (Go / Bubble Tea): interactive front-end over the idempotent
  installer — pick whole steps or hand-pick individual tools, watch them install
  live, and run `gearup doctor` to see what's present vs missing.
- **Terraform + devops tooling**: terraform, tflint, terraform-docs, kubectl,
  helm, k9s, aws-cli, lazydocker, dive — installable on macOS and Linux.
- **Expanded tool catalog**: backend/API (buf, sqlc, grpcui, evans,
  golang-migrate, hey, usql), modern CLIs (dust, procs, sd, hyperfine, tokei,
  bottom, gitui), workflow (gh, glab, direnv, just, mkcert, act, gitleaks, shfmt,
  glow, gum), DB clients, security scanners, and API extras.
- **GNU userland on macOS**: coreutils, findutils, gnu-sed, gawk, gnu-tar, grep,
  gnu-getopt — so `sed`/`awk`/`find`/`date`/`tar` behave like on Linux.
- **zsh + starship**: zsh with autosuggestions/syntax-highlighting/completions/
  history-search plugins and a backend-aware starship prompt.
- **Per-tool selection**: a `GEARUP_ONLY` allow-list lets the TUI install exactly
  the tools you choose while reusing the same idempotent scripts.
- **Install results report**: every run records each tool as installed / already
  present / failed. The CLI prints a tally (naming failures) and the TUI shows a
  results summary. Installation is strictly sequential — never concurrent.
- **AI coding CLIs** (opt-in): claude (Claude Code), codex (OpenAI), opencode,
  and gemini-cli, each installed via its own distribution (Homebrew on macOS,
  npm elsewhere).
- **Releases & packages**: GoReleaser publishes cross-platform binaries plus
  deb/rpm/apk packages and checksums on every `vX.Y.Z` tag.
