# Instructions for Claude sessions in this repository

## Read first

[SPEC.md](SPEC.md) is authoritative. Read it in full before writing code or proposing changes. If something in this file appears to conflict with SPEC.md, SPEC.md wins and the conflict is worth raising.

## Milestone discipline

Work proceeds in the milestone order at the bottom of SPEC.md. At the end of each milestone: **stop and show.** Report what was built, the test output, and any deviation from the spec with the reasoning behind it. Do not roll into the next milestone without being told to.

Do not build ahead of the current milestone, and do not implement anything in the spec's addendum. Items marked "reserve" mean: define in schema, types, and docs; validate if present; build nothing on them.

## Schema changes require approval

The fact schema, `scope.yaml` schema, and crosswalk rule schema are not to be changed, extended, or "improved" without explicit approval. This includes adding fields, relaxing validation, and widening a closed enum. Propose the change and the reasoning; wait for an answer.

The same applies to the predicate registry, which is governed by the no-orphan-predicates rule in [docs/predicates.md](docs/predicates.md): a predicate is added only alongside a crosswalk rule that consumes it.

## Commit signing is required

Every commit on `main` is signed, starting from the first. Never commit with signing disabled and never use `--no-gpg-sign`. If signing fails, stop and report it rather than working around it — [VERIFYING.md](VERIFYING.md) makes a public claim about this history, and an unsigned commit breaks it.

## Dependencies

No new dependencies without asking. The permitted set is named in SPEC.md — cobra (maybe), age, a YAML library, uuid — and each entry in `go.mod` carries a comment justifying it. Adding anything else is a decision, not an implementation detail. Prefer the standard library.

## Determinism

Trust-critical output is byte-identical for identical input. Sort JSON keys, use stable ordering, never leak map iteration order, honor `SOURCE_DATE_EPOCH` for embedded timestamps. If you are about to introduce a source of nondeterminism, that is a design question to raise rather than a detail to handle.

## Raise problems early

If part of the spec is ambiguous, or a decision in it looks wrong, say so before implementing. Silently choosing an interpretation is the failure mode this instruction exists to prevent.
