// Package tui is the gearup Bubble Tea front-end: pick steps or individual
// tools, see what's already installed, and run the bash installer with live
// output. It orchestrates install.sh — it does not re-implement it.
package tui

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/escalopa/gearup/internal/catalog"
	"github.com/escalopa/gearup/internal/runner"
)

// newResultsFile removes any previous results file and creates a fresh empty one
// for the next run. Returns "" if a temp file can't be made (results just won't
// be shown).
func newResultsFile(prev string) string {
	if prev != "" {
		_ = os.Remove(prev)
	}
	f, err := os.CreateTemp("", "gearup-results-*.tsv")
	if err != nil {
		return ""
	}
	name := f.Name()
	_ = f.Close()
	return name
}

// readResults parses the "<status>\t<name>" lines written by the installer into
// installed / present / failed name lists.
func readResults(path string) (installed, present, failed []string) {
	if path == "" {
		return nil, nil, nil
	}
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, nil
	}
	defer f.Close()
	seen := map[string]bool{}
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		parts := strings.SplitN(sc.Text(), "\t", 2)
		if len(parts) != 2 {
			continue
		}
		status, name := parts[0], parts[1]
		if seen[status+"\t"+name] {
			continue
		}
		seen[status+"\t"+name] = true
		switch status {
		case "installed":
			installed = append(installed, name)
		case "present":
			present = append(present, name)
		case "failed":
			failed = append(failed, name)
		}
	}
	sort.Strings(installed)
	sort.Strings(present)
	sort.Strings(failed)
	return installed, present, failed
}

type view int

const (
	menuView view = iota
	toolsView
	runView
	doctorView
)

var (
	titleStyle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("39"))
	subtleStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("245"))
	cursorStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("212"))
	okStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("42"))
	missStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("203"))
	selStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("214"))
	helpStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	headerStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("111"))
)

type model struct {
	root  string
	steps []catalog.Step

	view view

	// menu state
	menuCursor   int
	stepSelected map[string]bool

	// tools state
	activeStep string
	tools      []catalog.Tool
	toolCursor int
	toolSel    map[string]bool // by tool command

	// cached install status, keyed by command
	installed map[string]bool

	dryRun bool

	// run state
	vp           viewport.Model
	spin         spinner.Model
	lines        []string
	running      bool
	runDone      bool
	runErr       error
	run          *runner.Runner
	resultsFile  string
	resInstalled []string
	resPresent   []string
	resFailed    []string

	// doctor scroll
	docVP viewport.Model

	width, height int
	msg           string // transient status message
	quitting      bool
}

// New builds the initial model for the given repo root.
func New(root string) model {
	sp := spinner.New()
	sp.Spinner = spinner.Dot
	m := model{
		root:         root,
		steps:        catalog.Steps(root),
		stepSelected: map[string]bool{},
		toolSel:      map[string]bool{},
		installed:    map[string]bool{},
		spin:         sp,
		vp:           viewport.New(80, 20),
		docVP:        viewport.New(80, 20),
	}
	m.refreshInstalled()
	return m
}

func (m *model) refreshInstalled() {
	for _, t := range catalog.Tools {
		m.installed[t.Command] = catalog.Installed(t.Command)
	}
}

func (m model) Init() tea.Cmd { return m.spin.Tick }

// -- update ------------------------------------------------------------------

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		h := msg.Height - 6
		if h < 5 {
			h = 5
		}
		m.vp.Width, m.vp.Height = msg.Width-2, h
		m.docVP.Width, m.docVP.Height = msg.Width-2, h
		m.docVP.SetContent(m.doctorContent())
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd

	case runner.LineMsg:
		m.lines = append(m.lines, string(msg))
		m.vp.SetContent(strings.Join(m.lines, "\n"))
		m.vp.GotoBottom()
		if m.run != nil {
			return m, m.run.Next()
		}
		return m, nil

	case runner.DoneMsg:
		m.running = false
		m.runDone = true
		m.runErr = msg.Err
		m.resInstalled, m.resPresent, m.resFailed = readResults(m.resultsFile)
		m.refreshInstalled()
		m.docVP.SetContent(m.doctorContent())
		return m, nil

	case tea.KeyMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	// Global quit (except while a run is streaming, where q is reserved).
	switch msg.String() {
	case "ctrl+c":
		m.quitting = true
		return m, tea.Quit
	}

	switch m.view {
	case menuView:
		return m.updateMenu(msg)
	case toolsView:
		return m.updateTools(msg)
	case runView:
		return m.updateRun(msg)
	case doctorView:
		return m.updateDoctor(msg)
	}
	return m, nil
}

