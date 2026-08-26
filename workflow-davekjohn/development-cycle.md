# Development cycle: `fix/the-guard-covers-every-entry-point-v1` · 20260826-094730

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

## PLAN

**Issue [#897](https://github.com/DaveKJohn/claude-code-specialists/issues/897): the hand-maintained
counts of `Get-SharedScriptPairs` are stale in both scripts READMEs.** Verified on `main` at `88e370b`
by calling the registry rather than by counting files, and the report holds -- but three of its figures
move once #886 lands, and one of its two claims turns out to be understated.

| check | verdict on `main` at `88e370b` |
| --- | --- |
| subject | stands -- `Get-SharedScriptPairs`, both READMEs and every claim quoted are where the report says |
| symptom | stands -- every count named is wrong |
| reasoning | stands, and is the strongest part of the report: a prose tally of a machine-held list is wrong when typed and wrong again after the next entry |
| proposed repair | the report says the repair worth having is probably NOT "fix the numbers again", and this branch takes that seriously: the counts are dropped, not re-typed |
| size | **the report measured the registry AFTER `workflow-default` is gone.** On `main` it holds **43** pairs, not 42, because `check-report-lib` is registered twice on purpose. So a hand-typed 42 is wrong today and a hand-typed 43 is wrong the moment #886 merges |

**Which figures are stable across #886, and which are not.** This decides what may be written down at
all, so it was measured both ways rather than assumed:

| figure | on `main` | after #886 removes `workflow-default` |
| --- | --- | --- |
| pairs | 43 | **42** -- moves |
| unique source files | 40 (39 `.ps1` + 1 HTML template) | 40 -- stable |
| entry points (not `LibOnly`) | 23 | 23 -- stable |

The pair count moves and the source counts do not, because `workflow-default`'s single pair mirrors
`scripts\lib\check-report-lib.ps1`, which is registered to two other plugins as well. A page that states
the pair count therefore cannot be correct on both sides of a merge nobody here controls.

### The finding the report did not have: the exceptions list is one short

`scripts/README.md` says **"Fourteen of the sixteen shared entry points now refuse outright"** and names
the two exceptions -- `sync/check-roster-sync.ps1` and `sync/check-script-contract.ps1` -- with a reason
that is sound: SessionStart hooks invoke those from the plugin by design, so a refusal would fail every
session start here.

The report suspected the real ratio was 23/23 and said plainly that it had not verified each one. Checked
individually: **20 of 23** dot-source the guard, and the third absentee is
`scripts/maintenance/measure-always-on.ps1` -- which is **not** a SessionStart hook, so the stated reason
does not cover it. Its documenting page prints
`${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-always-on.ps1` and then says "in the source repo, run
its own copy instead", which is exactly the shape the guard exists for. It is a gap, not an exception --
almost certainly missed when the script joined the registry on August 25, 2026.

**So the repair is to close the gap rather than to widen the exceptions list**, which is this repo's
standing answer whenever a rule arrives needing one (checks 26 and 27 were both born green for the same
reason).

### Why the counts are dropped rather than regenerated

The report offers a `<!-- shared-scripts:all -->` span on the `[skill-list]` model. That works for a list
of NAMES and not for a tally in prose -- the same limit #873 records about its own heading. And a count
that moves with #886 cannot be pinned to either value. So:

- the pair/source tallies are rewritten **without numbers**, the way the root `CLAUDE.md` resolved its
  own name-count lesson: *throughout* and *elsewhere in this file* need no maintenance;
- the entry-point ratio is replaced by the RULE plus its two named exceptions, which is stable under a
  new script arriving -- and a **test** is what holds it, so the page stops being the only thing that
  knows.

**Out of scope, deliberately: the mirror page.** `plugins/workflows/workflow-davekjohn/scripts/README.md`
and its nine missing rows are #886's, whose branch already edits that file and whose rename moves the
whole directory. The root page is the half #897 explicitly records as untouched there.

## CREATE

- [ ] Add the source-repo guard to `scripts/maintenance/measure-always-on.ps1`, and regenerate its mirror
- [ ] Rewrite the two stale tallies in `scripts/README.md` without numbers, and replace the entry-point ratio with the rule plus its two named exceptions
- [ ] Leave the mirror README alone -- it belongs to #886

## TEST

- [ ] A COVERAGE assert in `scripts/tests/source-repo-guard.tests.ps1`: every non-`LibOnly` entry point in the registry dot-sources the guard, except the two named SessionStart-hook scripts. The suite tests the guard's logic today and nothing tests that it is actually WIRED IN -- which is why this gap was invisible
- [ ] That assert must be RED before the fix and green after, verified in that order rather than asserted
- [ ] `check-plugin-integrity.ps1` green on the real tree
- [ ] The full suite green (`scripts/tests/*.tests.ps1`), the same set CI runs

## DEPLOY: `fix/the-guard-covers-every-entry-point-v1`

**Score:**

### What makes this deploy extra special

**Score:**

### Pull Request

every shared entry point carries the source-repo guard, and scripts/README.md stops counting

