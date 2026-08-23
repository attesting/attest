# Predicate registry

A predicate is the dot-namespaced name of the thing a fact asserts about its subject: `disk_encryption.enabled`, `os.patch_age_days`. Predicates are the vocabulary shared between collectors (which produce facts) and crosswalk modules (which consume them), which makes the registry an interface and not a convenience list.

## Governance

**No orphan predicates.** A predicate MAY be added to the registry only alongside at least one crosswalk rule that consumes it. A predicate with no consuming rule MUST NOT be registered, and MUST NOT be emitted by a collector.

This is normative. The rule exists because the failure mode it prevents is the one that kills evidence tools: collectors accumulate everything that is easy to collect, the fact set grows without bound, clients are asked to consent to collection that serves no assessment purpose, and the reviewer cannot tell which facts matter. Every predicate in this registry must be able to answer "which control does this serve?" with a specific rule.

Two consequences worth stating explicitly:

- Removing the last crosswalk rule that consumes a predicate makes that predicate an orphan. It is removed or the removal is justified in the same change.
- "We will need it later" is not a consuming rule. Reserve the namespace instead.

## Naming conventions

Predicates are `domain.attribute`, lowercase, `snake_case` within each segment, dot-separated. The domain segment comes from a controlled list; the attribute segment is free but should read as a property of the subject, not as a question or a command.

Registered domains:

| Domain | Covers | Status |
| --- | --- | --- |
| `disk_encryption` | At-rest encryption state | Active |
| `os` | Operating system identity, version, patch state | Active |
| `firewall` | Host firewall configuration | Active |
| `mfa` | Multi-factor authentication enforcement | Active |
| `network` | Network configuration and exposure | Active |
| `edr` | Endpoint detection and response agent state | Active |
| `logging` | Audit and log configuration | Reserved — future fact classes |
| `policy` | Documented organizational policy | Reserved — future fact classes |
| `personnel` | Role, access, and personnel process | Reserved — future fact classes |

The three reserved domains are expected to carry `document` and `assertion` class facts rather than `observation` (see [fact-classes.md](fact-classes.md)). They are named now so that the namespace is not colonized by observation predicates that would have to move later.

Values are JSON scalars or small objects. Never blobs, never free text where an enum would do, never a file's contents.

### Naming guidance

- Booleans read as a state: `firewall.enabled`, not `firewall.is_on` or `firewall.check`.
- Durations and counts carry their unit in the name: `os.patch_age_days`, `screen_lock.max_timeout_seconds`, `password_policy.min_length`.
- Prefer the specific over the general. `admin_users.count` is auditable; `users.info` is not.

## Expected scale

The registry is expected to reach roughly **150 observation predicates**, plus approximately **50 document and assertion predicates** as those classes come online — on the order of 200 entries total.

This document is therefore organized to survive that size rather than to look tidy at eight entries. Registry tables are split by domain, one section per domain, each row carrying the type and the consuming control. When a domain exceeds roughly 25 predicates it moves to its own file under `docs/predicates/<domain>.md` and this document retains the domain index and the governance rules. Do not defer that split past the point where a reader has to scroll to find a domain.

## Registry v0.1

The eight predicates specified for v0.1. All are `observation` class. Consuming controls refer to NIST 800-171 r2 and are satisfied by the crosswalk module shipped in v0.1.

| Predicate | Type | Meaning | Consuming control |
| --- | --- | --- | --- |
| `disk_encryption.enabled` | boolean | Full-disk encryption is active on the subject | 3.13.11 |
| `os.version` | string | Operating system version as reported by the OS | 3.14.1 |
| `os.patch_age_days` | integer | Days since the most recent applied patch | 3.14.1 |
| `firewall.enabled` | boolean | Host firewall is active | 3.13.11 |
| `screen_lock.max_timeout_seconds` | integer | Maximum configured screen lock timeout | 3.1.5 |
| `mfa.enforced` | boolean | Multi-factor authentication is required for the subject | 3.5.3 |
| `password_policy.min_length` | integer | Minimum password length enforced by policy | 3.5.3 |
| `admin_users.count` | integer | Number of accounts with administrative privilege | 3.1.1, 3.1.5 |

The `screen_lock` domain is active by virtue of `screen_lock.max_timeout_seconds` and is added to the domain table when a second predicate joins it.

Crosswalk rules consuming these predicates live in the v0.1 `nist-800-171.yaml` module. Controls 3.4.1 and 3.4.2 are in scope for that module but have no consuming predicate in this registry yet; predicates serving them are added under the governance rule above — rule first, then predicate.
