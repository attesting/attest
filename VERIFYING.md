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

The authoritative copy of this fingerprint is published at https://attesting.dev, alongside the public key itself at https://attesting.dev/signing-key.asc. The copy above is reproduced here for convenience. **If the two disagree, trust the page and open an issue** — a fingerprint that differs across publication channels is exactly the condition this cross-publication is designed to expose.

The direction of that reference is deliberate. This repository is private until the first public release, so a reader who can reach the page may not be able to reach this file. The page is therefore the channel that must always be reachable, and it does not depend on this document to make its claim.

Verify the fingerprint of a key you have imported before relying on it:

```sh
gpg --fingerprint 2B96CD0E01A862E650A12C68D4F471A935E054FD
```

Key rotations will be announced on https://attesting.dev and recorded in this file, retaining the superseded fingerprint so that historical commits remain verifiable.

### Key custody

One key signs every commit here. It carries two identities:

```
Tony Rossi <me@tonyrossi.dev>
Tony Rossi <anthony.rossi1983@gmail.com>
```

Both belong to the same key — same fingerprint, same key material — so a signature under either uid is a signature from the key whose fingerprint is published above. The second uid is retained rather than removed, because commits made before the first was added carry it, and removing it would orphan their attribution.

The public half is published in two places, and both are load-bearing:

- **https://attesting.dev/signing-key.asc** — the armored public key, served as plain text. This is the authoritative copy.
- **The GitHub account that authors commits** — which is what lets GitHub render the green *Verified* badge. A signed commit without the public key on the authoring account is still signed; it simply will not display as verified.

**Authoring account, in transition.** Commits through the foundation of this repository were authored as `anthony.rossi1983@gmail.com` and are therefore attributed to **`xtonyknucklesx`**, which holds the key and verifies them. Work is moving to **`tony-grc`** under `me@tonyrossi.dev`. Until that account has the address verified *and* the public key uploaded, commits authored under it would sign correctly but display as unverified — so the switch of `user.email` is made only once both are in place, never before.

Rotating the key means updating all three of the following, **in this order**:

1. **The page** — publish the new key at https://attesting.dev/signing-key.asc and the new fingerprint on https://attesting.dev.
2. **The GitHub account key** — add the new public key to the account currently authoring commits, so newly signed commits continue to verify.
3. **The fingerprint in this file** — record the new fingerprint and retain the superseded one, marked as superseded.

The order matters. The page is the authoritative channel, so it leads; this file trails, so that it is never the only place claiming a fingerprint the page has not yet published.

Two operational notes for whoever performs a rotation. Of the GitHub credentials on this machine, only the token for `xtonyknucklesx` carries the `write:gpg_key` scope; `tony-grc` does not, and `gh api /user/gpg_keys` fails with a 404 and a scope hint when run under it. And adding a uid does **not** change the fingerprint — it is derived from the primary key material and creation time — so identity changes of that kind do not require a rotation, and must not be described as one.

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
