// Package catalog describes the gearup install steps and the tools each one
// installs. It is the Go-side mirror of the bash scripts: steps are discovered
// by scanning scripts/*.sh, while the tool list is hand-maintained here and
// keyed by command name — the same key the bash helper gearup_selected matches.
package catalog

import (
	"bufio"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// Step is one install stage (a scripts/NN-name.sh file).
type Step struct {
	Name string // e.g. "packages" (matches install.sh step argument)
	Desc string // one-line summary parsed from the script header
}

// Tool is a single installable program.
type Tool struct {
	Name     string // display name
	Command  string // probed via PATH lookup to decide installed/missing
	key      string // GEARUP_ONLY selection key (defaults to Command)
	Desc     string
	Step     string // which step installs it
	Category string // display grouping
}

// Key is what gets passed to the bash GEARUP_ONLY allow-list.
func (t Tool) Key() string {
	if t.key != "" {
		return t.key
	}
	return t.Command
}

// Installed reports whether the tool's command resolves on PATH.
func (t Tool) Installed() bool { return Installed(t.Command) }

// Installed reports whether cmd is found on PATH.
func Installed(cmd string) bool {
	_, err := exec.LookPath(cmd)
	return err == nil
}

// FindRoot locates the gearup repo: $GEARUP_ROOT, then ~/.gearup, then by
// walking up from the executable and the working directory looking for the
// install.sh + lib/utils.sh pair.
func FindRoot() string {
	if r := os.Getenv("GEARUP_ROOT"); isRoot(r) {
		return r
	}
	if home, err := os.UserHomeDir(); err == nil {
		if cand := filepath.Join(home, ".gearup"); isRoot(cand) {
			return cand
		}
	}
	var starts []string
	if exe, err := os.Executable(); err == nil {
		starts = append(starts, filepath.Dir(exe))
	}
	if wd, err := os.Getwd(); err == nil {
		starts = append(starts, wd)
	}
	for _, start := range starts {
		for dir := start; ; {
			if isRoot(dir) {
				return dir
			}
			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
		}
	}
	return ""
}

func isRoot(dir string) bool {
	if dir == "" {
		return false
	}
	for _, f := range []string{"install.sh", filepath.Join("lib", "utils.sh")} {
		if _, err := os.Stat(filepath.Join(dir, f)); err != nil {
			return false
		}
	}
	return true
}

var (
	stepFileRe = regexp.MustCompile(`^(\d\d)-(.+)\.sh$`)
	// second comment line looks like: "# 10-packages.sh — system packages ..."
	descRe = regexp.MustCompile(`^#\s*\S+\.sh\s*[—-]\s*(.+)$`)
)

// Steps discovers the install steps under <root>/scripts in run order.
func Steps(root string) []Step {
	dir := filepath.Join(root, "scripts")
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var steps []Step
	for _, e := range entries {
		m := stepFileRe.FindStringSubmatch(e.Name())
		if m == nil {
			continue
		}
		steps = append(steps, Step{Name: m[2], Desc: parseDesc(filepath.Join(dir, e.Name()))})
	}
	return steps
}

func parseDesc(path string) string {
	f, err := os.Open(path)
	if err != nil {
		return ""
	}
	defer f.Close()
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if m := descRe.FindStringSubmatch(line); m != nil {
			return strings.TrimSpace(m[1])
		}
	}
	return ""
}

// ToolsForStep returns the catalog tools installed by a given step.
func ToolsForStep(step string) []Tool {
	var out []Tool
	for _, t := range Tools {
		if t.Step == step {
			out = append(out, t)
		}
	}
	return out
}