func (m model) updateMenu(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	m.msg = ""
	switch msg.String() {
	case "q":
		m.quitting = true
		return m, tea.Quit
	case "up", "k":
		if m.menuCursor > 0 {
			m.menuCursor--
		}
	case "down", "j":
		if m.menuCursor < len(m.steps)-1 {
			m.menuCursor++
		}
	case " ":
		name := m.steps[m.menuCursor].Name
		m.stepSelected[name] = !m.stepSelected[name]
		if m.stepSelected[name] {
			m.clearToolsOf(name) // whole-step wins over any subset
		}
	case "a":
		for _, s := range m.steps {
			m.stepSelected[s.Name] = true
			m.clearToolsOf(s.Name)
		}
	case "A":
		m.stepSelected = map[string]bool{}
		m.toolSel = map[string]bool{}
	case "d":
		m.dryRun = !m.dryRun
	case "enter", "right", "l":
		name := m.steps[m.menuCursor].Name
		if len(catalog.ToolsForStep(name)) == 0 {
			m.stepSelected[name] = !m.stepSelected[name] // no tools to drill; toggle
			return m, nil
		}
		m.activeStep = name
		m.tools = catalog.ToolsForStep(name)
		m.toolCursor = 0
		m.view = toolsView
	case "D":
		m.docVP.SetContent(m.doctorContent())
		m.view = doctorView
	case "r":
		m.refreshInstalled() // double-check before install: state may have changed
		jobs, skipped := m.buildJobs()
		if len(jobs) == 0 {
			if len(skipped) > 0 {
				m.msg = "all selected tools are already installed ✓"
			} else {
				m.msg = "nothing selected — press space on a step, or enter to pick tools"
			}
			return m, nil
		}
		m.lines = nil
		if len(skipped) > 0 {
			m.lines = append(m.lines, subtleStyle.Render("already installed, skipping: "+strings.Join(skipped, ", ")))
		}
		m.resInstalled, m.resPresent, m.resFailed = nil, nil, nil
		m.resultsFile = newResultsFile(m.resultsFile)
		m.running = true
		m.runDone = false
		m.runErr = nil
		m.vp.SetContent(strings.Join(m.lines, "\n"))
		m.run = runner.Start(m.root, jobs, m.dryRun, m.resultsFile)
		m.view = runView
		return m, tea.Batch(m.spin.Tick, m.run.Next())
	}
	return m, nil
}

func (m model) updateTools(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc", "left", "h", "q":
		m.view = menuView
	case "up", "k":
		if m.toolCursor > 0 {
			m.toolCursor--
		}
	case "down", "j":
		if m.toolCursor < len(m.tools)-1 {
			m.toolCursor++
		}
	case " ":
		cmd := m.tools[m.toolCursor].Command
		m.toolSel[cmd] = !m.toolSel[cmd]
		if m.toolSel[cmd] {
			m.stepSelected[m.activeStep] = false // subset overrides whole-step
		}
	case "A":
		all := true
		for _, t := range m.tools {
			if !m.toolSel[t.Command] {
				all = false
				break
			}
		}
		for _, t := range m.tools {
			m.toolSel[t.Command] = !all
		}
		if !all {
			m.stepSelected[m.activeStep] = false
		}
	}
	return m, nil
}

func (m model) updateRun(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc":
		if m.runDone {
			m.view = menuView
		}
		return m, nil
	case "q":
		if m.runDone {
			m.quitting = true
			return m, tea.Quit
		}
		return m, nil
	}
	var cmd tea.Cmd
	m.vp, cmd = m.vp.Update(msg)
	return m, cmd
}

func (m model) updateDoctor(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc", "q", "left", "h":
		m.view = menuView
		return m, nil
	}
	var cmd tea.Cmd
	m.docVP, cmd = m.docVP.Update(msg)
	return m, cmd
}

