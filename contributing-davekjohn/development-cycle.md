## Development cycle: `fix/blank-phase-override-empties-the-arc-v1` · 20260826-181100

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
### PLAN

#### What #927 asked for, and what the measurement said instead

[#927](https://github.com/DaveKJohn/claude-code-specialists/issues/927) reports that
`check-branch-entry.ps1` refuses every branch **in a consumer that empties the `StepPhases` seam**: with no
phase configured, `Format-DevelopmentCycle` wrote the scaffolded step bare, which puts it in the region the
`#899` preamble check refuses. It asked for one measurement before either of its two candidate directions --
*does any registered consumer empty `StepPhases`?* -- and named retiring the phase-less branch as the
stronger fix if none does.

**The measurement came back the other way round, and it changes the repair.** No consumer *can* empty that
seam: `Get-BranchFileWording` merges an override with `if ($v) { ... }`, and an empty array is falsy, so
emptying a key keeps the default. That is the seam's documented fail-safe, and it holds. The reported
subject therefore does not exist -- but the **symptom does**, by a route the report did not name: a list of
**blanks** is a two-element array and therefore *truthy*, so it passed the fail-safe and was emptied
afterwards, downstream, where every reader of a list here filters blanks out. Measured before the fix:
`@{ StepPhases = @() }` -> `PLAN, CREATE, TEST`; `@{ StepPhases = @('', '') }` -> zero usable phases.

So the defect is not the phase-less branch and not the `#899` check. It is that the two sides of the seam
disagreed about the word *empty*: the merge asked whether anything was **there**, the readers asked whether
anything was **usable**. Neither of the issue's directions repairs that, and both would have left the hole
open one key over -- `Route0` and `Route1` in `Get-EntrySignificanceWording` are lists too.

#### And its test found a second defect, which predates #927 entirely

`FirstStepPhase` was compared straight against each phase name. A value naming no phase in the arc -- a
typo, a rename that moved the arc and not this key -- matched nothing and the scaffolded step was **dropped
without a word**: a well-formed document, every gate green, and a branch that simply arrives with no plan
in it. Reachable today through the seam alone, with no `#927` anywhere near it.

### CREATE

- [x] `Get-BranchFileWording`: a list override that leaves nothing usable behind is ignored, like an empty
      one -- so `empty` means the same thing on both sides of the seam
- [x] the same rule at `Get-EntrySignificanceWording`, where `Route0` and `Route1` are lists, with the
      reasoning written out once at the seam that measured it
- [x] `Format-DevelopmentCycle`: the headingless branch is retired and zero phases falls back to the
      defaults -- a broken setting gets the answer the seam gives one layer up, and a parked branch's
      `-Intent` can no longer be silently dropped
- [x] the step is anchored on **membership** rather than on a name: the default phase where the arc carries
      it, otherwise the arc's own first phase, never a heading the document does not have
- [x] `scripts/sync/build-shared-scripts.ps1` re-run, so the plugin mirror carries all four

### TEST

- [x] `scripts/tests/entry-scaffold.tests.ps1`: a blank-only `StepPhases` override keeps the default arc;
      the generated document has nothing but guidance above its first phase heading -- the shape `#899`
      reads -- and still carries both the step and the `-Intent` note
- [x] the two step-anchor cases: a `FirstStepPhase` naming no surviving phase, and the same key mistyped
      against the untouched default arc
- [x] a genuinely renamed arc still writes its own three headings and none of the English defaults leaks in
      beside them -- the assert a fail-safe is most likely to break on its way past
- [x] full suite green: 506 asserts, up from 500

### DEPLOY: `fix/blank-phase-override-empties-the-arc-v1`

Two seams in `scripts/lib/entry-scaffold-lib.ps1` now agree with their readers about what *empty* means. A
wording override that is a list of blanks used to pass the merge's truthiness test and be emptied
afterwards, downstream, where every reader filters blanks out. For `StepPhases` that left
`Format-DevelopmentCycle` with no phase heading to write the scaffolded step under, so it wrote the step
bare -- into the region `check-branch-entry.ps1`'s `#899` check refuses, which blocked every branch in such
a repo with no way through but deleting the step the scaffolder had just written
([#927](https://github.com/DaveKJohn/claude-code-specialists/issues/927)). The same rule now guards
`Get-EntrySignificanceWording`, whose `Route0` and `Route1` are lists as well.

**#927's own premise did not survive the measurement it asked for, and the fix follows the measurement.**
It reported the state as "a consumer who empties the seam"; emptying a key is exactly what the fail-safe
already ignores, so that consumer does not exist. Neither of the two directions the issue proposed --
tolerating the phase-less shape in `#899`, or retiring the phase-less branch -- addresses the route that
does reach it, and both would have left the identical hole standing one key over.

**The phase-less branch is retired all the same**, for a different reason than the issue gave: zero phases
is a broken setting rather than a configuration, and it now gets the answer the seam gives one layer up --
keep the default. Writing the default arc is visibly wrong in a repo that renamed it, and visible is the
point; writing nothing would silently drop a parked branch's `-Intent`, the one thing in that document
nobody can reconstruct afterwards.

**And the test wrote for it found a second defect that predates all of this**: `FirstStepPhase` was matched
by name, so a typo or a rename that moved the arc and not the key dropped the scaffolded step in silence --
a well-formed document, every gate green, and a branch arriving with no plan in it. The step is anchored on
membership now: the default phase where the arc carries it, otherwise the arc's own first phase, never a
heading the document does not have.

**Score:** 1

#### What makes this deploy extra special

This is plugin payload -- `entry-scaffold-lib.ps1` mirrors into
`plugins/workflows/contributing-davekjohn/`, so both repairs reach every consumer of the workflow at the
next release. **No registered consumer is in either broken state today**, checked across the five manifests
in `connectors/`, which is what keeps this a 2 rather than higher. What it is worth is the failure it takes
off the table for the consumer who translates the arc -- the seam's whole purpose -- and lands one key
slightly wrong: today that is either every branch refused with no diagnosable cause, or a plan silently
missing from the document a gate has just called fine.

**Score:** 2

#### Pull Request

A blank-only StepPhases override empties the arc, and the scaffolded step lands where the gate refuses it
