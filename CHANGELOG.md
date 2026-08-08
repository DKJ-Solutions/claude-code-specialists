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

## `docs/check-20-and-inbound-catch-up` changelog

### Branch title

The check-20 paragraph and the inbound rule catch up with what shipped

### Branch ID

20260808-190626

### Branch type

docs

### What does the change on this branch bring to main?

Two documents said less than the mechanisms they describe now do, and one of them said it in the paragraph
that exists to explain a gate against exactly this.

**`CLAUDE.md`'s #508 paragraph.** It described check 20 as it was born — the section COUNT, not the names —
and stopped there, while [#525](https://github.com/DaveKJohn/claude-code-specialists/pull/525) had given the
check a separate pass over `CHANGELOG.md`'s intro with the level marker optional, and moved matching from
per-line to whole-text. Both are now stated, with the measurements that chose them: whole-text finds the
same **4** claims in the scanned tree as per-line, while dropping the marker tree-wide would find **50** —
which is why it is dropped across a dozen lines and nowhere else.

**A figure in that same sentence was wrong from birth.** It read that a name-matching rule *"accuses six
correct documents, because `What does this change do?` and `Type of change` …"*, pairing one measurement
with the other's reason. The lint's own candidate table has them apart: **6** was that rule's finding count
(all six false), **2** is the number of correct documents the PR-template collision accuses. Both numbers
entered the tree in the same commit, `e285c9b`, so the doc and the code have disagreed since the day the
check was written, with nothing to catch it: check 20 holds section counts and check 16 holds byte counts
and file sizes, and a finding count is neither.

**Chris's lens gains the second inbound failure pattern.** It documented one: the item was already
repaired, so verifying it closes it (#469). [#456](https://github.com/DaveKJohn/claude-code-specialists/issues/456)
is the other shape — everything it asks for still open, while three of its own load-bearing facts had
expired in the four days since filing. A standing item is therefore not automatically a routable one, and
the lens now says to check the reasoning as well as the symptom.

Plugins: none

### Significance

#### Tier 0

The paragraph explaining this repo's newest gate is the one place a developer looks before touching it, and
it described a version of that gate that stopped existing the day before. The wrong figure is the sharper
half: it is a measurement citing a real table, so it reads as verified.

**Score:** 3

#### Tier 1

Nothing here is legible outside this repo's own developers — `CLAUDE.md`'s gate paragraph and Chris's repo
lens are both this checkout's own governance, and neither travels to a consumer or to a colleague on
another project.

**Score:** N/A

#### Tier 2

No consumer-facing surface is touched: no plugin, no manual, no portable persona, no script.

**Score:** N/A

### Pull Request

[PR #526](https://github.com/DaveKJohn/claude-code-specialists/pull/526) · merged 2026-08-08

---

## `fix/changelog-intro-in-the-shape-gate` changelog

### Branch title

The changelog intro rejoins the shape gate

### Branch ID

20260808-175617

### Branch type

fix

### What does the change on this branch bring to main?

`CHANGELOG.md`'s introduction told four things that had stopped being true, and check 20 — the gate built
two days earlier for exactly this class — could not see any of them. Both halves are repaired here.

**The four claims.** The intro promised *three named sections* per entry where the scaffolder writes
**six**; an *impact table under "Who is this for"*, which became `#### Tier N` sub-sections under
`### Significance` on August 6; that *a release needs at least one tier-1 entry*, where tier 0 alone has
earned a patch since August 7; and that *a minor needs a tier-2 one*, where tier 1 or higher now earns it.
The last sentence followed from those rules and inverted the answer: a changelog holding nothing but tier 0
was called a changelog with no release in it, and it is a patch waiting to be cut.

**Why nobody caught it.** A cut empties this document down to its intro and carries that intro through
**verbatim**, so it is the one piece of prose in the repo that no release rewrites and no reviewer opens.
The repo had already written this lesson down — `release-lib.ps1` records being bitten by exactly it on the
per-plugin CHANGELOGs: *"the entries below the intro were history, the intro was a live statement about the
present mechanism."* Check 20 nevertheless excluded `CHANGELOG.md` whole, on the history grounds it shares
with checks 11 and 12, the day after that note was written.

**Two independent things held the intro out of reach, and repairing either alone changes nothing.** The
file was excluded, so nothing read the intro — and the pattern would have walked past the sentence anyway:
it carried no `###` marker, and it ran across a line break. So the head gets its own pass with the level
marker optional, and matching moves from per-line to whole-text.

**Both relaxations were chosen by measuring rather than by arguing**, which is what keeps the marker rule
intact where it earns its place:

| pattern, scope | claims found |
|---|---|
| strict, per line, over the scanned tree | 4 — what the check did |
| strict, whole text, over the scanned tree | **4 — identical**; the 3 extra sit in history it already excludes |
| loose, whole text, over the whole tree | 50 — the documented noise, 46 of them |
| loose, whole text, over the intro alone | **1** — the real claim, before and after the repair |

So the marker still guards ~200 files against 46 false hits and is dropped only across a dozen lines this
repo owns, where it was the whole difference between catching the drift and not. Whole-text matching
changes nothing about what the tree pass reports; it closes the blind spot where a reflowed sentence hides
a claim. Five new asserts pin both directions, including the one that matters most: the same markerless
claim **inside an entry** stays silent, because entries are history and are full of prose that was true
when it was written.

One stale comment in the same file went with it: the import header named `Build-PluginChangelogIntro` and
check 17 as the reason `release-lib` is dot-sourced, and both were retired with the per-plugin CHANGELOGs on
August 8 — a comment naming a deleted function, one day old, in the file this branch was already opening.

Plugins: none

### Significance

#### Tier 0

The intro is the first thing anyone opening `CHANGELOG.md` reads, and it was wrong about the entry's shape
*and* about what may be released — a developer following it would have expected any release to need a
tier-1 entry. It is correct now, and the gate that should have caught it does. Noticed the moment somebody
touches that file, which is every branch.

**Score:** 3

#### Tier 1

N/A — nothing here reaches beyond this repo's own developers. The document is this repo's pending list and
the gate is this repo's own lint, which is deliberately not among the scripts mirrored into the workflow
plugin.

**Score:** N/A

#### Tier 2

N/A — a consumer receives `CHANGELOG.md` in the marketplace clone, but what they read there is our pending
changes; the entry format they work from is `CONTRIBUTING.md` and the templates, both of which were measured
correct and are unchanged.

**Score:** N/A

### Pull Request

[PR #525](https://github.com/DaveKJohn/claude-code-specialists/pull/525) · merged 2026-08-08

---