// Tools is the hand-maintained catalog, kept in sync with the bash scripts by
// command name. Steps without per-tool entries (symlinks, tmux-plugins, shell)
// simply run whole.
var Tools = []Tool{
	// -- packages (10-packages.sh) --------------------------------------------
	{Name: "git", Command: "git", Desc: "version control", Step: "packages", Category: "Core packages"},
	{Name: "tmux", Command: "tmux", Desc: "terminal multiplexer", Step: "packages", Category: "Core packages"},
	{Name: "neovim", Command: "nvim", Desc: "editor", Step: "packages", Category: "Core packages"},
	{Name: "ripgrep", Command: "rg", Desc: "fast grep", Step: "packages", Category: "Core packages"},
	{Name: "fzf", Command: "fzf", Desc: "fuzzy finder", Step: "packages", Category: "Core packages"},
	{Name: "fd", Command: "fd", Desc: "fast find", Step: "packages", Category: "Core packages"},
	{Name: "bat", Command: "bat", Desc: "cat with wings", Step: "packages", Category: "Core packages"},
	{Name: "jq", Command: "jq", Desc: "JSON processor", Step: "packages", Category: "Core packages"},
	{Name: "zoxide", Command: "zoxide", Desc: "smarter cd", Step: "packages", Category: "Core packages"},
	{Name: "delta", Command: "delta", Desc: "better git diffs", Step: "packages", Category: "Core packages"},
	{Name: "htop", Command: "htop", Desc: "process viewer", Step: "packages", Category: "Core packages"},
	{Name: "tree", Command: "tree", Desc: "directory tree", Step: "packages", Category: "Core packages"},
	{Name: "shellcheck", Command: "shellcheck", Desc: "shell linter", Step: "packages", Category: "Core packages"},
	{Name: "dig", Command: "dig", Desc: "DNS lookup", Step: "packages", Category: "Core packages"},

	// -- GNU userland on macOS (15-gnu.sh) ------------------------------------
	{Name: "coreutils", Command: "gdate", key: "coreutils", Desc: "GNU ls/date/du/sort…", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "findutils", Command: "gfind", key: "findutils", Desc: "GNU find/xargs", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "gnu-sed", Command: "gsed", key: "gnu-sed", Desc: "GNU sed", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "gawk", Command: "gawk", key: "gawk", Desc: "GNU awk", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "gnu-tar", Command: "gtar", key: "gnu-tar", Desc: "GNU tar", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "grep", Command: "ggrep", key: "grep", Desc: "GNU grep (-P)", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "wget", Command: "wget", key: "wget", Desc: "GNU wget", Step: "gnu", Category: "GNU (macOS)"},
	{Name: "moreutils", Command: "sponge", key: "moreutils", Desc: "sponge/ts/vidir…", Step: "gnu", Category: "GNU (macOS)"},

	// -- zsh + prompt (45-zsh.sh) ---------------------------------------------
	{Name: "zsh", Command: "zsh", Desc: "z shell", Step: "zsh", Category: "Shell"},
	{Name: "starship", Command: "starship", Desc: "cross-shell prompt", Step: "zsh", Category: "Shell"},

	// -- Go dev toolchain (40-tools.sh) ---------------------------------------
	{Name: "gopls", Command: "gopls", Desc: "Go LSP", Step: "tools", Category: "Go toolchain"},
	{Name: "golangci-lint", Command: "golangci-lint", Desc: "Go linter", Step: "tools", Category: "Go toolchain"},
	{Name: "delve", Command: "dlv", Desc: "Go debugger", Step: "tools", Category: "Go toolchain"},
	{Name: "air", Command: "air", Desc: "live reload", Step: "tools", Category: "Go toolchain"},
	{Name: "goose", Command: "goose", Desc: "DB migrations", Step: "tools", Category: "Go toolchain"},
	{Name: "mockgen", Command: "mockgen", Desc: "mock generator", Step: "tools", Category: "Go toolchain"},
	{Name: "goimports", Command: "goimports", Desc: "imports formatter", Step: "tools", Category: "Go toolchain"},
	{Name: "gofumpt", Command: "gofumpt", Desc: "stricter gofmt", Step: "tools", Category: "Go toolchain"},

	// -- backend / API / protobuf (40-tools.sh) -------------------------------
	{Name: "grpcurl", Command: "grpcurl", Desc: "gRPC cURL", Step: "tools", Category: "Backend / API"},
	{Name: "grpcui", Command: "grpcui", Desc: "gRPC web UI", Step: "tools", Category: "Backend / API"},
	{Name: "evans", Command: "evans", Desc: "gRPC REPL", Step: "tools", Category: "Backend / API"},
	{Name: "buf", Command: "buf", Desc: "protobuf tooling", Step: "tools", Category: "Backend / API"},
	{Name: "sqlc", Command: "sqlc", Desc: "SQL → typed Go", Step: "tools", Category: "Backend / API"},
	{Name: "protoc-gen-go", Command: "protoc-gen-go", Desc: "protobuf Go plugin", Step: "tools", Category: "Backend / API"},
	{Name: "protoc-gen-go-grpc", Command: "protoc-gen-go-grpc", Desc: "gRPC Go plugin", Step: "tools", Category: "Backend / API"},
	{Name: "migrate", Command: "migrate", Desc: "golang-migrate", Step: "tools", Category: "Backend / API"},
	{Name: "hey", Command: "hey", Desc: "HTTP load tester", Step: "tools", Category: "Backend / API"},

	// -- git / TUIs -----------------------------------------------------------
	{Name: "lazygit", Command: "lazygit", Desc: "git TUI", Step: "tools", Category: "Git & TUIs"},
	{Name: "lazydocker", Command: "lazydocker", Desc: "docker TUI", Step: "tools", Category: "Git & TUIs"},
	{Name: "lazysql", Command: "lazysql", Desc: "SQL TUI", Step: "tools", Category: "Git & TUIs"},
	{Name: "yq", Command: "yq", Desc: "YAML jq", Step: "tools", Category: "Git & TUIs"},

	// -- devops (Go-installable; 40-tools.sh) ---------------------------------
	{Name: "k9s", Command: "k9s", Desc: "Kubernetes TUI", Step: "tools", Category: "Devops"},
	{Name: "terraform-docs", Command: "terraform-docs", Desc: "TF module docs", Step: "tools", Category: "Devops"},
	{Name: "dive", Command: "dive", Desc: "docker image explorer", Step: "tools", Category: "Devops"},
	{Name: "cosign", Command: "cosign", Desc: "sign/verify artifacts", Step: "tools", Category: "Devops"},

	// -- VCS / CI / workflow --------------------------------------------------
	{Name: "gh", Command: "gh", Desc: "GitHub CLI", Step: "tools", Category: "Workflow"},
	{Name: "glab", Command: "glab", Desc: "GitLab CLI", Step: "tools", Category: "Workflow"},
	{Name: "direnv", Command: "direnv", Desc: "per-project env", Step: "tools", Category: "Workflow"},
	{Name: "just", Command: "just", Desc: "command runner", Step: "tools", Category: "Workflow"},
	{Name: "mkcert", Command: "mkcert", Desc: "local TLS certs", Step: "tools", Category: "Workflow"},
	{Name: "act", Command: "act", Desc: "run GH Actions locally", Step: "tools", Category: "Workflow"},
	{Name: "gitleaks", Command: "gitleaks", Desc: "secret scanner", Step: "tools", Category: "Workflow"},
	{Name: "shfmt", Command: "shfmt", Desc: "shell formatter", Step: "tools", Category: "Workflow"},
	{Name: "glow", Command: "glow", Desc: "markdown reader", Step: "tools", Category: "Workflow"},
	{Name: "gum", Command: "gum", Desc: "shell TUI toolkit", Step: "tools", Category: "Workflow"},

	// -- modern CLI (rust/go awesome) -----------------------------------------
	{Name: "eza", Command: "eza", Desc: "modern ls", Step: "tools", Category: "Modern CLI"},
	{Name: "xh", Command: "xh", Desc: "friendly HTTP client", Step: "tools", Category: "Modern CLI"},
	{Name: "dust", Command: "dust", Desc: "nicer du", Step: "tools", Category: "Modern CLI"},
	{Name: "procs", Command: "procs", Desc: "nicer ps", Step: "tools", Category: "Modern CLI"},
	{Name: "sd", Command: "sd", Desc: "nicer sed", Step: "tools", Category: "Modern CLI"},
	{Name: "hyperfine", Command: "hyperfine", Desc: "benchmarking", Step: "tools", Category: "Modern CLI"},
	{Name: "tokei", Command: "tokei", Desc: "count code", Step: "tools", Category: "Modern CLI"},
	{Name: "bottom", Command: "btm", key: "btm", Desc: "system monitor", Step: "tools", Category: "Modern CLI"},
	{Name: "gitui", Command: "gitui", Desc: "git TUI (rust)", Step: "tools", Category: "Modern CLI"},

	// -- DB clients -----------------------------------------------------------
	{Name: "redis-cli", Command: "redis-cli", Desc: "Redis client", Step: "tools", Category: "Database"},
	{Name: "pgcli", Command: "pgcli", Desc: "Postgres REPL", Step: "tools", Category: "Database"},
	{Name: "usql", Command: "usql", Desc: "universal SQL CLI", Step: "tools", Category: "Database"},

	// -- security scanners ----------------------------------------------------
	{Name: "trivy", Command: "trivy", Desc: "vuln/IaC scanner", Step: "tools", Category: "Security"},
	{Name: "hadolint", Command: "hadolint", Desc: "Dockerfile linter", Step: "tools", Category: "Security"},

	// -- API / proto extras ---------------------------------------------------
	{Name: "websocat", Command: "websocat", Desc: "WebSocket cURL", Step: "tools", Category: "API extras"},
	{Name: "tldr", Command: "tldr", Desc: "fast man pages", Step: "tools", Category: "API extras"},
	{Name: "jless", Command: "jless", Desc: "JSON/YAML pager", Step: "tools", Category: "API extras"},
	{Name: "watchexec", Command: "watchexec", Desc: "run cmd on change", Step: "tools", Category: "API extras"},

	// -- AI coding CLIs (35-ai.sh; opt-in) ------------------------------------
	{Name: "claude", Command: "claude", Desc: "Claude Code (Anthropic)", Step: "ai", Category: "AI coding"},
	{Name: "codex", Command: "codex", Desc: "Codex CLI (OpenAI)", Step: "ai", Category: "AI coding"},
	{Name: "opencode", Command: "opencode", Desc: "opencode (open source)", Step: "ai", Category: "AI coding"},
	{Name: "gemini", Command: "gemini", Desc: "Gemini CLI (Google)", Step: "ai", Category: "AI coding"},

	// -- heavier cloud CLIs (70-cloud.sh) -------------------------------------
	{Name: "terraform", Command: "terraform", Desc: "IaC", Step: "cloud", Category: "Cloud / IaC"},
	{Name: "kubectl", Command: "kubectl", Desc: "Kubernetes CLI", Step: "cloud", Category: "Cloud / IaC"},
	{Name: "helm", Command: "helm", Desc: "Kubernetes packages", Step: "cloud", Category: "Cloud / IaC"},
	{Name: "tflint", Command: "tflint", Desc: "Terraform linter", Step: "cloud", Category: "Cloud / IaC"},
	{Name: "aws", Command: "aws", Desc: "AWS CLI v2", Step: "cloud", Category: "Cloud / IaC"},
}
