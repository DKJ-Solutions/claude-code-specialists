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

### #472 · The merge date is added by the fold, at the bottom, instead of scaffolded into the heading · Feat

**This entry's own heading is the specimen: it carries no date.** The scaffolder used to write one, and
it ran when the *branch* was created — so what it recorded was the branch's birth date, not the landing
date. A branch opened on Monday and merged on Thursday was filed as Monday's work, silently, in the one
document whose whole subject is when things happened. Dave, August 5, 2026.

**The date is now the fold's, and it goes at the bottom** — his second call, and the better one. The
heading was mixing two kinds of fact: the author knows the title and the type, while the PR number and
the merge date do not exist until the merge. That second kind already had a home at the end of the entry,
on the `[PR #NN](url)` line. So the two facts the fold owns now sit together:

```text
### #NNN · Short strong title · Feat

…the description…

[PR #NNN](https://github.com/DaveKJohn/claude-code-specialists/pull/NNN) · merged 2026-08-05
```

**It reads the PR's own `mergedAt`, not the clock**, and that distinction is not theoretical here. The
fold usually runs seconds after the merge, but this repo has measured it not doing so: unfolded entry
files were once found sitting in the repo root the morning *after* their merge — the silent half-state
that put `git status` into Chris's stand-verification rule. A clock reading would have dated those a day
late with nothing in the output to say so. `mergedAt` costs nothing: the fold already makes exactly one
`gh pr list` call, and gh returns whatever fields are asked for in one roundtrip.

**The dangerous half of this change was not the date at all.** `Format-CategorizedEntries` read each
entry's branch type as the **second-to-last** middot field of its heading — correct only because a date
happened to follow the type. Removing the date would have made that read return the type's neighbour, and
every entry in every release document would have landed in the `Other` catch-all: no error, no empty
output, one meaningless heading where the categories used to be. Found by reading the code before
touching it, not by a failing test. Both heading parses are now **content-based** rather than positional
— the type is recognised by matching the known branch types, the date by its shape — so the same code
path reads a dated heading and a dateless one. That is also why nothing had to be migrated: this repo's
entire history keeps parsing.

**`Convert-EntryHeadingToTitle` needed the same treatment and taught the sharper lesson.** The first
implementation walked in from the end eating anything that looked administrative, and a newly written
assert caught it on `### #12 · Fix · Fix` — an entry whose title *is* a type name. It ate both fields and
gave up. The tail has a grammar (at most one date, and before it at most one type), so it is matched
rather than walked; two types in a row cannot both be the type, which the grammar states and a greedy
loop cannot. `Other` is deliberately not treated as a type: it is the catch-all label this repo prints,
never a value a branch table produces.

**The closing line became `Format-EntryFoldFooter` in the entry-format lib, and the reason is testability
rather than tidiness.** The fold drives a live remote, so its own suite deliberately runs without a PR —
which would have left the only path this line has untested. Extracting the pure part is the same move,
for the same reason, as `Get-ExistingPrRecord` in `pr-issues-lib.ps1`. Its five asserts cover the normal
case, the PR timestamp beating the fallback, a fold that runs a day late, a PR with no timestamp yet, and
an unparseable one degrading instead of throwing — because a completed fold must not read as failed over
a cosmetic line.

**Four asserts in the branch suite got stricter rather than looser.** They pinned `· Feat ·` — a trailing
middot that only existed because a date followed. They now compare the whole heading line, which proves
both that the type is there and that nothing follows it; the malicious-title scenario in particular gains
from that, since a prefix match would have passed even if a broken argv boundary had appended something.
Plus one new assert stating the point outright: the scaffold writes no date.

**One cost, stated rather than smoothed over.** `CHANGELOG.md` can no longer be scanned for dates from the
headings alone — you read an entry's last line. That is acceptable because the tier sections only ever
hold what is pending since the last release, a window of days in which the dates sit close together. The
release notes, where the history actually lives, keep the line per entry.

Plugins: specialists

