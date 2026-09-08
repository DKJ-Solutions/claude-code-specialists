## feat/1659-temp-path-unpredictable

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

Issue 1659 measured the class as one member (park-lib). Re-measured: seven predictable temp paths in the shipping script layer. Plan: one shared composer in native-capture-lib (already in scope at all seven sites), convert all seven, tests, and record why a reparse-point check is NOT the answer (macOS /tmp is itself a symlink).

#### What the report got right, and the one thing it did not

The symptom stands: `grep -rn "ReparsePoint|LinkType|IsSymbolic|Attributes -band" scripts/` still
returns nothing. The **size** does not. #1659 measured the class by looking at two neighbours and
reported one existing member; re-measured over the whole shipping script layer it is **seven**:

| site | leaf | what writes there |
|---|---|---|
| `lib/native-capture-lib.ps1` (test gate) | `test-suite-gate-$PID` | `New-Item -Force`, and a **recursive delete** at the same path on entry |
| `lib/park-lib.ps1` | `git-park-msg-$PID.txt` | `WriteAllText` |
| `release/open-pr.ps1` x2 | `open-pr-body[-edit]-$PID.md` | `WriteAllText` |
| `release/ship-pr.ps1` | `ship-pr-fold-<pr>-$PID` | `git worktree add` |
| `release/verify-resolved-issues.ps1` | `verify-resolved-<issue>-$PID.md` | `WriteAllText` |
| `task/sync-main.ps1` | `sync-pr-body-$PID-<branch>.md` | `WriteAllText` |

That changes the repair. Seven hand-edits leave nothing behind that stops an eighth, so this is one
shared composer plus a scan that fails on the next one.

#### The open question the report left, answered

It offered three candidates and asked which. **Unpredictability**, and the other two are declined with
a reason rather than skipped: a reparse-point check is a check-then-write with a window between the
halves, and it cannot be applied to the temp **root** at all, because on macOS `/tmp` *is* a symlink to
`/private/tmp` -- a check there refuses a whole platform for the ordinary case. An ACL is per-platform
where a guid is not. There is nothing to pre-plant at a name that does not exist until it is used.

#### What is NOT covered, and why it cannot be here

`session-cache-lib.ps1` -- the second member the title names -- is on `feat/1605-sessioncheck-version-cache`
and does not exist on the trunk. Its `<temp>/dkj-session-cache` **must** persist across processes, so a
guid is not available to it: that shape needs a different answer and it belongs on that branch. Said
there rather than left implicit here.

And `scripts/tests/` is outside the scan on purpose -- fixtures have their own rule and their own
enforcer -- but that rule answers a different question (two concurrent runs, not a hostile neighbour),
so the exposure is unchanged there. Measured while reviewing this branch: **108** predictable fixture
paths across **66** files, **53** of them opening with a recursive delete at that path. Bigger than the
half this branch closes, pre-existing, and filed as
[#1664](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1664) rather than swept in here.
The PR title is narrowed to *shipping* scripts for the same reason.

### CREATE

- [x] `New-ScratchPath` in `lib/native-capture-lib.ps1` -- `<temp>/<label>-<pid>-<guid>`, `-Extension`,
      `-Directory` (created **without** `-Force`), and a validated label so no caller-composed value can
      leave the temp directory. Placed there because all seven sites already dot-source that lib.
- [x] All seven sites converted. The three temp paths that were already guid-based
      (`Invoke-NativeCaptureUtf8`, `publish-to-business`, `sync-main`'s live mirror) are left alone --
      they were never the class.
- [x] The test gate's capture directory loses its entry-time `Remove-Item -Recurse -Force`: with a guid
      there is no stale directory to clear, and that line was itself the recursive delete at a
      pre-plantable path.
- [x] `scripts/README.md`: the shipping-script rule written beside the existing `$PID` fixture rule,
      saying which question each of the two answers.
- [x] Mirrors regenerated (`sync/build-shared-scripts.ps1`) -- 7 updated.

### TEST

- [x] `native-capture.tests.ps1`: nine asserts on the composer (two calls differ, direct child of the
      temp dir, leaf shape, nothing created without `-Directory`, and three refusals -- `..`, a
      separator, an undotted extension).
- [x] A **scan** in the same suite: any non-comment line under `scripts/**` outside `tests/` naming a
      temp root -- the .NET call or the `TEMP`/`TMP` environment variables -- must carry a guid or a
      `# temp-path-exempt:` marker, of which exactly two are declared and counted. Plus a per-file
      assert that the five caller files still reach the composer.
- [x] Negative control run: the scan was proved to fail by re-introducing `git-park-msg-$PID.txt` in
      `park-lib.ps1` -- 3 asserts red, green again on restore.
- [x] `test-suite-gate.tests.ps1` adjusted: it used to **compose** the capture directory from the
      driver's `GATE-PID`, which a guid makes impossible. It now reports `CapturePid` and **finds** the
      directory by `test-suite-gate-<pid>-*` -- zero matches is the green case's assertion, one match is
      the red case's.
- [x] Review round -- Victor, Sebastian and Edith in parallel on the diff. Three findings acted on, all
      in the commit after the first: the scan's first shape required the temp call and the join on **one
      line**, which a two-statement composition and `$env:TEMP` both walked past; its exemption was an
      exact source-text match that a reflow of the composer would have turned against itself; and the
      DEPLOY section said "seven scripts" where it is seven **sites** across six.
- [~] "Lint gate + all suites green" -- dropped as a step because `open-pr.ps1` runs both and refuses
      the push on either, so ticking it here is a claim about a run that has not happened. What WAS run
      by hand is the pair this branch changes, and only because Victor reproduced a failure in one:
      `native-capture.tests.ps1` 87/87 and `test-suite-gate.tests.ps1` 82/82.
- [x] The failure Victor reproduced is closed, and it is worth naming because it is the branch's own
      trap: the sibling scanner in `test-suite-gate.tests.ps1` reads **every** line in `scripts/tests/`,
      comments and string literals included, and flagged this scan's own explanatory comment as a
      predictable fixture path. A guard's prose lives inside the tree its sibling guard measures.

### DEPLOY: feat/1659-temp-path-unpredictable

Seven sites across six scripts composed their temp path as `<label>-$PID`, which is a name a local
actor can reach first: `New-Item -Force` and `WriteAllText` both follow a symlink or junction, so a
pre-planted link redirects the write, and where the script then deletes recursively there, the same
window is a delete primitive in somebody else's directory. All seven now call one composer,
`New-ScratchPath`, which
returns `<temp>/<label>-<pid>-<guid>` -- there is no name to plant at. A reparse-point check was the
obvious alternative and was declined on the measurement: it is a check-then-write, and on macOS `/tmp`
is itself a symlink, so the same check refuses a whole platform for the ordinary case. A scan in
`native-capture.tests.ps1` now fails on the eighth site, which is what the class needed more than the
seven edits did.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service sees. These are the workflow's own scripts, and the hardening
is against a local actor on the machine running them; no behaviour a consumer invokes changes.

**Score:** N/A

#### Pull Request

No shipping script composes a predictable temp path any more

