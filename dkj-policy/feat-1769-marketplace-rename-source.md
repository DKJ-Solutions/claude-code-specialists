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

**AMENDED the same day, for the SELF-record only (Dave, 2026-09-10).** A stands for the five consumer
records. It does not stand for `connectors/claude-code-specialists.json`, because the doctrine's
objection needs two parties -- a register claiming a migration its consumer has not performed -- and
here the register and the consumer are the same tree: this repo's `.claude/settings.json` and its own
record land in the same commit. Leaving it behind had a measured price rather than a theoretical one
(see TEST), and the carve-out is written into `connectors/README.md` beside the rule it bounds, so the
next reader does not meet a doctrine the tree contradicts.

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
- [~] connectors, the five CONSUMER records: still deferred to fase 3 per Dave's decision A --
      `life-hub.json`, `thumbnail-generator.json`, `smartwatchbanden.json`, `xoxowildhearts.json`
      and `djcylow-react.json` migrate alongside each consumer's own PR, on the day that consumer
      actually reinstalls
- [x] connectors, the SELF record: amendment to decision A, for this one file and no other (Dave,
      September 10, 2026). `connectors/claude-code-specialists.json` ->
      `connectors/dkj-claude-plugins.json`, its six ids and its `repo` field to `dkj-claude-plugins`,
      a dated `MIGRATED 2026-09-10 (#1769)` note in the established style, the carve-out written into
      `connectors/README.md`'s own doctrine so the next reader is not left with a rule the tree
      contradicts, plus the two places that name the file: `connectors.tests.ps1` (the case 6 path and
      four stub strings) and `INSTALL.md` r. 299. The doctrine's objection -- "a false alarm about a
      migration nobody performed" -- needs two parties, and here the register and the consumer are one
      tree: `.claude/settings.json` and this record land in the same commit. The alternative was
      opening the flag-day PR with `-SkipTests`
- [x] The business mirror follows the source's new name (Dave, September 10, 2026), recorded in
      `scripts/repo-config.ps1` where the August 14 carve-out sits. It was carried as an open fase 4
      question, and that framing did not survive reading `publish-to-business.ps1`: it never assigns
      `$manifest.name` and has no name parameter, so "the mirror follows" is what the first publish
      after this branch merges DOES, and "the mirror keeps the old name" would have been a build.
      Recorded with what it costs -- the BWJ colleagues on Claude Enterprise key on the old name too
      and are in no fase 2 list, so fase 5's release notes are where their migration reaches them
- [x] Catch-up merge from `main` (14 commits, through #1811) and the `@`-sweep re-run, September 10,
      2026. **Zero new `@claude-code-specialists` literals** -- the class the step was written for was
      empty. One conflict, in `connectors.tests.ps1`, where #1808's new `$Repo` fixture parameter met
      this branch's renamed `$Plugin` default; both kept
- [x] THE SLUG RENAME LANDED FIRST, out of the plan's order and to this branch's benefit (Dave,
      September 10, 2026): `DKJ-Solutions/claude-code-specialists` ->
      `DKJ-Solutions/dkj-claude-plugins`, i.e. fase 3 step 1 before the source merge rather than in
      the same movement. `origin` repointed in the one checkout on this machine that named the old
      slug. So the **functional** slug references follow it here, while the ~830 prose citations still
      drift per #1526: `Get-RepoName`, the `repository:` line the two consumer scaffolders write (plus
      their mirrors), the docstring quoting that block, `check-consumer-drift`'s synopsis, the
      `-RepositoryName` test call sites, the regenerated `config-blueprint.json`, and
      `connector-sessioncheck.ps1`'s source-checkout candidates -- additive, since a folder named after
      the old slug cannot be renamed without unlinking its install record
- [x] AND THE SWEEP FOUND A REAL GAP RATHER THAN DRIFT, which is why the step above is not just a
      rename. `consumer-runner-lib.ps1` finds a scaffolded runner by matching the **name half** of its
      `repository:` line against `Get-RepoName`. Every consumer scaffolded before today writes
      `claude-code-specialists` there; the runner keeps working, because GitHub answers the redirect --
      so the only thing the rename breaks is the **guard**, which would then report nothing about any
      existing consumer. A consumer nothing is reported about reads as clean, which is precisely the
      silence #1805 was filed to end, arriving through the detector built to end it. Repaired the way
      the check already handles the old OWNER (its scenario 12c), one axis over: `Get-RetiredRepoNames`
      in `scripts/repo-config.ps1` states the names this repo has been renamed away from,
      `Get-SharedScriptReference -RepositoryName` takes one or many, and `check-connectors.ps1` passes
      the current name plus the retired ones. New scenario **12h** proves the retired name still fires;
      12a and 12b now name the current one, so both directions are held. The seam is source-repo-only
      and correctly absent from the script contract: neither file ships to a consumer
