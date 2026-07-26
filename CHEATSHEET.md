# Cheatsheet

Print this. Tape it somewhere. Prefix = `Ctrl-a`, Leader = `Space`.

## tmux

| Keys | Action |
|---|---|
| `Ctrl-a g` | **workspace switcher** (fuzzy-pick project → its session) |
| `Ctrl-a L` | toggle last session |
| `Ctrl-a s` | list all sessions |
| `Ctrl-a d` | detach (everything keeps running) |
| `Ctrl-a c` / `Ctrl-a 1..9` | new window / jump to window |
| `Ctrl-a \|` / `Ctrl-a -` | split right / split down |
| `Ctrl-h/j/k/l` | move across panes **and** nvim splits |
| `Ctrl-a H/J/K/L` | resize pane |
| `Ctrl-a [` | scroll/copy mode (vi keys, `v` select, `y` yank → clipboard) |
| `Ctrl-a r` | reload tmux config |
| `Ctrl-a I` / `Ctrl-a U` | install / update tmux plugins (TPM) |
| `Ctrl-a Ctrl-s` / `Ctrl-a Ctrl-r` | save / restore session layout (resurrect) |

## Neovim — find

| Keys | Action |
|---|---|
| `Space f f` | find files (fuzzy) |
| `Space f g` | live grep whole workspace |
| `Space f d` / `Space f G` | files / grep near current file only |
| `Space f w` | grep word under cursor |
| `Space f b` / `Space f o` | buffers / recent files (project) |
| `Space f r` | **resume last search** |
| `Space f s` / `Space f S` | symbols in file / in workspace |
| `-` | browse directory as a buffer (oil) |

## Neovim — code (gopls / rust-analyzer)

| Keys | Action |
|---|---|
| `gd` / `gr` / `gI` | definition / references / implementations |
| `Ctrl-o` / `Ctrl-i` | jump back / forward |
| `K` | hover docs |
| `Space c r` / `Space c a` | rename symbol / code action |
| `[d` / `]d` / `Space e` | prev / next / show diagnostic |
| `Space x x` / `Space x b` | all diagnostics / this buffer (trouble) |
| save `*.go` | gofmt + organize imports |
| save `*.rs` | rustfmt (clippy lints via checkOnSave) |

## Neovim — motion & editing

| Keys | Action |
|---|---|
| `s` + 2 chars + label | flash: teleport to any visible match |
| `S` | flash: select a treesitter scope (func, block…) |
| `cs"'` / `ds(` / `ysiw"` | change / delete / add surroundings |

## Neovim — pins & git

| Keys | Action |
|---|---|
| `Space h a` | pin current file |
| `Space 1..4` | jump to pin |
| `Space h h` | pin menu |
| `]h` / `[h` | next / prev git hunk |
| `Space g p` / `Space g b` / `Space g r` | preview hunk / blame / reset hunk |

## Neovim — run in tmux (vimux)

| Keys | Action |
|---|---|
| `Space t t` | run tests (`go test ./...` / `cargo test`) in a tmux pane |
| `Space t b` / `Space t r` | build / run (`go`/`cargo`, by filetype) |
| `Space t p` / `Space t l` | prompt for a command / run last command |
| `Space t z` / `Space t x` | zoom / close the runner pane |
| `Ctrl-h/j/k/l` | move across nvim splits **and** tmux panes |

## gearup TUI

| Command / Key | Action |
|---|---|
| `gearup` | interactive installer: pick steps or individual tools |
| `gearup doctor` | report installed / missing tools |
| `space` / `enter` | select whole step / drill into its tools |
| `r` / `d` / `D` / `q` | run selection / dry-run / doctor / quit |

## Shell

| Command | Action |
|---|---|
| `ws` | workspace switcher from a plain shell |
| `z foo` | zoxide: cd to the `foo` dir you visit most |
| `Ctrl-r` / `Ctrl-t` | fuzzy history / fuzzy file insert |
| `vg <pattern>` | grep repo, open pick in nvim at the line |
| `lg` / `lzd` | lazygit / lazydocker |
| `v` / `ta` | nvim / tmux attach |
| `tf` / `k` | terraform / kubectl |
| `du` / `ps` / `top` | dust / procs / btm (modern replacements) |

## Devops

| Command | Action |
|---|---|
| `terraform` / `tf` | IaC — plan/apply; `tflint`, `terraform-docs` alongside |
| `k9s` | Kubernetes TUI; `kubectl`, `helm` for the CLI |
| `k get pods` | `k` is aliased to `kubectl` |
| `dive <image>` | explore a docker image's layers |
| `trivy image <img>` | scan an image for vulns; `hadolint` lints Dockerfiles |
