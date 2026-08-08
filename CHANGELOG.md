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

## `docs/v3-8-0-release-documents` changelog

### Branch title

The v3.8.0 release documents

### Branch type

docs

### Branch ID

20260808-165037

### What does the change on this branch bring to main?

The two hand-written documents `cut-release.ps1` deliberately does not write: the **highlights** for
consumers and the **internal summary**. The release commit and tag `v3.8.0` are already public, so
these land the ordinary way — a branch and a PR — rather than under the release exception, which is the
size it was granted at.

**The highlights were rewritten rather than edited, and the ordering is the whole point.** The cut
produced a 929-line draft: the fifteen tier-2 entries in the words their authors wrote for a *reviewer*.
A consumer needs the opposite shape. So the one thing this release asks them to **act** on leads the
page — enable `specialists-workflow-davekjohn`, with the two commands, or the next plugin update takes
`ship-pr`, `open-pr` and `cut-release` away — followed by the explicit *"if you never used them, do
nothing, and here is what stops happening to you"*. Everything that arrives without a decision comes
after it. The `RELEASE.md` removal gets a section of its own, because it is the one change that takes
away a file our own documentation used to send readers to; it says where the same history now lives and
that nothing needs migrating.

**The internal note answers a different question and is not a shorter highlights.** Tier 2 is *what a
consumer notices*; tier 1 is *what the organisation gets out of it*. Here that is: the product can now
be adopted by a team that does not work the way we do — the barrier was real and invisible while we were
its only consumer, since 47% of what the core shipped was workflow machinery, so "install this" meant
"and also work like this". Plus the standing effect: every future addition now meets one question at the
door (craft or way of working) instead of a case-by-case judgement that was measurably not being made
consistently.

**One thing found while inspecting the cut, and deliberately not repaired here.** `CHANGELOG.md`'s
introduction has drifted: it still promises an impact table under *Who is this for*, three `###`
sections per entry, and a minor requiring a tier-2 entry — all three replaced earlier this month. It
passes through every cut verbatim, so nothing checks it, which is the same write-once class
`release-lib.ps1` documents about itself. It is recorded in the internal note's open-items section and
left to its own branch: bundling an unrelated repair into the release-documents PR is how a diff stops
being reviewable.

Plugins: none

### Significance

#### Tier 0

Nothing about how this repo is developed changes; these are two documents about a release that is
already cut. The one thing a developer here gains is the recorded pointer to the stale changelog intro,
so the next person to open that file is not the one who has to notice it.

**Score:** 1

#### Tier 1

The internal note is this tier's document, so it exists precisely for this audience. It states what
v3.8.0 is worth in time and reach — the adoption barrier removed, the gate that dropped from ~8.5
minutes to ~2.5, and the release step now covered by the full gate rather than a lighter check — rather
than restating the file-level changes the developer notes already carry.

**Score:** 3

#### Tier 2

The highlights are the document a consumer meets when they update, and this release is the one where
doing nothing has a consequence: an unchanged repo silently loses `ship-pr` at its next plugin update.
The draft as generated buried that under fifteen reviewer-facing entries. Putting the required action
first, with the commands, is the difference between a consumer acting in time and finding out when a
merge fails.

**Score:** 4

### Pull Request

[PR #524](https://github.com/DaveKJohn/claude-code-specialists/pull/524) · merged 2026-08-08

---

