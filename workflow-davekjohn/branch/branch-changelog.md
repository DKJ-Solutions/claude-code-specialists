## Branch `docs/releases-readme-split` changelog - 20260819-110302

### What does the change on this branch bring to main?

#### Tier 0

`releases/` held **104** generated documents and no page saying what they are. The release README moved
into the workflow folder on August 14, 2026 together with the hand-kept pages, and the two directories
that stayed behind — `development/` (the complete note per version) and `github/` (the GitHub Release
bodies) — were left undescribed. [`releases/README.md`](releases/README.md) now covers exactly those
two and stops there.

**The split follows the layering the rest of the repo already uses.** The root page holds what is true
with no plugin installed: what the artefacts are, that they are generated rather than hand-written,
that each is a published record, and that the oldest notes are Dutch because history is not rewritten.
The `workflow-davekjohn` page keeps what the workflow adds — the dated release list, the seam values,
the local decisions — and gained one paragraph pointing down at the root page instead of absorbing it.

**Nothing is duplicated, and that was measured rather than asserted.** Comparing the two pages on
overlapping eight-word passages: **424** in the root page, of which **11** also appeared in the
workflow page. Nine were the same link path to `RELEASES-portable.md` in sliding windows — one shared
destination, not shared prose. The other two were a real overlap: both pages summarised what the
portable page contains. The root page now names the destination and lets it speak for itself, which
takes the count to **0 shared sentences**.

**The root `README.md`'s own description of `releases/` was wrong in four ways** and is corrected in
the same branch. It claimed the directory contains a `README.md` with *"overview table + the full
cutting-a-release mechanics"*: there was no README there at all, the link labelled `releases/README.md`
actually pointed into the workflow folder, the cutting mechanics moved to `RELEASES-portable.md` on
August 13, and `github/` was never mentioned.

**One thing was checked before writing and is worth recording**: `Get-ReleaseHistoryPath` is set
explicitly to `workflow-davekjohn/releases/README.md`, not left at its shared default of
`releases/README.md`. Had it been defaulting, the next cut would have written a release row into the
new page.

**Score:** 3

#### Higher than tier 0?

N/A — no plugin payload changed. `RELEASES-portable.md` and the `adopt-workflow-folder` scaffolder are
untouched, so a consumer receives nothing from this branch.

**Score:** N/A

### Pull Request

The root releases directory gets its own README, and the workflow page only adds to it
