## fix/1731-gate-tolerant-capture-read

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
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

#### The inconsistency (#1731), and what verifying it changed

`scripts/lib/native-capture-lib.ps1` builds `Read-NativeCaptureFile` for one hazard -- a writer
still holding a capture file when it is read -- and `Invoke-TestSuiteGate`, in the same file, read
each suite's `out.txt`/`err.txt` with a plain `Get-Content -Raw -Encoding Oem`. #1723 added a second
such site in the crash re-run block, correctly copying the surrounding pattern rather than diverging
on a branch about something else.

The report filed the inconsistency and was explicit that the failure had never been observed, so the
reason was verified before anything was repaired -- the repo's own rule, and it sharpened the case
rather than dissolving it:

- **`Get-Content -Raw` does not throw on a held file.** Measured September 9, 2026: it opens it
  happily and returns the flushed prefix. So where `ReadAllText` gives a diagnosable IO error, this
  gave a short suite block under a correct `== suite ==` header with the exit code intact -- this
  file's own recurring shape, a wrong answer arriving as a plausible value.
- **The settle cost the report asked to measure first is negligible.** 170 reads -- 85 suites' worth
  of both captures, none of them held -- cost 147 ms through the tolerant reader against 67 ms
  through `Get-Content`: 0.86 ms against 0.39 ms per file, ~80 ms on a run costing ~140 s. The
  budget is not touched at all when nothing holds the file; it is spent only where the alternative
  was a short block nobody could see was short. The decode is byte-identical.

#### And the report's own judgement call is taken, not skipped

It said `WriterHeld` would want to be a visible note rather than a silent flag, because these blocks
are read by a person. That is what shipped: the console gets a `[short read]` line naming the file.
A returned field nobody prints would have been the same silence in a new place.

### CREATE

- [x] `Write-GateCaptureBlock` added beside the other `*-Gate*` helpers -- one place for the read,
      the encoding, the settle budget and the note, so the two sites cannot drift apart again.
- [x] Both gate sites go through it: the pool's reap and #1723's crash re-run.
- [x] The note survives an empty read. The whitespace skip that keeps a stderr-less suite from
      printing a blank block used to run first, which would have dropped the note in the one case it
      matters most -- an empty held file is exactly "the child said nothing" against "we read before
      the flush".
- [x] `Read-NativeCaptureFile`'s docstring no longer says the `-Utf8` arm is its only caller. That
      sentence described the callers of the day; read as an argument, it is how the gate kept a plain
      `Get-Content` for the very hazard the function was built for.
- [x] The two plugin mirrors re-synced through `build-shared-scripts.ps1`.

### TEST

- [x] 12 asserts added to `native-capture.tests.ps1`, on a `FileStream` fixture this suite owns --
      a grandchild race cannot be scheduled, a held handle can.
- [x] The first of them pins the invisibility itself: `Get-Content` reads a held file without
      complaint. Without it a later reader has only the claim.
- [x] The note is asserted on the console text (`6>&1`), not on a flag -- the deliverable is what a
      person sees.
- [x] It discriminates: a settled file prints no note, an empty settled file prints nothing at all,
      so 85 stderr-less suites still add no blank lines.
- [x] The decode equivalence is asserted on a high byte rather than assumed.
- [x] The source itself is pinned -- no `Get-Content ... -Encoding Oem` left inside
      `Invoke-TestSuiteGate`, and both sites through the helper -- so a later edit that copies the
      old pattern back in, which is exactly how the exposure got its second site, fails here.
- [x] `native-capture.tests.ps1` 115 pass / 0 fail; `test-suite-gate.tests.ps1` 128 pass / 0 fail;
      full lint + suite gate green.

### DEPLOY: fix/1731-gate-tolerant-capture-read

Closes #1731. The test gate now reads each suite's capture files through `Read-NativeCaptureFile`, the
tolerant reader this same lib built for a writer that still holds one, instead of a plain
`Get-Content` -- and prints a visible `[short read]` note naming the file when one was still held.
Both sites are covered: the pool's reap and the crash re-run added by #1723.

The defect being closed is a silent one. `Get-Content -Raw` does not fail on a held capture file; it
returns whatever was flushed, so a truncated suite block printed under a correct `== suite ==` header
with the exit code intact, and nothing said so. That is not a failure a reader could have caught by
looking harder.

For a session reading a gate run: nothing changes on an ordinary green run. What is new is that a
short block can no longer arrive looking complete.

**Score:** 2

#### What makes this deploy extra special

Nothing a subscriber of this repo's plugins sees. The test gate is a maintainer's tool, and a
consumer's run behaves identically unless a suite of theirs leaves a grandchild holding a capture
file -- in which case they get a note where they previously got a quietly short block.

**Score:** N/A

#### Pull Request

Read a suite's capture files with the tolerant reader, and say when a block may be short
