## docs/1486-dkj-policy-scripts-readme-rows

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

- [x] Added the 21 missing rows (the four `lint/*` gates, five more `task/*` entry points, two more
      `maintenance/*` scripts, and ten `lib/*` files) to `plugins/dkj-policy/scripts/README.md`'s table,
      and rewrote the caveat paragraph above it to record this as the third re-measurement instead of
      leaving the second one's numbers standing. Re-ran the issue's own `Get-SharedScriptPairs` query
      afterwards: 0 rows remain missing for `dkj-policy`.

### TEST

- [x] `check-plugin-integrity.ps1` and the full test suite (`open-pr.ps1`'s own gates).

### DEPLOY: docs/1486-dkj-policy-scripts-readme-rows

`plugins/dkj-policy/scripts/README.md`'s table now lists all 21 scripts and libs the registry already
held for `dkj-policy` that its own page never named -- `task/claim-issue.ps1` through
`lib/claim-issue-lib.ps1` -- closing the gap the page's own "the missing rows are tracked separately"
sentence claimed was tracked when nothing was (#1486). The caveat paragraph above the table now records
this as a third re-measurement (August 15, August 26, September 6) instead of leaving the second one's
numbers standing as if still current.

**Score:** 2

#### What makes this deploy extra special

A consumer reading this page to see what the plugin mirror carries now finds the ten `lib/*` files and
the four `lint/*` gates described alongside the scripts that already had rows -- nothing new to run,
just nothing missing any more.

**Score:** 2

#### Pull Request

Fill in the 21 rows plugins/dkj-policy/scripts/README.md's table was missing

