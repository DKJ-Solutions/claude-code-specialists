## fix/1679-utf8-short-read-class

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

The fork #1679 left open is decided **lib-side**, and on two measurements rather than on taste.

#### Why lib-side, and not per caller

#1679 recorded the lib-side answer as needing "information the shared read deliberately gave up". It
does not. An open with `FileShare.Read` **fails precisely when a writer still holds the file**, which
is the whole question -- so the fact is one open away and it is free. Measured September 9, 2026: a
clean child's capture opens (no false positive), and a grandchild still holding the inherited handle
gives a sharing violation at `ExitCode` 0 with 0 bytes on disk, which is exactly the #1676 picture.

And the per-caller route is not merely more work, it is **wrong at two of the six sites**. An empty
capture is a legitimate answer there:

| site | the legitimate empty | measured |
|---|---|---|
| `ship-pr.ps1:1924` | `git show --name-status --format=` on a commit that changed no files | 0 bytes, exit 0 |
| `verify-resolved-issues.ps1:81` | `gh --json body -q .body` on a PR with an empty body | 0 bytes, exit 0 |

So "empty means the read failed" would have turned a PR with no body into an error, and only a
discriminator can tell the two apart. That settles the fork the issue asked about.

#### The settle wait, and the half of #1252 it does not touch

#1252 chose not to wait longer for the handle, and that reasoning is exact **for a killed tree**: a
truncated tail is the honest answer, because nothing more is coming. On a **clean exit** it is not --
the child exited of its own accord, so its full output exists and a lingering handle is a grandchild
being reaped. So the budget is spent there and is 0 on a timeout. It costs the normal case nothing:
five consecutive `gh issue view --json body` captures settled on the first probe, 2-8 ms.

#### The sixth site needed no code, and that is a finding

#1679 lists `ship-pr.ps1:1924` with the five, and its symptom is real -- an empty capture does read as
"this commit changed no files". But `Test-IsFoldOnlyCommit` **fails closed** on exactly that: the
commit is not exempted and stays counted, which is what a `ShortRead` guard's `continue` would also
produce. The two are behaviourally identical, so a guard there would have been a no-op wearing a
citation. What a short read costs at that call is one spurious stale-CI refusal, never a merge that
should have been refused. The measurement is recorded in a comment beside the call instead.

### CREATE

- [x] Measure whether a `FileShare.Read` probe can distinguish a lingering writer from a settled
      file -- it can, and it costs 2-8 ms on a real `gh` call
- [x] Measure whether any group A site can legitimately return an empty capture -- two can, which is
      what decides the fork
- [x] `Read-NativeCaptureFileText` -> `Read-NativeCaptureFile`, returning `{ Text; WriterHeld }` and
      reading from the handle the probe opened, so there is no window between asking and reading
- [x] The bounded settle wait, spent on a clean exit only (`$script:NativeCaptureSettleMilliseconds`)
- [x] `ShortRead` on the returned object from **both** arms of `Invoke-NativeCapture` -- additive, so
      no existing caller had to change
- [x] The five group A callers read it: `ship-pr.ps1`'s DEPLOY lock, `check-branch-entry.ps1`'s
      advisory twin, `verify-resolved-issues.ps1`, and the rival-PR search in `open-pr.ps1` and
      `new-branch.ps1`
- [x] The sixth site gets the measurement in a comment rather than a no-op guard
- [x] Regenerate the plugin mirrors (`build-shared-scripts.ps1` -- 8 updated across two rounds)
- [x] `remote-ahead-lib.ps1`'s #1676 comment: the old function name is gone, and it records that the
      fact is now available as a field while keeping its own inference, which is provably sound there

### TEST

- [x] `native-capture.tests.ps1` extended: `WriterHeld` on a held handle and on a settled file, the
      budget actually being spent, an **empty and settled** capture staying distinguishable from a
      short one, a missing file rethrown at once rather than waited on, and `ShortRead` present on
      both arms
- [x] The lint gate (`check-plugin-integrity.ps1`) -- 0 errors
- [ ] Code review (Victor #19) and security review (Sebastian #23) on the diff

### DEPLOY: fix/1679-utf8-short-read-class

`Invoke-NativeCapture` now says when a capture was read while a writer still held it, so a caller can
tell "the child said nothing" from "we read before the flush". Both are an empty `Output` at exit `0`,
and until now nothing separated them: five callers in the shipping scripts resolved that toward a
substantive answer -- "no PR", "no issue declared", "the body does not carry the section". The
sharpest was the DEPLOY lock, which refused the merge over a section that had not changed, in a gate
with no `-Force`; the quietest was the resolves verification, which reported itself as a clean pass
having checked nothing. The read itself is unchanged -- `FileShare.ReadWrite` still returns whatever
was flushed (#1252) -- it simply no longer does so in silence, and on a clean exit it now waits
briefly for the handle to release rather than reporting a short read it could have avoided.

**Score:** 3

#### What makes this deploy extra special

These are the scripts a consumer runs through the workflow plugin, so the wrong verdicts were theirs
to meet: a merge refused by a gate that has no way past it, and an already-done check that quietly
stopped warning. Nothing to do on adoption -- the field is additive and every existing caller keeps
working -- but the refusals a consumer does hit now name the read that failed instead of accusing
their document.

**Score:** 3

#### Pull Request

A short capture on exit 0 is reported as a short read instead of as a substantive answer
