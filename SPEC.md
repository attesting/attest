# attest — v0.1 Engineering Specification

**Project: attesting** · **Binary: `attest`** · **Module: `github.com/attesting/attest`** · **Site: https://attesting.dev**

**Module and naming.** The Go module path is `github.com/attesting/attest`. The project is *attesting*, the binary is `attest`, and the sealed bundle extension is `.attest`. These names are final; they are not working titles.

This is the authoritative v0.1 spec. Read it fully before writing code. Propose a build plan against the milestones at the bottom before implementing. The name is final.

## What this is

A compiled, local-first CLI that collects security posture facts inside a client's boundary, lets the client review those facts in plaintext, seals them for transport, and on the assessor's side maps them to compliance framework controls and emits signed, machine-readable assessment evidence (OSCAL) plus a human-readable summary. Think "terraform plan for compliance evidence": declarative, diffable, provenance on everything.

## Non-negotiable architecture principles

1. Single static binary. Go 1.22+. CGO_ENABLED=0. No runtime dependencies. Must cross-compile for linux/amd64, linux/arm64, darwin/arm64, windows/amd64.
2. The core makes NO network calls. Ever. Collectors (separate plugin binaries in later versions; in v0.1 they are built-in subpackages behind the same interface) may call APIs, but the core engine (map, emit, sign, verify, seal) must work fully offline.
3. Facts are files. No database. JSONL on disk, human-readable, greppable. The filesystem layout IS the data model.
4. Everything trust-critical is deterministic and reproducible. Same input facts must produce byte-identical output artifacts. Respect SOURCE_DATE_EPOCH for any embedded timestamps in rendered artifacts. Sort all JSON keys, use stable ordering everywhere, no map iteration order leaks.
5. Credentials never appear in facts, logs, config files, or error messages. Collectors read creds from environment variables only. Write a redaction test that proves a planted fake credential never appears in any output file.
6. The binary must be verifiable: reproducible build documented in the Makefile, SBOM generated at build time, and a VERIFYING.md that walks a skeptical client sysadmin through checking the binary offline before running it.

## CLI surface (v0.1)

```
attest collect --collector <name> --scope <scope.yaml> --out <facts-dir>
attest review --facts <facts-dir>          # pretty-prints facts for client review, summary stats, out-of-scope warnings
attest sign --facts <facts-dir> --key <path>   # hashes fact tree into manifest.json, ed25519 signs it
attest seal --facts <facts-dir> --recipient <age-pubkey> --out <bundle.attest>   # encrypts reviewed+signed facts (age/X25519)
attest unseal --bundle <bundle.attest> --identity <age-key> --out <dir>
attest verify --facts <dir>                # verifies manifest signature and that no fact file drifted
attest map --facts <dir> --crosswalk <dir-of-yaml> --out <mapped.json>
attest emit --mapped <mapped.json> --format oscal-ar --out <results.json>   # OSCAL Assessment Results
attest render --mapped <mapped.json> --format md --out <summary.md>
attest keygen                              # generate signing keypair
attest version                             # version, commit, build date, SBOM hash
```

Use spf13/cobra or stdlib flag (your call, justify it). Errors must be actionable. Exit codes: 0 ok, 1 error, 2 verification failure (distinct so scripts can gate on it).

## Fact schema (the heart of the system)

One fact per JSONL line:

```json
{
  "id": "f-<uuidv7>",
  "class": "observation",
  "observed_at": "RFC3339 UTC",
  "collector": {"name": "localhost", "version": "0.1.0"},
  "subject": {"type": "host", "identifier": "<hostname or asset id>"},
  "predicate": "disk_encryption.enabled",
  "value": true,
  "source": {"method": "command", "detail": "fdesetup status"},
  "scope_ref": "<id from scope.yaml that authorized this>"
}
```

Predicates are dot-namespaced strings. Define an initial registry in docs/predicates.md covering: disk_encryption.enabled, os.version, os.patch_age_days, firewall.enabled, screen_lock.max_timeout_seconds, mfa.enforced, password_policy.min_length, admin_users.count. Values are JSON scalars or small objects, never blobs.

