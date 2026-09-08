## fix/1627-trunk-and-lsremote-paste

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

#### What was verified before anything was written, and the one thing the report got wrong

[#1627](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1627) reports two printed,
paste-ready commands in `sync-main.ps1` carrying a raw ref name that #1594 never measured. Both stand,
and the report's scope is exact -- a sweep of every printed line in `sync-main.ps1` and `ship-pr.ps1`
carrying a command word plus a ref found these two and nothing else.

One claim in it does not stand, and it changes nothing: the report says #1623 "is closed", and it was
still open when this branch was verified. It landed mid-work, as #1631. That only strengthens the case
rather than weakening it -- #1623's own comment now reads *"The raw `$trunk` stays raw for `git
checkout` and `gh pr create --base`"*, so the tree states the gap in its own words.

**That sentence is why this branch touches a comment as well as two commands.** Repairing the line
without it would leave the file asserting the raw base is deliberate, two lines above the guard that
replaced it.

- [x] Verify both sites against the tree -- confirmed, and the report's line numbers had drifted
- [x] Sweep for a third site in either script -- none; `ship-pr`'s remaining `$trunk` prints are prose (#1623's axis)
- [x] Confirm `git check-ref-format --branch` accepts `sync/live-2026-08-17;touch` (exit 0), so the fixture name is a legal ref
- [x] Re-verify every anchor after #1623, #1626, #1631, #1634, #1640 and #1643 landed on the trunk mid-branch

### CREATE

- [x] `$trunkPaste = Get-PasteableRef -Ref $trunk -Placeholder '<trunk>'`, beside the `$trunkShown` #1623 added -- judged once, at the seam read
- [x] Its **own** placeholder, because one printed command can now carry two: `<branch>` twice leaves the reader unable to pair a note with a half
- [x] `gh pr create` routes `--base` through that token and prints its note beneath the command
- [x] `gh pr list` judges **per predecessor**, since one line is printed per standing branch and each needs its own note
- [x] Correct #1623's comment, which named the printed `gh pr create --base` as a place the raw trunk stays
- [x] Mirror all of it into `plugins/dkj-teams/dkj-team-shopify/scripts/task/sync-main.ps1` -- held byte-identical

### TEST

- [x] `ref-print-lib.tests.ps1`: the pinned needle for the `gh pr create` line updated -- it asserted the **raw** `--base $trunk`, so the old shape was under test
- [x] `--base $trunk` and `--head $($s.Branch)` added to the raw-interpolation scan, which read for `$branch` only and so was blind to both
- [x] Five source-shape asserts: the trunk judged for paste beside its display copy, its note printed, its own placeholder, per-predecessor judging, that note printed
- [x] Proved all four needle asserts flip: True against the fixed file, False against a pre-fix reconstruction held in memory
- [x] `sync-main.tests.ps1`: a behavioural case on a legal-but-unsafe predecessor name -- the command carries `<branch>`, the note carries the real name, and the raw name never follows a command word
- [x] `ref-print-lib.tests.ps1` 316 asserts, `sync-main.tests.ps1` 131 asserts, lint gate 0 errors

### DEPLOY: fix/1627-trunk-and-lsremote-paste

Two printed commands in `sync-main.ps1` no longer hand you a ref name your shell would act on. The
`gh pr create` line routed `--head` through the paste guard and left `--base` raw beside it, so one
command was visibly half-protected -- and the base is no safer for being the trunk: it is
`Get-TrunkBranchName`, a seam answer a consumer wrote, which git has never validated. It now carries
its own `<trunk>` placeholder and its own note, separate from the branch's, because a command printing
two placeholders has to let you tell them apart. The `gh pr list` line the standing-predecessor refusal
hands over is judged per branch, and those names are the most externally-authored refs in the script:
they come off `git ls-remote`, so whoever pushed a branch under the sync prefix chose them, and
`git check-ref-format` accepts `;`, `$(` and a backtick alike. A refused name prints as a placeholder
with the real branch named beneath as prose, where its characters are inert -- so you can still act on
it. #1623's comment, which named this very line as a place the raw trunk stays, is corrected in the
same change.

**Score:** 3

#### What makes this deploy extra special

A consumer running `sync-main` is the reader of both lines. The `gh pr list` one is the sharper of the
two for them: it is printed by a refusal, at the moment they are being told to go look at somebody
else's branch, and that branch was named by whoever pushed it -- which in a Shopify repo can be another
machine or another person. Nothing about the ordinary path changes: a normal branch name is safe by the
allowlist, so both commands print exactly as before and remain copy-and-run.

**Score:** 3

#### Pull Request

sync-main judges the trunk and each predecessor before printing a command
