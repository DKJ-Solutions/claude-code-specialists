## Development: `fix/new-branch-warns-on-stale-base-v1` · 20260828-220126

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

Inbound #1046: `worktree-lane.ps1` refuses a base that is behind `origin` -- *"a lane must not be based
on a stale trunk"* -- while `new-branch.ps1` cut from whatever `HEAD` held and never looked. One hazard,
two answers. Verified against the source tree at v4.22.0 before routing: symptom, reason, proposed
repair, subject, size and repo all stand (the report measured the v4.21.0 plugin cache; the line numbers
shifted by one or two, nothing else).

The report's own first step is taken -- **warn with the count, do not refuse** -- because this script is
mirrored into every consumer's plugin cache and arrives by plugin update rather than by choice. That is
the same reasoning the version-suffix block in this script already gives for keeping its rule out of
`Test-BranchName`. Refusing stays open as the stronger follow-up.

### CREATE

- [x] `scripts/task/new-branch.ps1`: measure `HEAD..origin/<trunk>` after the name is final and before
      the checkout; warn with the count, the local remedy and the lane route. Gate the fetch on
      `refs/remotes/origin/<trunk>` existing, so an offline repo is neither asked nor warned.
- [x] Repeat the warning as the LAST line of the run -- the scaffold, the tier rubric, the commit and the
      push all print in between, so the first copy is off-screen by the time the run ends.
- [x] Move the `native-capture-lib.ps1` dot-source out of the push block: two callers now need it and the
      first runs long before the push.
- [x] Header docstring updated with what the check does and why it warns rather than refuses.
- [x] `build-shared-scripts.ps1` run, so the plugin mirror matches its source.
- [x] `skills/new-branch/SKILL.md`: the step list renumbered and a section added -- the measurement, the
      three states it prints, and why each design choice is the one it is.
- [x] `skills/worktree-lane/SKILL.md`: its step 2 now says it is no longer the only script that looks,
      and that it still goes further by *taking* the right base rather than reporting the wrong one.

### TEST

- [x] Three new sections in `scripts/tests/new-branch.tests.ps1` -- a base behind by 3 (count named, both
      remedies named, warning counted **twice**), a current base (says so, warns about nothing), and no
      remote-tracking trunk (not asked, nothing claimed). 134 asserts to 148.
- [x] Two helpers: `Publish-FixtureTrunk` (pushes the fixture trunk, which is what brings
      `refs/remotes/origin/main` into existence -- without it every fixture answers "not compared", which
      is why the check landed green against the whole existing suite) and `Add-OriginCommits` (advances
      the bare origin through a throwaway clone -- the second session on the same board).
- [x] Two traps hit and written down where the next reader meets them. `$fixtureS` collides
      case-insensitively with the teardown accumulator `$script:fixtures`, so the fixture path was
      string-concatenated onto it and the run died on a `Set-Location` over three glued temp paths.
      And `git init --bare` leaves the bare HEAD on `refs/heads/master`, so a plain clone of a
      main-only origin lands on an unborn `master`: the upstream commits went nowhere, the push failed
      and the fixture read 0 behind -- a helper that looks green and proves nothing.
- [x] `scripts/tests/entry-scaffold.tests.ps1`: its round-trip fixture completed with
      `native-capture-lib.ps1` and `park-lib.ps1`, and the run now **held to its exit code**. This is a
      pre-existing hole my change surfaced rather than caused, verified against `main`: since #900 made
      the creation push the default, `new-branch` dot-sourced `native-capture-lib.ps1` unconditionally in
      its push block, so that fixture's run has been exiting 1 for two weeks -- after the document was
      written, with the child's stderr going to `$null` and nobody reading the exit code, which is why
      610 asserts stayed green over a script that had died. Moving the dot-source above the checkout
      killed the run *before* the document existed and the hole fell out. The assert is what keeps it
      shut: nothing else in that suite can tell a finished run from a dead one.
- [x] Cost measured rather than assumed: the added `git fetch origin --quiet` runs at **477-558 ms**
      (n=3, warm, this repo) and only in a repo that has a `refs/remotes/origin/<trunk>` to compare
      against -- `worktree-lane` already pays the same fetch on every lane. `-DiscardStderr` on it is
      deliberate beyond tidiness: a failing fetch echoes the remote URL, which carries a credential in an
      HTTPS clone that embeds one.
- [x] Full local gate green: `check-plugin-integrity.ps1` 0 errors, all suites pass.

### DEPLOY: `fix/new-branch-warns-on-stale-base-v1`

`new-branch.ps1` now measures the base it is about to cut from and warns when it is behind
`origin/<trunk>`, naming the count -- the same fact `worktree-lane.ps1` has always refused on. The two
scripts met one hazard and answered it in opposite ways: the lane fetches and bases its worktree on
`origin/<trunk>`, while `new-branch` cut from whatever `HEAD` held and never looked, in a run that
reaches `origin` moments later to push. The safe base existed but was reachable only if you already knew
to take the lane route.

It warns rather than refusing, and it says it **twice** -- once before the checkout, once as the last
line of the run, because the scaffold, the commit and the push all print in between. A repo with no
`refs/remotes/origin/<trunk>` is neither asked nor warned, which is what keeps the script usable
offline. Both skill pages say what changed, and the lane's own page now states that it still goes
further by *taking* the right base rather than reporting the wrong one.

Along the way it surfaced a two-week-old hole in `entry-scaffold.tests.ps1`: its round-trip fixture was
missing `native-capture-lib.ps1`, so since #900 that fixture's `new-branch` run had been exiting 1 in the
push block -- after the document was written, with nobody reading the exit code, which is why 610 asserts
stayed green over a script that had died. The fixture is complete now and the run is held to its exit
code, because nothing else in that suite can tell a finished run from a dead one.

**Score:** 3

#### What makes this deploy extra special

Every repo running this workflow gets the warning on its next `new-branch`, through a plugin update
rather than by choosing it -- which is exactly why this warns instead of refusing. What it prevents was
measured, not imagined: a branch cut from a trunk 17 commits behind `origin/main`, to fix an issue
another session had closed by a merged PR four minutes earlier, producing a complete duplicate of
already-merged work -- branch, commit, PR, every gate green on both -- found only when the PR sat without
a CI check. The claim step is no safeguard against it either: `gh issue edit <n> --add-assignee @me`
succeeds silently on a closed issue.

**Score:** 4

#### Pull Request

new-branch warns when the branch base is behind origin
