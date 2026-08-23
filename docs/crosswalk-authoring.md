# Authoring crosswalk modules

> **Stub — populated at milestone 4** (crosswalk load + map with findings and freshness). Headings below reflect what [SPEC.md](../SPEC.md) promises this document will cover.

## Module structure

## Control entries

## Rule schema

### condition

Supported operators: `equals`, `not_equals`, `gte`, `lte`, `in`, `exists`.

### freshness_max_days

### sufficiency

Values: `primary` | `corroborating` | `assertion`. The third is reserved — parsed and validated, evaluated by nothing in v0.1.

### attester_role

Reserved optional field. Parsed and validated in v0.1, evaluated by nothing.

## Freshness semantics for assertion-class facts

Assertion-class facts are expected to carry shorter `freshness_max_days` than observations. See [fact-classes.md](fact-classes.md) for the decay rationale.

## Findings and reason codes

Findings: `satisfied`, `not-satisfied`, `insufficient-evidence`. Reasons for insufficient evidence: `stale`, `missing`, `corroborating-only`.

## Writing a rationale

## Versioning a module

## Testing a module
