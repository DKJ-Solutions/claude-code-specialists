## Development: `fix/new-branch-no-version-suffix-v1` · 20260902-181023

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

### CREATE

- [x] `new-branch.ps1` -- the `-NoVersionSuffix` switch, the parameter comment, the `.PARAMETER` block and an `.EXAMPLE`; the completion gets one `-not $NoVersionSuffix` and an `elseif` that says out loud that the name was taken as given
- [x] `build-shared-scripts.ps1` -- the plugin mirror regenerated
- [x] `DEVELOPMENT-portable.md` -- the switch under **The version suffix**, with why it is explicit rather than inferred
- [x] `skills/new-branch/SKILL.md` -- step 2 points at it, and it gets its own entry in the parameter list
- [x] Derek's lens -- the toolbox line, plus why *he* never types it here

### TEST

- [x] `new-branch.tests.ps1` -- block `(x)`: the bot's branch on origin, resumed rather than forked, the marker file proving it, no `-v1` in either ref namespace, the document on the branch the PR points at, both hard rejects still refusing under the switch, and the default untouched
- [x] `scripts/tests/new-branch.tests.ps1` green -- 183 asserts
- [x] `check-plugin-integrity.ps1` + all suites green

### DEPLOY: `fix/new-branch-no-version-suffix-v1`

`new-branch.ps1` gets **`-NoVersionSuffix`**: take the branch name exactly as given, skipping the `-v1`
completion. For a caller that is not *naming* a branch, because the branch already exists under a name
somebody else chose and the only thing still missing is its development document.

The reported case is a bot's. Dependabot opens its own branch and its own pull request, so steps 1-3 of
the branchflow have already happened, and `new-branch` is otherwise exactly right for the rest: idempotent
on an existing branch, and the one writer of the format the CI gate reads -- which is why a consumer
should not be scaffolding that document by hand. Without the switch it could not be used at all, and it
failed **silently** rather than refusing. The completion runs *before* the branch is looked up, so the
name searched for was never the one on `origin`: the run forked a second branch `<name>-v1`, wrote the
document there and pushed it, leaving the entry on a branch the pull request does not point at, the gate
still red on the real branch, and a stray remote branch to delete by hand.

Nothing about the default changes. The suffix rule stands, the hard rejects still run first on the name as
typed, and a caller that does not pass the switch cannot tell it was added.

**Score:** 3

#### What makes this deploy extra special

It is an **inbound** repair, and the switch is deliberately explicit where the report itself offered a
quieter alternative. *"Take the name verbatim when the branch already exists on `origin`"* needs nothing
typed and is wrong twice over: a name that happens to be taken is not a statement that the caller does not
own it, and this script's own resume path (#1139) is built on exactly that coincidence -- it resumes a
parked `feat/x-v1` from `origin` all day. Inferring would have changed what every one of those runs is
called, in a file that reaches three consumers by plugin update rather than by choice.

The reason was verified rather than transcribed, and it turned out sharper than reported: the failure is
not only that the suffix cannot be turned off, but that the completion sits **ahead of the exists-check**,
so #1139's resume path never gets a chance to fire. That ordering is what the test block asserts against,
and it is why the switch is checked at the completion and nowhere else.

**Score:** 3

#### Pull Request

new-branch takes a branch name verbatim with -NoVersionSuffix

