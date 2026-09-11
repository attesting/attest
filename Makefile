# attest: build and verification targets
#
# Targets are declared here from the first commit so the build surface is
# visible before it is implemented. Bodies marked TODO name the milestone that
# fills them in; they are not silently-passing stubs.
#
# SOURCE_DATE_EPOCH discipline: reproducible builds and deterministic artifacts
# are a non-negotiable requirement of SPEC.md, but there is no artifact to make
# reproducible yet. When the first binary ships (milestone 6), SOURCE_DATE_EPOCH
# is set from the commit timestamp and honored by every target that embeds a
# time or emits an archive. Until then, no target here embeds a timestamp, which
# is the only reason its absence is currently harmless.

GO ?= go

.PHONY: all build test lint sbom reproducible clean help

all: build

## build: compile all packages
# Functional today. There are no Go source files yet, so this is a no-op that
# verifies the module is well-formed.
build:
	CGO_ENABLED=0 $(GO) build ./...

## test: run the test suite
# The real command, wired up from the first commit. It exits non-zero today
# ("matched no packages") because no package exists yet; that is left as-is
# rather than guarded, so the target starts passing the moment milestone 1
# lands a package instead of passing vacuously before then.
test:
	$(GO) test ./...

## lint: run golangci-lint
# TODO(milestone 1): add .golangci.yml and wire this up. SPEC.md requires a
# golangci-lint-clean tree; this target fails loudly until that is real.
lint:
	@echo "lint: not yet configured (golangci-lint arrives with milestone 1)"
	@exit 1

## sbom: generate a Software Bill of Materials
# TODO(milestone 6): generate at build time and publish with each release.
# VERIFYING.md commits to this; see the "SBOM" section there.
sbom:
	@echo "sbom: milestone 6, no dependencies and no artifact to describe yet"
	@exit 1

## reproducible: build twice and verify byte-identical output
# TODO(milestone 6): build the release artifacts twice under SOURCE_DATE_EPOCH
# and diff the checksums. This is the strongest claim VERIFYING.md makes.
reproducible:
	@echo "milestone 6"

## clean: remove build output
clean:
	rm -rf dist bin
	$(GO) clean

## help: list available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'
