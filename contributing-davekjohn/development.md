## Development: `fix/fold-stops-the-doubled-plugins-line-v1` · 20260828-112816

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issue #1015: `fold-changelog-entry.ps1:676` appends a `Plugins:` line to every entry it folds,
unconditionally, so an entry that already carries one ends up with two. 22 doubled lines are in the
record, 8 shipped in the v4.21.0 cut. The reporter verified line 676 is the only writer and asked
whoever picked it up to establish HOW a second line enters the entry before adding a guard, so a fix
would not mask something running twice.

Mechanism established: it is not a script running twice. The fold reads the entry from the `## DEPLOY`
section of the branch document; `new-branch.ps1` scaffolds its `#### Pull Request` sub-section with the
one-line title only. For all 8 doubled v4.21.0 entries the branch's own work commit had hand-added a
`Plugins:` line into that section (e.g. `c898d9f3` for PR #1010); the non-doubled plugin-touching
entries (e.g. #1009) had not. The fold then appended its computed line underneath. So the source is a
session mirroring the folded-entry shape into the branch document.

### CREATE

- [x] Move `Remove-EntryPluginsLine` from `scripts/lib/release-lib.ps1` down into
      `scripts/lib/entry-scaffold-lib.ps1` (the lib the fold dot-sources), leaving a MOVED breadcrumb
      -- same precedent as `Get-ReleaseChangeTypes` and `Set-EntryHeadingLevel`. Regenerated the
      plugin mirrors with `scripts/sync/build-shared-scripts.ps1`.
- [x] `fold-changelog-entry.ps1`: before the footer, strip any `Plugins:` line already in the entry
      (via `Remove-EntryPluginsLine`) and `Write-Host` a `DarkYellow` note naming the file and where
      the stray line came from. Runs for every entry, PR or no PR.
- [x] `Get-EntryScaffoldFindings` (`entry-scaffold-lib.ps1`): a `Plugins:` line in the entry text
      (outside fences) is a finding -- `"a 'Plugins:' line -- the fold writes this at the merge,
      delete it"`. Consumed by both `check-branch-entry.ps1` (CI) and `open-pr.ps1` (local).
- [x] De-duplicated the 22 shipped doublings in `contributing-davekjohn/releases/changelog/**`
      (1.11.0, 3.0.4/5/6, 3.1.0, 3.6.0, 4.20.0, 4.21.0). 21 were exact repeats; `3.6.0.md` (PR #483)
      had two lines that DISAGREED -- kept the fold-written (second) one, which is what
      `Get-EntryPlugins` should have been reading.

### TEST

- [x] `scripts/tests/fold-changelog.tests.ps1` -- new case: an entry carrying a stray `Plugins:` line
      folds with no `Plugins:` line in the changelog and the removal note on the fold's output.
      153 pass, 0 fail (was 148).
- [x] `scripts/tests/entry-scaffold.tests.ps1` -- the new finding fires on a `Plugins:` line, not on
      the same line fenced, and not on an entry without one. 609 pass (was 604).
- [x] `scripts/tests/release-lib.tests.ps1` -- `Remove-EntryPluginsLine` still resolves (through the
      `entry-scaffold-lib` dot-source) and collapses both a repeated-identical and a disagreeing pair.
      433 pass (was 430). Its history comment updated for the move + the new caller.
- [x] `scripts/sync/build-shared-scripts.ps1 -Check` -- mirrors in sync.
- [x] Issue #1015's `awk` detector over `contributing-davekjohn/releases/**` + `CHANGELOG.md` -- 0 hits.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- clean, and it runs every suite as CI does.

### DEPLOY: `fix/fold-stops-the-doubled-plugins-line-v1`

`fold-changelog-entry.ps1` wrote the `Plugins:` line -- derived from the PR's touched files --
unconditionally, so an entry that already carried one folded with two, one blank line apart. 22 such
doubled lines are in the record; 8 shipped in the v4.21.0 cut. `Get-EntryPlugins` reads this line and
the release notes are published output, so it is cosmetic per occurrence and permanent.

The mechanism, established before the guard was added (issue #1015 asked for exactly that): not a
script running twice, but a session hand-writing a `Plugins:` line into the `#### Pull Request`
section of its branch document -- mirroring what a folded entry looks like. `new-branch.ps1` scaffolds
that section with the title alone; all 8 doubled v4.21.0 entries had the line added in the branch's
own work commit (`c898d9f3` for PR #1010), the non-doubled plugin-touching entries did not.

Three parts. **The fold now strips any `Plugins:` line already in the entry before it appends its
own**, for every entry, and names what it dropped rather than doing it silently -- so a branch opened
before the gate below still folds clean, loudly. `Remove-EntryPluginsLine` moved from `release-lib.ps1`
into `entry-scaffold-lib.ps1` so the fold can reach it, the same move `Get-ReleaseChangeTypes` and
`Set-EntryHeadingLevel` made and for the same reason. **`Get-EntryScaffoldFindings` refuses a
`Plugins:` line in the entry**, so `open-pr` and CI tell the author on the branch, before the merge.
**The 22 shipped doublings are de-duplicated** -- 21 exact repeats collapsed; `3.6.0.md` (PR #483)
carried two lines that disagreed and the fold-written one was kept.

**Score:** 3

#### What makes this deploy extra special

A consumer receives `fold-changelog-entry.ps1` and `entry-scaffold-lib.ps1` through the workflow
plugin. One who had been hit by the same doubling -- an author on their side copying the folded shape
into a branch document -- stops shipping doubled `Plugins:` lines into their own changelog, and their
branch-entry gate gains a check that names the stray line before the merge. No action is required of
anyone; the fold repairs a stray line on its own and says so.

**Score:** 2

#### Pull Request

The fold stops emitting a doubled Plugins line, and the branch document stops carrying one
