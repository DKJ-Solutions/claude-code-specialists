## feat/plugin-version-overview

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

Direct request from Dave: he cannot tell, per device, which plugin version is installed in a given
checkout, so he does not know whether to run a plugin update. The existing automatic check
(`connector-sessioncheck` -> `check-connectors.ps1` check 4) is inert on a plain consumer with no
sibling source checkout and gives no version signal at all. Deliver a plugin-shipped skill (in
`dkj-policy`, so every consumer receives it via a release) that reads the install record for this
checkout's path against the marketplace clone's `plugin.json` version + git HEAD and prints a verdict
per plugin. Read-only; nothing persisted (the removed `syncedVersion` bookkeeping is not
reintroduced).

### CREATE

- [x] `scripts/task/plugin-versions.ps1` -- the canonical script. Dual-context repo root, source-repo
  guard wired, reuses `check-report-lib` (`Get-EnabledPlugins`, `Get-InstallRecord`,
  `Get-UserClaudeHome`, `Get-JsonField`), `plugin-tree-lib` (`Get-RepoPluginRoots` against the clone's
  own `marketplace.json`) and `native-capture-lib` (`Invoke-NativeCapture` for the clone's git reads).
- [x] Extend `Get-InstallRecord`'s fixed projection in `scripts/lib/check-report-lib.ps1` with
  `GitCommitSha` (additive; the three existing call sites read named fields). Docstring updated; one
  assertion added in `scripts/tests/check-report-lib.tests.ps1`.
- [x] Register the pair in `scripts/lib/shared-scripts-lib.ps1`
  (`Plugin = 'dkj-policy'`, `Skill = 'plugin-versions'`, `SkillParamsExempt` for the two test seams,
  `MeasureArgs = @()`) and run `scripts/sync/build-shared-scripts.ps1` to write the mirror.
- [x] `plugins/dkj-policy/skills/plugin-versions/SKILL.md` -- the skill page (model-invocable;
  read-only).
- [x] Mirror-table rows: `plugins/dkj-policy/scripts/README.md` (gated by check 32) and the sibling
  catalog in `scripts/README.md`. `skills:all` spans in the root `README.md` (x2) and the
  `skills:plugin` span in `plugins/dkj-policy/README.md`.

### TEST

- [x] Sanity run against the real machine state: correctly reports a genuine split install
  (`dkj-policy` at the clone HEAD; `dkj-team-alpha` same version string but an older commit -> "clone
  is ahead"; `dkj-team-ecomm/lifehub/shopify` at 4.31.0 -> update; `dkj-policy-bwj` orphan sha ->
  update; `figma` non-DKJ marketplace -> "cannot determine" without error).
- [x] Fixture runs via `-RootOverride` + `-UserHomeOverride`: no marketplace clone, no install
  administration, declarative-only enable, and no plugins enabled -- each degrades to a clear message
  and exit 0.
- [x] `check-plugin-integrity.ps1` -- 0 errors (after the doc-sync rows above).
- [x] `check-report-lib.tests.ps1` (206 pass), `shared-scripts.tests.ps1` (579 asserts -- dual-context,
  mirror sync, skill-param), `source-repo-guard.tests.ps1` (43 asserts -- the new entry point's guard
  wiring is covered). A dedicated `plugin-versions` suite is downstream (Tycho).

### DEPLOY: feat/plugin-version-overview

A new `dkj-policy` skill, `plugin-versions`, answers a question nothing else in the system does: for
each enabled plugin, is the version installed IN THIS CHECKOUT the same as the one the local
marketplace clone holds, and if not, which command closes the gap? It reads only what every consumer
machine already has -- the install record keyed on this checkout's `projectPath`
(`version`, short `gitCommitSha`, `scope`), and the marketplace clone's per-plugin `plugin.json`
`version` plus its git `HEAD`. Because the clone advances only on
`claude plugin marketplace update`, the version string is cut-granular and the HEAD sha is the finer
truth, so the verdict prefers the sha (ancestor of HEAD -> `claude plugin update`; equal -> up to
date; unknown to the clone -> refresh the clone) and falls back to the version comparison when a sha
is absent. Read-only, no arguments, runs on any device; a missing clone, a missing install record, a
declarative-only enable, a moved checkout and a non-git marketplace fetch each degrade to a clear
line rather than an error. `Get-InstallRecord` in `check-report-lib.ps1` gains a `GitCommitSha` field
on its projection to feed it.

**Score:** 3

#### What makes this deploy extra special

Every consumer of the `dkj-policy` workflow receives the `plugin-versions` skill in the next release,
and with it the first per-device answer to *"is this checkout on the current plugin release, and do I
run `claude plugin update` or `claude plugin marketplace update`?"* -- a blind spot the repo slot in
`CLAUDE.md` calls out explicitly ("between two releases no version check can tell you the clone is
behind"). It is noticed the moment a consumer wonders whether a session loaded a stale plugin.

**Score:** 3

#### Pull Request

A per-device plugin-version overview: installed vs. marketplace clone, with a verdict
