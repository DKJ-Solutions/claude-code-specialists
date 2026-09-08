## fix/1585-unfolded-entry-stale-checkout

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

#### What #1585 reported, and what was verified before building

`check-unfolded-entry.ps1` reads the working copy only, so a checkout that is merely behind
`origin/main` reports a fold that has already landed as one that never ran -- and points at
`fold-changelog-entry.ps1`, which refuses on a stale checkout anyway. Verified against the tree before
starting: the script makes no git call at all, and neither it nor `Get-UnfoldedTrunkEntry` has any
notion of a remote-tracking ref. The symptom stands as filed.

The issue offered two shapes. The one taken is a hybrid of both, and narrower than either: the gap is
measured with the existing shared `Get-TrunkGap -NoFetch`, and only when it is non-zero is each leftover
asked whether it still exists on `origin/<trunk>`. Asking the presence question alone would misread an
UNCOMMITTED document as an already-folded one; measuring the gap alone would not know which of several
leftovers the pull actually clears.

### CREATE

- [x] `scripts/lint/check-unfolded-entry.ps1`: measure the trunk gap (`Get-TrunkGap -NoFetch`) and, only
      at a non-zero gap, split the leftovers into already-folded-on-origin and genuinely stranded
- [x] The all-folded case reports `[WARN]` and exits 0 with `git pull --ff-only` as the remedy; the
      stranded case keeps its `[ERROR]`, its exit 1 and its exact headline, and now also names the gap
      because the fold it prints would refuse on it
- [x] `native-capture-lib.ps1` dot-sourced guarded, so a plugin cache predating this degrades to the
      pre-#1585 report instead of throwing at a session start
- [x] `unfolded-entry-sessioncheck.ps1`: a `[WARN]` branch with its own headline -- the error sentence
      "its fold never ran" is the mis-statement #1585 reported, so it must not carry this case
- [x] `.claude/specialists/lenses/05-15-extension.md`: the distinction recorded on the bullet that owns
      the check
- [x] `scripts/sync/build-shared-scripts.ps1` run, so the plugin mirror matches

### TEST

- [x] `scripts/tests/unfolded-entry-gate.tests.ps1`: seven new asserts on real git fixtures -- no origin
      at all, an origin in sync, the fold landed upstream, a mixed tree, and the hook's `[WARN]` headline
- [x] All 20 asserts pass; the 13 pre-existing ones are untouched
- [x] The two CI consumers checked by reading rather than by running: `fold-on-merge.yml` matches on
      `[ERROR] the trunk carries`, which the stranded case still prints verbatim, and both workflows run
      at a gap of 0, where the new arm is unreachable

### DEPLOY: fix/1585-unfolded-entry-stale-checkout

The skipped-fold check no longer reports a landed fold as a missing one. A checkout that is merely
behind `origin/<trunk>` now gets a `[WARN]` naming the gap and `git pull --ff-only`, instead of an
`[ERROR]` pointing at a fold that would refuse on that same stale trunk; where a fold really is owed the
report is unchanged, and now also says to pull first. The extra question costs no network and is asked
only at a non-zero gap, so CI and an offline session both behave exactly as before.

**Score:** 3

#### What makes this deploy extra special

A consumer's session start stops raising a red `[ERROR]` for the ordinary state of being a few commits
behind, and the one line it prints instead is the command that fixes it. That noise was
indistinguishable from the real skipped-fold state the check exists to catch, which is what made it
worth repairing rather than tolerating.

**Score:** 3

#### Pull Request

Tell a stale checkout apart from a skipped fold in check-unfolded-entry

