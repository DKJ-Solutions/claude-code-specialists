## fix/machine-local-note-review-findings

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

PR #1577 merged the #1574 fix from its first commit while this session's reviews were still running, so Victor's and Edith's five findings never reached main. Land them here: the multi-path antecedent in the note, the overstated 'entire subject' in the seam comment, and the three prose defects in the folded CHANGELOG entry (which is still Unreleased).

#### Why this is a second branch and not an amendment

The reviews ran while the branch was parked on `origin`, and `cycle-autopark` had already pushed the
first commit. PR #1577 was opened on that commit and the queue merged it at 08:32Z, so `fold-on-merge`
folded the entry and deleted the branch document from the trunk. The review-findings commit then had
nowhere to land: a PR opened from it (#1582) was a delete/modify conflict against `main`, GitHub
registers no check suite for a conflicting PR, and it could never go green. #1582 is closed as
superseded. Nothing here is new work -- it is the five findings, applied to the text that shipped
without them.

### CREATE

- [x] `scripts/release/open-pr.ps1` + its plugin mirror: the note's remedy no longer says "that file's
      gitignored sibling". The line above it lists however many paths a consumer configures, so the
      singular had no antecedent for anyone watching more than one file -- the note ships to every
      consumer, so this was a live defect in advice rather than a phrasing preference (Edith)
- [x] `scripts/repo-config.ps1`: "whose entire subject was that change" overstated PR #1573, whose diff
      is 15 files -- the `enabledPlugins` hunk plus the roster catch-up documenting it (Victor)
- [x] `dkj-policy/CHANGELOG.md`, the folded entry, still under `[Unreleased]` and therefore still
      correctable: it cited #1557 as the issue the gate was built for, where #1559 is and #1557 is the
      PR the sweep was measured on; "misfires advice" used the verb transitively where the other two
      restatements of the same idea in the same change do not; and the tier-2 paragraph switched the
      referent of "it" mid-sentence (Edith)

### TEST

- [x] `machine-local-gate.tests.ps1`: 42/42 green. The two asserts that read the note's wording --
      `Two cases` and `only THIS clone's own` -- both still hold against the corrected sentence, which
      is what they were written to allow: they pin the two-case structure, not one phrasing of it

### DEPLOY: fix/machine-local-note-review-findings

Five review findings on the machine-local note reached `main` after the change they were about. The
gate's reworded note (#1574) merged from a parked commit while the reviews on it were still running, so
the text that shipped still said to keep a swept-in edit in "that file's gitignored sibling" -- singular,
against a note whose first line lists however many paths the repo watches. A consumer with two entries
in `Get-MachineLocalPaths` read advice with no antecedent. That is corrected here, along with a seam
comment that called PR #1573 a branch whose "entire subject" was one hunk of a fifteen-file diff, and
three defects in the folded changelog entry: it credited #1557 with founding the gate where #1559 did,
used "misfires" transitively where the two neighbouring restatements do not, and switched the referent
of "it" mid-paragraph. Nothing about when the gate fires changed, and it still only warns.

**Score:** 2

#### What makes this deploy extra special

The note is printed by a shared script that travels in the plugin mirror, so its wording is what every
consumer reads at `open-pr`. The correction matters most in the repo this text was NOT written in: one
watched path is this repo's answer, and the sentence only breaks where somebody has configured two.

**Score:** 1


#### Pull Request

Land the review findings the queue merged past on the machine-local note

