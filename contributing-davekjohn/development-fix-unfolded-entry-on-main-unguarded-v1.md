## Development: `fix/unfolded-entry-on-main-unguarded-v1` · 20260903-100303

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

Issue #1270 (split from #1266): a fold that never runs after a merge is silent -- the fold is invoked
only from `ship-pr.ps1`, so a PR merged from the GitHub UI leaves the `### DEPLOY:` entry trapped in the
development document on `main` and no gate downstream catches it. Dave's steer (`AskUserQuestion`,
2026-09-03): add the guard in **both** homes -- a CI workflow on `push` to `main` and a SessionStart
signal.

### CREATE

- [x] `Get-UnfoldedTrunkEntry` in `scripts/lib/entry-scaffold-lib.ps1` -- one detector for both callers:
      every written `development-*.md` under `contributing-davekjohn/` whose declared branch is not the
      one under HEAD. Offline (no `gh`), wide declared-branch read (fixed path, known shape).
- [x] `scripts/lint/check-unfolded-entry.ps1` -- the gate around it, dual-context root + optional
      `repo-config.ps1` like `check-branch-entry.ps1`, but NO source-repo guard: a SessionStart hook runs
      it from `${CLAUDE_PLUGIN_ROOT}`, so the guard would refuse it in the source repo -- the same carve-out
      `check-roster-sync` / `check-script-contract` have. `Skill = ''` in the registry, like `check-script-contract`.
- [x] `.github/workflows/unfolded-entry.yml` -- `push` to `main` only, advisory (not in `main-ci-gate`),
      `windows-latest` / `shell: powershell`, `cancel-in-progress: true` to swallow the merge->fold ship
      window.
- [x] `plugins/workflows/contributing-davekjohn/hooks/unfolded-entry-sessioncheck.ps1` + wired into that
      plugin's `hooks.json` -- modelled on `script-contract-sessioncheck.ps1`, soft, always exit 0.
- [x] Registered in `Get-SharedScriptPairs`; `build-shared-scripts.ps1` regenerated the two mirrors.
- [x] Docs: `CLAUDE.md` (a post-merge guard bullet), Sylvester's lens (`#1244` passage + owned list),
      Chris's lens (`verify-stand-against-repo` now names a fourth session gate).

### TEST

- [x] `scripts/tests/unfolded-entry-gate.tests.ps1` -- 13 asserts over the detector, the gate and the
      hook; document states from the real `Format-Development`, `$PID` fixture paths.
- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors -- `[skill-param]` names
      `check-unfolded-entry` as correctly skill-less). `build-shared-scripts.ps1 -Check` in sync.
      `check-script-contract.ps1` 0 errors. Affected suites green: `shared-scripts` (483),
      `entry-scaffold` (669), `branch-entry-gate` (35), `script-contract` (293), `branch-document-path`
      (24).
- [~] Full suite + gate: left to `open-pr.ps1` / CI -- pre-running the tooling's own gate proves
      nothing it will not prove itself (Chris's persona, "whose clock is it").

### DEPLOY: `fix/unfolded-entry-on-main-unguarded-v1`

A merge that skips the fold -- a PR merged from the GitHub UI, or any path that bypasses `ship-pr.ps1`
-- used to leave the branch's `### DEPLOY:` entry trapped in `contributing-davekjohn/development-*.md`
on `main`, with `CHANGELOG.md` never receiving it and a release cut in that window silently missing the
change. Measured on #1266: PRs #1253 and #1261 sat unfolded for ~10 hours.

`check-unfolded-entry.ps1` now reports any written `development-*.md` on the trunk whose declared branch
is not the one checked out (the invariant: the fold removes it at the merge, so `main` carries none).
It runs from two places because neither covers the whole population: `.github/workflows/unfolded-entry.yml`
on every `push` to `main` catches it regardless of who merged or how (advisory -- making it required is
Dave's repo-settings call, and a required check cannot gate a push anyway), and the SessionStart hook
`unfolded-entry-sessioncheck.ps1` tells the next specialists session at start instead of relying on
Chris's manual `verify-stand-against-repo` check. Neither calls `gh`. The one false positive -- the
seconds between `ship-pr`'s merge commit and its fold commit -- is swallowed by the workflow's
`cancel-in-progress` and reads to a session as a finding that resolves itself.

**Score:** 3

#### What makes this deploy extra special

N/A -- an internal CI guard and a session hook; no subscriber of any service notices it.

**Score:** N/A

#### Pull Request

Guard against a skipped fold leaving an unfolded entry on main
