# gearup

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

Rerun it whenever: every step checks before it acts, existing files are
backed up (never overwritten), and rc-file edits live between sentinel
markers so they update in place instead of piling up. `./install.sh
--dry-run` shows the plan without touching anything; `./uninstall.sh`
removes the links and blocks.

## What you get

| | Tools |
|---|---|
| Terminal | tmux, Neovim, fzf, ripgrep, fd, bat, eza, zoxide, jq, yq, htop, tree |
| Git | delta diffs, lazygit, sane aliases (via an *included* gitconfig — yours is untouched) |
| Go | toolchain + gopls, golangci-lint, dlv, air, goose, mockgen, goimports, gofumpt |
| APIs | grpcurl, xh, dig |
| Toolchains | Go (official tarball / brew) and Rust (rustup) — they also build everything above that ships via `go install` / `cargo install` |

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
- **Shell block** for bash *and* zsh: PATH wiring, zoxide, fzf
  keybindings, and the `ws` workspace switcher.

## Learn the workflow

- **[TUTORIAL.md](TUTORIAL.md)** — a guided, hands-on tour using the
  bundled `demo/` Go workspace (shared package + two services under
  `go.work`, sized like a slice of a real monorepo).
- **[CHEATSHEET.md](CHEATSHEET.md)** — one page of keys worth printing.

## Layout

```
install.sh          entry point (idempotent; --dry-run supported)
bootstrap.sh        curl-able one-command installer (clones + installs)
lib/utils.sh        ensure_pkg / ensure_symlink / sentinel rc blocks
scripts/NN-*.sh     steps, run in order: packages, go, rust, tools, symlinks, tmux plugins, shell
config/             every dotfile, symlinked into $HOME
bin/ws              the workspace switcher (pure bash: fd/find + fzf + zoxide)
demo/               practice codebase for the tutorial
```

Add a tool = one line in `scripts/10-packages.sh` (system package) or
`scripts/40-tools.sh` (go/cargo). PRs welcome.

## Machine-local overrides

Need a custom gopls on one machine (company monorepos often ship a
patched build)? Drop a `config/nvim/lua/gearup_local.lua` returning
`{ cmd = ..., root_dir = ..., settings = ... }` — it's gitignored, so
machine- or company-specific setup never leaks into this repo.

## Supported

Ubuntu/Debian (apt), Fedora/RHEL (dnf), Arch (pacman), macOS (brew).
WSL Ubuntu works via the apt path. Windows-native is out of scope.

MIT licensed.