// clearToolsOf removes any per-tool selections belonging to a step.
func (m *model) clearToolsOf(step string) {
	for _, t := range catalog.ToolsForStep(step) {
		delete(m.toolSel, t.Command)
	}
}

// buildJobs turns the current selection into at most two install.sh jobs: one
// for whole-step selections (no filter) and one for per-tool subsets. Tools that
// are already installed are dropped from per-tool subsets up front (a second
// check on top of the scripts' own skip logic), and the names of the ones we
// skipped are returned so the UI can report them.
func (m model) buildJobs() (jobs []runner.Job, skipped []string) {
	var fullSteps, subsetSteps []string
	var only []string
	for _, s := range m.steps {
		var missing []string
		picked := false
		for _, t := range catalog.ToolsForStep(s.Name) {
			if !m.toolSel[t.Command] {
				continue
			}
			picked = true
			if m.installed[t.Command] {
				skipped = append(skipped, t.Name)
			} else {
				missing = append(missing, t.Key())
			}
		}
		switch {
		case picked:
			// per-tool subset: only run the step if something is still missing
			if len(missing) > 0 {
				subsetSteps = append(subsetSteps, s.Name)
				only = append(only, missing...)
			}
		case m.stepSelected[s.Name]:
			// whole step: the scripts skip anything already present
			fullSteps = append(fullSteps, s.Name)
		}
	}
	if len(fullSteps) > 0 {
		jobs = append(jobs, runner.Job{Steps: fullSteps})
	}
	if len(subsetSteps) > 0 {
		jobs = append(jobs, runner.Job{Steps: subsetSteps, Only: only})
	}
	return jobs, skipped
}

func (m model) selectedToolsOf(step string) []string {
	var out []string
	for _, t := range catalog.ToolsForStep(step) {
		if m.toolSel[t.Command] {
			out = append(out, t.Key())
		}
	}
	return out
}

// -- view --------------------------------------------------------------------

func (m model) View() string {
	if m.quitting {
		return ""
	}
	switch m.view {
	case toolsView:
		return m.viewTools()
	case runView:
		return m.viewRun()
	case doctorView:
		return m.viewDoctor()
	default:
		return m.viewMenu()
	}
}

func (m model) viewMenu() string {
	var b strings.Builder
	dry := ""
	if m.dryRun {
		dry = selStyle.Render("  [dry-run]")
	}
	fmt.Fprintf(&b, "%s%s\n", titleStyle.Render(" gearup "), dry)
	b.WriteString(subtleStyle.Render(" select steps to install, or drill into a step to pick individual tools\n\n"))

	for i, s := range m.steps {
		cursor := "  "
		if i == m.menuCursor {
			cursor = cursorStyle.Render("❯ ")
		}
		box := "[ ]"
		if m.stepSelected[s.Name] {
			box = selStyle.Render("[x]")
		} else if n := len(m.selectedToolsOf(s.Name)); n > 0 {
			box = selStyle.Render(fmt.Sprintf("[%d]", n))
		}
		name := s.Name
		if i == m.menuCursor {
			name = cursorStyle.Render(name)
		}
		line := fmt.Sprintf("%s%s %-14s %s", cursor, box, name, m.stepStatus(s.Name))
		b.WriteString(line + "\n")
		if s.Desc != "" {
			b.WriteString(subtleStyle.Render("       "+s.Desc) + "\n")
		}
	}
	if m.msg != "" {
		b.WriteString("\n" + missStyle.Render(" "+m.msg) + "\n")
	}
	b.WriteString("\n" + helpStyle.Render(" space select · enter tools · a all · A none · d dry-run · r run · D doctor · q quit"))
	return b.String()
}

// stepStatus shows how many of a step's cataloged tools are already installed.
func (m model) stepStatus(step string) string {
	tools := catalog.ToolsForStep(step)
	if len(tools) == 0 {
		return subtleStyle.Render("(runs whole step)")
	}
	got := 0
	for _, t := range tools {
		if m.installed[t.Command] {
			got++
		}
	}
	style := missStyle
	if got == len(tools) {
		style = okStyle
	}
	return style.Render(fmt.Sprintf("%d/%d present", got, len(tools)))
}

