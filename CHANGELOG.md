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

## `docs/a-release-note-cannot-time-its-own-publication` changelog

### Branch title

The release note carries its own total, and step 0a says where each half goes

### Branch ID

20260811-105337

### Branch type

docs

### What does the change on this branch bring to main?

**Step 0a asked for a number the release note structurally cannot contain, and running it once was what
exposed that.** The instruction said: note the clock before the cut, note it again when the Release is
published, write the end-to-end duration into the release document's organisational section. All three
halves are right and the combination is impossible — the note is frozen for its own pull request at step 4,
and the Release is published at step 5, so while the timing section is being written its CI gate, its merge
and the publish are all still running on that very file.

**The size of the gap is the argument.** At `v4.4.0` the subtotal available at freeze was **9m 42s** of a
release that came to **28m 03s**: the unmeasurable tail was **two thirds**. A document carrying only the
first pass is not slightly incomplete, and the predictable failure is that whoever writes it fills the gap
with an estimate — in the one section whose entire point is that the figure was measured rather than felt.

**So the step is two passes now, and the second one is expected rather than exceptional.** At step 4 the
document gets the clock start, the legs already readable off timestamps, the subtotal to freeze, and which
of them blocked a person — the half that cannot be recovered later. After step 5 the total is added in its
own small pull request, together with the three legs the first pass could not see. This branch *is* that
second pass for `v4.4.0`, which is why the number it adds is a measurement and not a worked example.

**Two wrong repairs are refused by name, because both suggest themselves before the right one.** Publishing
the Release earlier would make the total writable in one pass and would put the page up before its
attachments exist, which is exactly what step 5's ordering is for — the tail of a release is cheap to
measure twice and expensive to publish twice. And letting the total live only in the closing report to the
requester is refused too: a chat message is not where the next person looks for what a release costs, which
is the whole reason the number was asked for in a document.

**The measurement itself lands in three places, each for a different reader.** The v4.4.0 note gets the full
leg table and the 56% gate share; [Nolan #25](.claude/specialists/lenses/06-25-extension.md)'s first
outstanding number is answered with both cautions attached — that release carried two entries against
`v4.2.0`'s seven, so it measures the clock well and the writing gain not at all, and 28m 03s **confirms** the
~30 min everyone had been reasoning about rather than improving on it; and
[Rendall #06](.claude/specialists/lenses/05-06-extension.md)'s clock paragraph learns that noting the time is
a two-pass job for him specifically.

### Significance

#### Tier 0

The repo's most-repeated expensive procedure has a complete measured duration for the first time — 28m 03s,
56% of it gates, all of it blocking — and the instruction that produces it no longer asks for something
impossible.

**Score:** 4

#### Tier 1

An improvement cycle that could not state its result in the asked-for unit now has a figure that can be
compared against the next one, with the two conclusions it does *not* license written down beside it.

**Score:** 3

#### Tier 2

The corrected step travels: a consuming repo following step 0a would have hit the same impossibility, filled
it with an estimate, and had no way to tell that two thirds of the number was guessed.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #594](https://github.com/DaveKJohn/claude-code-specialists/pull/594) · merged 2026-08-11

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

## `docs/the-release-overview-describes-one-document` changelog

### Branch title

The release overview describes the one document it actually writes

### Branch ID

20260811-115645

### Branch type

docs

### What does the change on this branch bring to main?

`releases/README.md` still described the retired three-document model four days and two releases after
the August 10, 2026 merge into one hand-written note with a named section per reader — a stale claim no
gate could see, because the drift sat in table cells and prose rather than in a link (lint check 4 is
deliberately scoped away from a path in prose) and never touched a live-figure sample either (checks 15/16
guard those, not a document-count claim). This branch corrects it: the tier table, `## The three documents`
(renamed `## The release documents`) and its three `### Tier N` sub-sections are rewritten around the
merged `notes/<dir>/<X.Y.Z>.md` with its *For consumers* / *What it is worth* / *What was still open*
sections, cross-checked against `cut-release.ps1`, `release-lib.ps1`'s `Build-ReleaseNoteDraft`, the
`cut-release` skill and Rendall's lens rather than invented from summary. Two further staleness sites
turned up while reading the "Cutting a release" section for correctness rather than rewrite: the GitHub
Release closing step still said the body came from the internal note (it is generated), and the seam-value
note still described `new-internal-note.ps1` writing the overview's Version cell (the cut writes it itself
now). Both are corrected. The published release list at the bottom of the page — rows, `#### 4.x` heading,
the `release-lib.tests.ps1` major pin — is untouched, as required: those are published records and a live
test asserts against that exact heading.

**And the same defect was carrying a false claim in `CLAUDE.md`, which is why it is in this branch rather
than a later one.** The constitution said the note's inbound Version cell is *"written by
`new-internal-note.ps1` rather than by the cut"*, and pointed at `Set-ReleaseInternalNoteLink` for why it
*could not* be the cut's job. That reasoning was correct on August 5 and expired on August 10: it could not
be the cut's job while the note did not exist during the cut, and the merge made the cut **draft** the note,
so there is a real file to point at by the time the row is written. Verified against the tree rather than
inherited — `cut-release.ps1:794` says so in its own comment, `Set-ReleaseInternalNoteLink` is still called
by `new-internal-note.ps1` alone for the two-document flow, and `v4.4.0`'s row pointed at
`notes/4.x/4.4.0.md` on the first write with nothing repointing it. Same August 10 movement, same class of
drift, one document further in — so it belongs in the same entry rather than being filed as an unrelated
find. What generalises is the shape: **when a mechanism moves, the sentence explaining why it could not move
is the one that survives longest**, because it reads as reasoning rather than as a fact anyone re-checks.

### Significance

#### Tier 0

The class of defect this closes — a written convention that moved while the scripts moved with it, leaving
only the prose behind — is exactly the shape this repo's own docs sweeps keep finding (inbound #508, #556,
#557, #561 are all instances of the same pattern: a mechanism changes and no gate reads the sentence
describing it). `releases/README.md` is the page a release manager actually opens mid-checklist, so a
developer following it during the next cut would have hit "the consumer document" and "the internal note"
and had to reconcile that against what `cut-release.ps1` actually printed.

