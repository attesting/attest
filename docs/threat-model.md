# Threat model

> **Stub — populated at milestone 6** (alongside the reproducibility and verification work). Headings below reflect what [SPEC.md](../SPEC.md) promises this document will cover.

## Trust boundaries

## Assets

## Adversaries and their capabilities

## The core makes no network calls

## Credential handling and redaction

Credentials never appear in facts, logs, config files, or error messages. Collectors read credentials from environment variables only.

## Scope enforcement as a consent mechanism

## Fact integrity: signing, manifests, and drift detection

## Transport: sealing and the recipient model

## Key management

v0.1 stores keys as files and has no key management ambitions. Production keys on hardware are roadmap.

## Cryptography roadmap

FIPS-validated cryptography is **not** claimed by v0.1. This section records the position and what would be required to change it.

## Known limitations
