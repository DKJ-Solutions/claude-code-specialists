## Development: `fix/unfolded-entry-on-main-sessioncheck-v1` · 20260903-101000

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

Issue #1270. A fold that never runs after a merge (a PR brought up to date and merged from the
GitHub UI, which never touches `ship-pr.ps1`) is currently silent: `main` carries the orphaned
`development-<branch>.md` and its `### DEPLOY:` entry stays out of `CHANGELOG.md` until a release
cut trips over it. `cut-release.ps1` already guards this at cut time; nothing surfaces it before.

Chris's `verify-stand-against-repo` lens already tells a session to check this by hand -- "a copy
sitting on `main` is a silent half-state". This branch automates that one check.

Decision (Dave, 2026-09-03): **SessionStart signal only**, no CI-on-`push` (a push-to-`main` check
fights this repo's two-push merge rhythm -- merge commit, then fold commit).

The signal is purely local and offline: the fold REMOVES a branch's development document, and the
trunk carries no copy, so ANY `contributing-davekjohn/development-*.md` (or a legacy name) committed
on the trunk ref is a skipped fold. No `gh`, no merged/closed lookup needed.

#### Shape (three pieces, mirroring script-contract-sessioncheck)

- `scripts/sync/check-unfolded-entry.ps1` -- the shared, mirrored check. `[SCOPE]` + `[OK]`/`[ERROR]`
  + `Summary:` via `check-report-lib.ps1`; reads the trunk ref (`origin/<trunk>` if present, else
  local `<trunk>`) with `git ls-tree`/`git show`, names the declared branch and the fold command.
- `plugins/workflows/contributing-davekjohn/hooks/unfolded-entry-sessioncheck.ps1` -- the thin
  SessionStart hook: runs the check, forwards `[ERROR]`/`[SCOPE]` lines, always `exit 0`.
- registry + `hooks.json` + generator run to produce the mirror.

### CREATE

- [x] `scripts/sync/check-unfolded-entry.ps1` -- the shared check
- [x] Register it in `scripts/lib/shared-scripts-lib.ps1` (`Skill = ''`, like check-script-contract) and update the "except check-script-contract" comment to name both
- [x] `plugins/workflows/contributing-davekjohn/hooks/unfolded-entry-sessioncheck.ps1` -- the hook
- [x] Add the hook to `plugins/workflows/contributing-davekjohn/hooks/hooks.json`
- [x] Run `scripts/sync/build-shared-scripts.ps1` to mirror the check into the plugin
- [x] Docs: promote the `verify-stand-against-repo` note (01-01-extension.md) from "manual check" to "automated signal"; update the sessioncheck lists in `README.md`, `.claude/specialists/SPECIALISTS.md` and the workflow plugin `README.md`
- [x] Tests: `scripts/tests/unfolded-entry.tests.ps1` -- clean trunk, an orphaned per-branch doc, a legacy name, a reset-state leftover, no trunk ref; hook forwarding

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` green (mirror in sync, ASCII, frontmatter, links)
- [x] All `scripts/tests/*.tests.ps1` green
- [x] Lint + tests green, then PR + merge + fold

### DEPLOY: `fix/unfolded-entry-on-main-sessioncheck-v1`

A fold that never runs after a merge is no longer silent. A new read-only SessionStart check,
`check-unfolded-entry.ps1`, run by the `unfolded-entry-sessioncheck` hook in the
`contributing-davekjohn` plugin alongside the roster / connector / script-contract checks, reports an
`[ERROR]` when the trunk carries a branch's `development-<branch>.md` (or a legacy name) that the fold
should have removed -- naming the file, the branch it declares, and the fold command. It is purely
local and offline: the fold removes the document, so its mere presence on the trunk ref
(`origin/<trunk>` if present, else the local branch) is the whole signal -- no `gh`, no merge lookup.
This closes the window `cut-release.ps1` already guarded only at cut time, measured on PRs #1253 and
#1261 (#1266), which sat orphaned on `main` for ~10 hours. Decision (Dave, 2026-09-03): a SessionStart
signal, not a CI-on-`push` check.

**Score:** 3

#### What makes this deploy extra special

N/A -- a subscriber of a service notices nothing here; the reader is a maintainer of this repo or of a
repo that runs the workflow plugin.

**Score:** N/A

#### Pull Request

A skipped fold after a merge is caught by a SessionStart signal

