## feat/1437-dkj-policy-rename

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

Issue #1437: hard cutover, no compatibility shim beyond the readers that already exist for the rename
before this one. Plugin folder + plugin name + root folder all move; historical prose and the release
archive stay verbatim.

#### The three renames this branch performs

| what | from | to |
|---|---|---|
| the workflow plugin | `contributing-davekjohn` | `dkj-policy` |
| its companion plugin | `bwj-codex` | `dkj-policy-bwj` |
| the workflow's own root folder | `contributing-davekjohn/` | `dkj-policy/` |

The folder follows the plugin because it always has: `workflow-davekjohn` the plugin and
`workflow-davekjohn/` the folder renamed together at #886, and every seam default is composed from
`Get-WorkflowFolderName`, which names the folder after the plugin that legislates it.

#### What is deliberately NOT swept

The #952 rule: a dated measurement keeps the name it was written with. That covers
`dkj-policy/releases/**` (the whole archive, prose only -- its LINK TARGETS are repointed, exactly as
#886 did), the entries already folded into `CHANGELOG.md`, `connectors/*.json` (a register of what a
consumer HAS, and no consumer has migrated yet), and every sentence in the tree that records what was
true on a date. Three sweeps of this branch had to be reverted for exactly that reason, and one
pre-existing instance of the same defect was found and repaired -- see TEST.

### CREATE

- [x] `git mv` the three directories -- `plugins/workflows/{contributing-davekjohn,bwj-codex}` and the
      root `contributing-davekjohn/`
- [x] `marketplace.json`: both plugin `name`/`source` pairs, and the three descriptions that name either
      plugin
- [x] both `plugin.json` manifests -- `name`, `displayName`, the naming rationale in `description`,
      and a `policy` keyword
- [x] `.claude/settings.json`: the enabled-plugin id this repo consumes itself under
- [x] `Get-WorkflowFolderName` (`scripts/lib/seam-lib.ps1`): an ordered list, newest first, replacing the
      two-name if-chain -- `dkj-policy`, `contributing-davekjohn`, `workflow-davekjohn`
- [x] every other list of accepted folder or plugin names grew an entry rather than being substituted:
      `Assert-WorkflowIsolatedSeamPath`'s `$allowedRoots`, `Get-MojibakePaths`, `check-script-contract`'s
      `$workflowFolderNames`, `bootstrap.ps1`'s `$workflowPluginNames`
- [x] `Get-BranchFilePaths`: a whole `ContribFolder*` generation for the pre-#1437 folder, per-branch name
      included -- the row set is larger than `PriorFolder*` because this rename lands three days after the
      documents went per-branch, so `contributing-davekjohn/<slug>.md` is a name real open branches carry
- [x] `Get-BranchFileLegacyNames` reads that generation, and `Get-RetiredDocNames` reports both retired
      folder names to the consumer-prose gate
- [x] `Get-PrDescriptionPlaceholderDefaults`: the seven `contributing-davekjohn/` forms restored and seven
      `dkj-policy/` forms appended -- append-only, which is the whole of #952
- [x] `check-plugin-integrity`'s plugin-kind check accepts `*-policy` and `*-policy-*` alongside
      `workflow-*`, `contributing-*` and `*-codex`; the retired shapes stay accepted
- [x] sweep the rest -- 582 occurrences in `scripts/**`, 953 across the tree outside the archive -- with
      history-bearing lines excluded from the sweep and reviewed by hand
- [x] rebuild the 22 shared-script mirrors and regenerate `config-blueprint.json` from the libs
- [x] rename `scripts/tests/bwj-codex.tests.ps1` and its row in `suite-durations.json`; rekey
      `baselines/skill-cost.json`
- [x] `INSTALL.md`: a migration section for the two retired ids -- the commands, why the folder rename is
      optional, what re-running the scaffolder costs if you skip it, and the `Get-ShopifySyncLogPath` seam

### TEST

- [x] `check-plugin-integrity.ps1` -- 0 errors. It found the whole dead-link set for me: 34 of them, all
      inside the release archive, which is what established that #886 had repointed archive LINK TARGETS
      while leaving archive PROSE alone. Same treatment applied here.
- [x] all suites under `scripts/tests/*.tests.ps1`
- [x] a pre-existing instance of the #952 defect, found because this branch walked over it:
      `INSTALL.md`'s retired-id table said `specialists-contributing-davekjohn@claude-code-specialists`.
      No such id ever existed -- #886 swept the historical `specialists-workflow-davekjohn` when it
      renamed, so the uninstall command in the migration section matched nothing a consumer could have
      installed. Restored to what `git show 5dc6c364^:INSTALL.md` records.

### DEPLOY: feat/1437-dkj-policy-rename

The workflow plugin is now **`dkj-policy`** and its companion **`dkj-policy-bwj`**, and the workflow's own
root folder is **`dkj-policy/`**. The old names said what the plugin was *called after*; the new ones say
what it *is* -- the top rung of the order, the page that outranks a consumer's root `CLAUDE.md` on every
subject it addresses, with one ministry under it narrowed to the two repos it binds. Nothing about the
precedence rule itself changed, and no plugin gained or lost a skill, script, gate or seam.

Inside this repo the rename is complete: manifests, seams, gates, tests, the shared-script mirrors and the
generated config blueprint. Everything that reads a folder or plugin name by list grew an entry instead of
being substituted, so a repo still on `contributing-davekjohn/` -- or `workflow-davekjohn/`, from the rename
before this one -- keeps its changelog, its release history and its branch documents exactly where they are.

**Score:** 4

#### What makes this deploy extra special

**Consumers must act.** The plugin ids they enable no longer resolve: `contributing-davekjohn@` and
`bwj-codex@` are gone from the marketplace, and a `.claude/settings.json` naming one resolves to nothing --
silently, which is the shape this family has met twice before. `INSTALL.md` carries the procedure as its own
section: uninstall, refresh, install `dkj-policy@` (and `dkj-policy-bwj@` in BWJ's two store repos), restart.

Renaming the FOLDER is optional and nothing breaks if it is left alone -- but re-running
`adopt-workflow-folder` in a repo that has not renamed it writes a second folder beside the one holding its
history, so the half-way state is the one to avoid. A repo that STATED `Get-ChangelogPath` or a release-note
root in its own `repo-config.ps1` repoints that answer in the same commit as the `git mv`; a repo on the
computed default is carried across for free.

One accepted cost, named because the register already documents the class: `check-connectors` resolves each
registered plugin id against `marketplace.json`, reports one the marketplace no longer declares as `[INFO]`,
and then SKIPS that plugin's block. So until each consumer migrates and `connectors/` catches up, their
workflow plugin cannot be reported as version-drifted. That is exactly what #978 recorded after #886, and it
is left as an `[INFO]` for the same reason it was then: making it an error re-opens four false alarms.

**Score:** 5

#### Pull Request

rename contributing-davekjohn to dkj-policy, and bwj-codex to dkj-policy-bwj
