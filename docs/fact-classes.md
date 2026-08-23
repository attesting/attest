# Fact classes

Every fact carries a required `class` field. It takes exactly one of three values:

```
observation | document | assertion
```

Validation rejects any other value. This is a closed set, not an open vocabulary — a fact whose class cannot be determined does not get a new class invented for it.

**v0.1 emits only `observation`.** Both built-in collectors hardcode it. The other two classes are reserved: defined in the schema, validated if present, and built on by nothing.

## Why three classes

The classes correspond to the three assessment methods in NIST 800-171A. That correspondence is the entire reason the field exists — it lets a mapped finding state not just *whether* a control is satisfied but *by what kind of evidence*, which is the distinction an assessor is already required to make.

| Class | 800-171A method | Source of the fact | Status |
| --- | --- | --- | --- |
| `observation` | Test | A machine was inspected and reported its own state | v0.1 |
| `document` | Examine | A fact derived from a signed policy or configuration repository | Reserved |
| `assertion` | Interview | A signed, dated statement by a named human | Reserved |

### observation

The machine speaks for itself. A collector ran a command or queried an API and recorded what came back, along with the exact command in `source.detail`. Observations are the strongest evidence class because they are independently re-derivable: run the collector again and you should get the same answer, or a defensible reason why not.

### document

A fact extracted from documentary evidence — a policy repository, a configuration baseline, a signed procedure. The distinguishing property is that a document fact describes what an organization has *committed to*, not what a machine is *currently doing*. The two diverge constantly, and a system that cannot represent the difference cannot represent the finding that matters.

### assertion

A human states something that no machine can observe and no document records. "Terminated staff have their access revoked within one business day" is not a query result; it is a claim by a person with a role and a name, and it is evidence only insofar as that attribution holds.

Assertion-class facts are expected to carry a shorter `freshness_max_days` than observations, and crosswalk rules that consume them should set it accordingly. **The rationale is decay.** An observation ages predictably against a system that changes at a rate you can reason about. An assertion ages against staff turnover, reorganizations, and memory — and the person who made the claim may no longer hold the role that made it meaningful, or may no longer be at the organization at all. A six-month-old disk encryption observation is stale in a well-understood way. A six-month-old statement about a process is stale in a way nobody has measured. The schema treats the second as more perishable than the first because it is.

## Naming rationale

The tool **attests**, humans **declare**, machine facts **observe** — three words, three meanings, no overlap.

This is a deliberate constraint on the vocabulary, and it is worth stating plainly because the obvious alternative is worse. "Attestation" is the natural word for a signed human statement, but it is already the word for what the tool does to the fact set as a whole and for what the surrounding supply-chain ecosystem means by the term. Reusing it inside the schema would create a token whose meaning depends on where you are standing.

So the schema token is `assertion`, and the future subcommand that produces one is:

```
attest declare
```

which reads correctly in both directions: the human declares, the tool attests to the declaration. `attest declare` is not implemented in v0.1 and is an explicit non-goal for it.

## Related schema fields

`source.method` is a closed enum whose values align with the classes:

```
command | api | document | assertion
```

v0.1 uses `command` only. The static collector re-emits facts through scope filtering and uses `command` semantics, since it carries forward the method by which the fact was originally obtained rather than asserting a new one.

Crosswalk `sufficiency` reserves a matching third value — `primary | corroborating | assertion` — so that a rule can express that a control is satisfied only in part, and by testimony rather than by test. See [crosswalk-authoring.md](crosswalk-authoring.md).
