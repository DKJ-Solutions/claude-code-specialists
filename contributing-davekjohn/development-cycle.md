## Development cycle: `fix/seam-lib-folder-name-v1` · 20260826-214918

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issue #948: `scripts/lib/seam-lib.ps1` composes every isolated default out of `Get-WorkflowFolderName`,
and four statements in the same file still name `workflow-davekjohn/` as if it were the answer -- in the
present tense, so the published-record exception does not cover them. The issue asks for a sweep of the
rest of the tree in the same pass, because the #886 rename almost certainly left more.

#### What the sweep measured, before anything was scoped

The report's count is four lines in one file. The subject is larger and the difference is worth stating:
**361 occurrences across 51 files** (tracked, this document excluded), of which all but ten are correct
and must not be swept.

- **Correct, deliberately naming the prior folder:** `Get-WorkflowFolderName` itself and its
  `$allowedRoots` list, `scripts/repo-config.ps1` + the generated `config-blueprint.json`,
  `scripts/sync/check-script-contract.ps1`, `plugins/teams/team-alpha/skills/specialists-init/bootstrap.ps1`
  (all of these scan or accept BOTH names on purpose), `scripts/tests/seam-lib.tests.ps1` (the asserts that
  pin the pre-rename name), and `scripts/lib/entry-scaffold-lib.ps1` (its `Prior*` keys and a verbatim
  quoted 2026-08-09 measurement).
- **Published record, out of scope:** `CHANGELOG.md` and the archived notes under
  `contributing-davekjohn/releases/{audience,changelog,github}/`.
- **Register data, out of scope:** the `workflow-davekjohn@claude-code-specialists` plugin id in the three
  `connectors/*.json` manifests. That register records what a consumer HAS, so the old id there is a
  measurement rather than a stale statement.

Ten live statements were left, in three files.

### CREATE

- [x] `scripts/lib/seam-lib.ps1`, four statements: the synopsis, `Get-DefaultChangelogPath`, and
      `Get-DefaultReleaseHistoryPath` twice. Each now names `Get-WorkflowFolderName` rather than either
      folder name, which is the only form that cannot go stale on the next rename.
- [x] `plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md`, two statements: where the
      branch's one file lives, and the `/goal` example that names its path.
- [x] `contributing-davekjohn/releases/README.md`, four statements: the plugin's own name, the
      `releases/README.md` path a consumer is told to write, and the two `releases/page/` paths --
      the second of which `.gitignore` already spells `contributing-davekjohn/`.
- [x] `plugins/workflows/contributing-davekjohn/scripts/lib/seam-lib.ps1` regenerated via
      `scripts/sync/build-shared-scripts.ps1` (mirror, not a second edit).

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors, no findings across all 29 checks.
- [x] `scripts/tests/seam-lib.tests.ps1` -- 19/19 asserts pass, including the four that pin the
      pre-rename name, which is the proof the behaviour did not move with the prose.
- [x] Re-swept the tree: the only remaining occurrences are the ones enumerated in PLAN as correct.

### DEPLOY: `fix/seam-lib-folder-name-v1`

`scripts/lib/seam-lib.ps1` is the file whose entire job is composing the workflow folder's name, and four
of its own statements still named the pre-rename folder as the answer. A reader who trusted the prose next
to `Get-WorkflowFolderName` -- whose docstring argues at length that hardcoding either name is wrong --
concluded the default resolves inside `workflow-davekjohn/`. The four are rewritten to name the function
instead of a folder, so the next rename cannot make them wrong again.

The sweep the issue asked for found six more in two documents: `DEVELOPMENT-portable.md`, which ships to
every consumer and told them the branch's one file lives at a path the scaffolder no longer writes, and
`contributing-davekjohn/releases/README.md`, which named the plugin by its retired name and pointed at two
`releases/page/` paths `.gitignore` already spells the other way.

No behaviour changed and nothing was added: 10 statements in 3 files, plus the regenerated mirror. The
other 347 occurrences of the old name in this tree were measured and deliberately left -- the dual-name
scanners, the tests that pin the pre-rename answer, the published record, and the connector register.

**Score:** 2

#### What makes this deploy extra special

Nothing a subscriber acts on: this is documentation prose in a shared script and two workflow documents,
with no change to what any function returns.

**Score:** N/A

#### Pull Request

seam-lib and two docs name the pre-rename workflow folder in live statements
