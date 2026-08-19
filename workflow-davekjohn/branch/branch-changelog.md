## Branch `docs/release-history-to-root` changelog - 20260819-112521

### What does the change on this branch bring to main?

#### Tier 0

The previous branch gave `releases/` a page about its **artefacts** and left the **release list** —
which versions exist, when each was cut, what each was worth — in the workflow folder. Delete that
folder and the repo loses its own history. It is back at the root, in
[`releases/README.md`](releases/README.md), and `Get-ReleaseHistoryPath` is back at the shared default
it had until August 14.

**The test that decided it, and it cuts both ways** (Dave, August 19, 2026): does the thing survive
the workflow folder being deleted? A repo that has cut releases has a **history** whichever tooling
cut it, so an index of files that live in `releases/` had no business sitting in a folder a teardown
removes. A per-reader **note** is the opposite — `audience/` exists only *because* the tier model
does — so it stayed. Both moved into the folder together on August 14; only the list moved back. That
asymmetry is now written on both pages, in the seam comment, and in the shipped skill, because it is
the part a later reader would otherwise "tidy up".

**What moved:** 135 lines — the list intro and the four major tables — with every link rewritten for
its new depth. The `davekjohns-workshop` rename note moved with it, because it describes the notes
under `development/`. **93 link targets** were re-checked: those to `development/` shortened, those to
the hand-written notes lengthened to `../workflow-davekjohn/releases/audience/`, which the extraction
missed on the first pass and the sweep caught.

**Three mechanical consequences, all found by the gates rather than by reading.** The suites went red
in five places on one config change: `workflow-davekjohn/CONTRIBUTING.md` linked the moved anchor, the
shipped config blueprint went stale, `config-blueprint.tests.ps1` asserted the old adopted answer, and
`cut-release-drive.tests.ps1` wrote its fixture history where the seam no longer pointed. **The live
assert that pins which major the overview targets needed no edit at all** — it reads the path from
`Get-ReleaseHistoryPath` instead of hardcoding it, a choice whose own comment records paying off twice
in opposite directions on August 4. This is the third time, and the first in a third direction.

**The payload was corrected rather than left to drift.** `adopt-workflow-folder` used to tell a
consumer to repoint `Get-ReleaseHistoryPath` into the workflow folder; it now tells them to leave it
alone and says why, in the script's own output and in its skill page. The mirroring instruction on
this repo's workflow page follows, including what a consumer should do with a list they already have
there: move it, not delete it.

**One line was deliberately not corrected.** `CHANGELOG.md`'s folded entry for
[#753](https://github.com/DaveKJohn/claude-code-specialists/pull/753) still records the seam as
pointing at the workflow folder. That was **true when it was written** yesterday, so it is the half of
the record rule that is protected — going stale is the record working.

**Score:** 3

#### Higher than tier 0?

The shipped `adopt-workflow-folder` script, its skill page and the config blueprint all changed, so a
consumer adopting after this release gets the corrected advice: leave `Get-ReleaseHistoryPath` at its
default. A consumer who already repointed it keeps a working repo — nothing errors — but their history
sits in the folder their own teardown would remove.

**Score:** 3

### Pull Request

The release history moves to the root, where it survives the plugin
