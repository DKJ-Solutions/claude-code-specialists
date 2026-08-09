## `docs/v3-10-0-release-documents` changelog

### Branch title

The v3.10.0 release documents

### Branch ID

20260809-122825

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the release tagged earlier today:
the **internal summary** and the **consumer-facing highlights**. They arrive via a branch and a PR
because the release commit is already tagged, and neither is one of the two changes allowed to land
directly on the trunk.

**The highlights went from 593 lines to 92, and the cutting was most of the work.** The generated draft
is the tier-2 entries copied verbatim — still in the words their authors wrote for a reviewer of this
repo, complete with branch names, scores, and the internal reasoning behind each decision. A consumer
needs none of that. What survives is what they must do, what is new, and what was repaired, in that
order: the document opens on the reinstall rather than on the feature, because a reader scanning ten
lines has to learn that their install is about to stop resolving.

**It also carries forward the trap that a mechanical rename hides.** A consumer who never enabled the
old workflow plugin gets every team back and, silently, no workflow — nothing about their session
announces it, because enabling none is a legitimate state the new session check is deliberately quiet
about. That is stated as a property of the mechanism rather than by naming which repos it applies to;
who is in that position is this project's register, not the reader's business.

**The internal summary answers a different question and is written to it.** Not what changed, but what
the organisation gets: the naming was costing a decision on every addition to this product, the
reinstall is a one-off cost that gets more expensive with every consumer added rather than less, and
the largest reduction in dependence on a developer is the one easiest to miss — five scripts that each
kept their own answer to "which plugins exist and where do their folders sit" now read one, which is
why the directory move in this same release needed no production script change at all.

Its "what was still open" section is written as a **snapshot**, per the skeleton's own warning, and
records four things: the three connected repos had not migrated, a second checkout on another machine
was still on the old ids, the pre-seam lens caveat is documented rather than repaired, and this release
is `3.10.0` rather than `4.0.0` — the rule that a major recaps ten minors met a line that had nine, the
rule won, and the next release can be the major without overruling anything.

### Significance

#### Tier 0

The release is only finished once these two exist; until then the history page points at a note that is
a skeleton. Nothing else in the repo changes.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes — the internal summary is written for exactly this reader, and it is the only document in the set
that answers what the release was worth rather than what it contained.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and more than usual for a release-documents branch. Every existing install stops resolving with
this release, so the highlights are not a summary anybody may skip — they are where a consumer finds
out they have to act, and the one place that warns them a straight id swap can leave them without a
workflow.

**Score:** 4

### Pull Request