**Score:** 2

#### Tier 1

Colleagues on this project read this page to understand how a release is put together and what it costs;
a page that describes a retired model teaches the wrong mental model of the one document that now carries
both the *For consumers* section and the organisation's two sections. This is the release process's own
reference page, not a peripheral doc.

**Score:** 3

#### Tier 2

**This page's portable half exists to be copied**, and that is the half that was stale. Its own mirroring
instruction tells an agent that everything above the horizontal rule *"is portable and can be copied
as-is"* — and `releases/` sits in every consumer's plugin cache, because a marketplace source is a git
clone of the whole repository. So for four days, anyone mirroring this workflow into their own repo copied
a retired three-document model and would have built their release process around two documents their
scripts no longer write.

Small rather than urgent: it needs a mirroring to have happened inside that window to bite anyone, and
nothing a consumer already has stops working. But it is not nothing, and it was first assessed as `N/A` on
the premise that a consumer cannot reach this page — which its own mirroring section disproves.

**Score:** 2

### Pull Request

[PR #597](https://github.com/DaveKJohn/claude-code-specialists/pull/597) · merged 2026-08-11

---

## `docs/markdown-only-does-not-mean-script-free` changelog

### Branch title

Nine of thirty suites read this repo's own markdown

### Branch ID

20260811-113314

### Branch type

docs

### What does the change on this branch bring to main?

Answers item 2 of Nolan #25's own "three numbers owed" list in
[`06-25-extension.md`](.claude/specialists/lenses/06-25-extension.md#wall-clock-here--the-gates-and-the-baseline-measured-at-v420-august-10-2026):
which of the 30 suites in `scripts/tests/*.tests.ps1` can change behaviour on a markdown-only diff. Measured
rather than guessed, over all 30 files: **9** read this repo's own real markdown for content and can flip on
a docs-only diff, **21** build and read only their own fixtures and cannot, **0** were undecided. So the
assumption "markdown-only, therefore skip the second local run" does not hold in this repo — 9 of 30 read
real content a docs change can move.

The transferable half is not the count but the method that produced it, and the reason that matters is the
result it caught: the obvious guess — that the lint-gate suite (`check-plugin-integrity.tests.ps1`), which
exercises checks over agent defs, manuals and the changelog, must be one of the nine — is wrong. It builds
every document into its own fixture and is in the 21. A guess sorted by "sounds document-heavy" would have
put the wrong nine in the risk bucket; only reading each suite's source and citing the line that reads (or
doesn't read) the real repo root got the right nine. That is the repeatable part for any future "can a
diff of shape X change behaviour in suite Y" question: cite the line, don't infer from the suite's name or
subject matter.

No recommendation is made about whether to change how the second local run works — that is a change to
this repo's safety rules and is not this branch's decision to take.

### Significance

#### Tier 0

A repo-internal cost question — is a tempting optimisation (skip the second local suite run on a
markdown-only diff) actually safe here — is closed with evidence instead of instinct, and the answer is "no,
don't", with the nine named suites and their exact triggers as the record. That refusal-on-measurement is
the substantive part: without this branch, the next person tempted by that shortcut would either skip it on
a hunch (and might silently lose coverage on the 9) or re-derive the same 30-file audit from scratch to be
sure.

**Score:** 4

#### Tier 1

Colleagues on this project gain a citable answer to a question that was open in the shared lens, plus the
method (read the source, cite the line) for the next such audit — useful, but it is the same fact as tier 0
seen by a different reader, not a new one.

**Score:** 2

#### Tier 2

This measurement is about *this* repo's own thirty suites and their real-file reads — a consumer has a
different suite set, if any, and would have to re-run the same audit against their own tree rather than
inherit this count. Only the method travels, and the method is already carried by tier 0/1's record of how
it was done; there is nothing here written for a consumer to read.

**Score:** N/A

### Pull Request

[PR #595](https://github.com/DaveKJohn/claude-code-specialists/pull/595) · merged 2026-08-11

---

