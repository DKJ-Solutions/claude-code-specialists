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

## `docs/v4-7-0-release-note` changelog

### Branch title

The v4.7.0 release note

### Branch ID

20260813-115746

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can generate.

**The release has a theme and the *what it is worth* section is built on it.** Three of the six changes are
the same shape — a hardcoded path sitting behind a working seam, a skill page showing an entry block the
scaffolder has never written, and a step-list convention satisfiable only by ticking a box for work not
done. None failed loudly; each produced a plausible page, a passing gate or a populated directory. It is the
shape `v4.6.0` named, found three more times by looking for it rather than by being bitten again.

**The consumer section leads with the one item that asks anything of the reader**, and hands them a one-line
test for whether it reaches them at all: if `Get-ReleaseNoteRoot` answers anything other than
`releases/notes`, the hardcoded directory would have hard-failed their first cut into a new major. The other
two items are corrections to pages they may have copied from, and the fourth points back at `v4.6.0`'s notes
rather than repeating them.

**Step 0a's first pass is a subtotal of 15m 31s, and the comparison it invites is the honest half.** That is
three times less than `v4.6.0`'s frozen 46m 05s, and the document says plainly that the process did not get
faster: that release carried a mid-release repair and needed two manual interventions before the cut would
start. Both causes were removed by work shipped in this release, so this is the first cut in three to start
on the first attempt.

**Four things go into *what was still open* rather than being smoothed over**, including the one this release
paid again without building: `ship-pr` re-runs locally the same 32 suites `open-pr` proved minutes earlier on
the same commit, about seven minutes per pull request, measured at `v4.6.0` and still unbuilt.

### Significance

#### Tier 0

The record of what this release cost, and of the first cut in three that started on the first attempt, lives
here or nowhere. It is also where the next person reads that the `-NoPush` inspection and the two-pass timing
are load-bearing rather than ceremony.

**Score:** 3

#### Tier 2

It is the only document written *to* a consumer for `v4.7.0`, so it is the only place they learn whether this
version asks anything of them. It carries the one item that does — with a one-line check for whether the
hardcoded release-note directory ever reached their repo — and tells them what changed in the two skill pages
they may have copied an entry block from.

**Score:** 4

### Pull Request

[PR #641](https://github.com/DaveKJohn/claude-code-specialists/pull/641) · merged 2026-08-13

---