scope.yaml names what is authorized for collection (subjects, predicates allowed). The collect command MUST refuse to emit any fact whose subject or predicate is not covered by scope, and must log what it refused. Scope enforcement is a hard gate, not a warning.

## v0.1 collectors (built-in)

1. "localhost": collects the registry predicates from the machine it runs on. macOS and Linux support required, Windows stubbed with clear errors. Shell out to OS tools (fdesetup, defaults, ufw, etc.), parse defensively, every fact records the exact command in source.detail.
2. "static": reads facts from a provided JSONL file and re-emits them through scope filtering. This exists so tests and demos never require a real environment, and so third-party data can enter the pipeline.

Collector interface: `Collect(ctx, scope) ([]Fact, []Refusal, error)`. Design it so v0.2 can move collectors to separate plugin binaries speaking JSON over stdio without changing the core.

## Crosswalk format

Directory of YAML modules, one file per framework. v0.1 ships nist-800-171.yaml covering a starter set to be expanded: 3.1.1, 3.1.5, 3.4.1, 3.4.2, 3.5.3, 3.13.11, 3.14.1. Schema:

```yaml
framework: nist-800-171
version: r2
controls:
  - id: "3.13.11"
    title: "Employ FIPS-validated cryptography..."
    rules:
      - predicate: disk_encryption.enabled
        condition: {equals: true}
        freshness_max_days: 30
        sufficiency: primary   # primary | corroborating
        rationale: "Disk encryption observed enabled satisfies confidentiality-at-rest evidence for this subject class."
```

map evaluates every rule against every in-scope fact and produces per-control findings: satisfied, not-satisfied, insufficient-evidence (with reason: stale, missing, corroborating-only). Conditions support: equals, not_equals, gte, lte, in, exists. Freshness is evaluated against observed_at at map time, and map records the evaluation time so results are reproducible when re-run with --as-of.

## OSCAL emission

Emit a minimal valid OSCAL Assessment Results (JSON, current stable schema version; check the schema and pin it). Every finding must link back to fact IDs as evidence references, carry the crosswalk module version, and include the manifest hash of the fact set. Do not model the entire OSCAL universe; model the smallest valid document that a consuming tool can validate. Include a make target that validates output against the official schema.

## Signing and sealing

- Manifest: sorted file list with SHA-256 per file, tree hash, created_at, tool version. ed25519 signature detached alongside.
- Keys: generate via `attest keygen`, stored as files, no key management ambitions in v0.1. Document that production keys live on hardware later.
- Seal: age (filippo.io/age library) encryption of the tar of the facts dir + manifest + signature. Deterministic tar (fixed ordering, zeroed timestamps, SOURCE_DATE_EPOCH honored).

## Quality bar

- Table-driven tests throughout. Golden-file tests for map, emit, render proving byte-identical output. A reproducibility test that builds artifacts twice and diffs.
- The credential redaction test described above.
- Scope-enforcement tests: out-of-scope facts refused and logged.
- No panics reachable from user input. Fuzz the fact parser and scope parser (go native fuzzing, even briefly).
- golangci-lint clean. No global state. Context plumbed through.
- Keep dependencies minimal and justified in go.mod comments: cobra (maybe), age, yaml (goccy or gopkg.in/yaml.v3), uuid. Nothing else without asking.

## Repo layout

```
cmd/attest/         main
internal/fact/      schema, parse, validate, redaction
internal/scope/     scope.yaml parsing + enforcement
internal/collect/   interface + localhost + static
internal/manifest/  hashing, sign, verify
internal/seal/      age seal/unseal, deterministic tar
internal/crosswalk/ yaml load, rule eval, findings
internal/oscal/     minimal AR types + emit + schema validate
internal/render/    markdown summary
docs/               predicates.md, fact-classes.md, crosswalk-authoring.md, threat-model.md
testdata/           golden files, sample facts, sample scope, demo script
scripts/            demo.sh, genfacts
VERIFYING.md        repo root, not docs/ — the first thing a skeptical sysadmin looks for
```

## Demo script (acceptance)

scripts/demo.sh must run the full lifecycle on the local machine with zero external services: keygen, collect (localhost), review, sign, seal, unseal, verify, map against nist-800-171.yaml, emit OSCAL, render markdown, then TAMPER with one fact file and show verify exiting 2. This script is the sales demo; it must narrate what it is doing at each step.

