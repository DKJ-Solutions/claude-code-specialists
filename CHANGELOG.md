# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-4-0-release-note` changelog

### Branch title

The v4.4.0 release note, and the first release this repo timed

### Branch ID

20260811-103026

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning — and the first release note in this repo
that answers *"how long does a release take"* in minutes, which is the whole reason the previous branch
existed.

**The number that had no owner now has one.** `v4.3.0` ran a full cycle against the thirty-minute release,
demonstrably improved it, and reported **43% fewer words** because words were what somebody had counted.
Step 0a was written to close that, and this is its first run: the clock was noted at **10:24:11** before
anything was cut, and the legs are taken from git timestamps rather than recalled — **5m 07s** from clock
start to the release commit, covering the repo-state check, the checklist walk, the lint gate, the 30 test
suites at **231s**, the writes, the commit and the tag.

**The document names the boundary it cannot cross, and that is the part worth keeping.** A release note is
frozen before the Release is published, so the last two legs — the pull request's CI gate and the publish
— are running *on the document itself* while it is written. Rather than estimate them into the total, the
section states the subtotal to freeze, marks the release commit's own CI as the non-blocking leg it is, and
reports what `lint-en-tests` has actually cost across the four most recent runs (**8m 41s to 9m 20s**),
which is the largest single thing a person waits on. The closing report carries the end-to-end figure. A
document that estimates its own tail is the failure step 0a was written against, one recursion deeper.

**And it writes down the conclusion nobody should draw from it.** This release carried two entries against
`v4.2.0`'s seven, so it is a good test of the clock and a weak one of the writing gain — less to read is
less to write, and the merged-document model is not shown to be faster by a smaller release. The caveat is
in the organisational section instead of being left for a later reader to reconstruct, together with the
admission that cutting this soon after `v4.3.0` works *against* the cadence lever the performance engineer
had just named: it was paid deliberately, because a baseline cannot be taken retroactively.

**One defect found by walking the checklist, and routed rather than repaired here.**
[`releases/README.md`](releases/README.md)'s tier table still named `consumer/<dir>` and `internal/<dir>`
as the tier-2 and tier-1 documents, four days after both were merged into `notes/`. No gate sees it: a
directory named in a table cell is prose, not a link, and lint check 4 reads links. It is the technical
writer's change and belongs in its own branch, so this one records it in the release note's *still open*
section and leaves it there.

### Significance

#### Tier 0

The repo's most-repeated expensive procedure has a measured duration for the first time, with the split
that decides whether any proposal about it is worth anything — two of the three gate runs block a person,
the third does not.

**Score:** 4

#### Tier 1

An improvement cycle that could not state its result in the unit it was commissioned in now has one that
can, and the document says out loud which comparison this release does *not* license.

**Score:** 4

#### Tier 2

This is the document a consumer receives. It carries the one new thing to do — time your own release — and
states plainly that nothing breaks and no command changes.

**Score:** 3

### Pull Request

[PR #593](https://github.com/DaveKJohn/claude-code-specialists/pull/593) · merged 2026-08-11

---

