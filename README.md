# gearup

[![ci](https://github.com/escalopa/gearup/actions/workflows/ci.yml/badge.svg)](https://github.com/escalopa/gearup/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/escalopa/gearup?sort=semver)](https://github.com/escalopa/gearup/releases/latest)
[![license](https://img.shields.io/github/license/escalopa/gearup)](LICENSE)

Gear up any Linux or macOS box for Go backend work — in one command,
safely, as many times as you like.

```sh
curl -fsSL https://raw.githubusercontent.com/escalopa/gearup/main/bootstrap.sh | bash
```

That clones the repo into `~/.gearup` (configs symlink from there) and
runs the installer. Prefer to look first? Clone it yourself:

```sh
git clone https://github.com/escalopa/gearup && cd gearup && ./install.sh
```

**Every install method** — one-liner, `go install`, prebuilt binaries, and
deb/rpm/apk packages for macOS and each Linux distro — is in
**[INSTALL.md](INSTALL.md)**. Release notes live on the
[Releases](https://github.com/escalopa/gearup/releases) page.

Rerun it whenever: every step checks before it acts, existing files are
backed up (never overwritten), and rc-file edits live between sentinel
markers so they update in place instead of piling up. `./install.sh
--dry-run` shows the plan without touching anything; `./uninstall.sh`
removes the links and blocks.

## What you get

| | Tools |
|---|---|
| Terminal | tmux, Neovim, fzf, ripgrep, fd, bat, eza, zoxide, jq, yq, htop, tree; modern extras: dust, procs, sd, hyperfine, tokei, bottom, gitui |
| Shell | **zsh** + autosuggestions/syntax-highlighting/completions/history-search, and the **starship** prompt (git/go/k8s/aws/terraform aware) |
| Git | delta diffs, lazygit, gitui, sane aliases (via an *included* gitconfig — yours is untouched) |
| Go | toolchain + gopls, golangci-lint, dlv, air, goose, mockgen, goimports, gofumpt |
| Backend / API | grpcurl, grpcui, evans, buf, sqlc, protoc-gen-go(-grpc), golang-migrate, hey, usql, xh, dig |
| IaC / Cloud | **terraform**, tflint, terraform-docs, kubectl, helm, k9s, aws-cli |
| Containers | lazydocker, dive |
| Workflow | gh, glab, direnv, just, mkcert, act, gitleaks, shfmt, glow, gum |
| Database | redis-cli, pgcli, usql, lazysql |
| Security | trivy, hadolint, cosign, gitleaks, age (+ age-keygen) |
| AI coding | claude (Claude Code), codex (OpenAI), opencode, gemini-cli, graphify — **opt-in**, each via its own channel (brew / npm / pipx) |
| GNU on macOS | coreutils, findutils, gnu-sed, gawk, gnu-tar, grep, gnu-getopt — so `sed`/`awk`/`find`/`date`/`tar` behave like on Linux |
| Toolchains | Go (official tarball / brew) and Rust (rustup) — they also build everything above that ships via `go install` / `cargo install` |

Everything is à la carte: the **`gearup` TUI** (below) lets you install whole
categories or hand-pick individual tools, and shows what's already present.

The **AI coding** CLIs are opt-in (they install from npm/brew, outside the system
package manager). Pick them in the TUI, or run `./install.sh ai` /
`GEARUP_AI=1 ./install.sh`; a plain full install skips them.

…plus opinionated, portable configs, symlinked from this repo, so a
`git pull` updates every machine you own:

- **tmux** with `Ctrl-a` prefix, vi copy-mode, a **workspace switcher**
  (`Ctrl-a g`): fuzzy-pick any project → it opens as its own session,
  layout preserved — plus TPM plugins installed automatically:
  tmux-sensible, vim-tmux-navigator, tmux-yank, and
  tmux-resurrect/continuum so sessions survive reboots.
- **Neovim (Lua)** built for huge codebases: fzf-lua (streamed
  ripgrep — no indexing), gopls tuned with `directoryFilters` and a
  completion budget, harpoon file pins, oil.nvim, flash.nvim jumps,
  trouble.nvim diagnostics, nvim-surround, treesitter, gitsigns, and
  which-key so the keymap teaches itself.
- **Shell block** for bash *and* zsh: PATH wiring, GNU userland on macOS,
  zoxide, fzf keybindings, zsh plugins, starship, and the `ws` switcher.

## The `gearup` TUI

The installer builds a small Go TUI and puts it on your PATH as `gearup`. It's
the friendly front-end to everything above — it does not replace the scripts,
it drives them, so the idempotency guarantees still hold.

```sh
gearup           # interactive: pick steps or individual tools, watch them install
gearup doctor    # non-interactive: report which tools are installed / missing
```

Inside the TUI: `space` selects a whole step, `enter` drills into a step to
**hand-pick individual tools**, `r` runs your selection with live output, `d`
toggles dry-run, `D` opens the doctor view, `q` quits. After a run it shows a
**results summary** — how many tools were installed, were already present, and
**which ones failed** (by name). The CLI prints the same tally at the end of
`./install.sh`, and `gearup doctor` reports installed-vs-missing any time. Picking a subset of tools
just scopes that step (via `GEARUP_ONLY`) — the same idempotent scripts run
underneath. Build it yourself anytime with `make install`.

## Learn the workflow

- **[TUTORIAL.md](TUTORIAL.md)** — a guided, hands-on tour using the
  bundled `demo/` Go workspace (shared package + two services under
  `go.work`, sized like a slice of a real monorepo).
- **[CHEATSHEET.md](CHEATSHEET.md)** — one page of keys worth printing.

## Layout

```
install.sh          entry point (idempotent; --dry-run supported)
bootstrap.sh        curl-able one-command installer (clones + installs)
lib/utils.sh        ensure_pkg / ensure_brew / ensure_symlink / gearup_selected
scripts/NN-*.sh     steps in order: packages, gnu, go, rust, ai, tools, zsh,
                    symlinks, tmux plugins, shell, cloud, tui
config/             every dotfile (incl. starship.toml), symlinked into $HOME
cmd/gearup/         the TUI entry point (Go)
internal/           TUI internals: catalog (steps+tools), runner, model
Makefile            build / install / doctor / snapshot the TUI
.goreleaser.yaml    release build: binaries + deb/rpm/apk + checksums
INSTALL.md          every install method, per-OS; CHANGELOG.md tracks versions
bin/ws              the workspace switcher (pure bash: fd/find + fzf + zoxide)
demo/               practice codebase for the tutorial
```

Add a tool = one line in `scripts/10-packages.sh` (system package) or
`scripts/40-tools.sh` (go/cargo), plus one entry in
[`internal/catalog/catalog.go`](internal/catalog/catalog.go) so it shows up in
the TUI/doctor (keyed by command name). Heavy cloud CLIs live in
`scripts/70-cloud.sh`. PRs welcome.

> **Note on `GOROOT`:** if your shell exports a `GOROOT` from another toolchain
> (e.g. a company `ya`/bazel Go) that differs from the `go` on your PATH,
> `go install` normally fails with *"compile version does not match"*. gearup's
> Go step detects this and realigns `GOROOT` **for the install run only** — your
> interactive shell and other toolchains are left untouched.

## Machine-local overrides

Need a custom gopls on one machine (company monorepos often ship a
patched build)? Drop a `config/nvim/lua/gearup_local.lua` returning
`{ cmd = ..., root_dir = ..., settings = ... }` — it's gitignored, so
machine- or company-specific setup never leaks into this repo.

## Supported

Ubuntu/Debian (apt), Fedora/RHEL (dnf), Arch (pacman), macOS (brew).
WSL Ubuntu works via the apt path. Windows-native is out of scope.

MIT licensed.
