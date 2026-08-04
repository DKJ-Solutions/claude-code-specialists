### The v3.4.0 internal note: what this release is worth · Docs · 2026-08-04

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
