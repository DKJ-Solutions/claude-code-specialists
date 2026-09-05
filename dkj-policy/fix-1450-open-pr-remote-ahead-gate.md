## fix/1450-open-pr-remote-ahead-gate

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

Add a single-branch fetch + rev-list ahead-check to open-pr.ps1, run before Invoke-WorkflowGates, so a branch whose remote head has moved (another session pushed) is caught before the 136s gate runs instead of at the push rejection afterwards. Reuse new-branch.ps1's tip-warning composition (issue #1446's UTF-8 fix) via a shared lib instead of duplicating it. Resolves #1450.

### CREATE

- [x] Extracted `Get-RemoteAheadNote` out of `new-branch.ps1`'s inline resume-warning composition into a
      new shared lib, `scripts\lib\remote-ahead-lib.ps1` -- the rev-list count, the `-Utf8` tip read
      (issue #1446), the control/format strip and the length cap, unchanged in behaviour.
- [x] `new-branch.ps1` calls the shared function instead of the inline block; the surrounding narrative
      comments (why this fires, why it warns rather than refuses) are untouched.
- [x] `open-pr.ps1` dot-sources the same lib and adds a new gate immediately before `Invoke-WorkflowGates`
      (both the PR path and `-GatesOnly` are unaffected -- the new block sits above the PR-path call
      only): a single-branch `git fetch` refspec'd straight into `refs/remotes/origin/<branch>`, then
      `Get-RemoteAheadNote` against `HEAD..refs/remotes/origin/<branch>`. A real divergence is a hard
      refusal (`exit 1`), not a warning -- unlike new-branch's own use of the same note, there is no
      legitimate fork in the road here: a non-fast-forward push is coming regardless. A failed fetch
      warns and lets the run continue, so a network hiccup costs nothing this script did not already
      risk (the divergence is still caught at the push, exactly today's behaviour).
- [x] Registered `remote-ahead-lib` in `scripts\lib\shared-scripts-lib.ps1` (both callers are mirrored)
      and regenerated the plugin mirrors via `scripts\sync\build-shared-scripts.ps1`.
- [x] Added `scripts\tests\remote-ahead-lib.tests.ps1` (36 asserts): the function against real
      bare+clone git fixtures (level, diverged, multi-commit, fresh/stale label selection, the
      adversarial-tip and length-cap cases new-branch.tests.ps1 already covers end-to-end, an
      unanswerable ref), plus structural asserts that both callers reach the shared function (and that
      neither carries a second copy of the sanitiser regex), that open-pr's gate sits before the
      PR-path `Invoke-WorkflowGates` call and refuses rather than warns, and that the lib is registered
      and mirrored.
- [x] Rewrote the one landmark-ordering check in that suite from two raw `.IndexOf()` calls to a
      single `[regex]::IsMatch` in dotall mode, after three CI runs in a row (windows-latest) read
      plain `.IndexOf()` as -1 for one of the two landmarks against a file independently verified
      byte-identical to the commit CI tested, and reproducible neither locally (four full local gate
      runs, an isolated repro against the exact committed bytes, the exact CI shard grouping and lane
      count) nor by changing the string's own quoting (backtick-escaped and single-quoted forms both
      failed identically). The cause was never pinned down; regex is the mechanism every neighbouring
      check in the same test case already used reliably, on CI, throughout.
- [x] Fixed three existing test fixtures that build a throwaway copy of `new-branch.ps1` and its dot-sourced
      libs by hand (`new-branch.tests.ps1`, `entry-scaffold.tests.ps1`, `worktree-lane.tests.ps1`): each
      was missing the new lib, which failed every case that actually runs `new-branch.ps1` with a raw
      path-not-found rather than testing anything -- caught by running the full local test gate, not by
      the targeted suite alone.

### TEST

- Lint gate (`scripts\lint\check-plugin-integrity.ps1`): 0 errors.
- Full local test gate (`Invoke-TestSuiteGate`, all 69 suites, 32 lanes): **all 69 suites passed in 133s**.
  First full run caught the two fixtures above missing the new lib (`entry-scaffold.tests.ps1`,
  `worktree-lane.tests.ps1`) -- both green after the fix.
- `remote-ahead-lib.tests.ps1` on its own: 36/36 pass, locally and on CI (after the regex rewrite above).
- `new-branch.tests.ps1` on its own: all 255 asserts pass (unchanged output -- the extraction did not
  move a single printed word, which is what the pre-existing "remote ahead"/"adversarial tip" cases in
  that suite actually pin).
- `shared-scripts.tests.ps1`: all 527 asserts pass (registration + mirror parity for the new lib).
- `gate-lib.tests.ps1`: 115/115 pass (unaffected -- the new gate sits above `Invoke-WorkflowGates`,
  never inside it).

### DEPLOY: fix/1450-open-pr-remote-ahead-gate

A branch resumed from a parked commit can still lose the full lint + test gate to a push rejection: if
another session pushes to the same branch after this checkout last looked, `open-pr.ps1` never re-checked
before spending two minutes proving a tree the push then refuses anyway (`! [rejected] ... fetch first`).
Measured on `fix/1446-tip-utf8-decode` on September 5, 2026 -- the fourth instance of this class (after
#1282, #1409, #1439), and the one #1439's own repair cannot reach: that check fires once, when a session
first resumes the branch, not at the one other door where a second session's push can still land unseen.

`open-pr.ps1` now fetches that one branch and compares `HEAD` against it immediately before the gate runs.
A real divergence is refused outright, with the fast-forward instruction, instead of discovered two minutes
and one discarded gate run later. The warning text itself -- the diverging commit's subject and author,
sanitised against control/format characters and capped -- is not a second copy: it is the same function
`new-branch.ps1`'s own resume warning already used, now shared so the day's other fix to that text (#1446)
cannot exist in one copy and not the other.

**Score:** 2

#### What makes this deploy extra special

N/A -- this is entirely mechanism between a session and its own push; nothing about it is visible to
anyone outside this repo's own contributors.

**Score:** N/A

#### Pull Request

open-pr checks for a diverged remote head before spending the lint+test gate

Reuses new-branch.ps1's own tip-warning composition (issue #1446's UTF-8 fix) via a new shared lib,
`scripts/lib/remote-ahead-lib.ps1`, rather than a second hand-typed copy of it. Resolves #1450.

