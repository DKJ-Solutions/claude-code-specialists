## Development: `fix/major-refusal-names-the-seam-v1` · 20260830-154642

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

Inbound [#1151](https://github.com/DaveKJohn/claude-code-specialists/issues/1151): the major refusal in
`Test-ReleaseBumpEarned` names the threshold and the count, and answers *what would satisfy it* with two
routes -- cut the minor instead, or `-SkipTierGate`. The seam that legitimately lowers the threshold,
`Get-ReleaseMajorMinMinors`, is named in neither. Add it as a third route in `$result.Reason`, mirror the
lib to the plugin, and pin it with an assertion.

#### Verified before building, not inferred

The report's symptom, reason, repair, size, subject and repo all hold: the text is built at
`scripts/lib/release-lib.ps1:305` (pre-change) and interpolates `$MinMinorsForMajor` as a bare number, the
function name appears nowhere in that file, and the seam's own blueprint record says *"a repo that cuts
minors rarely sets this lower"* -- so the seam exists for exactly the repo that meets this refusal.

### CREATE

- [x] `Test-ReleaseBumpEarned`'s major refusal names `Get-ReleaseMajorMinMinors` and the file it lives in,
      alongside the two routes already there
- [x] The reasoning above it, so the next reader knows the clause is load-bearing rather than decorative
- [x] Mirrored to the plugin copy with `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] Two assertions in `scripts/tests/release-lib.tests.ps1` on the refusal text -- the function name and
      the path -- placed with the existing count assertion: 472 asserts green
- [x] No doc quotes the refusal verbatim, so nothing drifted (`grep` over `*.md` and `*.ps1`)
- [x] The lint gate and every suite run as `open-pr.ps1`'s own gate; nothing is pre-run beside it

### DEPLOY: `fix/major-refusal-names-the-seam-v1`

The release cut's major refusal now names the seam that lowers its threshold. It always answered two of the
three questions a reader arrives with -- what the threshold is, and how many minors this major line has had
-- and left the third with two routes: *"cut the minor this work earns instead"*, correct where the bump was
simply wrong, and `-SkipTierGate`, the bypass, named in full. `Get-ReleaseMajorMinMinors` was in neither, so
the repo the seam exists to serve met a hard refusal with no configuration-shaped answer on offer and the
bypass as the nearest thing to one -- the worse of the two outcomes, because it overrules a content
judgement that was correct where answering the seam produces a correct release. The refusal now carries a
third clause naming the function and `scripts/repo-config.ps1`, and two assertions pin it.

This repo's own threshold of `10` is measured against its own history -- the 1.x line ran to 1.18 and the
2.x line to 2.16 before each was recapped -- so its maintainers will not meet this refusal wrongly. The
failure it prevents here is one that has not happened yet: a maintainer reading the refusal on a slower line
and reaching for `-SkipTierGate` because it is the only knob the message offers.

**Score:** 1

#### What makes this deploy extra special

A consumer that cuts minors rarely is precisely who this threshold is not measured for, and until now the
refusal it meets pointed only at the bypass. That consumer now reads, in the refusal itself, the one thing
that turns it into a correct release: set `Get-ReleaseMajorMinMinors` in their own `scripts/repo-config.ps1`.
The seam was always discoverable in `CONTRIBUTING-portable.md`, the `cut-release` skill page and the contract
registry -- and a person meeting a refusal reads the refusal. This is the only class of refusal in this
workflow whose remedy is a configuration value rather than an act on the branch, so it is the one that has to
carry the seam's name in the message.

**Score:** 3

#### Pull Request

The major refusal names the seam that lowers its threshold
