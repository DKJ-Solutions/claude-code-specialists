## Development cycle: `fix/test-capture-flattens-the-console-wrap-v1` · 20260827-184133

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

Both suites captured child output with Out-String and matched phrases against it, so a hard wrap at the console column broke the regex. Give both the canonical Get-FlatOutput helper prune-merged.tests.ps1 already documents and match phrase asserts against the joined string.

### CREATE

- [x] `scripts/tests/seam-lib.tests.ps1`: added the canonical `Get-FlatOutput`, kept the capture as
      records, and exposed both readings -- `Out` keeps the line structure, `Flat` is the joined one.
      The five phrase asserts now read `Flat`; the `Code` asserts are untouched.
- [x] `scripts/tests/internal-note.tests.ps1`: the same pair, and all twelve phrase asserts moved to
      `Flat` -- including the two `-notmatch` ones, where a wrap makes the assert pass for the wrong
      reason rather than fail.
- [x] `scripts/tests/prune-merged.tests.ps1`: corrected the at-risk list its docstring maintains by
      hand. It named four suites; the tree has five carrying an older copy, and one of the four it
      named carries none at all. The three older variants are now separated, because they are not
      equally exposed.
- [~] Promoting `Get-FlatOutput` to a shared test lib -- dropped, and filed instead. Seven copies in
      four variants is a real duplication finding, but it is Ravi's subject and a change to every
      suite in the folder; doing it inside a two-suite repair would scope the work to the grep.

### TEST

Measured on this machine by re-running the two suites at four console widths in a child host, because
the width is the variable that drives the defect and a single run proves nothing:

| console width | `seam-lib` | `internal-note` |
|---|---|---|
| 120 | OK: 37 | OK: 95 |
| 130 | OK: 37 | OK: 95 |
| 140 | OK: 37 | OK: 95 |
| 300 | OK: 37 | OK: 95 |

Before the change, on the same machine: `seam-lib` red at 120 and 130 and green from 140 up, and
`internal-note` red at 300 and green at 120. Those two facts together are why option 2 in #959 --
matching a shorter fragment -- was not taken: the two instances fail on opposite sides of the width,
so there is no margin to stay ahead of.

- [x] Both suites green at every width measured above.
- [x] `prune-merged.tests.ps1` still green -- it carries the copy the other two were given.
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite, the run `open-pr.ps1` performs.

### DEPLOY: `fix/test-capture-flattens-the-console-wrap-v1`

Two test suites stop failing on the width of the console they happen to run in.
`scripts/tests/seam-lib.tests.ps1` and `scripts/tests/internal-note.tests.ps1` captured their child
process with `Out-String` and matched phrases against the result, so a hard wrap at the console column
split the phrase mid-word and the regex missed -- red on a developer machine, green in CI, for a script
that was correct in both places. Both now carry the canonical `Get-FlatOutput` helper
`prune-merged.tests.ps1` already documents: the capture is kept as records and joined with nothing
between them, so the two halves reconstruct exactly. Each suite keeps both readings -- `Out` where the
line structure matters, `Flat` for the phrase asserts -- because the join deliberately glues genuinely
separate lines together and is wrong as a general-purpose capture.

The repair proposed in #959 was measured before it was applied and does not work: joining with a space
re-breaks the very word the wrap broke, so `'the da' + ' ' + 'te by hand'` matches nothing. The join
has to be `''`, and the `\s*` in that proposal has to go with it, or it eats the continuation's
genuine leading space.

Third change, and the one that outlasts these two suites: the at-risk list `prune-merged.tests.ps1`
maintains in its own docstring was wrong in both directions -- it named `shared-scripts`, which
carries no copy of the helper at all but a stronger redirect-file mechanism, and it omitted
`park-cycle` and `worktree-lane`, which do carry one. It now separates the three older variants by how
exposed each actually is, and names the one that joins with a space as the variant measured to fail
outright. All five stay unrepaired on purpose: they are green, and a risk that has not bitten is
written down here rather than built against.

Why it matters beyond three files: `open-pr.ps1` refuses to push while any suite fails, so this
blocked every branch on the machine it fired on until somebody reached for `-SkipTests` -- the gate
being switched off rather than heeded, which is the failure the class was written down to prevent. It
had already cost at least three branches a `-SkipTests` run, each for work that had nothing to do
with it.

Closes [#982](https://github.com/DaveKJohn/claude-code-specialists/issues/982) and
[#959](https://github.com/DaveKJohn/claude-code-specialists/issues/959).

**Score:** 4

#### What makes this deploy extra special

N/A. Nothing here ships: `scripts/tests/` is not plugin payload, and no consumer receives these three
files or the helper in them.

**Score:** N/A

#### Pull Request

Phrase asserts survive the console wrap in seam-lib and internal-note

