## Development: `fix/the-quotepath-flake-names-its-own-axis-v1` · 20260829-231219

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

Issue #1117. The `quotepath` assert in `scripts/tests/sync-main.tests.ps1` went red once under the CI
gate, on PR #1105 -- a branch byte-identical to the trunk in both that suite and the script it tests.
The report proposed no fix on purpose, on the ground that the plausible repair would carry a citation
the measurement did not support, and left the axis behind #821 unidentified.

#### The cause is measured, not inferred

It is not #821's axis and not a second one beside it. `c`, `a` and `f` are all hex digits; the fixtures
are named `syncmain-<pid>-<label>-<six hex chars>` off a GUID, and the run PRINTS those paths. About one
run in 500 spells the three-character needle in a directory name and fails an assert about a file it
never touched.

#### Not in scope

The fixture suffix is left as it is, and the reasoning is in the code comment: digits-only would kill
`caf` and open the identical door to a digit needle.

### CREATE

- [x] `sync-main.tests.ps1`: the needle gains its path prefix -- `-notmatch 'sections/caf'` instead of
      `-notmatch 'caf'` -- so it names a path in the drift report rather than three characters anywhere
      in the run's output
- [x] the comment above it records the reproduction, the measured rate, why the tail stays truncated,
      and why hardening the fixture suffix is not the repair

### TEST

- [x] reproduced the CI failure deterministically by forcing the fixture suffix to `caf123`:
      `[FAIL] quotepath: ...` / `FAILED: 1 of 80 asserts.` -- the same assert and the same count as the
      run in the report
- [x] captured what the run actually printed, which is the evidence the report could not have:
      `using the mirror given: ...\Temp\syncmirror-32348-live-caf123` and
      `To ...\Temp\syncmain-32348-live-caf123\origin.git` -- two temp paths, no accented file involved
- [x] measured the rate over 2,000,000 random six-hex names: 0.0968% contain `caf`; two are printed per
      run, so 0.194% -- one in 517, which is the order that explains "once, on a branch touching nothing"
- [x] excluded the two axes the report and #821 pointed at, so nobody re-walks them: fixtures are
      isolated on `$PID` + GUID, and no suite holds `[Console]::OutputEncoding` in-process any more
      (`native-capture.tests.ps1` sets it only inside a child with its own console)
- [x] checked the same collision class across the tree: `-notmatch '2099'` and `-notmatch '332340'` are
      the only other all-hex needles, and neither is reachable today
- [x] suite green after the repair: 80 of 80

### DEPLOY: `fix/the-quotepath-flake-names-its-own-axis-v1`

The `sync-main` quotepath flake had nothing to do with character encoding, and cannot happen again.

It went red once under the CI gate on a branch byte-identical to the trunk, was filed as a possible
second axis behind #821 -- a git path decoded off the inherited console code page -- and was explicitly
left without a proposed fix because no measurement supported one. The real cause is smaller and fully
reproducible: the assert's needle was the three characters `caf`, and `c`, `a` and `f` are all hex
digits. The fixtures are named off a GUID and the run prints their paths, so roughly one run in 500
spells the needle in a temp directory and fails an assert about a file it never touched. Forcing the
suffix to `caf123` reproduces the reported line and count exactly, and it is why the neighbouring
`drift on 2 file(s)` assert stayed green: nothing was ever miscounted as drift.

The needle now carries its path prefix. Its tail stays truncated on purpose -- mojibake is what the
assert hunts, and pinning the full filename would pin exactly the bytes that go wrong.

The measured cost was a red required check on a clean branch: `lint-en-tests` blocks the merge, so it
also sent whoever was shipping to hunt for a cause in a diff that had none. That is what is gone. It
had already happened twice under two different explanations, which is the more expensive half.

**Score:** 3

#### What makes this deploy extra special

`scripts/tests/` is repo-internal and travels in no plugin -- `sync-main.ps1` is mirrored to
`team-shopify`, its suite is not, and this branch does not touch the script. No consumer installs the
change and no subscriber of the service can observe it.

**Score:** N/A

#### Pull Request

The quotepath flake was a hex collision, not an encoding one
