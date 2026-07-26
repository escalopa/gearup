// Command gearup is the TUI front-end for the gearup dev-environment installer.
//
// Usage:
//
//	gearup            launch the interactive TUI
//	gearup doctor     print an installed/missing report and exit
//	gearup --version  print version and exit
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/escalopa/gearup/internal/catalog"
	"github.com/escalopa/gearup/internal/tui"
)

// version is overridable at build time: -ldflags "-X main.version=v1.2.3".
var version = "dev"

func main() {
	args := os.Args[1:]
	if len(args) > 0 {
		switch args[0] {
		case "-v", "--version", "version":
			fmt.Printf("gearup %s\n", version)
			return
		case "-h", "--help", "help":
			usage()
			return
		case "doctor":
			os.Exit(doctor())
		case "update", "upgrade":
			os.Exit(update())
		default:
			fmt.Fprintf(os.Stderr, "gearup: unknown command %q\n\n", args[0])
			usage()
			os.Exit(2)
		}
	}

	root := catalog.FindRoot()
	if root == "" {
		fmt.Fprintln(os.Stderr, "gearup: could not locate the gearup repo.")
		fmt.Fprintln(os.Stderr, "  set GEARUP_ROOT, or run from inside a clone (default: ~/.gearup).")
		os.Exit(1)
	}

	p := tea.NewProgram(tui.New(root), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintln(os.Stderr, "gearup:", err)
		os.Exit(1)
	}
}

func usage() {
	fmt.Print(`gearup — gear up a machine for Go backend work.

Usage:
  gearup            launch the interactive installer TUI
  gearup doctor     report which tools are installed / missing
  gearup update     fast-forward the repo to origin/main and rebuild the binary
  gearup --version  print version

Inside the TUI: space selects a step, enter drills into its tools, r runs the
selection, d toggles dry-run, D opens the doctor view, q quits.
`)
}

// updateBranch is the single branch gearup tracks: updates always fetch, check
// out, and build from main — never whatever branch the clone happens to be on.
const updateBranch = "main"

// update fast-forwards the repo to origin/main and rebuilds the gearup binary in
// place from main. Configs are symlinked from the repo, so the update refreshes
// them too; run `gearup` or `./install.sh` afterwards to pick up any new tools.
func update() int {
	root := catalog.FindRoot()
	if root == "" {
		fmt.Fprintln(os.Stderr, "gearup: could not locate the repo (set GEARUP_ROOT, or clone to ~/.gearup).")
		return 1
	}
	fmt.Printf("updating gearup in %s (branch %s)\n", root, updateBranch)

	// Always track main: fetch it, switch to it, and fast-forward — so the local
	// clone stays a single canonical copy of main regardless of prior state.
	env := os.Environ()
	for _, args := range [][]string{
		{"fetch", "origin", updateBranch},
		{"checkout", updateBranch},
		{"merge", "--ff-only", "origin/" + updateBranch},
	} {
		if err := runAt(root, env, "git", args...); err != nil {
			fmt.Fprintf(os.Stderr, "gearup: `git %s` failed: %v\n", strings.Join(args, " "), err)
			return 1
		}
	}

	self, err := os.Executable()
	if err != nil || self == "" {
		home, _ := os.UserHomeDir()
		self = filepath.Join(home, ".local", "bin", "gearup")
	}
	ver := gitDescribe(root)

	// Build with a GOROOT-free env so a stale exported GOROOT (e.g. a company
	// toolchain) can't break the build with a "compile version" mismatch.
	if err := runAt(root, envWithout("GOROOT"), "go", "build", "-buildvcs=false",
		"-ldflags", "-s -w -X main.version="+ver, "-o", self, "./cmd/gearup"); err != nil {
		fmt.Fprintln(os.Stderr, "gearup: rebuild failed (is Go installed and on PATH?):", err)
		return 1
	}

	fmt.Printf("gearup updated to %s → %s\n", ver, self)
	fmt.Println("run `gearup` to install any new tools, or `./install.sh` to refresh everything.")
	return 0
}

func runAt(dir string, env []string, name string, args ...string) error {
	c := exec.Command(name, args...)
	c.Dir = dir
	c.Env = env
	c.Stdout, c.Stderr, c.Stdin = os.Stdout, os.Stderr, os.Stdin
	return c.Run()
}

func gitDescribe(dir string) string {
	out, err := exec.Command("git", "-C", dir, "describe", "--tags", "--always", "--dirty").Output()
	if err != nil {
		return "dev"
	}
	return strings.TrimSpace(string(out))
}

func envWithout(key string) []string {
	prefix := key + "="
	var out []string
	for _, kv := range os.Environ() {
		if strings.HasPrefix(kv, prefix) {
			continue
		}
		out = append(out, kv)
	}
	return out
}

// doctor prints a non-interactive installed/missing report grouped by category.
func doctor() int {
	var order []string
	groups := map[string][]catalog.Tool{}
	for _, t := range catalog.Tools {
		if _, ok := groups[t.Category]; !ok {
			order = append(order, t.Category)
		}
		groups[t.Category] = append(groups[t.Category], t)
	}
	missing := 0
	for _, cat := range order {
		tools := groups[cat]
		sort.Slice(tools, func(i, j int) bool { return tools[i].Name < tools[j].Name })
		fmt.Printf("\n%s\n", cat)
		for _, t := range tools {
			mark := "✗"
			if t.Installed() {
				mark = "✓"
			} else {
				missing++
			}
			fmt.Printf("  %s %-20s %s\n", mark, t.Name, t.Desc)
		}
	}
	fmt.Println()
	if missing > 0 {
		fmt.Printf("%d tool(s) missing. Run `gearup` to install.\n", missing)
		return 1
	}
	fmt.Println("all cataloged tools present.")
	return 0
}
