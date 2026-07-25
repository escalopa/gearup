# gearup — Go TUI build helpers.
BIN     ?= $(HOME)/.local/bin/gearup
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS := -X main.version=$(VERSION)

.PHONY: build install run doctor tidy fmt vet test clean version snapshot release-check

build: ## build the TUI into ./gearup
	go build -buildvcs=false -ldflags "$(LDFLAGS)" -o gearup ./cmd/gearup

install: ## build and install to ~/.local/bin/gearup
	@mkdir -p $(dir $(BIN))
	go build -buildvcs=false -ldflags "$(LDFLAGS)" -o $(BIN) ./cmd/gearup
	@echo "installed $(BIN)"

run: ## run the TUI from source
	go run ./cmd/gearup

doctor: ## print the installed/missing report
	go run ./cmd/gearup doctor

tidy: ## sync go.mod/go.sum
	go mod tidy

fmt: ## format the Go code
	gofmt -w .

vet: ## static checks
	go vet ./...

test: ## run tests
	go test ./...

version: ## print the version that a build would embed
	@echo $(VERSION)

release-check: ## validate .goreleaser.yaml
	goreleaser check

snapshot: ## build all release artifacts locally into ./dist (no upload)
	goreleaser release --snapshot --clean

clean: ## remove build artifacts
	rm -f gearup
	rm -rf dist
