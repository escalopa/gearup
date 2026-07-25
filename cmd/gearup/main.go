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
	"sort"

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
  gearup --version  print version

Inside the TUI: space selects a step, enter drills into its tools, r runs the
selection, d toggles dry-run, D opens the doctor view, q quits.
`)
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
