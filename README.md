# attest

A local-first compliance evidence engine: collect security posture facts inside a client's boundary, review them in plaintext, seal them for transport, map them to framework controls, and emit signed OSCAL assessment results.

## Status

Pre-release and spec-first. **Not yet functional**: this repository currently contains the specification and project documentation. There is no implementation.

[SPEC.md](SPEC.md) is the authoritative v0.1 engineering specification. Read it first.

Project site and signing key: https://attesting.dev

## Verification

This project expects to be verified rather than trusted. See [VERIFYING.md](VERIFYING.md) for how to check commits today and how released binaries will be checked once they exist.

Project site: https://attesting.dev

## Documentation

| Document | Contents |
| --- | --- |
| [SPEC.md](SPEC.md) | Authoritative v0.1 engineering specification |
| [VERIFYING.md](VERIFYING.md) | Provenance and verification posture |
| [docs/fact-classes.md](docs/fact-classes.md) | Fact classes and their mapping to NIST 800-171A assessment methods |
| [docs/predicates.md](docs/predicates.md) | Predicate registry and governance rules |
| [docs/crosswalk-authoring.md](docs/crosswalk-authoring.md) | Authoring crosswalk modules |
| [docs/threat-model.md](docs/threat-model.md) | Threat model and trust boundaries |

## License

MIT. See [LICENSE](LICENSE).
