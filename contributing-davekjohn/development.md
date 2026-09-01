## Development: `fix/sync-main-network-calls-bounded-v1` · 20260901-114419

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

Route the five unguarded git network calls in `scripts/task/sync-main.ps1` through
`Invoke-NativeCapture`, so they inherit the non-interactive environment and the bound
[#1179](https://github.com/DaveKJohn/claude-code-specialists/issues/1179) added — closing
[#1181](https://github.com/DaveKJohn/claude-code-specialists/issues/1181), the follow-on that report's
own branch deliberately did not widen to.

#### Three things the report said that the tree did not confirm

Verified before anything was written, per the inbound pickup rule:

1. **The count.** The report lists the sites correctly but then says *"the four that reach the
   network"*. All **five** do — `ls-remote` is a network call as much as `fetch`, `pull` and `push` are.
   All five are bounded here.
2. **The mechanism did not exist yet.** `-TimeoutSeconds` and `$NativeCaptureNetworkTimeoutSeconds` were
   on `fix/git-calls-noninteractive-and-bounded-v1`, not on the trunk — PR
   [#1182](https://github.com/DaveKJohn/claude-code-specialists/pull/1182) was still in CI when this
   branch was picked up. This branch waited for it rather than stacking on it, so the diff is only
   `sync-main.ps1`'s own.
3. **The report's open question has a definite answer, and it is not the one it leaned towards.** It
   asked *"whether `sync-rules.ps1` should dot-source the lib or whether the two callers should"*. It has
   to be the caller. `Invoke-SyncGitQuiet`'s other eight callers are **local** queries that must not
   carry a network bound, two of them (`merge-base --is-ancestor`, and the `rev-parse` loop) read
   `$LASTEXITCODE` as the answer — which the `Start-Process` arm a bound implies does not set — and
   `sync-rules.ps1` declares itself dependency-free in its own header because it is the one file here the
   suite loads without running a sync. So the wrapper is untouched and the two network call sites left it.

#### Two things that went further than the report asked

Both fall out of routing through a wrapper that hands back an exit code, and both are the same defect
class the report's *"why it matters"* section argues from:

- **`ls-remote` and `fetch` failures are now refusals.** They ran through `Invoke-SyncGitQuiet`, which
  swallows stderr by design (inbound #801) — so an unreachable origin produced **no lines**, and no lines
  is indistinguishable from *"no sync branch on origin"*. The standing-predecessor guard then reported
  `none on origin` and let the run proceed, which is exactly the silent miss inbound #1021 built that
  guard to end, arriving through the guard's own query.
- **The post-merge `git pull` is now judged.** It had no exit-code check at all: the
  `Done -- sync PR #<n> merged into main` line printed whether or not the pull worked, so a failure left
  the operator told the sync had landed on a trunk that did not contain it.

#### What this branch deliberately did not widen to

The same script's four **`gh`** network calls (`pr list`, `pr create`, `pr view`, `pr merge`) are also
outside `Invoke-NativeCapture`. #1181 named git and reasoned its own scope; #1179 measured that `gh` was
unaffected because it carries its own token. Filed as
[#1184](https://github.com/DaveKJohn/claude-code-specialists/issues/1184) with the evidence on both
sides rather than ridden along here. The `gh pr checks` polling loop is not part of that: it is already
bounded by `-ChecksTimeoutMinutes` and is a deliberate long wait, which is the one call
`native-capture-lib` warns by name against bounding.

### CREATE

- [x] `scripts/task/sync-main.ps1` dot-sources `native-capture-lib.ps1` — unguarded, unlike the
      source-repo guard beside it, so a payload missing the lib fails at load rather than pushing
      unbounded.
- [x] All five network calls routed through `Invoke-NativeCapture` with
      `-TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds`: the `[1/6]` trunk pull, the `[3b/6]`
      `ls-remote` and `fetch` (both `-DiscardStderr`, which preserves `Invoke-SyncGitQuiet`'s contract on
      the way across), the sync branch's `push`, and the post-merge pull. The eight local `& git` calls
      (`status`, `rev-parse`, `checkout`, `commit`, `ls-tree`) are deliberately untouched — they cannot
      reach a credential helper, so a bound would buy nothing.
- [x] Each of the five reports a timeout distinctly from an ordinary non-zero exit, naming what state the
      run is in: the push says the branch is **not** on origin and hands over the command, the post-merge
      pull says the PR **is** merged and only the checkout is behind.
- [x] `scripts/lib/shared-scripts-lib.ps1` gains a second mirror of the lib,
      `native-capture-lib-shopify`, on `check-report-lib-workflow`'s precedent. Without it the mirrored
      script dot-sources a file that is not in the mirror, and fails at load for any consumer running
      `team-shopify` without `contributing-davekjohn` — and `build-shared-scripts -Check` cannot catch
      that, because a missing entry is a pair it never looks at.
- [x] `scripts/sync/build-shared-scripts.ps1` run: the two `team-shopify` mirrors are current.

A side effect worth naming rather than leaving to be discovered: a bounded call routes onto the lib's
`Start-Process` arm, which decodes the child's stdout as **UTF-8** instead of with the inherited console
code page. For `ls-remote` that is a small repair in the class inbound #821 documents — a branch name
carrying a non-ASCII character used to be decoded with whatever code page the run inherited, and
`Get-SyncBranchNamesFromRefs` anchors on `refs/heads/<prefix>`, so it survived either way. It is
cosmetic-to-better here, not a fix this branch claims.

### TEST

- [x] **Four of the five calls are driven for real** by the cases already in
      `scripts/tests/sync-main.tests.ps1`, against the fixture's local bare origin — the trunk pull, the
      `ls-remote`, the `fetch`, and the drift case's genuine `push`. That push is still not asserted (the
      suite header's coverage boundary is unchanged); what it now proves is that the call survives the
      routing.
- [x] **A new `the network guard` section**, 12 asserts: the dot-source is present and unguarded, no bare
      `& git` network verb survives, none went back through the stderr-swallowing wrapper, exactly five
      calls carry exactly five shared bounds (pinned as a count, so a sixth call added without one fails),
      the registry mirrors the lib into `team-shopify` and that mirror exists — plus the behavioural half:
      a `-DryRun` against an origin it cannot read now **refuses** and says `UNKNOWN`, where before it
      printed `none on origin`. `-DryRun` because it skips the `[1/6]` pull, which would otherwise fail
      first and never reach the step under test.
- [x] **A measured assumption pinned in `scripts/tests/native-capture.tests.ps1`.** A bound routes the
      call onto the `Start-Process` arm, and `Set-Location` moves PowerShell's *provider* location without
      touching `[Environment]::CurrentDirectory` — the classic 5.1 divergence. `sync-main.ps1` does
      `Set-Location` to the root it resolved and then relies on every git call landing there, so had
      `Start-Process` followed the .NET value, every bounded call would have run git in the wrong
      directory. It follows the provider location; measured, not reasoned about, and the new assert
      diverges the two itself so it cannot pass by accident.
- [x] `sync-main.tests.ps1`: 92/92. `native-capture.tests.ps1`: 58/58. Full lint + all suites green via
      `open-pr.ps1`'s gate.

### DEPLOY: `fix/sync-main-network-calls-bounded-v1`

`sync-main.ps1` — the pre-task sync `team-shopify` ships to the Shopify consumers — reached the network
five times with neither the non-interactive guard nor the bound that #1179 added, because that repair
landed at a choke point this script was not a caller of. All five now go through
`Invoke-NativeCapture`: they run with `GIT_TERMINAL_PROMPT=0` and `GCM_INTERACTIVE=never`, and a stall
kills the process tree after two minutes and reports itself instead of reading as a run still in
progress. Two calls also stop failing **silently**: an `ls-remote` or `fetch` that cannot reach origin
used to leave the standing-predecessor guard reporting `none on origin`, and the post-merge pull had no
exit-code check at all. The lib now travels in `team-shopify`'s own payload, so a consumer without the
workflow plugin gets it too.

For this repo the reach is narrow, and worth saying plainly: `sync-main.ps1` **refuses to run here** —
a repo that publishes plugins is its source, not a Shopify store. So nobody maintaining this repo will
meet the hang. What they meet is the maintenance shape: a second mirror entry for a lib that now travels
in two payloads, and a `the network guard` section in the suite that pins the five calls at five, so a
sixth added without a bound fails a test rather than shipping.

The part worth reading twice is not the bound. It is that two of these calls ran through a wrapper that
swallows stderr *by design*, and the guard reading them errs toward refusing — so a network failure
arrived as the one answer that guard treats as safe. Bounding them and stopping there would have made the
*hang* diagnosable and left the *silence* exactly where it was.

**Score:** 2

#### What makes this deploy extra special

A Shopify consumer running `team-shopify` gets this the moment they update, without configuring
anything — and they are the only ones who can meet the failure, because they are the only ones for whom
this script runs at all. The hang is not hypothetical for them: #1179 measured it on `DAVE-KOK-BWJ`,
fifteen minutes on a `git push` whose credential helper was drawing a window nothing was listening to.
This is that same push, in the script whose commit holds a third party's in-flight edits to the live
theme — taken out of a mirror the `finally` block then deletes, so until the push lands the only copy of
that work is a local branch nobody is looking at, presented as a push still running.

**One thing to know if you run this script on a flaky connection**, because the behaviour genuinely
changed rather than only got safer: a `git ls-remote` or `git fetch` that cannot reach origin now
**refuses the run**, where it used to continue. That includes `-DryRun`. Nothing is written either way, so
the cost is re-running it; what you get back is that the standing-predecessor guard can no longer report
`none on origin` when what it actually means is that it could not ask. There is nothing to adopt and no
flag to set.

**Score:** 3

#### Pull Request

sync-main.ps1's network calls run non-interactively and bounded

