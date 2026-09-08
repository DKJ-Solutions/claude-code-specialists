## fix/1676-remote-ahead-tip-short-read

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### The finding, verified before it was repaired

#1676's symptom and mechanism both still stand, read out of the tree rather than taken from the report:
`remote-ahead-lib.ps1` composed `, whose tip is: <sha> <author>: <subject>` behind `if ($tipLine)`, and an
empty `$tipLine` fell through that in silence. The `-Utf8` arm can produce one with exit code 0 --
`Read-NativeCaptureFileText` opens the capture with `FileShare.ReadWrite` on purpose (#1252), so a
grandchild holding the handle past a clean exit yields whatever was flushed.

The report left three things open. Two are settled here and the third is filed:

- **Caller or lib?** The caller, which is what the report recommended. It needs nothing to change
  underneath and does not weaken #1252's trade.
- **Can an empty capture ever be legitimate here?** No, and that is what makes stating the failure honest
  rather than defensive: the `rev-list` above has already returned a count above zero, so `$RemoteRef`
  resolves and has at least one commit, and `--format=%h ...` always yields the hash for one. There is no
  third reading in which git legitimately answers nothing.
- **The other `-Utf8` callers.** Surveyed, and it is a class: filed as
  [#1679](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1679), with five more sites that
  turn an empty capture into a substantive answer -- the sharpest being ship-pr's DEPLOY lock, which would
  refuse a merge naming a section that had not changed. Out of scope here on purpose: the choice between a
  per-caller repair and a lib-side `ShortRead` field is the substance of that issue.

- [x] Verify the symptom, the reason and the proposed repair against the tree, not the report
- [x] Settle where the repair goes -- the caller, per #1676's own recommendation
- [x] Survey the other `-Utf8` callers and file what the survey found (#1679)

### CREATE

- [x] `remote-ahead-lib.ps1`: name the three reasons a tip could not be read, and say so in the sentence
      instead of dropping the clause
- [x] Record in the function's own docstring that the sentence now has two shapes, so a caller needs no
      knowledge of which one it got
- [x] Mirror the shared lib into `plugins/dkj-policy/` via `build-shared-scripts.ps1`

### TEST

- [x] `remote-ahead-lib.tests.ps1` case 6b: the observed shape (exit 0, nothing read), a whitespace-only
      capture, a non-zero `git log`, and a tip that strips to nothing -- each asserted on the reason it
      names, plus the regression asserted as a shape rather than as wording (never the bare count sentence)
- [x] A premise assert that the same fixture DOES yield a tip with the real capture, so the stub is what
      changes the answer -- and a restore assert that it does not leak into the cases below
- [x] `remote-ahead-lib.tests.ps1`: 57 pass, 0 fail
- [x] `new-branch.tests.ps1`: all 255 asserts pass, the ten #1439 `adversarial tip` asserts among them

### DEPLOY: fix/1676-remote-ahead-tip-short-read

The remote-ahead warning now says when it could not read the diverged branch's tip, instead of dropping
that half of the sentence in silence. `Get-RemoteAheadNote` reads an empty `git log` capture on exit code 0
as a failure to read rather than as nothing to report, names which of three reasons it was, and states
that the author and the subject are missing from the warning and not absent from the branch.

The silent drop degraded the guard to exactly the sentence #1439 was filed for being insufficient: "1
commit(s) behind" reads identically for another session's push and for a fast-forward of your own autopark,
and the author and the subject are what separate them. It degraded on the loaded machine, which is when two
sessions are most likely to be racing.

**Score:** 3

#### What makes this deploy extra special

`remote-ahead-lib.ps1` is a shipping script, so this reaches every consumer through the next release, at
all three doors that ask the question -- `new-branch`'s resume warning, `open-pr`'s remote-ahead gate and
`park-cycle`'s refused-push report. Nothing a consumer types changes; the sentence gains a clause it used
to omit.

**Score:** 3

#### Pull Request

The remote-ahead warning says when it could not read the tip, instead of dropping it in silence

