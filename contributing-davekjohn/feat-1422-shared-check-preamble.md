## feat/1422-shared-check-preamble

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

Extract the dual-context repo-root resolution and the always-on prose walk into scripts/lib/consumer-check-lib.ps1; point the two prose checks' marketplace skip at the existing Test-IsWorkflowSourceRepo.

#### What the pickup measured, before anything was written

The five files and the shared block are as #1422 reports them. Two things the report could not see
from the outside, both found by reading the tree:

- **The resolution had already drifted.** Four checks resolve the root on one line;
  `check-git-identity.ps1` carries a `try`/`catch` variant. So outside a checkout one of the five
  answers and four die on `.Trim()` against `$null` under `Set-StrictMode` -- and nothing said which
  reading was intended, because both were written as though obviously right. The tolerant one wins:
  **four** of the five run from a SessionStart hook (`hooks.json` wires all but `check-branch-entry`,
  which is the CI gate), and an advisory check must not strand the session it starts.
- **The marketplace skip already has a name, and the two copies were asking the wrong question.**
  `Test-IsWorkflowSourceRepo` (seam-lib) exists precisely because *"does this repo publish plugins"*
  and *"is this repo the source of THIS workflow"* come apart under the one-product-one-repository
  rule -- that is issue #998. Its docstring carries a census of the sites that legitimately use the
  broad test; both prose checks were written in September, after that census, and neither is in it.

#### Where the extraction deliberately stops

`#1422` guessed that a single `Initialize-ConsumerCheck` taking five switches would not be an
improvement. It would not, and the measured subset is smaller than even the issue's fallback:

- the **repo-config load cannot be extracted at all**, and the reason is PowerShell scope rather than
  judgement -- `. $file` inside a function defines into the *function's* scope, so a helper would load
  a consumer's seams and discard them on return;
- the **marketplace skip needs no new definition**, it needs the existing one;
- the **lib dot-sources** differ per check and have nothing shared to name.

So the new lib holds exactly two things, and the boundary is the interesting half: it returns the
**fact** and never the **verdict**. `''` means *"could not tell"*, and the five callers give **three
different** answers to it -- the CI gate refuses, three session checks exit 0 because there is
genuinely no prose and no trunk to judge, and `check-git-identity` needs no test at all, because `''`
reaches `Get-GitUserName`, which drops the `-C` and reads the **global** git config, and comparing
that against the active `gh` account is still a meaningful answer. Three verdicts from one
resolution is the argument for the split: folding any of them into the lib imposes it on the other two.

### CREATE

- [x] `scripts/lib/consumer-check-lib.ps1` -- `Resolve-CheckRepoRoot` (the tolerant reading) and
      `Get-CheckProseCorpus` (the guarded `measure-context-lib` load plus the `Get-AlwaysOnDocuments`
      walk). Dependency-free for the first, as it is dot-sourced before anything is resolved.
- [x] All five checks call it, dot-sourced **guarded**, each keeping its own `''` verdict.
- [x] The two prose checks' skip calls `Test-IsWorkflowSourceRepo` instead of re-testing the manifest
      file inline -- #998's repair applied to the two sites written after it.
- [x] `Test-IsWorkflowSourceRepo`'s census updated: it was one short in each direction, and it is the
      docstring that arbitrates exactly the choice both authors got wrong.
- [x] Registered in `shared-scripts-lib.ps1` as a `LibOnly` pair and the mirrors regenerated -- all
      five callers are mirrored, so a lib that stayed behind would break every consumer's copy.

### TEST

- [x] New suite `scripts/tests/consumer-check-lib.tests.ps1` -- 9 asserts. The precedence *order* is
      pinned because nothing else in the tree states it, and the outside-a-checkout case is pinned
      because a happy-path-only test is what let two readings of one line coexist.
- [x] Both skip fixtures now assert **both directions**: a manifest publishing somebody else's product
      is judged, one publishing `contributing-davekjohn` is skipped. The negative case is the assert
      that catches a reversion to the broad file test -- under it, that fixture passed as `[OK]`.
- [x] Lint gate green; the eight directly affected suites green, then the full gate via `open-pr`.

### DEPLOY: feat/1422-shared-check-preamble

Five consumer-facing lint checks opened with the same ~30-line preamble, and it had already drifted:
four resolved the repo root on one line and crashed outside a git checkout, while the fifth carried a
tolerant variant nobody had reconciled. The dual-context root resolution and the always-on prose walk
now have one definition in `scripts/lib/consumer-check-lib.ps1`, and each check keeps its own verdict
on what that definition cannot decide -- a session check has nothing to judge outside a checkout, a
CI gate must refuse there.

The same pass closed a hole the duplication was hiding. Both prose checks skipped *"a repo that
publishes plugins"* by testing `marketplace.json` inline, where the question they mean is *"is this
repo the source of this workflow"* -- the distinction #998 already exists for. A repo publishing
another product while consuming this workflow was silently exempted from both checks; it is now
judged, with an assert in each suite pinning it.

**Score:** 3

#### What makes this deploy extra special

N/A -- the subject is this repo's own lint layer and the shared scripts a consumer runs. No
subscriber of a service notices a preamble having one definition instead of five. The behaviour that
did change reaches a consuming repo that also publishes a marketplace of its own, which no current
consumer is.

**Score:** N/A

#### Pull Request

One definition for the lint checks' shared preamble