- [x] FLAG DAY, the `CLAUDE.md` half -- done the moment the slug existed. Its "Repo citation" section
      now names `DKJ-Solutions/dkj-claude-plugins`, sets out **both** retired halves (owner, September 2;
      name, September 10) with the rule that neither old path may ever be recreated, records that the
      retired name is data the tooling reads rather than only prose to correct, and states the test that
      separates the two: **something that RESOLVES the name may not lag, something that merely prints it
      may**
- [x] FLAG DAY, the remaining half -- resolved by REWORDING rather than by scheduling.
      `scripts/repo-config.ps1` said "FASE 1 IS BUILT, NOT MERGED", an honest sentence that goes false
      at the merge, so this step was to correct it on the day. **That step could not have been run.**
      `open-pr.ps1` refuses to push while a step above DEPLOY is unresolved, so the edit was only
      reachable after the last moment it could be made, and the flag day would have opened with a gate
      deadlock. The paragraph is now written to be true on both sides of its own merge, and it records
      why: a sentence that has to be corrected by the act it describes is a sentence to reword, not a
      step to schedule. Nothing on this branch now waits for the flag day
- [x] Victor (scripts) + Edith (docs/links) review, September 10, 2026 -- four half-landed renames
      repaired (plus the same fault in `check-report-lib.ps1` and its two mirrors, which the review
      missed), one test gap closed by Tycho, and the sweep's own over-reach corrected by Tessa across
      15 places in 5 files: dated transcripts and migration tables' OLD columns keep the retired name.
      The branch stays open until fase 2 is built
