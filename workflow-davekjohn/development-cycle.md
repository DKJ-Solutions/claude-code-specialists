# Development cycle: `fix/remove-prompt-inbox-v1` · 20260825-152817

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Issue #882 (Dave): remove the prompts/ mechanism entirely -- folder, skill, scripts, hook, and every doc reference. Full removal, no replacement.

## PLAN

**The ask ([#882](https://github.com/DaveKJohn/claude-code-specialists/issues/882), Dave).** Dave has
stopped using the prompt inbox in favour of GitHub issues; the mechanism, its skill, its scripts and its
hook may go entirely. No decision needed — full removal, no replacement, no seam left behind.

**Full inventory, from a targeted search (`prompt-inbox|prompt-sessioncheck|skills/prompt/|...`, 21
files, historical release notes excluded per the published-record doctrine):**

Delete outright:
- `workflow-davekjohn/prompts/` (this repo's own scaffolded instance: `.gitignore`, `README.md`,
  `templates/prompt_template.md`; `prompt.md` itself is untracked/gitignored and goes with the folder)
- `scripts/lib/prompt-inbox-lib.ps1` + its mirror `plugins/workflows/workflow-davekjohn/scripts/lib/prompt-inbox-lib.ps1`
- `scripts/task/prompt-inbox.ps1` + its mirror `plugins/workflows/workflow-davekjohn/scripts/task/prompt-inbox.ps1`
- `scripts/tests/prompt-inbox.tests.ps1` (root only — tests are not mirrored into the plugin)
- `plugins/workflows/workflow-davekjohn/skills/prompt/` (whole skill folder)
- `plugins/workflows/workflow-davekjohn/hooks/prompt-sessioncheck.ps1`

Edit:
- `plugins/workflows/workflow-davekjohn/hooks/hooks.json` — drop the third SessionStart hook entry
- `scripts/lib/shared-scripts-lib.ps1` — remove the two registry entries (`prompt-inbox-lib`, `prompt-inbox`)
- `scripts/task/adopt-workflow-folder.ps1` — drop the `prompt-inbox-lib.ps1` dot-source, the
  `$promptsReadme` block, the prompts row/paragraph in the generated folder docs, the `$promptPaths`
  line and its four scaffold targets
- `workflow-davekjohn/CLAUDE.md` (root instance) — drop the `prompts/prompt.md` bullet
- `plugins/workflows/workflow-davekjohn/README.md` — drop the `prompt` skill row, the hook-table clause,
  fix "the thirteen skills" → twelve (two places)
- `plugins/workflows/workflow-davekjohn/scripts/README.md` — drop the `prompt-inbox.ps1` and
  `prompt-inbox-lib.ps1` rows, fix `adopt-workflow-folder.ps1`'s description
- Root `README.md` — drop `prompt` from both skills-all-list spans, "five SessionStart hooks" →
  four (two spots)
- `.claude/specialists/SPECIALISTS.md` — same hook-count fix
- `connectors/README.md` — same hook-count fix
- `scripts/maintenance/baselines/skill-cost.json` — drop the stale `workflow-davekjohn/prompt` baseline entry

**Non-goal:** historical mentions in `CHANGELOG.md` and `releases/**` stay exactly as written (published
records — the same doctrine `workflow-davekjohn/CLAUDE.md` states for `releases/audience/`).

## CREATE

- [x] Delete `workflow-davekjohn/prompts/` (and the untracked `prompt.md` inside it)
- [x] Delete the four script files (root pair + plugin mirror pair) and `scripts/tests/prompt-inbox.tests.ps1`
- [x] Delete `plugins/workflows/workflow-davekjohn/skills/prompt/`
- [x] Delete `plugins/workflows/workflow-davekjohn/hooks/prompt-sessioncheck.ps1`, edit `hooks.json`
- [x] Edit `scripts/lib/shared-scripts-lib.ps1` — remove both registry entries
- [x] Edit `scripts/task/adopt-workflow-folder.ps1` — remove every prompts-related block (dot-source,
      `$promptsReadme`, table row, CLAUDE.md paragraph, `$promptPaths` + 4 targets), regenerate its mirror
      via `build-shared-scripts.ps1`
- [x] Edit `workflow-davekjohn/CLAUDE.md` — remove the prompts bullet
- [x] Edit this repo's own already-scaffolded `workflow-davekjohn/README.md` — not just the generator;
      it carried the same dead `prompts/` link and row (found by the lint gate's link-scan check)
- [x] Edit `plugins/workflows/workflow-davekjohn/README.md` — remove skill row + hook clause, fix skill
      count (thirteen → twelve, two places)
- [x] Edit `plugins/workflows/workflow-davekjohn/scripts/README.md` — remove two rows, fix one description
- [x] Edit root `README.md`, `.claude/specialists/SPECIALISTS.md`, `connectors/README.md` — fix hook
      count (5→4, four spots total), drop mentions including the "assignment written in an editor"
      clause in the skills:all mechanism-description parenthetical
- [x] Edit `scripts/maintenance/baselines/skill-cost.json` — remove stale baseline entry
- [x] Run `check-plugin-integrity.ps1` + full test suite locally before opening the PR — green: 0 lint
      errors, 52/52 suites (208 asserts) passed. Two real defects caught and fixed along the way: a
      dangling trailing comma left by the target-list edit (`Missing expression after ','` in both the
      source and the mirror of `adopt-workflow-folder.ps1`), and the PLAN text above literally spelling
      out the skills-all HTML comment marker tripped the skill-list check's own marker scan — reworded
      rather than exempted

## TEST

No dedicated new suite: this branch removes a mechanism and its own regression suite along with it
rather than adding behaviour to cover. Correctness is the removal being *total* and *clean*, which the
two existing gates already prove for this kind of change:

- [x] `check-plugin-integrity.ps1` — 0 errors, including the link-scan, parse and skill-list checks that
  are the ones a half-finished removal would actually trip (and did, twice, before the fix)
- [x] Full local suite — 52/52 `scripts/tests/*.tests.ps1` passed, 208 asserts, none of the removed
  suite's own assertions (it went with the mechanism)
- [x] Targeted repo-wide grep for every prompt-inbox surface (`prompt-inbox`, `prompt-sessioncheck`,
  `skills/prompt/`, `Get-PromptInboxPath`, `Format-Prompt*`, `workflow-davekjohn/prompts`) — zero live
  hits; the only survivors are this document's own PLAN prose and the two historical release notes,
  correctly left untouched

## DEPLOY: `fix/remove-prompt-inbox-v1`

Removed the prompt-inbox mechanism entirely (issue #882, Dave): the `workflow-davekjohn/prompts/`
folder, the `prompt` skill, its two scripts (`prompt-inbox.ps1` + `prompt-inbox-lib.ps1`, root and
plugin mirror), the `prompt-sessioncheck` SessionStart hook, and every doc that named any of it — the
plugin's own README and scripts README, this repo's `workflow-davekjohn/CLAUDE.md` and
`workflow-davekjohn/README.md`, the root README's two skill-list spans, `SPECIALISTS.md`,
`connectors/README.md`, and a stale cost baseline. No replacement: Dave now hands assignments over as
GitHub issues instead.

Tier 1 — this repo's own contributors notice one fewer skill and, once merged, one fewer SessionStart
hook line; nothing in how a branch, PR or release works changes.

**Score:** 3

### What makes this PR extra special

N/A — nothing here reaches a service subscriber; the prompt inbox was a workflow-authoring convenience
inside this repo and its consumers, never anything an end user of a published product could see.

**Score:** N/A

### Pull Request

Remove the prompt inbox from workflow-davekjohn

