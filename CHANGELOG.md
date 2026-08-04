# Changelog

Where this repo stands: under **Latest Release** the version currently cut, and under **Pull Requests**
everything merged since it — so the top of this file is the published state and the rest is what is
queued behind it. Every release ever cut is listed in
[`releases/HISTORY.md`](releases/HISTORY.md); how the mechanism works (entry files, folding) is described
in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Latest Release

The most recent release — every earlier one is listed in
[releases/HISTORY.md](releases/HISTORY.md), with its date, type and title.

**v3.4.0** — 2026-08-04 — Minor

See [releases/internal/3.x/3.4.0.md](releases/internal/3.x/3.4.0.md) for what this release is worth. The full per-PR record is in [releases/development/3.x/3.4.0.md](releases/development/3.x/3.4.0.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.
### #457 · The v3.4.0 internal note: what this release is worth · Docs · 2026-08-04

**The note itself, and the first live proof that the link-repointing chain works.** `new-internal-note.ps1`
now updates `CHANGELOG.md` as well as writing the skeleton, and this is the first release where that ran
for real. Before: `See [releases/development/3.x/3.4.0.md] ... for the full release notes.` After:
`See [releases/internal/3.x/3.4.0.md] ... for what this release is worth. The full per-PR record is in
[releases/development/3.x/3.4.0.md].`

**It found the block by the shape it was warned about.** `## Latest Release` no longer carries a
`### [vX.Y.Z]` heading — that went in #454, because a section holding exactly one release does not need a
per-version heading. `Set-ReleaseInternalNoteLink` matches the bold `**vX.Y.Z**` line as well, which is
the only reason this worked. Had it known only the old heading, **the failure would have been silent**:
the cut succeeds, the note is written, and the link simply never moves. That was the argument for teaching
it both shapes, and it is now an observed outcome rather than an argument.

**What the note says, written for the reader it names.** Not a list of sixteen changes but four claims:
undocumented tools were costing measurable work (the two-day fold-by-hand instance, plus the gate that
makes it non-repeatable), shipping a release now takes a fraction of the attention (five manual steps to
one command — and this very cut caught two defects before publication *because* the process has an
inspection point), three projects had each written the same repair tool and now share one, and verifying
an inbound report's premise avoided a day of work on a problem that had ceased to exist.

**The open section is deliberately a snapshot**, per the rule that earned itself in #439: this file is the
Release body, so anything phrased as a live claim goes stale in place within hours. It names the
unpublished Release page, the blueprint proposal filed as
[#456](https://github.com/DaveKJohn/claude-code-specialists/issues/456), and the two items consciously not
backfilled — each as "open at this release", not as a statement about now.

[PR #457](https://github.com/DaveKJohn/claude-code-specialists/pull/457)

---

### #455 · The v3.4.0 highlights, written for the consumer instead of assembled from entries · Docs · 2026-08-04

**831 lines to 91**, and the reduction is a side effect rather than the goal. The generated draft is the
changelog entries stacked up — text written for whoever reviews the diff. This is the first highlights
document written from the other end: what a reader of this plugin can now do, get quieter, or switch on.

**The model came from the storefront repo this tier was borrowed from** (`davekokbwj/smartwatchbanden`),
where the good examples open with what a visitor can *do* and put the reason with its evidence right
behind it. Its `v2.11.0`: *"Bezoekers kunnen nu met pijltjes door álle productafbeeldingen bladeren"*,
then **Waarom** with a measured conversion figure. Compare our `v3.3.0`, which opened with *"A PR is now
refused while its changelog entry still carries the scaffolder's own wording"* — accurate, and written
from the system's side.

**Turning the perspective around surfaced the strongest item, which the draft had buried.** #442 appeared
there as a rule about our own gate — a shared script's parameters must be in its skill. From the reader's
side it is this: *you spent two days committing the fold by hand while `-Push` already existed, because
our page did not mention it.* That is somebody's wasted work, and it was sitting underneath a process
statement. It now leads the section, with the command to stop doing it.

**What the reordering cost the draft's own top item.** The draft opened with `#453`, our
README/HISTORY split — a sentence about this repo's internal file layout, as the first thing a consumer
reads. It does not appear in the finished document at all.

**Three headings that answer questions instead of listing changes**: *What you can do now* · *What gets
quieter* · *What you can turn on*, plus *Worth knowing* for the two facts you need once but need not act
on.

**One thing from the model was deliberately not copied: dropping the technical names.** `-Push`,
`Get-ReleaseHistoryMode`, `-Check` are not jargon to this reader — they are the buttons. In a storefront
repo `product-card.liquid` is noise because that reader never touches it; here, removing the script names
would make the document unusable. **The audience differs, so the rule "strip the technical detail"
transfers as "strip what the reader does not touch" instead.**

**Also worth recording: the source is not itself consistent.** That repo's `v2.13.0` is as
implementation-heavy as anything we produce, with liquid snippets and CSS classes in the consumer tier. The
model is its `v2.11.0`, not the folder.

[PR #455](https://github.com/DaveKJohn/claude-code-specialists/pull/455)

---