## Non-goals for v0.1 (do not build)

Web anything, database, continuous scheduling, plugin RPC, Windows collector implementation, PDF rendering (markdown only; PDF pipeline exists elsewhere), FIPS-validated crypto claims (document as roadmap in threat-model.md), multi-framework crosswalks beyond the one file.

## Addendum — schema future-proofing (reserve, do not build)

These reflect roadmap decisions. v0.1 implements NONE of the deferred features, but the schemas must not preclude them. Anything here marked "reserve" means: define it in the schema/types/docs, validate it if present, build nothing on it.

1. Fact classes. The fact schema's required "class" field takes: "observation" | "document" | "assertion". v0.1 emits only "observation" (both collectors hardcode it). Rationale for the other two, documented in docs/fact-classes.md (create as a real doc, not a stub): the roadmap maps fact classes to NIST 800-171A assessment methods — Test = observation, Examine = document (facts derived from signed policy repos), Interview = assertion (signed, dated human statements with fast freshness decay). Naming rationale: the tool attests, humans declare, machine facts observe — three words, three meanings, no overlap. The future human-statement subcommand is `attest declare`. Validation must reject unknown classes.

2. source.method becomes a closed enum: "command" | "api" | "document" | "assertion". v0.1 uses only "command" (localhost) and "api" (reserved; the static collector uses "command" semantics — pick and document one).

3. Crosswalk sufficiency gains a reserved third value: "primary" | "corroborating" | "assertion". The rule schema also reserves two optional fields, parsed and validated but not evaluated in v0.1: attester_role (string) and freshness semantics noting that assertion-class facts are expected to carry shorter freshness_max_days than observations. Document in docs/crosswalk-authoring.md.

4. scope.yaml consent granularity. Design the scope schema now as per-subject grants, not global allowlists: each entry names a subject (or subject pattern), the predicates authorized FOR THAT SUBJECT, and an optional consent_ref (string, e.g. an Annex or per-person authorization id). Rationale: future household/multi-party engagements require per-person opt-in; enforcement is identical either way, so pay the schema cost now. The collect gate refuses subject+predicate pairs not covered by a grant, and the refusal log names the missing grant.

5. Predicate registry discipline. In docs/predicates.md, add the governance rule as normative text: a predicate may only be added alongside at least one crosswalk rule that consumes it ("no orphan predicates"). Include naming conventions (dot-namespaced domains: disk_encryption, os, firewall, mfa, network, edr, logging, policy, personnel — the last three reserved for future fact classes) and note the registry is expected to grow to roughly 150 observation predicates plus ~50 document/assertion; design the docs layout to survive that scale.

6. Synthetic fact generator. Add scripts/genfacts (Go, small, part of the repo, tested) that emits configurable synthetic fact sets: N hosts, per-predicate value distributions, tunable drift/staleness rates, fixed seed for reproducibility. This is test tooling for map/emit performance and correctness at fleet scale (hundreds of subjects), and demo fuel. Golden tests may consume small generated sets checked into testdata with the seed recorded.

7. Collector interface note. When designing the Collect interface, document (in a doc comment, not code) that future collector families include api-based (MDM, EDR, cloud config, HRIS) and document-repo collectors, and that the v0.2 plugin split must serve those without interface change.

Non-goals unchanged and extended: no declare subcommand, no document collector, no router/home collectors, no EDR/SIEM integration, no multi-party consent UI. Schema space reserved, nothing more.

## Milestones (propose plan, then build in this order, tests with each)

1. fact + scope packages with parsing, validation, redaction, fuzz targets
2. collect: static collector end-to-end, then localhost (macOS + Linux)
3. manifest sign/verify + deterministic tar + seal/unseal
4. crosswalk load + map with findings and freshness
5. emit OSCAL AR + schema validation target
6. render markdown + demo.sh + VERIFYING.md + reproducibility test in CI (GitHub Actions, build matrix, artifact checksums)

At the end of each milestone, stop and show: what was built, test output, and any deviation from this spec with reasoning. If any part of this spec is ambiguous or a decision seems wrong, raise it before implementing rather than silently choosing.
