## feat/1769-marketplace-rename-source

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Issue 1769 fase 1: build the source-side rename `claude-code-specialists` -> `dkj-claude-plugins`
on this branch and **do NOT merge** -- the merge is the coordinated flag day in fase 3. The branch is
a staging area; once the session-breaking edits land (see below) it is no longer a usable working
environment, so those come last and fase 2 consumer branches / review fixes happen before them or
off `main`.

#### Scope of fase 1

- `.claude-plugin/marketplace.json` `"name"` -- the single source of truth; `Get-MarketplaceName`
  (`scripts/lib/release-lib.ps1`) derives from it, so most readers follow automatically.
- The ~281 literal `@claude-code-specialists` refs in prose / comments / printed install-command
  strings across `scripts/**`, `plugins/**`, docs, `INSTALL.md`, `UNINSTALL.md`, `README.md`,
  `dkj-policy/README.md`. **Skip** `dkj-policy/releases/**` -- the #1526 / language-layers
  historical carve-out.
- The byte-identical `plugins/**/scripts/` mirrors kept in lockstep with `scripts/lib/**` and
  `scripts/**` (shared-scripts drift lint). `.ps1` files stay ASCII.
- `bootstrap.ps1` / `teardown.ps1`.
- `.claude/rules/language-layers.md`, `CLAUDE.md` "Repo citation" section, `scripts/repo-config.ps1`
  carve-out comment (r. 49-62) -- rewrite so it states the rename is done, not pending.
- `connectors/` -- **see the open decision below.**
- `.claude/settings.json` self-consumption: the 6 `enabledPlugins` keys, the `github` marketplace
  source key, the `repo` field. **Session-breaking on this branch** -- the local marketplace clone
  stays registered as `claude-code-specialists` until the fase 3 re-add, so a session started on
  this branch after this edit loads no plugins. Last commit.
- The live `@`-import paths (`~/.claude/plugins/marketplaces/claude-code-specialists/...`) in
  `SPECIALISTS.md`, `.claude/specialists/lenses/{01-01,05-05,05-06}-extension.md`,
  `.claude/specialists/README.md`, `INSTALL.md`, `UNINSTALL.md`, `README.md`, the
  `adopt-dkj-policy-bwj` skill. **Also session-breaking** for the same reason. Last commit, with
  settings.json.
- ~91 test suites green (the issue's "~19" is stale) + `check-plugin-integrity.ps1`.

#### Blast radius -- measured 2026-09-10

Flipping only `marketplace.json` `"name"` and running all 91 suites: **exactly one suite fails --
`connectors.tests.ps1` (exit 1)**, on the `[UNLISTED]` / retired-id checks. `check-connectors.ps1`
compares a consumer's enabled `plugin@marketplace` id against `$ThisMarketplaceName` (from
`marketplace.json`); the fixtures build ids with `@claude-code-specialists`, so the ordinal compare
at `check-connectors.ps1:655` stops matching. Every other suite (`check-plugin-integrity-commands`
included -- it validates `--scope project`, not the name) stays green, so the prose/command-string
refs are drift to be cleaned, not gate failures.

#### Open decision -- connector-file rename timing (for Dave)

The plan lists `connectors/*.json` (6x) + renaming `connectors/claude-code-specialists.json` under
fase 1. But `connectors/README.md` r. 107-119 is explicit doctrine: **a renamed id is not written
into `plugins[].id` until the consumer itself has migrated** -- doing it early makes the register
"a false alarm about a migration nobody performed". The `@<marketplace-name>` half is part of that
id, and no consumer does the marketplace re-add before flag day (fase 3). The self-connector is the
same: this repo re-installs itself on flag day too.

- Option A (follows the doctrine): connectors move to **fase 3, per consumer**, alongside each
  consumer's own PR. Fase 1 leaves `connectors/` untouched except `connectors.tests.ps1` +
  `check-connectors.ps1` machinery, which must track `marketplace.json`.
- Option B: rename connectors in fase 1 anyway; register is knowingly "ahead of reality" until flag
  day.

Recorded as an inconsistency between the plan (2026-09-10) and standing doctrine. **Dave chose A
(2026-09-10):** connectors move to fase 3, per consumer.

#### Bare-name `claude-code-specialists` literals -- a second class the `@`-sweep does not reach

Beyond `<plugin>@claude-code-specialists`, the bare string `claude-code-specialists` appears in three
distinct roles that rename on different schedules:

1. **Marketplace name** -- `claude plugin marketplace update claude-code-specialists` command strings
   (`INSTALL.md` ~15x, `dkj-policy/README.md`, `plugins/dkj-policy/README.md`,
   `specialists-init/SKILL.md`, `UNINSTALL.md`), `check-plugin-integrity.ps1:3` docstring, and stale
   test literals (`cut-release-drive.tests.ps1:182`, `release-lib.tests.ps1:1467`,
   `fresh-consumer.measure.ps1:78`, `bootstrap-drift.tests.ps1:725-726`,
   `check-plugin-integrity-commands.tests.ps1` fixture strings). **Fase 1** -- none is a gate failure
   (suite + lint green without them) but all are stale post-rename. `connector-sessioncheck.ps1:177`
   (`$mp.name -eq ...`) and the four fixture marketplace-name vars are the functional subset and are
   already done.
2. **Repo slug** -- `# claude-code-specialists`, section anchors
   `#specific-to-this-repo-claude-code-specialists`, lens headers, `SECURITY.md`, `README.md:1`.
   **Drift per #1526** -- correct-on-edit, plus the slug rename itself is fase 3.
