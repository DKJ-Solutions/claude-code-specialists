## Development: `fix/step-list-remedy-names-the-act-v1` · 20260829-150111

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

Inbound #1081: both findings print one shared remedy, and it is only true for 'still open'.

`Get-BranchProgressFindings` returns two labels -- `still open` and `still the scaffolded step` -- and
both printers appended the same four lines of advice under either. Verified in the tree before
repairing: the labels are separate in the data, only the printed advice was shared, and there are two
printers (open-pr's push gate and ship-pr's merge gate) rather than one.

### CREATE

- [x] `entry-scaffold-lib.ps1`: each finding carries the act that resolves it, in `Remedy`, composed
      once from the wording seam's own marks.
- [x] `open-pr.ps1`: print the remedy under each finding, and drop the shared mark list that was only
      true for one of the two.
- [x] `ship-pr.ps1`: the same, for the merge-time copy of the gate.
- [x] The `open-pr` skill page: say that no mark resolves a scaffolded step, and that "there is no
      `-Force`" is not the answer to it.
- [x] Mirror the changed scripts into the plugin (`build-shared-scripts.ps1`).

### TEST

- [x] Asserts on both remedies, including that they are not the same sentence, and on both printers
      emitting them.
- [x] The full local gate green: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: `fix/step-list-remedy-names-the-act-v1`

The step-list gate refuses on two different findings and printed one remedy for both. That remedy --
resolve each step, `- [x]` done or `- [~]` dropped -- is the whole answer for a step that is `- [ ]`,
and no answer at all for a line still carrying the scaffolder's placeholder: a placeholder is resolved
by replacing its text, and a mark cannot do it. So an author who met the second finding, followed the
advice exactly, and re-ran, was refused again by the same gate printing the same four lines. The advice
was a loop.

Each finding now carries the act that clears it, on its own line under it:

```text
  - still the scaffolded step: - [~] <the line new-branch scaffolded, marked but never rewritten>
      Not resolved by a mark: this line still says what the scaffolder wrote. Replace its text with
      the step you actually took, or delete the line if the plan grew past it.
```

The sentence is composed in `Get-BranchProgressFindings`, beside the label it belongs to, because two
scripts print these findings -- `open-pr` before the push and `ship-pr` before the merge -- and a remedy
written twice is a remedy that drifts. It reads the marks from the wording seam, so a repo that
translated them gets its own characters back. The shared paragraph keeps what is true for every
finding and stops offering a mark to the one no mark can resolve.

Nothing about the gate itself changed: the rule is right, the reasoning behind refusing a ticked
placeholder is right, and there is still no `-Force`. What changed is that the refusal now names the
tool for the job instead of repeating the one that just failed.

Closes [#1081](https://github.com/DaveKJohn/claude-code-specialists/issues/1081).

**Score:** 2

#### What makes this deploy extra special

It lands on the reader with the least context there is: someone walking this cycle for the first time
on a fresh repo, at the moment `open-pr` first refuses them for real. They have no prior for which
parts of the tooling to trust, and the one sentence the old message was emphatic about -- "there is no
`-Force` for this gate" -- read as *you are stuck* rather than *you have used the wrong tool for this
finding*. The fix is one line of output; what it buys is that the gate stops looking broken on the day
somebody meets it.

**Score:** 3

#### Pull Request

the step-list gate's remedy names the act each finding actually needs
