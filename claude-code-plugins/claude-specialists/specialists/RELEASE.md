# Release v2.15.1

**Date:** 2026-07-29  
**Type:** Patch

Three silent failures made visible

You are on this release.

## Fixes

### #257 · check-roster-sync calls the seam canonical · Fix · 2026-07-29

`check-roster-sync.ps1` still carried the **pre-seam path hardcoded in two places**, while the shared
source it is supposed to agree with — `Get-LensDirCandidates` / `Get-SeamPaths` in
[`check-report-lib.ps1`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/scripts/lib/check-report-lib.ps1) — had named the seam
`.claude/specialists/lenses/` canonical since [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221).
Reader and writers had drifted apart, and this repo tripped over it the moment it migrated onto the
seam itself in [#255](https://github.com/DaveKJohn/davekjohns-workshop/pull/255).

**1. Its own lenses were reported as living off-path.** `Get-CanonicalLensDir` returned only
`.claude/plugins/<family>/<plugin>/`, so all 19 seam lenses produced one `[INFO]` telling the reader to
move them — back to the layout the repo had just left. A reader who followed that advice would undo the
migration. Replaced by `Get-OnPathLensDirs`, which derives **both** currently-written locations from the
shared source: the seam (candidate 0) and the pre-seam plugin path (candidate 1, still written by
`Get-LensWriteDir` for a consumer that already has a tree there). Neither is a misalignment now, and the
finding keeps meaning exactly what #179 built it for: the marketplace-named family that only the
reader's back-compat list keeps working.

**2. A seam consumer could be declared "never bootstrapped".** The `$anyLensFile` probe behind the
`[BOOTSTRAP]` marker scanned `.claude/plugins` and `.claude/extensions` — not the seam. So for any
consumer bootstrapped since #221 the probe saw no lenses at all, and a single unfilled roster was enough
to swallow every real finding behind advice to run `specialists-init` on a repo whose whole lens tree
was already in place. The seam directory joined the scan.

Worth noting how invisible this was: the false finding was an **`[INFO]`**, which the session hook
suppresses by design — so nothing reported it, and the check's exit code stayed 0. It surfaced only
because someone ran the script deliberately and read the one line the hook filters away. The same shape
as the `[INVENTORY]` case: a rule nobody was ever prompted about.

Both are covered by regression tests in
[`scripts/tests/roster-sync.tests.ps1`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/scripts/tests/roster-sync.tests.ps1) (scenario 9c: the seam is
canonical and a migrated repo reports *completely* clean — asserting "no `[ERROR]`" would have missed
this entirely; 9d: the pre-seam path stays tolerated **silently**, so the fix cannot be "corrected" by
swapping one hardcoded path for another; plus the seam case in 5d for `[BOOTSTRAP]`). Verified the
honest way: all five new assertions fail against the unfixed script and pass against the fixed one.

[PR #257](https://github.com/DaveKJohn/davekjohns-workshop/pull/257)

---

Full workshop notes: [releases/development/2.x/2.15.1.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/2.x/2.15.1.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
