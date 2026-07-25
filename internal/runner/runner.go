// Package runner executes the gearup bash installer as a child process and
// streams its combined output back to the TUI, one line at a time. It never
// re-implements install logic — install.sh remains the single source of truth.
package runner

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

// Job is one install.sh invocation: the steps to run and an optional per-tool
// allow-list (passed as GEARUP_ONLY). An empty Only means "install everything
// in these steps".
type Job struct {
	Steps []string
	Only  []string
}

// LineMsg is a single line of installer output.
type LineMsg string

// DoneMsg is emitted once every job has finished.
type DoneMsg struct{ Err error }

// Runner streams messages from a sequence of jobs over a channel.
type Runner struct {
	ch chan tea.Msg
}

// Start launches the jobs in the background and returns a Runner to pump.
func Start(root string, jobs []Job, dryRun bool) *Runner {
	r := &Runner{ch: make(chan tea.Msg, 512)}
	go r.run(root, jobs, dryRun)
	return r
}

// Next returns a tea.Cmd that yields the next output line (or the done marker).
func (r *Runner) Next() tea.Cmd {
	return func() tea.Msg { return <-r.ch }
}

func (r *Runner) run(root string, jobs []Job, dryRun bool) {
	for _, job := range jobs {
		if err := r.runJob(root, job, dryRun); err != nil {
			r.ch <- DoneMsg{Err: err}
			return
		}
	}
	r.ch <- DoneMsg{}
}

func (r *Runner) runJob(root string, job Job, dryRun bool) error {
	args := []string{filepath.Join(root, "install.sh")}
	if dryRun {
		args = append(args, "--dry-run")
	}
	args = append(args, job.Steps...)

	cmd := exec.Command("bash", args...)
	cmd.Dir = root
	cmd.Env = append(os.Environ(), "GEARUP_ROOT="+root)
	if len(job.Only) > 0 {
		cmd.Env = append(cmd.Env, "GEARUP_ONLY="+strings.Join(job.Only, " "))
	}

	// Merge stdout+stderr into one pipe so ordering matches what a user sees.
	pr, pw, err := os.Pipe()
	if err != nil {
		return err
	}
	cmd.Stdout = pw
	cmd.Stderr = pw

	if len(job.Only) > 0 {
		r.ch <- LineMsg(fmt.Sprintf("\x1b[1;34m[gearup]\x1b[0m running %s (only: %s)",
			strings.Join(job.Steps, " "), strings.Join(job.Only, " ")))
	} else {
		r.ch <- LineMsg(fmt.Sprintf("\x1b[1;34m[gearup]\x1b[0m running %s", strings.Join(job.Steps, " ")))
	}

	if err := cmd.Start(); err != nil {
		pw.Close()
		pr.Close()
		return err
	}
	// Only the child needs the write end now.
	pw.Close()

	sc := bufio.NewScanner(pr)
	sc.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for sc.Scan() {
		r.ch <- LineMsg(sc.Text())
	}
	if err := sc.Err(); err != nil && err != io.EOF {
		r.ch <- LineMsg("\x1b[1;31m[gearup]\x1b[0m read error: " + err.Error())
	}
	pr.Close()
	return cmd.Wait()
}
