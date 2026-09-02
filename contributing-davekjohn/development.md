## Development: `fix/gate-assert-errorrecord-wrap-v1` · 20260902-194808

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

#### The report's reason was checked before the repair, and it holds

`$r6.Out` is a `Write-Error` from a child `powershell`, rendered by that child's host formatter and
captured through `Invoke-NativeCapture` as separate lines. The wrap is therefore made in the child,
before the pipe, at that console's width -- which is why the same message is green here and red on the
reporting machine. Verified: the suite is 33 pass / 0 fail on this machine at the same commit where
the report measured 32/1.

#### One thing the report got too narrow, and it is filed rather than built

#1242 argues against a shared helper because this is "the only assert in the tree that matches a bare
token against an `ErrorRecord` rendering". True as written, but the class is any host-rendered stream:
`prune-merged.tests.ps1:417` matches `HandBack` against a `Write-Warning` carrying two absolute paths.
It has not bitten, so under "no pre-emptive fixes" it is named and left -- #1248.

### CREATE

- [x] `round-tally.tests.ps1:209` -- rejoin the wrapped lines before matching, with the reason in a comment
- [~] Promote the normalisation to `native-capture-lib.ps1` -- dropped: the second instance has not bitten, so it is filed as #1248 instead of built
- [x] Trace the other bare-token asserts in the tree, so the "exactly two" claim in #1248 is measured rather than assumed

### TEST

- [x] `round-tally.tests.ps1` -- 33 pass, 0 fail
- [x] The normalisation proved against the exact wrapped string from the report: old assert `False`, new assert `True`
- [x] And against an indented continuation, which the report's own newline-only proposal would miss: `True`
- [~] A regression test that the assert survives a wrap -- dropped, and it is a real test gap: reproducing it means driving the child's console width, which tests the formatter rather than the counter. The comment at the assert is the durable record instead.

### DEPLOY: `fix/gate-assert-errorrecord-wrap-v1`

The local test gate no longer refuses a branch because of how long the operator's home directory is.
`round-tally.tests.ps1` asserted that the "nothing to count" error names `-ColumnPattern` by matching
the bare token against the child's rendered `ErrorRecord` -- and PowerShell 5.1 hard-wraps that
rendering at the console width, mid-token, at a column that moves with the absolute paths the message
carries. On a long enough home path the token split and the assert went red on a message that visibly
contained it, blocking every PR while CI stayed green, because a runner's path is short. The wrapped
lines are now rejoined before the match, since the property under test is that the message names the
parameter and never that the formatter left the line whole.

**Score:** 3

#### What makes this deploy extra special

N/A -- `scripts/tests/` is repo-owned and ships to no consumer; the suite this touches has no mirror in
any plugin.

**Score:** N/A

#### Pull Request

Rejoin the child formatter's hard wrap before the round-tally assert matches
