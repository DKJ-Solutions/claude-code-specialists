## fix/1632-missing-entry-refused

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

- [x] Reproduce #1632: a document cut at the `### PLAN` inside its own guidance passes both
      `check-branch-entry.ps1` document checks (measured: entryText 556 chars of preamble,
      IsFilled True, 0 scaffold findings, 0 phase headings)
- [x] Verify the reported REASON against the code rather than the symptom --
      `Get-DevelopmentEntryText`'s fallback, and why it must stay
- [x] Establish that `open-pr.ps1` shares the hole, so the repair belongs in the lib

### CREATE

- [x] `Test-DevelopmentEntryMissing` in `entry-scaffold-lib.ps1`, beside the splitter it bounds
- [x] `check-branch-entry.ps1`: refuse ahead of the scaffold check and ahead of the shape checks
- [x] `open-pr.ps1`: the same refusal ahead of its own scaffold gate, `-Force` honoured
- [x] Regenerate the plugin mirror (`build-shared-scripts.ps1`)

### TEST

- [x] `entry-scaffold.tests.ps1`: the predicate over ten shapes, five of them false-refusal cases,
      plus both call sites
- [x] `branch-entry-gate.tests.ps1`: the fourth state end to end, cut the way the measured one was
- [x] `check-plugin-integrity.ps1` green, script contract in sync, all suites green

### DEPLOY: fix/1632-missing-entry-refused

A branch document with its `### DEPLOY` section **deleted** carried no entry at all and passed every
gate that exists to catch exactly that -- both of `check-branch-entry.ps1`'s document checks in CI and
both of `open-pr.ps1`'s locally, which then composed the PR title and description out of the guidance
block. The cause is one value standing for two states: `Get-DevelopmentEntryText` hands back the whole
text when it finds no DEPLOY heading, which is the honest answer for a legacy entry file and the guidance
*preamble* for today's document, and a blockquote nobody scaffolded carries no scaffold marker -- so the
scaffold gate passed **by absence**. A new pure predicate, `Test-DevelopmentEntryMissing`, separates the
two beside the splitter it bounds, and both readers now ask it ahead of their scaffold check. It reads
shape rather than text, so it survives translation: no DEPLOY section *and* a plan present -- the
scaffolder's blockquote guidance under the title, or the phases by their seam names -- is a document that
lost its entry, while no DEPLOY section and no plan is the legacy shape whose fallback stands. Reachable
by accident rather than only by hand, which is what earns it a gate: the measured document was produced
by an edit truncating at `### PLAN`, a string that also sits *inside* the guidance blockquote.

**Score:** 3

#### What makes this deploy extra special

Three discriminators were tried and two rejected on evidence rather than taste, and the rejections are
the reusable part. A **level** test cannot work -- today's document title is an H2 and the flat-window
entry heading (August 5-26, 2026) is an H2 too, so `Test-IsChangelogEntryFile` and
`Test-BranchChangelogIsFilled` both read the broken document as an entry file, which is the same
collision that moved the latter to the name test. The **declared branch** looked clean until
`Get-BranchFileDeclaredBranch`'s deliberately un-narrowed `**Branch:**` fallback answered for a pre-split
root entry as well, so refusing on it would have refused a perfectly good entry. What is left errs
toward under-refusal on purpose: a document that lost its guidance *and* its phases is not recognised,
because a missed refusal is the state that already exists while a false one stops a branch that worked
yesterday. Ten shapes are pinned at the lib, five of them false-refusal cases somebody's branch is
carrying right now.

**Score:** N/A

#### Pull Request

Refuse a branch document whose DEPLOY section is gone