[PR #472](https://github.com/DaveKJohn/claude-code-specialists/pull/472) · merged 2026-08-05

---

### #471 · Publishing the GitHub Release is part of a cut that was already asked for · Docs · 2026-08-05

**Cutting a release is asked for; the closing steps of that cut are no longer asked for again.** The
version bump and the tag are the irreversible act and stay behind an explicit request. Once that is
given, the run goes through in one motion — generate the artefacts, ship the two hand-written documents
via their branch and PR, **publish the GitHub Release**. Stopping at the last step of a checklist the
requester started is a rubber stamp, and a rubber stamp trains everyone to stop reading it. The same
reasoning that made the PR merge a default rather than a checkpoint (July 27, 2026), applied one step
further along. Decision by Dave, August 5, 2026.

**The boundary that remains is Block 2 of the checklist, and it is a boundary rather than a carve-out.**
Where a repo sets `Get-LiveStage` it has a second stage — pushing to the live target — and that is a
different act with a different audience: a Release document describes a version, a live push changes
what customers see. This approval covers Block 1. A repo wanting another boundary states that in its
own lens.

**Four places said this and they had to stop disagreeing.** The constitution named "creating a tag or
GitHub Release" in one breath under *only on explicit request*, which would have outranked everything
else written elsewhere — the safety rules take precedence over any convenience, so leaving that line
standing would have made the new default unusable in exactly the sessions that read the rules
carefully. It now separates the tag from the publication. Rendall's **portable body** carries the
statement in his own terms, the release page's **portable half** carries it where the closing step is
described, and the **cut-release skill** carries it at step 5, which is where somebody actually reads
it mid-procedure.

**And the reason all four are portable is itself now a written rule, in Tessa's manual.** The first
draft of this change was headed for Rendall's *repo lens*, because that is where the decision was made.
Dave's correction: where a decision is made says nothing about where it applies, and what he wants in
this repo he wants in the others he runs the plugin in. The failure mode is quiet — a general rule
filed in a lens is not wrong anywhere, it simply never arrives, and nothing reports its absence.

**The corollary was the second correction, and it is the sharper one.** Knowing the rule was portable,
the next instinct was to *narrow* its wording so it could not surprise a consumer with a live deploy
stage. That is the wrong repair: it weakens the core for every reader to pre-empt one repo that has its
own place to speak. The core is stated in full here; the deviating consumer records the deviation in
its own lens. Both halves are in Tessa's hard rules now, because she is the one who guards which half a
sentence belongs in.

Plugins: specialists

[PR #471](https://github.com/DaveKJohn/claude-code-specialists/pull/471)

---

## Tier 1 - Pull Requests

What a colleague working on this project gets out of it - newest at the top, one block per
pull request. At least one entry of this tier or higher is what any release requires.

## Tier 0 - Pull Requests

Repo-internal: docs, config and work nobody outside this repo's own developers notices -
newest at the top, one block per pull request. No release can be cut from this tier alone.
### #470 · The v3.5.0 release documents: the internal note and the edited highlights · Docs · 2026-08-05

The two documents `cut-release.ps1` deliberately does not write, for the release cut earlier today. Both
land here rather than on the release commit because that commit is already tagged, and neither is one of
the two named direct-on-`main` exceptions.

**The internal note (tier 1) is written from scratch, as it must be** -- the generated skeleton supplies
the metadata and the entry titles as bullets, and the one section carrying the tier's whole point, *what
it is worth*, is the one nothing can generate. Written in time, risk and reduced dependence on a
developer: the version number stopped being a matter of taste, three audiences stopped sharing one
document, and a gate we believed was running turned out not to be.

**The highlights (tier 2) went from 300 lines to 60, and that is the edit rather than a side effect of
it.** The generated draft is now the right *selection* -- the four tier-2 entries, chosen by their own
authors instead of guessed from branch prefixes -- but it is still their words, written for a reviewer.
The reader of this document decides whether to update, so the rewrite drops every file name, function
name and assert count, and keeps the four things that reader can act on: the changelog gains tiers and
the bump has to be earned, the shared release script stops assuming it runs in its home repo, two
workflow scripts resume instead of failing, and nothing changes for a repo that has adopted none of it.

**One line was deliberately not written into the internal note**, and its absence is the lesson from
v3.4.0's note holding. That tier warns that it is a *snapshot* and goes stale in hours where it is also
the published release body -- measured once by a line stating the previous release had no public page,
which its own author then published. So the open-points section names what sits with whom, and says
nothing about what has or has not been published as of the hour it was written.

[PR #470](https://github.com/DaveKJohn/claude-code-specialists/pull/470)

---

