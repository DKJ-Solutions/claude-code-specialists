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

Recorded as an inconsistency between the plan (2026-09-10) and standing doctrine. Default pending
Dave's word: **A**.

#### Slug prose refs

The ~830 `DKJ-Solutions/claude-code-specialists` / `DaveKJohn/claude-code-specialists` prose
citations: **let drift, correct-on-edit**, per #1526 (the slug redirect holds as long as nothing is
created at the old path). Not swept in fase 1 unless Dave says otherwise.

### CREATE

- [ ] Dave's word on the connector-rename timing (A or B above); adjust the two connector steps below
- [ ] `marketplace.json` `"name"` -> `dkj-claude-plugins`
- [ ] `check-connectors.ps1` + `connectors.tests.ps1` fixtures track the new name; suite green
- [ ] Bulk rename literal `@claude-code-specialists` -> `@dkj-claude-plugins` in `scripts/**` +
      `plugins/**/scripts/` mirrors (ASCII-safe, mirrors byte-identical), `bootstrap.ps1`,
      `teardown.ps1`
- [ ] Bulk rename literal `@claude-code-specialists` in docs / manuals / agent-defs / skills /
      `INSTALL.md` / `UNINSTALL.md` / `README.md` / `dkj-policy/README.md` -- NOT
      `dkj-policy/releases/**`
- [ ] `.claude/rules/language-layers.md` + `CLAUDE.md` "Repo citation" + `scripts/repo-config.ps1`
      carve-out comment
- [ ] connectors: per the timing decision -- content of `connectors/*.json` (6x) + `git mv`
      `connectors/claude-code-specialists.json` -> `dkj-claude-plugins.json` + `connectors/README.md`
- [ ] `check-plugin-integrity.ps1` green + all 91 suites green
- [ ] Victor (scripts) + Edith (docs/links) review -- branch stays open until fase 2 is built
- [ ] LAST: `.claude/settings.json` self-consume keys + `github` source + `repo`
- [ ] LAST: live `@`-import paths `marketplaces/claude-code-specialists/` ->
      `marketplaces/dkj-claude-plugins/`

### TEST

### DEPLOY: feat/1769-marketplace-rename-source

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

Rename the marketplace to dkj-claude-plugins (source side)

