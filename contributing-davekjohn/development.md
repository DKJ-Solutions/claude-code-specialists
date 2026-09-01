## Development: `feat/bwj-codex-rename-v1` · 20260901-093509

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

#### Why

The plugin shipped a day ago (v4.28.0) as `workflow-bwj`, a narrow "ticket-work workflow seam". Dave
is repositioning it as the home of BWJ's *laws* -- the binding rules the working environment of BWJ's
two Shopify store repos (`smartwatchbanden`, `xoxowildhearts`) operates under, which `team-shopify`
obeys. "Workflow" no longer fits; "codex" (a book of law) does. This branch does ONLY the rename: no
new content, no restructuring of the plugin's internals. `WORKFLOW-portable.md` keeps its name -- it
accurately describes the ticket workflow, which stays one part of the plugin.

### CREATE

- [x] `git mv plugins/workflows/workflow-bwj plugins/workflows/bwj-codex` (7 files) and
      `git mv scripts/tests/workflow-bwj.tests.ps1 scripts/tests/bwj-codex.tests.ps1`.
- [x] `.claude-plugin/marketplace.json`: plugin `name` and `source` -> `bwj-codex`; plugin
      `description` and the marketplace-level `description` reframed to the codex/law framing, light and
      factual, claiming no new capability (the plugin still ships only the Asana ticket seam today).
- [x] `plugins/workflows/bwj-codex/.claude-plugin/plugin.json`: `name` -> `bwj-codex`.
- [x] Swapped `workflow-bwj` -> `bwj-codex` inside the moved folder: `README.md`,
      `skills/adopt-bwj-asana/SKILL.md`, `templates/asana-mirror.yml`, `templates/asana-mirror.ps1`
      (including the `scripts/tests/...tests.ps1` path it names). `WORKFLOW-portable.md` and
      `skills/report-issue/SKILL.md` had no `workflow-bwj` string.
- [x] `scripts/tests/bwj-codex.tests.ps1`: describe/synopsis text, `$PluginRoot` path, and the
      `plugin.json name` / `marketplace source` assertions -> `bwj-codex`.
- [x] Current-tense references updated in root `README.md` (one-product section, plugin table, skills
      section), `plugins/workflows/README.md`, and `contributing-davekjohn/`'s
      `CONTRIBUTING-portable.md` + `README.md`.
- [x] `scripts/lint/check-plugin-integrity.ps1` check 23 (`[plugin-kind]`) extended to accept
      `*-codex` as a way-of-working name under `plugins/workflows/` -- alongside `workflow-*` and
      `contributing-*`, which was itself added the same way when `workflow-davekjohn` was renamed
      `contributing-davekjohn`. Docstring, the WHY comment, both `Add-Error` messages and the coverage
      note updated to match, plus the two READMEs that describe the check. A pre-existing typo in that
      comment (`'contributing-davekjohn' -> 'contributing-davekjohn'`) corrected to
      `'workflow-davekjohn' -> 'contributing-davekjohn'`.
- [x] `contributing-davekjohn/releases/changelog/4.x/4.28.0.md`: the one relative link into the moved
      folder was now dead and failed the link gate -- corrected the href only
      (`.../workflow-bwj/README.md` -> `.../bwj-codex/README.md`); link text, prose and the
      `feat/workflow-bwj-plugin-v1` heading left as the historical record.
- [x] Left untouched as historical record: `releases/{github,audience}/4.x/4.28.0.md`,
      `releases/history.md`, the rest of `releases/changelog/4.x/4.28.0.md`, and the three folded
      `CHANGELOG.md` mentions (lines 124, 137, 147 -- other branches' merged DEPLOY entries).

### TEST

- [x] `powershell -NoProfile -File ./scripts/lint/check-plugin-integrity.ps1` -- `0 error(s)`, no
      findings.
- [x] All 56 test suites via `Invoke-TestSuiteGate` (the shared gate `open-pr`, `cut-release` and CI
      run) -- `all 56 suites passed in 76s`. `bwj-codex.tests.ps1` passes all 30 asserts.

### DEPLOY: `feat/bwj-codex-rename-v1`

The `workflow-bwj` plugin is renamed to `bwj-codex` throughout the tree: its folder
(`plugins/workflows/bwj-codex/`), its `marketplace.json` name and source, its `plugin.json` name, its
test file (`scripts/tests/bwj-codex.tests.ps1`), and every current-tense reference in the root and
plugin READMEs, the `contributing-davekjohn` portable pages, and the plugin's own skill and template
text. The marketplace and plugin descriptions are reframed from "a narrow ticket-work workflow" to
"BWJ's codex -- the binding rules its two Shopify store repos operate under"; no capability is added,
the plugin still ships exactly the Asana ticket seam. Lint check 23 (`[plugin-kind]`) learns `*-codex`
as a third way-of-working name shape, the same accommodation it already makes for `contributing-*`.
The v4.28.0 release record is left intact except for one dead relative link, whose href is repointed
at the moved README.

**Score:** 1

A published plugin changes identity. Any repo that enabled `workflow-bwj@claude-code-specialists` in
`.claude/settings.json` must rename that entry to `bwj-codex@claude-code-specialists` or the plugin
silently stops loading. The plugin is one release old and opt-in, so the set of affected repos is
small-to-empty, but the change is breaking for an adopter rather than invisible plumbing -- above
tier 0.

#### What makes this deploy extra special

A consumer who had enabled `workflow-bwj` (BWJ's two store repos are the only intended adopters) needs
a one-line settings change to `bwj-codex` after taking the release carrying this. Nothing migrates
automatically and nothing warns; a session in a repo whose settings still name `workflow-bwj` just
loses the two skills and the CI template reference. Small, mechanical, but real for that reader.

**Score:** 1

#### Pull Request

Rename the workflow-bwj plugin to bwj-codex

