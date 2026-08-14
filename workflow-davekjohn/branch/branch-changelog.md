## `feat/releases-into-workflow-folder` changelog

### Branch title

The audience releases and their history move into the workflow's own root folder

### Branch ID

20260814-102908

### Branch type

feat

### What does the change on this branch bring to main?

Phase 3 of the workflow folder (Dave, August 14, 2026): this repo now carries the `releases/` half of
the folder it ships — `releases/README.md` (the release history) and `releases/audience/` (the
hand-written notes) moved by `git mv` into `workflow-davekjohn/releases/`, and the two seams follow:
`Get-ReleaseHistoryPath` answers `workflow-davekjohn/releases/README.md`,
`Get-ReleaseNoteRoot` answers `workflow-davekjohn/releases/audience`. The generated
`releases/development/` and `releases/github/` trees stay at the repo root, as decided when the folder
was scoped. The shared defaults do not move — an unstated seam keeps meaning what it meant yesterday —
and phase 2's two derivations (the history row computed relative to the README, the note's link prefix
from its own depth) are what make this repointing safe: for the new layout they produce
`../../releases/development/...` rows and `../../../../` prefixes instead of dead links.

What moved with it: the moved records' links repointed one level deeper (prose untouched, the standing
published-record rule — six dead links in `releases/development/` archives repointed the same way), the
live docs and the two lenses now name the new paths, the lint's link scan covers the whole workflow
folder by deriving it from the branch seam, the history exclusions of checks 11/12/20 recognise the new
address alongside the old, and `find-specialist-mentions` files the moved records as history while
keeping the README live at both addresses. `Get-ReleaseHistoryPath`'s copy record now carries the
folder answer, so `adopt-config` and `adopt-workflow-folder` propose the same location.

One latent phase-1 defect surfaced and is repaired here: the lifecycle checks' branch-dir exclusion
compared the seam's forward slashes against a backslash path and had silently stopped matching since
the branch move — separators are now normalised, the same lesson check 20 already recorded.

### Significance

#### Tier 0

Every release-history edit, hand-written note and its lint coverage moves address; the cut writes rows
and notes to the folder from now on.

**Score:** 3

#### Tier 2

The folder a consumer adopts is now also the folder the source itself runs: the shipped seam copy and
the scaffold propose the same `workflow-davekjohn/releases/` location, and a consumer's first cut
against it writes working rows.

**Score:** 3

### Pull Request

