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

