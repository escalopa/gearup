# Hands-on tutorial: tmux + Neovim on a huge codebase

Work through this once, in order, with your hands on the keyboard. It uses
the `demo/` folder — a miniature version of a real multi-service Go
monorepo (shared package + two services in a `go.work` workspace).

The mental model for huge codebases, in one paragraph: **don't browse,
jump.** You never scroll a file tree with 40k files. Instead you (1) keep
one tmux **session per project/workspace**, (2) fuzzy-find files and grep
on demand — nothing is pre-indexed, (3) let **gopls** answer semantic
questions (definition/references/implementations), and (4) **pin** the
handful of files you're actually editing. Every exercise below drills one
of those four moves.

---

## Part 1 — tmux: one session per workspace (15 min)

Start from any terminal:

```sh
tmux            # new session. Status bar on top shows the session name.
```

Your prefix is **Ctrl-a** (press Ctrl-a, release, then the key).

1. **Panes.** `Ctrl-a |` splits vertically, `Ctrl-a -` horizontally.
   Move between panes with plain `Ctrl-h/j/k/l` — no prefix needed.
   Close a pane with `exit` (or `Ctrl-d`).
2. **Windows** (like browser tabs): `Ctrl-a c` creates one, `Ctrl-a 1`,
   `Ctrl-a 2`… jump by number, `Ctrl-a ,` renames. Keep window 1 for the
   editor, window 2 for tests/builds, window 3 for logs.
3. **The workspace switcher — the habit that changes everything.**
   Press `Ctrl-a g`. A popup lists your project directories (from
   `$WS_ROOTS` + your zoxide history). Type a few letters of the demo
   folder, Enter. You are now in a *separate session* named after it.
   - Press `Ctrl-a g` again, pick another project → another session.
   - `Ctrl-a L` bounces between your last two sessions.
   - `Ctrl-a s` shows all sessions as a tree.

   Each project keeps its own windows, panes, and running processes. Long
   test run in repo A? Switch to repo B, come back — everything's still
   there. Detach entirely with `Ctrl-a d`; `ta` reattaches later.

**Exercise:** create sessions for `demo/` and one real repo of yours, set
up an editor window and a test window in each, and bounce between them
with `Ctrl-a L` until it's muscle memory.

---

## Part 2 — Neovim: finding anything without an index (25 min)

```sh
cd demo && nvim
```

Leader is **Space**. Press Space and pause — which-key pops up a menu of
everything available. Use that instead of memorizing.

### Files

1. `Space f f` — fuzzy file finder. Type `ordma` → `services/orders/main.go`.
   You never type full paths; a few scattered letters is enough.
2. `Space f o` — recent files *in this project*. Usually the fastest
   "get back to what I was doing" key after `Space f b` (open buffers).
3. Press `-` — the current directory opens as an editable buffer
   (oil.nvim). Navigate with normal vim motions, Enter descends, `-` goes
   up. Rename a file by editing its line and `:w`. This replaces a file
   tree sidebar and works beautifully in unfamiliar corners of a big repo.

### Text (ripgrep, streamed — fine on millions of lines)

4. `Space f g` — live grep the whole workspace. Type `CanCancel`.
   Results appear as you type; Enter jumps to the line.
5. In a big monorepo you often want to search only *this service*:
   `Space f G` greps only near the current file's directory. Same idea,
   `Space f d` finds files only near the current file.
6. `Space f w` — grep the word under the cursor. Put the cursor on
   `ErrNotFound` and try it.
7. `Space f r` — reopen the last picker exactly where you left it.
   Searched, jumped, realized it's the wrong hit? `Space f r`, pick again.

**Exercise:** find every `TODO(demo)` in the workspace with `Space f g`,
visit both, using `Space f r` in between.

### Semantics (gopls — this is why it beats grep)

Open `services/users/main.go`:

8. `gd` on `models.NewUser` — jump to the definition in `pkg/models`,
   across module boundaries. Jump back with `Ctrl-o` (forward: `Ctrl-i`).
   This back-jump is your safety rope; you can dive 5 levels deep and
   `Ctrl-o` all the way home.
9. `gr` on `User` (in `pkg/models/user.go`) — every reference across BOTH
   services, in a fuzzy picker.
10. `gI` on `UserStore` (in `store.go`) — jump to implementations.
    On an interface with 12 implementations this is the only sane way.
11. `Space f s` — symbols in the current file (functions, types); great
    as a table of contents for a 2000-line file. `Space f S` searches
    symbols across the workspace: type `memorystore` from anywhere.
12. `K` on any symbol — docs in a float. `Space c r` — rename a symbol
    project-wide (try renaming `seed`, then undo with `u` + `:w`).

### In-file motion (flash)

13. Press `s` then two characters of anywhere you can see — labels
    appear; press one to teleport. `S` selects a whole function or block
    (treesitter scope). After a day these replace most scrolling.

### Pins (harpoon — your working set)

You're editing `store.go`, its test, and `user.go`, and keep bouncing:

14. In each file press `Space h a` (add pin). Now `Space 1`, `Space 2`,
    `Space 3` teleport between them. `Space h h` shows/edits the pin list.
    Pins are per-project and survive restarts. Re-pin new files as your
    task changes — the pin list *is* your working set.

**Exercise:** pin `user.go`, `store.go`, `orders/main.go`; make a change
in each; bounce with `Space 1/2/3`; check hunks with `]h` and preview
with `Space g p` (gitsigns).

---

## Part 3 — the combined workflow (10 min)

The daily loop on a huge repo, end to end:

1. `Ctrl-a g` → pick the workspace (its session, its layout, its history).
2. `Space f o` or `Space 1..4` → back to your working set instantly.
3. New question ("who constructs Server?") → `Space f g` or `gr`.
4. Deep-dive with `gd` `gd` `gd`, come home with `Ctrl-o` `Ctrl-o`.
5. `Ctrl-l` → hop to the right tmux pane, `go test ./...`, hop back with
   `Ctrl-h`. (Same keys cross nvim splits and tmux panes — one habit.)
6. Commit with `lg` (lazygit): stage hunks with space, `c` to commit.

**Final exercise (the real thing):** in `services/orders/main.go` there's
an exercise comment — extract an `OrderStore` interface mirroring
`services/users/store.go`. Use `Space f f` to flip between the two
services, `gd`/`gr` to check usages, pins to hold your 3 files, and run
`go build ./...` in a tmux pane to verify. When `gI` on your new
interface finds your new implementation, you've earned the workflow.

---

## Working with YOUR huge repo

- Set `export WS_ROOTS="$HOME/work:$HOME/that-monorepo/services"` in your
  rc *before* the gearup block — the switcher then offers each service
  as a workspace.
- In a giant monorepo, **open nvim at the subtree you work in** (or use a
  `go.work` file listing just your modules) — gopls then loads only that
  slice, which keeps memory and startup sane. The config already filters
  out `node_modules`, bazel outputs, etc. via `directoryFilters`.
- gopls in this setup skips `staticcheck` (heavy); run `golangci-lint run`
  in a tmux pane instead — that's what CI runs anyway.

## Company VMs with a patched gopls

Some companies ship their own gopls build for their monorepo. The nvim
config supports this without any company code in the repo: create
`config/nvim/lua/gearup_local.lua` (gitignored) returning a table with
`cmd`, `root_dir`, and `settings` for gopls — it overrides the stock
setup on that machine only. Everything else in this tutorial (fzf,
pins, gd/gr/gI) works the same there.