3. **Marketplace-clone dir path** -- `~/.claude/plugins/marketplaces/claude-code-specialists/`,
   `cache\claude-code-specialists`, `.claude/plugins/claude-code-specialists/` path segments.
   **LAST** (with `.claude/settings.json` and the `@`-import paths) -- session-breaking until the
   flag-day re-add.

#### Slug prose refs

The ~830 `DKJ-Solutions/claude-code-specialists` / `DaveKJohn/claude-code-specialists` prose
citations: **let drift, correct-on-edit**, per #1526 (the slug redirect holds as long as nothing is
created at the old path). Not swept in fase 1 unless Dave says otherwise.

#### The sweep is not once-and-for-all -- every catch-up merge re-imports literals

Measured on the September 10 catch-up merge from `main` (it brought 39 files): two fresh
`@claude-code-specialists` literals arrived in `scripts/tests/measure-skill.tests.ps1`, written on the
trunk after this branch's own sweep. `main` keeps producing them and will go on doing so for as long
as this branch stays a staging area -- which is by design, until fase 3. So the sweep is a step of the
FLAG DAY as well as of fase 1: re-run it on the final catch-up merge, immediately before the fase 3
merge, and do not treat a green run from an earlier day as proof.

### CREATE

- [x] Dave's word on the connector-rename timing -- **A**: connectors deferred to fase 3
- [x] `marketplace.json` `"name"` -> `dkj-claude-plugins`
- [x] `check-connectors.ps1` + `connectors.tests.ps1` fixtures track the new name; suite green
- [x] Bulk rename literal `@claude-code-specialists` -> `@dkj-claude-plugins` in `scripts/**` +
      `plugins/**/scripts/` mirrors (ASCII-safe; mirror byte-identity + script-contract green),
      `bootstrap.ps1`. `teardown.ps1`: `@`-refs swept AND its `-match 'specialists'` settings.json
      detection fixed to recognise both marketplace names (#1769)
- [x] Bulk rename literal `@claude-code-specialists` in docs / manuals / agent-defs / skills /
      `INSTALL.md` / `UNINSTALL.md` / `README.md` / `dkj-policy/README.md` -- NOT
      `dkj-policy/releases/**` (the #1526 / language-layers carve-out)
- [x] Functional marketplace-name literals: `connector-sessioncheck.ps1:177` + the four fixture
      marketplace-name vars (`connectors.tests.ps1`, `roster-sync.tests.ps1` x2, `sync-roster.tests.ps1`)
- [x] `check-plugin-integrity.ps1` green (0 errors) + all 91 suites green + `shared-scripts` +
      `script-contract` green
- [x] Remaining bare-name **marketplace-name** literals (fase 1, not gate failures): the
      `marketplace update claude-code-specialists` command strings in `INSTALL.md` / `UNINSTALL.md` /
      the two READMEs / `specialists-init/SKILL.md`, `check-plugin-integrity.ps1:3` docstring, and the
      stale test literals listed in the PLAN note
- [x] `.claude/rules/language-layers.md` + `CLAUDE.md` "Repo citation" + `scripts/repo-config.ps1`
      carve-out comment (r. 49-62) -- rewrite so it states the rename is in progress on this branch,
      not merely decided
- [~] connectors: deferred to fase 3 per Dave's decision A -- `connectors/*.json` (6x) +
      `connectors/claude-code-specialists.json` rename + `connectors/README.md` move with each
      consumer's own migration
- [ ] Re-run the `@`-sweep on the LAST catch-up merge, immediately before the fase 3 merge -- `main`
      keeps writing new `@claude-code-specialists` literals while this branch waits (see PLAN)
- [ ] FLAG DAY: rewrite the two staging paragraphs, which go false at the moment of the merge --
      `CLAUDE.md`'s "A second rename is pending on this same citation" (the slug rename is no longer
      pending) and `scripts/repo-config.ps1`'s "FASE 1 IS BUILT, NOT MERGED" (it merged). Both say
      "does not merge until fase 3" in as many words, so neither degrades quietly; found by Edith on
      review, September 10, 2026
- [x] Victor (scripts) + Edith (docs/links) review, September 10, 2026 -- four half-landed renames
      repaired (plus the same fault in `check-report-lib.ps1` and its two mirrors, which the review
      missed), one test gap closed by Tycho, and the sweep's own over-reach corrected by Tessa across
      15 places in 5 files: dated transcripts and migration tables' OLD columns keep the retired name.
      The branch stays open until fase 2 is built
- [ ] FLAG DAY: the three migration procedures in `INSTALL.md` need a marketplace remove+add step
      between their uninstall and install halves, or they cannot run at all after the rename --
      filed as [#1801](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1801) because the
      repair defines part of the procedure and interacts with fase 5's release notes- [ ] LAST (session-breaking on this branch until flag day): `.claude/settings.json` self-consume
      keys + `github` source + `repo`
- [ ] LAST (session-breaking): live `@`-import paths + clone-dir path segments
      `marketplaces/claude-code-specialists/` -> `marketplaces/dkj-claude-plugins/`,
      `.claude/plugins/claude-code-specialists/`, `cache\claude-code-specialists`

### TEST

### DEPLOY: feat/1769-marketplace-rename-source

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

Rename the marketplace to dkj-claude-plugins (source side)