func (m model) viewTools() string {
	var b strings.Builder
	fmt.Fprintf(&b, "%s\n", titleStyle.Render(fmt.Sprintf(" gearup · %s ", m.activeStep)))
	b.WriteString(subtleStyle.Render(" space toggles a tool; leave all unchecked to run the whole step\n\n"))
	for i, t := range m.tools {
		cursor := "  "
		if i == m.toolCursor {
			cursor = cursorStyle.Render("❯ ")
		}
		box := "[ ]"
		if m.toolSel[t.Command] {
			box = selStyle.Render("[x]")
		}
		status := missStyle.Render("✗")
		if m.installed[t.Command] {
			status = okStyle.Render("✓")
		}
		name := t.Name
		if i == m.toolCursor {
			name = cursorStyle.Render(name)
		}
		fmt.Fprintf(&b, "%s%s %s %-20s %s\n", cursor, box, status, name, subtleStyle.Render(t.Desc))
	}
	b.WriteString("\n" + helpStyle.Render(" space toggle · A all/none · esc back · q back"))
	return b.String()
}

func (m model) viewRun() string {
	var b strings.Builder
	head := titleStyle.Render(" gearup · installing ")
	if m.running {
		head += " " + m.spin.View()
	} else if m.runDone {
		if m.runErr != nil {
			head += missStyle.Render("  failed: " + m.runErr.Error())
		} else {
			head += okStyle.Render("  done ✓")
		}
	}
	b.WriteString(head + "\n\n")
	b.WriteString(m.vp.View() + "\n")
	if m.runDone {
		b.WriteString(m.resultsSummary() + "\n")
		b.WriteString(helpStyle.Render(" esc back · q quit · ↑/↓ scroll"))
	} else {
		b.WriteString(helpStyle.Render(" running… ↑/↓ scroll"))
	}
	return b.String()
}

// resultsSummary is the post-run tally shown under the log: how many tools were
// installed, were already present, and failed — with the failed ones named.
func (m model) resultsSummary() string {
	if len(m.resInstalled)+len(m.resPresent)+len(m.resFailed) == 0 {
		return subtleStyle.Render(" no tool changes recorded")
	}
	verb := "installed"
	if m.dryRun {
		verb = "would install"
	}
	line := fmt.Sprintf(" %s  %s  %s",
		okStyle.Render(fmt.Sprintf("✓ %d %s", len(m.resInstalled), verb)),
		subtleStyle.Render(fmt.Sprintf("• %d already present", len(m.resPresent))),
		func() string {
			s := fmt.Sprintf("✗ %d failed", len(m.resFailed))
			if len(m.resFailed) > 0 {
				return missStyle.Render(s)
			}
			return subtleStyle.Render(s)
		}(),
	)
	if len(m.resFailed) > 0 {
		line += "\n " + missStyle.Render("failed: "+strings.Join(m.resFailed, ", "))
	}
	return line
}

func (m model) viewDoctor() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render(" gearup · doctor ") + "\n\n")
	b.WriteString(m.docVP.View() + "\n")
	b.WriteString(helpStyle.Render(" ↑/↓ scroll · esc back"))
	return b.String()
}

func (m model) doctorContent() string {
	// group tools by category, preserving first-seen order
	var order []string
	groups := map[string][]catalog.Tool{}
	for _, t := range catalog.Tools {
		if _, ok := groups[t.Category]; !ok {
			order = append(order, t.Category)
		}
		groups[t.Category] = append(groups[t.Category], t)
	}
	var b strings.Builder
	for _, cat := range order {
		tools := groups[cat]
		got := 0
		for _, t := range tools {
			if m.installed[t.Command] {
				got++
			}
		}
		fmt.Fprintf(&b, "%s  %s\n", headerStyle.Render(cat), subtleStyle.Render(fmt.Sprintf("%d/%d", got, len(tools))))
		sorted := append([]catalog.Tool(nil), tools...)
		sort.Slice(sorted, func(i, j int) bool { return sorted[i].Name < sorted[j].Name })
		for _, t := range sorted {
			mark := missStyle.Render("✗")
			if m.installed[t.Command] {
				mark = okStyle.Render("✓")
			}
			fmt.Fprintf(&b, "  %s %-20s %s\n", mark, t.Name, subtleStyle.Render(t.Desc))
		}
		b.WriteString("\n")
	}
	return b.String()
}