- [x] The three migration procedures in `INSTALL.md` now carry a `marketplace remove claude-code-specialists`
      + `marketplace add DKJ-Solutions/dkj-claude-plugins --scope project` step between their uninstall
      and install halves, plus a kept `marketplace update dkj-claude-plugins` before the installs (the
      lint's refresh-next-to-install rule wants it and it is idempotent) -- without it step 3's install
      resolves against a marketplace the reader's machine does not know
      ([#1801](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1801)). Dave's word,
      September 10, 2026: fold into this branch rather than defer to flag day -- it is the same
      post-rename doc content as the `@`-id swap already done here, not session-breaking and not stale
      at merge. The four decision points in #1801 resolved conservatively: three procedures keep their
      shape; re-add sits between uninstall and install; slug is the post-#1769 `DKJ-Solutions/dkj-claude-plugins`
      (per `CLAUDE.md`'s own updated "Repo citation" note); `INSTALL.md` is canonical and fase 5's notes
      link to it. `UNINSTALL.md` checked -- no equivalent gap: it is a one-directional teardown that
      never reinstalls, so there is no re-add to be missing, and its `marketplace remove` name was
      already swept. Issue stays open until this branch merges on flag day
- [x] LAST (session-breaking on this branch until flag day): `.claude/settings.json` self-consume
      keys + `github` source + `repo`
- [x] LAST (session-breaking): live `@`-import paths + clone-dir path segments
      `marketplaces/claude-code-specialists/` -> `marketplaces/dkj-claude-plugins/`,
      `.claude/plugins/claude-code-specialists/`, `cache\claude-code-specialists`

### TEST

**Before the catch-up merge and the LAST commits: lint 0 errors, all 91 suites green** (407s), including
the cases that arrived with #1804.

**After the LAST commits: lint 0 errors, 90 of 91 green.** `connectors.tests.ps1` failed on one assert --
case 6, *"self-manifest (workshop consumes itself): exit code 0"*. That case runs `check-connectors.ps1`
against the **real** self-connector, which still named this repo's plugins as
`<plugin>@claude-code-specialists` while `.claude/settings.json` had said `@dkj-claude-plugins` since the
LAST commit. The check saw a consumer enabling something other than what its own register claimed, which
is exactly what it exists to report -- correct behaviour, not a defect, and the direct consequence of
decision A deferring `connectors/**` to fase 3.

**Resolved September 10, 2026 by amending decision A for the self-record alone (Dave), and the suites are
now 91 of 91 green** -- lint 0 errors, `open-pr.ps1 -GatesOnly` reporting *"all 91 suites passed in 371s
(16 lanes)"*. The register, `connectors/README.md`'s doctrine and the two places naming the file moved in
the same commit as the settings they describe. **The amendment is the self-record and nothing else**: the
five consumer records still migrate on the flag day with their own PRs, and the reason it is safe here and
nowhere else is that the register and the consumer are one tree, so nothing is claimed ahead of anything.

**What it bought, stated because the alternative was cheap to take and expensive to have taken.**
`open-pr.ps1` blocks on a failing suite, so the flag-day source PR would otherwise have opened with
`-SkipTests` -- the test gate switched off on the largest merge this repo has made, where one red suite is
indistinguishable from ten and nothing in the PR records that anything was skipped.

**Not proven by this run, and deliberately so:** the machine side. `installed_plugins.json` on this machine
still holds all six records under the old marketplace name until the flag-day re-install (#1802), so a
version check from this checkout reads this register's ids as not installed here. That is the truth about
the machine, not a fault in the file, and it goes green with the re-install rather than before it -- the
same shape as the consumers' nine red suites and their CI gates.
### DEPLOY: feat/1769-marketplace-rename-source

This marketplace is called `dkj-claude-plugins`. The name is the key half of every
`<plugin>@<marketplace>` id, so it is stated once in `.claude-plugin/marketplace.json` and read from
there by `Get-MarketplaceName` -- and everything that had spelled it out instead now follows: the
`@`-ids across `scripts/**`, the byte-identical `plugins/**/scripts/` mirrors, `bootstrap.ps1` and
`teardown.ps1`, the manuals, agent defs, personas and skills, the printed
`claude plugin marketplace update` command strings, `INSTALL.md` and `UNINSTALL.md`, and the live
`@`-import paths into the marketplace clone. This repo consumes itself, so its own
`.claude/settings.json` enables all six plugins under the new name and its entry in `connectors/`
moved with it, in the same commit rather than a later one -- the register and the consumer being one
tree here is the whole reason that is honest.

The repository itself was renamed the same day, ahead of this merge, and the two halves are not the
same job. **What resolves the name follows it; what merely prints it may lag.** So `Get-RepoName`, the
`repository:` line the two consumer scaffolders write, the matcher that finds it again, the regenerated
config blueprint and the session check's candidate paths are all current, while the ~830 prose citations
stay correct-on-edit per #1526 -- both spellings resolve, and a sweep would buy prose consistency at the
price of an unreviewable diff.

**And the rename broke one guard silently, which is the part worth reading twice.**
`consumer-runner-lib.ps1` finds a scaffolded CI runner by matching the name half of its `repository:`
line. Every consumer scaffolded before the rename names the old one; those runners keep working, because
GitHub answers the redirect -- so nothing fails, and the check simply stops finding them. A consumer
nothing is reported about reads exactly like a consumer with nothing wrong, which is the silence #1805
was filed to end, arriving through the detector built to end it. `Get-RetiredRepoNames` now states the
names this repo has been renamed away from, the matcher takes one or many, and a new scenario holds both
directions. The list only grows.

**Score:** 5

#### What makes this deploy extra special

**Every existing install stops resolving, and no consumer can be fixed by an update.** An
`enabledPlugins` key is `<plugin>@<marketplace-name>`, and there is no redirect for a marketplace name
the way there is for a git slug -- so the old key matches nothing and the plugin silently does not load.
The route out is per machine **and** per checkout, because an install record is keyed on the folder path:
uninstall the old ids, remove the old marketplace, add the new one, refresh, install again.
`INSTALL.md` carries that sequence for each migration shape and is the canonical copy of it.

Read the flag day as one movement rather than a release: the five consumer repositories were prepared on
their own branches first and merge alongside this one, and the re-installs follow immediately -- because
between this merge and the last re-install, every consumer that has not been brought over is dark.

**Score:** 5

#### Pull Request

Rename the marketplace -- and the functional half of the repo name -- to dkj-claude-plugins
