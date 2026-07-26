# Installing gearup

`gearup` has two parts that install together:

1. **The dev environment** — the idempotent installer (`install.sh` + step
   scripts) that sets up tmux, Neovim, Go tooling, Terraform, GNU userland on
   macOS, zsh + starship, and the rest.
2. **The `gearup` TUI** — a small Go binary that drives that installer so you can
   pick steps or individual tools interactively, and check what's installed
   (`gearup doctor`).

The recommended path installs both in one command. If you only want the CLI
binary (e.g. for `gearup doctor` in CI), jump to
[Just the TUI binary](#just-the-tui-binary).

> **Supported:** macOS (Apple Silicon & Intel), Ubuntu/Debian (apt),
> Fedora/RHEL (dnf), Arch (pacman). WSL Ubuntu works via the apt path.
> Windows-native is out of scope.

---

## Recommended: one command (macOS & Linux)

```sh
curl -fsSL https://raw.githubusercontent.com/escalopa/gearup/main/bootstrap.sh | bash
```

This clones the repo into `~/.gearup`, runs the idempotent installer, and builds
the `gearup` TUI onto your `PATH` at `~/.local/bin/gearup`. It is safe to re-run
any time — every step checks before it acts and existing files are backed up,
never overwritten.

Prefer to read before you run? Clone and install manually:

```sh
git clone https://github.com/escalopa/gearup ~/.gearup
cd ~/.gearup
./install.sh --dry-run   # show the plan, change nothing
./install.sh             # do it
```

Then open a new shell (or `source ~/.zshrc` / `source ~/.bashrc`) and run:

```sh
gearup          # interactive installer / tool picker
gearup doctor   # what's installed vs missing
```

### Prerequisites

Only `git` and `curl` are required to bootstrap; the installer brings the rest.

| OS | Get the prerequisites |
|----|----------------------|
| macOS | Xcode CLT (`xcode-select --install`); Homebrew is installed for you if missing |
| Debian/Ubuntu | `sudo apt-get install -y git curl ca-certificates` |
| Fedora/RHEL | `sudo dnf install -y git curl` |
| Arch | `sudo pacman -S --needed git curl` |

On Linux, some steps use `sudo` for system packages. On macOS everything goes
through Homebrew (no `sudo`).

### Scoping the install

You do not have to install everything at once:

```sh
./install.sh --dry-run           # preview the full plan
./install.sh packages go tools   # run only these steps
gearup                           # or pick steps / individual tools in the TUI
```

Steps, in run order: `packages · gnu · go · rust · ai · tools · zsh ·
symlinks · tmux-plugins · shell · cloud · tui`.

### AI coding tools (opt-in)

The `ai` step installs claude (Claude Code), codex, opencode, gemini-cli, and
graphify via each provider's own channel (Homebrew/npm for most; graphify is a
Python tool installed with uv/pipx/pip). Because they come from npm/brew/pipx
rather than the system package manager, a plain full install skips them. Install
them any of these ways:

```sh
gearup                      # pick them in the TUI (AI coding category)
./install.sh ai             # install all four
GEARUP_AI=1 ./install.sh    # include them in a full install
```

The npm-distributed ones need Node.js; the step installs it if missing.

---

## Just the TUI binary

The TUI can run standalone for `gearup doctor` and `--version`. Running an
**install** from the TUI still expects the repo at `~/.gearup` (or `$GEARUP_ROOT`),
because it drives the shell scripts — so for a full setup, use the bootstrap
above. To grab only the binary:

### With Go

```sh
go install github.com/escalopa/gearup/cmd/gearup@latest
```

