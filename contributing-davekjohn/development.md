## Development: `fix/open-pr-sees-the-uncommitted-work-v1` · 20260828-151359

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

Issue #1026: `open-pr` merges an entry with no content behind it. PR #1025 shipped a changelog entry
describing two new rules in a manual whose edit was never committed -- the branch's whole diff was its
development document, the fold removed that file, and the merge delivered an entry and nothing else.

Two faults, and the second is the one worth repairing:

1. The lint gate and the suites judge the **working tree** while the PR ships **HEAD**, so on a dirty
   tree a green result is evidence about something other than what merges. Nothing said so.
2. The signal already existed and reached the wrong reader. `park-cycle`'s backing note (#960/#976)
   named the count, named the state and gave the instruction that would have prevented the merge -- in
   a **commit body**, which is right for a reader on a second device and invisible to the session that
   is holding the uncommitted file and about to open the PR.

Mechanism chosen by Dave, August 28, 2026, from the three the issue listed: the **narrow refusal plus
the dirty note**, not a blanket refusal on any dirty tree. `park-lib`'s own stated principle is the
reason -- a gate that fires on almost every run is one nobody reads by the time it matters.

### CREATE

- [x] `Get-BranchBackingFinding` in `scripts/lib/park-lib.ps1`: the pure condition -- is this a plan
      that claims to be finished with nothing committed behind it, and which of the two shapes.
      `Format-GitParkBacking` now **asks** it instead of restating the alarm test, so the park note and
      the gate cannot drift apart over one tree.
- [x] The **backing gate** in `scripts/release/open-pr.ps1`, after the step-list gate and before the
      push: refuses `UncommittedHere` (`-Force` is the valve, and it still warns), warns on
      `NotInThisCheckout` rather than refusing -- from open-pr that shape is indistinguishable from a
      branch legitimately shipping its entry alone, and refusing it would wedge the cross-device flow
      #960 exists to serve.
- [x] `Get-GateTreeDirtyCount` in `scripts/lib/gate-lib.ps1` plus one warning line above both gates:
      the fingerprint hashes the dirty list away, so it can answer "same tree as last time" and never
      "is this tree HEAD". A count, never filenames.
- [x] Plugin mirrors rebuilt via `scripts/sync/build-shared-scripts.ps1`.
- [x] Documented in `contributing-davekjohn/CONTRIBUTING.md` as **2.2.3**, at the point where it fires
      and directly after the step-list gate whose question it completes. Everything below it shifted by
      one -- the DEPLOY lock to 2.2.4 and the CI gate to 2.2.5 -- along with the three prose
      cross-references to the DEPLOY lock's old number.
- [x] The two claims that counted the gates were repointed with it: `CONTRIBUTING.md`'s 2.2 intro and the
      always-on root `CLAUDE.md`, which both said **four**. Both now say five, and both state
      that CI re-checks three of the four local gates rather than all of them -- the backing gate's
      subject is what sits uncommitted in a working copy, and a CI runner checks out a commit, so there
      the measurement always reads zero. A check that cannot fail is not a check.

### TEST

- [x] New suite `scripts/tests/backing-gate.tests.ps1` -- 41 asserts. Most of them assert **silence**,
      because narrowness is the property that would break quietly: a half-done plan, a document with no
      steps, a finished plan with work committed, and an unmeasurable trunk ref all stay quiet.
- [x] `scripts/tests/gate-lib.tests.ps1` case 11 -- clean/modified/untracked-in-a-new-directory counts,
      `$null` outside a repository, and that open-pr prints the warning **above** the lint gate.
- [x] `park-cycle.tests.ps1` still green at 64 asserts: the `Format-GitParkBacking` refactor is
      behaviour-preserving.
- [x] End-to-end against a real fixture reproducing #1025 -- the plan document committed, the manual edit
      left in the working copy. `Get-BranchBackingFinding` returns the `UncommittedHere` kind over one
      uncommitted file, and returns `$null` the moment that edit is committed. The same fixture on a
      checkout whose trunk ref is absent returns `$null` too, which is the "not measured is not zero"
      guard doing its job rather than a miss.

### DEPLOY: `fix/open-pr-sees-the-uncommitted-work-v1`

`open-pr` now refuses to open a PR for a plan that reads as finished while the work behind it sits
uncommitted in the working copy -- the shape that let PR #1025 merge a changelog entry describing a
manual edit that never left a working copy. The measurement is not new: `park-cycle` already took it and
wrote it into a commit body, where only a reader on another device would find it. It is now put in front
of the session that can still act on it, from the same shared function, so the two cannot disagree.

Alongside it, both gates now say out loud when they ran against a dirty tree. They judge the working
tree while the PR ships HEAD, so on a dirty tree a green result proves the working copy and not what
merges -- which is how #1025's lint run walked a manual *with* the two new rules in it and reported zero
errors.

**Score:** 4

#### What makes this deploy extra special

The repair is a *delivery* change, not a new measurement. Something in the system had already noticed
the exact failure, written it down precisely, and filed it where only the wrong reader would look. The
fix is one function shared by both readers rather than a second gate with its own opinion.

**Score:** 3

#### Pull Request

open-pr refuses a finished plan with work still uncommitted, and the gates say when they ran dirty
