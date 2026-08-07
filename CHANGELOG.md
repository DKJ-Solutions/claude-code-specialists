# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it three
named sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the impact table, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — the impact table
under *Who is this for*. That is what orders this list: furthest reach first, and within a tier the most
consequential change first. It also decides what may be released: **a release needs at least one tier-1
entry**, **a minor needs a tier-2 one**, and a **major** recaps ten minors. So a changelog holding nothing
but tier 0 is a changelog with no release in it yet.

---

## `docs/v3-7-0-release-documents` changelog

### Branch description

The v3.7.0 release documents

### Branch ID

20260807-123726

### Branch type

docs

### What does the change on this branch bring to main?

The two hand-written documents of `v3.7.0`: the internal summary and the customer-facing highlights. The
cut generates a draft of each and names them as deliberately unwritten; this is that writing, shipped the
way every other change is, because the release commit is already tagged and neither document is one of
the two direct-on-`main` exceptions.

Both drafts arrived carrying **branch administration** -- branch names as the subject of a bullet, internal
IDs, the branch type -- which the dossier form put there and which means nothing to either reader. Edited
out by hand here. Worth recording rather than only fixing: it is avoidable work at every release, and the
generators could strip it the way they already strip the significance scores.

### Significance

#### Tier 0

Nothing changes in how anyone works here; two documents that did not exist now do.

**Score:** 1

#### Tier 1

The internal summary is the one document that says what the organisation got out of the release, and it is
also the body of the published GitHub Release -- so it is the version of this release most people outside
the work will ever read.

**Score:** 3

#### Tier 2

The highlights are written for the people who consume this product, and they are what a consumer meets
when they update. Rewritten from the draft so they describe the new branch-file form rather than quoting
the branches it arrived on.

**Score:** 3

### Pull Request

[PR #502](https://github.com/DaveKJohn/claude-code-specialists/pull/502) · merged 2026-08-07

---

