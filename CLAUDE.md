# Instructions for Claude sessions in this repository

## Read first

[SPEC.md](SPEC.md) is authoritative. Read it in full before writing code or proposing changes. If something in this file appears to conflict with SPEC.md, SPEC.md wins and the conflict is worth raising.

## Milestone discipline

Work proceeds in the milestone order at the bottom of SPEC.md. At the end of each milestone: **stop and show.** Report what was built, the test output, and any deviation from the spec with the reasoning behind it. Do not roll into the next milestone without being told to.

Do not build ahead of the current milestone, and do not implement anything in the spec's addendum. Items marked "reserve" mean: define in schema, types, and docs; validate if present; build nothing on them.

## Schema changes require approval

The fact schema, `scope.yaml` schema, and crosswalk rule schema are not to be changed, extended, or "improved" without explicit approval. This includes adding fields, relaxing validation, and widening a closed enum. Propose the change and the reasoning; wait for an answer.

The same applies to the predicate registry, which is governed by the no-orphan-predicates rule in [docs/predicates.md](docs/predicates.md): a predicate is added only alongside a crosswalk rule that consumes it.

## There is a downstream consumer, and it changes nothing about priorities

A separate system, the Tony Rossi Consulting client portal, reads this tool's
output: `manifest.json`, the OSCAL assessment results, the rendered summary, and
it generates `scope.yaml` as input. That integration is specified on its side
(`design/44` in that repo) and deliberately requires **no changes here**. The
core makes no network calls, and nothing about having a consumer may alter that.

What it does mean:

- **Output formats are somebody's input.** A change to the manifest shape, the
  emitted OSCAL, or the `scope.yaml` schema is a breaking change for a consumer
  that cannot see it happen. This is a further reason for the approval rule
  above, not a new rule.
- **`attest` does not depend on the portal, know its name at runtime, or grow a
  feature for its benefit.** A compliance engine coupled to one consultancy's
  SaaS is not a product anyone else can buy. If a proposed change only makes
  sense because of that consumer, it is the wrong change.
- **SPEC.md and the milestone order still win.** Nothing downstream reorders the
  milestones or justifies building ahead of them.

One thing is worth building here for this tool's own users and happens to serve
the consumer too: **a way to validate a `scope.yaml` without collecting
anything.** Anyone hand-authoring a scope file wants to check it before running
against a client. It is not in the v0.1 CLI surface, so it is a spec change to
propose and have approved, not to assume.

When golden files exist (milestones 4–6), consider publishing them as a small
**conformance bundle** alongside releases. Consumers can then pin a version and
test against real output without building this tool, which is how a format
change gets caught in someone's CI instead of at a client site.

## Commit signing is required

Every commit on `main` is signed, starting from the first. Never commit with signing disabled and never use `--no-gpg-sign`. If signing fails, stop and report it rather than working around it: [VERIFYING.md](VERIFYING.md) makes a public claim about this history, and an unsigned commit breaks it.

## Dependencies

No new dependencies without asking. The permitted set is named in SPEC.md: cobra (maybe), age, a YAML library, uuid. Each entry in `go.mod` carries a comment justifying it. Adding anything else is a decision, not an implementation detail. Prefer the standard library.

## Determinism

Trust-critical output is byte-identical for identical input. Sort JSON keys, use stable ordering, never leak map iteration order, honor `SOURCE_DATE_EPOCH` for embedded timestamps. If you are about to introduce a source of nondeterminism, that is a design question to raise rather than a detail to handle.

## Raise problems early

If part of the spec is ambiguous, or a decision in it looks wrong, say so before implementing. Silently choosing an interpretation is the failure mode this instruction exists to prevent.
