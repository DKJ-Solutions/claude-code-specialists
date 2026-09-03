## Development: `fix/legacy-name-test-hardcodes-v1-suffix` · 20260903-121727

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

`main` is red. `new-branch.tests.ps1` fails at the `#1259` legacy-name block, which builds the
document name it expects from a `-v1` suffix `new-branch` stopped appending in #1268.

#### Why a green PR left a red trunk

Both changes are individually correct and neither branch could see the other. The legacy-name block
arrived on `main` in `7b783516` (#1259); PR #1268 was cut **before** that commit, so its own CI run --
green, `lint-en-tests` at 15m30s -- never executed this block at all. The merge commit is the first
artefact that contains both, and nothing tested it: the required check runs on the branch head, and
the branch was not required to be up to date with `main` first.

That is the general shape, not a one-off: any PR cut before a test block that constrains what the PR
changes will pass its own gate and break the trunk on merge. Filed separately -- this branch repairs
the instance, not the mechanism.

### CREATE

- [x] drop the `$vBranch` alias in the legacy-name block and use `$case.Branch`, the name as given
- [x] record at the site why the alias existed and why it is gone rather than corrected

### TEST

- [x] `new-branch.tests.ps1` alone: 187 asserts, all pass
- [x] full local gate: `check-plugin-integrity.ps1` + every suite

### DEPLOY: `fix/legacy-name-test-hardcodes-v1-suffix`

`new-branch.tests.ps1` no longer builds the expected document name from a `-v1` suffix that
`new-branch.ps1` stopped appending. The `#1259` legacy-name block held a `$vBranch =
"$($case.Branch)-v1"` alias, and #1268 removed the completion that made it true -- so the block looked
for `development-feat-on-pre963-v1.md`, a file nothing writes, and threw a `FileNotFoundException`
before its first assert. The alias is deleted rather than corrected: named after a version suffix, it
could only mislead the next reader, and `$case.Branch` says exactly what it is.

**This was a green PR that landed a red trunk**, which is worth stating plainly because no gate
reported it. #1268's branch was cut before `7b783516` (#1259) added this block, so its required check
passed on a tree that did not contain the test its own change breaks. The merge commit is the first
thing that holds both, and the merge is not gated -- the check runs on the branch head, and a branch
is not required to be current with `main` before it merges. Every suite is green again on the merge
result; 187 asserts in this suite, 61 suites in the gate.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches a consumer. The repaired file is a test suite that ships nowhere: `new-branch.ps1`
itself is unchanged, so a repo on the workflow plugin sees no difference. What it buys is that the
trunk is green again, which every open branch needs before its own gate can pass.

**Score:** N/A

#### Pull Request

the legacy-name test stops hardcoding the -v1 suffix new-branch no longer appends
