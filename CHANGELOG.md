# Changelog

Where this repo stands: under **Latest Release** the version currently cut, and under the three
**tier sections** everything merged since it - ordered by how far each change reaches, furthest
first. Every release ever cut is listed in [`releases/README.md`](releases/README.md); how the
mechanism works (entry files, tiers, folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

The tier is declared per entry while it is still on its branch and stated by the section once it is
folded, and it decides what may be released: **a release needs at least one tier-1 entry**, **a minor
needs a tier-2 one**, and a **major** recaps ten minors. So an empty tier section is normal, and a
changelog holding nothing but tier 0 is a changelog with no release in it yet.

## Latest Release

The most recent release — every earlier one is listed in
[releases/README.md](releases/README.md), with its date, type and title.

**v3.5.0** — 2026-08-05 — Minor

See [releases/internal/3.x/3.5.0.md](releases/internal/3.x/3.5.0.md) for what this release is worth. The full per-PR record is in [releases/development/3.x/3.5.0.md](releases/development/3.x/3.5.0.md).

## Tier 2 - Pull Requests

What a consumer of this product notices - newest at the top, one block per pull request.
At least one entry here is what a minor release requires.

## Tier 1 - Pull Requests

What a colleague working on this project gets out of it - newest at the top, one block per
pull request. At least one entry of this tier or higher is what any release requires.

## Tier 0 - Pull Requests

Repo-internal: docs, config and work nobody outside this repo's own developers notices -
newest at the top, one block per pull request. No release can be cut from this tier alone.