Installs to `$(go env GOPATH)/bin` (usually `~/go/bin` — make sure it's on `PATH`).

### Prebuilt binary (no Go needed)

Download the archive for your OS/arch from the
[latest release](https://github.com/escalopa/gearup/releases/latest), verify the
checksum, and drop it on your `PATH`:

```sh
VER=0.1.0                       # the release version, without the leading v
OS=$(uname -s | tr 'A-Z' 'a-z') # linux or darwin
ARCH=$(uname -m); case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
BASE="https://github.com/escalopa/gearup/releases/download/v${VER}"

curl -fsSL -o gearup.tar.gz "${BASE}/gearup_${VER}_${OS}_${ARCH}.tar.gz"
curl -fsSL -o checksums.txt  "${BASE}/checksums.txt"
shasum -a 256 -c checksums.txt --ignore-missing   # verify
tar -xzf gearup.tar.gz gearup
sudo mv gearup /usr/local/bin/
gearup --version
```

### Linux packages (deb / rpm / apk)

Every release ships native packages so you can install with your package
manager and track the version through it:

```sh
# Debian / Ubuntu
curl -fsSLO https://github.com/escalopa/gearup/releases/download/v0.1.0/gearup_0.1.0_linux_amd64.deb
sudo dpkg -i gearup_0.1.0_linux_amd64.deb

# Fedora / RHEL
sudo rpm -i https://github.com/escalopa/gearup/releases/download/v0.1.0/gearup_0.1.0_linux_amd64.rpm

# Alpine
curl -fsSLO https://github.com/escalopa/gearup/releases/download/v0.1.0/gearup_0.1.0_linux_amd64.apk
sudo apk add --allow-untrusted gearup_0.1.0_linux_amd64.apk
```

### From source

```sh
git clone https://github.com/escalopa/gearup && cd gearup
make install     # builds ./cmd/gearup -> ~/.local/bin/gearup (version from git)
make doctor      # run the report without installing
```

---

## Updating

The quickest path — fast-forward the clone to `origin/main` and rebuild the
binary in one command:

```sh
gearup update
```

`gearup update` always tracks **main**: it fetches, checks out, and builds from
`origin/main` regardless of which branch the clone was on, so your install stays
a single canonical copy of main. Because the configs are symlinked from the repo,
this also refreshes them.
To additionally (re)install any new/missing tools, run the installer — it's
idempotent, so it only does what's needed:

```sh
cd ~/.gearup && git pull        # (gearup update already did this)
./install.sh                    # re-run: installs only what's missing
```

The bootstrap one-liner also updates in place if `~/.gearup` already exists.
Check your installed version with `gearup --version`.

---

## Uninstalling

```sh
cd ~/.gearup
./uninstall.sh          # removes the symlinks and the rc-file blocks
rm -rf ~/.gearup        # remove the clone (optional)
rm -f ~/.local/bin/gearup
```

Your original dotfiles were backed up to `~/.gearup-backup/<timestamp>/` on first
run — restore from there if needed. Tools installed via the package manager /
`go install` are left in place; remove them individually if you want.

---

## Versioning & releases

Releases are cut from semver tags (`vX.Y.Z`). Pushing a tag runs GoReleaser in
CI, which publishes cross-platform binaries, deb/rpm/apk packages, a
`checksums.txt`, and auto-generated release notes to
[Releases](https://github.com/escalopa/gearup/releases). The binary reports its
version:

```sh
gearup --version
```

Maintainers can preview a release locally without publishing:

```sh
make release-check   # validate .goreleaser.yaml
make snapshot        # build all artifacts into ./dist (no upload)
```

---

## Troubleshooting

**`gearup: could not locate the gearup repo`** — the TUI looks for the repo at
`$GEARUP_ROOT`, then `~/.gearup`, then by walking up from the current directory.
Set `GEARUP_ROOT=/path/to/gearup` or run the bootstrap so the clone lives at
`~/.gearup`.

**`gearup` prints `could not open a new TTY`** — the interactive TUI needs a real
terminal. In a non-interactive context use the subcommands, e.g. `gearup doctor`.

**`go install` fails with _"compile version does not match go tool version"_** —
your shell exports a `GOROOT` from another toolchain (e.g. a company `ya`/bazel
Go) that differs from the `go` on your `PATH`. gearup's Go step realigns
`GOROOT` for the install run automatically; to run `go` commands yourself, use
`env -u GOROOT go ...` or unset `GOROOT`.

**A tool didn't install on Linux** — a few tools have no package on every distro
and are best-effort (they warn instead of aborting). Install those manually, or
let the cargo/go fallback build them. Everything else keeps going.

**`command not found` after install** — open a new shell, or
`source ~/.zshrc` / `source ~/.bashrc`. gearup adds `~/.local/bin`, `~/go/bin`,
and the Go toolchain to `PATH` via its shell block.
