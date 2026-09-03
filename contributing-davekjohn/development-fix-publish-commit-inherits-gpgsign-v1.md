## Development: `fix/publish-commit-inherits-gpgsign-v1` · 20260903-133738

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

Pin commit.gpgsign=false beside the identity already pinned in publish-to-business.ps1's own commit; add a regression test that forces ambient signing on via GIT_CONFIG_GLOBAL. Reasoning verified: the target repo has no rulesets and all published commits are already unsigned (#1297).

### CREATE

- [x] Pin `commit.gpgsign=false` in `publish-to-business.ps1`'s own commit, beside the synthetic
      identity already pinned there.
- [x] Record why the pin is coherent here and would be WRONG in the four sibling commit paths, on
      the line itself -- that is the part a later reader would get backwards.

#### The sweep the report did not do

`#1287` repaired one half of this class and missed the other, so the size was worth measuring rather
than assuming. Five production commit paths exist; only this one gets the pin:

| path | author | pinned? |
|---|---|---|
| `scripts/release/publish-to-business.ps1` | synthetic (`marketplace-publisher`) | **yes, this branch** |
| `scripts/lib/park-lib.ps1` | the operator's own | no, deliberately |
| `scripts/release/cut-release.ps1` | the operator's own | no, deliberately |
| `scripts/release/fold-changelog-entry.ps1` | the operator's own | no, deliberately |
| `scripts/task/sync-main.ps1` | the operator's own | no, deliberately |

The four are the operator committing to the operator's own repo. There a locked signing agent
*should* fail the commit rather than quietly land it unsigned, so pinning would suppress a
deliberate setting. The synthetic author is what makes this one different.

### TEST

- [x] Reproduce first, before repairing: with `commit.gpgsign=true` and the signer unreachable, a
      commit carrying only the identity pins fails with `fatal: failed to write commit object`, and
      the same commit with `-c commit.gpgsign=false` lands as `%G? = N`.
- [x] Answer the one question the report left open by measurement rather than by opinion: the target
      repo carries no rulesets and its five most recent commits are all `verified=false / unsigned`.
- [x] Add assert 17 to `publish-to-business.tests.ps1`, forcing ambient signing on via
      `GIT_CONFIG_GLOBAL` -- with a guard-on-the-guard asserting an *unpinned* commit still fails
      under that config, so a green result cannot be the forced config silently not applying.
- [x] Prove the test fails without the fix: pin removed, exactly the two new asserts go red and the
      other 62 stay green. With the pin, 64/64.

### DEPLOY: `fix/publish-commit-inherits-gpgsign-v1`

The commit `publish-to-business.ps1` makes in its temp clone now pins `commit.gpgsign=false`, beside
the synthetic identity it already pinned. It used to inherit the machine's global signing config, so
with signing on and the signing agent locked git could not write the commit object: the publish
exited non-zero and five asserts went red naming the **subset filter**, which blocked a push on a
branch touching neither this script nor its suite. It presents as a flake and is not one -- CI
configures no signing at all, so it was green there and red only where somebody would act on it.

Off rather than on, because the author is deliberately synthetic: a signature by the operator's own
key could never verify against `marketplace-publisher <publisher@localhost>`. Measured rather than
assumed -- the target repo carries no rulesets and every commit it already holds is unsigned.

The residual of #1287, which pinned the commits the *fixture* makes and not the one the script makes
itself. The four sibling commit paths keep inheriting the setting on purpose: they commit under the
operator's own identity, where a locked agent *should* fail rather than quietly land it unsigned.

**Score:** 2

Small, and the trigger is a machine state the source repo does not currently hold -- but it is a
failure that has already happened rather than one being guarded against in advance, and the cost was
disproportionate to the fix: an unrelated branch could not be pushed, and the red asserts pointed at
the wrong subject entirely.

#### What makes this deploy extra special

N/A. `scripts/` does not travel to the published marketplace and this script has no plugin mirror, so
no consumer runs it or can observe the change.

**Score:** N/A

#### Pull Request

The publish commit no longer inherits the machine's signing config

