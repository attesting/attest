# Verifying attest

`attest` runs inside a client's security boundary and reads their security posture. That is an unusual amount of trust to extend to a binary from the internet, and you should not extend it on the strength of a README.

This document exists so that a skeptical system administrator can answer two questions without contacting anyone and without an internet connection to anything but this repository:

1. **Did this code come from who it claims to?** — answered by commit signatures, verifiable today.
2. **Does the binary I am about to run correspond to that code?** — answered by release checksums, signatures, an SBOM, and a reproducible build. Not yet applicable; no releases exist.

If a verification step in this document fails, the correct response is to stop and report it, not to work around it.

---

## Verifying commits

**This section is accurate today.**

Every commit on `main` is signed, beginning with the repository's first commit. There are no unsigned commits in the history and there are not expected to be any.

### Check the signature on a commit

```sh
git log --show-signature -1
```

A verified commit reports `Good signature` and the signing identity. To check the entire history at once:

```sh
git log --show-signature --pretty=%H | grep -c "Good signature"
```

Compare that count against `git rev-list --count HEAD`. They should match. Any commit that does not report a good signature is a finding.

If `git` reports `Can't check signature: No public key`, you have not imported the signing key yet — that is a missing key, not a bad signature. Import the key, then re-run.

### Signing key

Commits are currently signed with the following OpenPGP key:

```
2B96CD0E01A862E650A12C68D4F471A935E054FD
```

The authoritative copy of this fingerprint is published in two places: this file, and https://attesting.dev. Both should agree. **If they disagree, trust neither and open an issue** — a fingerprint that differs across publication channels is exactly the condition this cross-publication is designed to expose.

Verify the fingerprint of a key you have imported before relying on it:

```sh
gpg --fingerprint 2B96CD0E01A862E650A12C68D4F471A935E054FD
```

Key rotations will be announced on https://attesting.dev and recorded in this file, retaining the superseded fingerprint so that historical commits remain verifiable.

---

## Verifying releases

**NOT YET APPLICABLE.** No releases exist. There is no binary to verify, and any artifact claiming to be a release of `attest` at this time did not come from this project.

This section is present in the first commit so that the verification shape is visible before there is anything to hide behind it. When the first release ships, this section will carry the following, and each item is a commitment rather than an aspiration:

### Checksums

A `SHA256SUMS` file covering every published artifact, alongside a detached signature over that file. The procedure will be: verify the signature on `SHA256SUMS`, then verify your downloaded artifact against `SHA256SUMS` — in that order, because an unsigned checksum file proves nothing.

### Signatures

A detached signature for the checksum file, made with the release signing key. The release signing key may differ from the commit signing key above; if so, both fingerprints will be published here and on https://attesting.dev.

### SBOM

A Software Bill of Materials generated at build time and published with each release, listing every dependency and version compiled into the binary. `attest version` will report the SBOM hash of the running binary so that the binary in your hands can be tied to a specific published SBOM.

### Reproducible build

Instructions for rebuilding the released binary from source and obtaining a byte-identical result. Builds are `CGO_ENABLED=0` with trimmed paths and honor `SOURCE_DATE_EPOCH`, so an independent rebuild is expected to match the published checksums exactly.

This is the strongest of the four checks: it means you do not have to trust the release process, only the source you can read. If you rebuild and the hashes do not match, that is a serious finding and we want to hear about it.

---

## Verifying behavior

Verification of provenance is not verification of conduct. Two properties of `attest` are designed to be checkable by inspection rather than taken on faith, and both are specified in [SPEC.md](SPEC.md):

- **The core makes no network calls.** Collectors may reach APIs; the core engine (map, emit, sign, verify, seal) must function with the network removed. You can confirm this by running it with no network and by inspecting the dependency tree in the SBOM.
- **Facts are plaintext, and you review them before they leave.** `attest review` prints the complete fact set for inspection prior to sealing. Nothing is transmitted by the tool itself — sealed bundles are files that you move deliberately.

Both properties are load-bearing for the trust model and will be covered by tests in the repository.
