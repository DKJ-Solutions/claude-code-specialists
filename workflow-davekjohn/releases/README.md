# Releases

Releases in this repo are cut by the shared release workflow: the tier model, what a release must earn,
the release documents, and how one is cut. **That process is not this repo's own** — it is what the
`workflow-davekjohn` plugin does, in every repo that enables it, and it is described once, with the plugin:

📄 **[Releases — the portable half](../../plugins/workflows/workflow-davekjohn/RELEASES-portable.md)**

Read that first. **This page is this repo's set of answers to it**: the seam values in force here, the
local decisions, the measured instances behind the portable rules, and the full list of releases actually
cut. The release block in [`CHANGELOG.md`](../../CHANGELOG.md) points here for everything but the current
version.

The split is the same one [`CONTRIBUTING.md`](../CONTRIBUTING.md) already uses: the portable half travels
with the plugin, the local half stays in the repo. Until August 13, 2026 both halves lived on this page
behind a horizontal rule, and two consumers hand-maintained a 4,154-word verbatim mirror of the top half
because that was the only way to keep it from drifting — inbound
[#646](https://github.com/DaveKJohn/claude-code-specialists/issues/646), which is also where the
measurement lives.

---

## claude-code-specialists (REPLACE WHEN MIRRORING)

### How to build your own version of this page

> **To an agent setting this workflow up in another repo:** do not copy this page's process half — there
> is none any more. The process ships with the plugin as
> [`RELEASES-portable.md`](../../plugins/workflows/workflow-davekjohn/RELEASES-portable.md) and stays current
> through plugin updates, which is exactly what a hand-maintained mirror cannot do (two consumers measured
> that cost before this split — inbound #646). Your own `workflow-davekjohn/releases/README.md` (the
> `adopt-workflow-folder` skill scaffolds it) holds only what this section
> holds: a pointer to the portable page, your seam values, your local decisions, and your release list —
> started **empty** rather than carrying these versions, dates and PR references across. Do not delete the
> release-list section: a page without it has nowhere to put your history, and the next release will write
> a row into a document that never declared where rows go. If your page today still carries a hand-copied
> mirror of the process above a horizontal rule, delete that half and keep your own — the plugin's page is
> the same text with a maintainer.

### Seam values in force here

**`Get-ReleasePluginTier` is true** — this repo is the marketplace source, so every cut bumps all
`plugin.json` versions in lockstep and the current version is read from a `plugin.json`. **A repo that
publishes no plugins answers false**, skips step 1 of the cut entirely, and reads its current version from the
newest `vX.Y.Z` tag; the release is then the tag and the documents, nothing else.

**`Get-ReleaseAudienceTier` is `2`** — this repo is a service its consumers subscribe to, so the
hand-written note's *For consumers* section is written for them. A repo that delivers to management or a
commissioner answers `1` and never writes that section.

Every release document groups **per major** (`3.x`) — the consumer this model came from folders per minor.
`Get-ReleaseHistoryPath` answers `workflow-davekjohn/releases/README.md` — this page — since the list lives
here; it sat at the shared default (`releases/README.md`) until the hand-kept release pages moved into the
workflow folder on August 14, 2026, and that default itself deliberately did not move with them. Since the hand-written note merged into one document (August 10, 2026), `cut-release.ps1` drafts that
note itself before it writes this page's **Version cell**, so the cell points straight at it — the hand-written
note where the bump wrote one, the development notes on a patch — with nothing repointing it afterwards.

**Six changelog seams retired on August 5, 2026 and are therefore not stated here either.**
`Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` (#178) named changelog section headings, and
the document has none; `Get-ReleaseCategoryTitles` labelled the release-notes categories, and the grouping is
gone with the branch-prefix guess behind it; `Get-ReleaseLiveMarker`, `Get-ReleaseHistoryMode` and
`Get-ChangelogReleaseWording` (#462) all described the release **block** a cut used to append, and a cut
writes none. A consumer that still defines one is unaffected — nothing calls them.

**`Get-ReleaseMajorMinMinors` is `10`.** Held against this repo's own history that is roughly right rather
than arbitrary: the `1.x` line ran to `1.18` and the `2.x` line to `2.16` before each was recapped into a
major.

**`Get-LintScript` is [`scripts/lint/check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1),
which is what the release route runs here.** It used to carry a check written *for* this route — check 9,
guarding that every plugin's `RELEASE.md` card existed and that its version matched `plugin.json`. Both the
card and the check were retired on August 8, 2026: with no second statement of a plugin's version, there is
nothing left to compare `plugin.json` against. The gate is still named here because it is what the cut runs;
the rest of its checks are unaffected.

**What a non-English consumer loses with `Get-ChangelogReleaseWording`, stated rather than glossed over.**
That seam existed because those four strings were the most visible generated output in `CHANGELOG.md`, and
inbound #462 asked for them to be repo-owned. The capability is not being taken away — the **output** is
gone. What replaced it is the intro's own pointer to this page: hand-written prose in a file the repo owns
outright, so it needs no seam to be in their language. It simply is.

### Local decisions

**A GitHub Release is published at every release, patch included** (Dave, August 4, 2026). Two consequences
of that "every release" half: patches now get one — so `v2.6.1` and `v2.7.1`, cited here for years as
examples of releases deliberately without one, describe the **old** rule and are left standing as history
rather than as guidance. And a patch gets no hand-written note at all by construction, so on a patch the
attachment list is the development notes alone.

> **Named `davekjohns-workshop` until August 3, 2026.** The marketplace was renamed with the
> [one-product decision](../../README.md#one-product-one-repository); the older notes under `development/`
> still carry the old name and are deliberately not rewritten — they are history.

> **Markdown only.** For one release (v3.2.0) the tier also generated a print-ready `.html` beside the
> `.md`. That is gone and is not coming back — Dave's decision, August 3, 2026. A PDF, if ever needed, comes
> from rendering the markdown with a tool built for it rather than from a partial HTML renderer maintained
> here. `v3.2.0`'s `.html` was removed from `main`; the `v3.2.0` **tag** still contains it, because a tag is
> a record of a moment and is not rewritten.

### Measured instances behind the portable rules

- **The branch prefix does not predict impact here**, and this is the measurement the whole tier model rests
  on. Held against v3.2.0's 19 entries, the most consequential change for a consumer — renaming the
  marketplace, which breaks every existing install — arrived on a `chore/` branch. While the consumer
  document was assembled from `Feat`/`Fix` that change landed *below* the remove-before-publishing marker, so
  the guidance here used to be "expect to promote `Docs`/`Chore` items". Since August 5, 2026 there is nothing
  to promote: the entry's author declares the tier, and the branch prefix decides nothing but the category
  heading an entry is grouped under. Kept as history because it is the evidence for that change, not a rule
  still in force.
- **Both of this repo's majors were already recaps**, which is what the 10-minor rule now requires up front:
  `v2.0.0` consolidated v1.0–v1.18 and `v3.0.0` consolidated v2.2.0–v2.16.0, both written that way after the
  fact. The rule states the practice rather than inventing one.
- **The per-plugin `CHANGELOG.md` and `RELEASE.md` cards were retired against a measurement** (August 8,
  2026), which is the source half of the retired step 3 in the portable page: a consumer receives this
  marketplace source as a git clone of the whole repository, so `CHANGELOG.md` and this entire `releases/`
  tree already sit at `~/.claude/plugins/marketplaces/<marketplace>/` — the cards were ten files and
  11,684 lines, a second copy free to disagree with the original, which is exactly what lint checks 9
  and 17 existed to police.
- **The attachment-filename collision was measured at `v3.3.0`**, where the second upload returned
  `HTTP 404` on `…&name=3.3.0.md`.
- **The written-notes route has a worked instance**:
  [PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) shipped `v3.2.0`'s internal note
  post-tag, gates green and entry folded, with nothing about being post-tag causing friction.
- **The closing step used to sit directly after the tag** and was moved to last on August 4, 2026. It had
  worked only because the body was then the consumer document file the script itself had already generated.

### The release list

**Every release ever cut, newest first, grouped by major version.** This is the full record:
`CHANGELOG.md`'s release block names only the current version and points here for the rest, so nothing else
in the repo carries this list.

New releases are added to the current major's table, the top one. That is why **opening a new major's
section is a deliberate act, taken before the release is cut**: `cut-release.ps1` inserts the row after the
first release table it finds, so without a section for the new major a `v4.0.0` row would be filed under
`3.x` with nothing erroring. A guardrail refuses that rather than doing it quietly.

Three things about the structure below are load-bearing rather than stylistic, and all three are why this
list sits at the **end** of the page:

- **The inserter takes the first release table in the whole document**, so any table introduced above these
  would silently start receiving the rows. That is the one thing to check when adding a section anywhere on
  this page.
- **The guardrail reads the last `<n>.x` heading above that table**, so those headings must stay
  recognisable. The heading **level** may change — `###` and `####` are both accepted, because how deeply
  the list is nested is a layout choice the repo owns — but the `<n>.x` text is not decoration.
- **The table header is described in prose and quoted nowhere on this page**, because the inserter matches
  that exact line and a document explaining a pattern should not be one edit away from triggering it.

#### 4.x

| Version | Date | Type | Title |
|---|---|---|---|
| [4.11.0](audience/4.x/4.11.0.md) | 2026-08-15 | Minor | A prompt inbox for assignments, and a third of the always-on layer moved off the load path |
| [4.10.0](audience/4.x/4.10.0.md) | 2026-08-15 | Minor | The Claude App marketplace publishes a chosen subset, and an inbound report's subject is verified before it is routed |
| [4.9.0](audience/4.x/4.9.0.md) | 2026-08-15 | Minor | the workflow gathers into its own root folder at the consumer, and what the plugin ships is held to what a consumer can actually use |
| [4.8.0](audience/4.x/4.8.0.md) | 2026-08-13 | Minor | The branch and release conventions and the consumer test gate now travel with the plugin |
| [4.7.0](audience/4.x/4.7.0.md) | 2026-08-13 | Minor | The documents describe what the tooling actually writes: the entry's tier shape, the post-merge step, and a seam that escaped in a third spelling |
| [4.6.0](audience/4.x/4.6.0.md) | 2026-08-12 | Minor | One audience tier per repo, and releases/ reduced to three reader-named roots |
| [4.5.0](audience/4.x/4.5.0.md) | 2026-08-11 | Minor | Repairs across the entry, PR-body and release-document machinery: gates and documents that pointed at retired shapes now name the ones actually written. |
| [4.4.0](audience/4.x/4.4.0.md) | 2026-08-11 | Minor | The merged note model gets its first written instance, and a release now times itself end to end |
| [4.3.0](audience/4.x/4.3.0.md) | 2026-08-11 | Minor | One hand-written release note per release, a generated Release page, and the performance engineer owns wall-clock |
| [4.2.0](audience/4.x/4.2.0.md) | 2026-08-10 | Minor | The consumer release document is named and written for its reader, and three silent failures gain a check |
| [4.1.0](audience/4.x/4.1.0.md) | 2026-08-10 | Minor | The workflow's portable half: a consumer can copy the PR template and the contribution cycle, and three seams stop failing quietly |
| [4.0.0](audience/4.x/4.0.0.md) | 2026-08-09 | Major | Chapter 3 consolidated (v3.0.0 -> v3.10.0) |

#### 3.x

| Version | Date | Type | Title |
|---|---|---|---|
| [3.10.0](audience/3.x/3.10.0.md) | 2026-08-09 | Minor | Teams and workflows |
| [3.9.0](audience/3.x/3.9.0.md) | 2026-08-09 | Minor | A consumer can adopt the source's release config with one command |
| [3.8.0](audience/3.x/3.8.0.md) | 2026-08-08 | Minor | The workflow becomes opt-in, and the product has one changelog |
| [3.7.0](audience/3.x/3.7.0.md) | 2026-08-07 | Minor | The branch files take their designed form |
| [3.6.0](audience/3.x/3.6.0.md) | 2026-08-06 | Minor | The changelog ranks itself by reach and weight, a branch keeps its plan in branch/, and a filled lens survives the teardown |
| [3.5.0](audience/3.x/3.5.0.md) | 2026-08-05 | Minor | The changelog gets three tiers and a release has to earn its bump, and the shared workflow stops assuming it runs in the repo it was written in |
| [3.4.0](audience/3.x/3.4.0.md) | 2026-08-04 | Minor | Every shared script has a page, and the changelog leads with the release instead of archiving them |
| [3.3.0](audience/3.x/3.3.0.md) | 2026-08-04 | Minor | A release now writes for three readers, and a third gate keeps scaffolding out of it |
| [3.2.0](audience/3.x/3.2.0.md) | 2026-08-03 | Minor | One product, one marketplace: renamed and flattened, with the release cut shared and three tiers deep |
| [3.1.2](../../releases/development/3.x/3.1.2.md) | 2026-08-02 | Patch | Round v12 processed: the teardown papers corrected, and the staleness gate reaches into prose |
| [3.1.1](../../releases/development/3.x/3.1.1.md) | 2026-08-02 | Patch | The v11 follow-up: the gates see what they claim to see |
| [3.1.0](../../releases/development/3.x/3.1.0.md) | 2026-08-01 | Minor | Every finding of test rounds v9 and v10, processed — and a gate so a PR closes what it fixes |
| [3.0.9](../../releases/development/3.x/3.0.9.md) | 2026-08-01 | Patch | Round v8: the install record now says what you are actually running — plus the gate for the class behind all three findings |
| [3.0.8](../../releases/development/3.x/3.0.8.md) | 2026-07-31 | Patch | a crafted plugin id can no longer forge a line, and a repo-wide guard keeps every native call site honest |
| [3.0.7](../../releases/development/3.x/3.0.7.md) | 2026-07-31 | Patch | the checks read the install record, and three adoption claims match the measurement |
| [3.0.6](../../releases/development/3.x/3.0.6.md) | 2026-07-31 | Patch | the enable state is read from the whole settings chain, and three claims are corrected to what was measured |
| [3.0.5](../../releases/development/3.x/3.0.5.md) | 2026-07-31 | Patch | what the refresh was measured to do, per command |
| [3.0.4](../../releases/development/3.x/3.0.4.md) | 2026-07-31 | Patch | the checks that reported the wrong answer — and a gate for the class |
| [3.0.3](../../releases/development/3.x/3.0.3.md) | 2026-07-30 | Patch | the second update gate: refresh the marketplace before you update |
| [3.0.2](../../releases/development/3.x/3.0.2.md) | 2026-07-30 | Patch | the adoption and teardown paths, measured against the actual CLI |
| [3.0.1](../../releases/development/3.x/3.0.1.md) | 2026-07-30 | Patch | Patch release |
| [3.0.0](../../releases/development/3.x/3.0.0.md) | 2026-07-30 | Major | Chapter 2 consolidated (v2.2.0 -> v2.16.0) |

#### 2.x

| Version | Date | Type | Title |
|---|---|---|---|
| [2.16.0](../../releases/development/2.x/2.16.0.md) | 2026-07-30 | Minor | Adoption is reversible by design, and a gate now says what it checked |
| [2.15.1](../../releases/development/2.x/2.15.1.md) | 2026-07-29 | Patch | Three silent failures made visible |
| [2.15.0](../../releases/development/2.x/2.15.0.md) | 2026-07-29 | Minor | The seam: a consumer's whole specialist surface becomes one directory and one line, and the orchestrator can be delivered by the plugin |
| [2.14.1](../../releases/development/2.x/2.14.1.md) | 2026-07-29 | Patch | Three checks now see what they claimed to cover: the entry scan, the machine records, and the settings proposal |
| [2.14.0](../../releases/development/2.x/2.14.0.md) | 2026-07-29 | Minor | Teardown becomes a real exit: it warns about the runtime dependency and can hand the shared scripts back |
| [2.13.3](../../releases/development/2.x/2.13.3.md) | 2026-07-29 | Patch | Entry heading levels corrected, the round-trip protocol moved into the skill, and the notes parser no longer reads quoted markdown as structure |
| [2.13.2](../../releases/development/2.x/2.13.2.md) | 2026-07-29 | Patch | The teardown-init round trip is honest and idempotent: no false authorship claim, no accumulation, no line-ending drift |
| [2.13.1](../../releases/development/2.x/2.13.1.md) | 2026-07-29 | Patch | The teardown no longer deletes a filled-in scaffold that merely mentions VUL-IN |
| [2.13.0](../../releases/development/2.x/2.13.0.md) | 2026-07-29 | Minor | Adoption becomes reversible: a teardown skill, a fresh consumer told what to do instead of shown 44 errors, and a lighter always-on path |
| [2.12.0](../../releases/development/2.x/2.12.0.md) | 2026-07-29 | Minor | Inventory drift in a repo's own connector entry becomes visible at session start, and the register catches up with reality |
| [2.11.0](../../releases/development/2.x/2.11.0.md) | 2026-07-28 | Minor | Session hooks survive compaction, the consumer is served instead of put to work, and the ignore-list is empty |
| [2.10.0](../../releases/development/2.x/2.10.0.md) | 2026-07-28 | Minor | An unregistered consumer no longer reads as 'no errors', plus the register handover in specialists-init |
| [2.9.0](../../releases/development/2.x/2.9.0.md) | 2026-07-28 | Minor | Two inbound fixes: session checks name the repo a finding is about, and the roster check covers persona-only specialists |
| [2.8.0](../../releases/development/2.x/2.8.0.md) | 2026-07-27 | Minor | Relaxed PR flow and Sylvester permission rules |
| [2.7.3](../../releases/development/2.x/2.7.3.md) | 2026-07-26 | Patch | Follow the ruleset rename in the docs and retire the dated research dossiers |
| [2.7.2](../../releases/development/2.x/2.7.2.md) | 2026-07-26 | Patch | Documentation audit: correct the GitHub Release doctrine, stale enumerations, and the last language gap |
| [2.7.1](../../releases/development/2.x/2.7.1.md) | 2026-07-26 | Patch | Cross-link the new-skill restart rule from the connectors README |
| [2.7.0](../../releases/development/2.x/2.7.0.md) | 2026-07-26 | Minor | Skill-enumeration lint check, plus the corrected cut-release skill claim in the family README |
| [2.6.1](../../releases/development/2.x/2.6.1.md) | 2026-07-26 | Patch | Document that a new skill from an updated plugin needs a session restart |
| [2.6.0](../../releases/development/2.x/2.6.0.md) | 2026-07-26 | Minor | Four inbound fixes from consuming repos: lens paths, changelog heading, roster token boundary, and the shared cut-release checklist |
| [2.5.0](../../releases/development/2.x/2.5.0.md) | 2026-07-24 | Minor | Shared park-branch script + park skill for the branch-workflow layer |
| [2.4.1](../../releases/development/2.x/2.4.1.md) | 2026-07-24 | Patch | Allow cut-release.ps1 in settings.json to bypass the auto-mode classifier |
| [2.4.0](../../releases/development/2.x/2.4.0.md) | 2026-07-24 | Minor | THESIS.md convention for Auden (#30) and the isolated-worktree parallel-PR pattern for Derek (#05) |
| [2.3.0](../../releases/development/2.x/2.3.0.md) | 2026-07-24 | Minor | Auden #30, the academic/long-form content author (resolves inbound #169) |
| [2.2.1](../../releases/development/2.x/2.2.1.md) | 2026-07-24 | Patch | Globalize two shared boundary rules into agent-shared/ (DRY cleanup) |
| [2.2.0](../../releases/development/2.x/2.2.0.md) | 2026-07-24 | Minor | Marlowe #29, the investigative-journalist reviewer, plus a fold-changelog entry-detection fix |
| [2.1.0](../../releases/development/2.x/2.1.0.md) | 2026-07-23 | Minor | Park move + portable post-merge branch cleanup, plus repo-meta and docs housekeeping |
| [2.0.2](../../releases/development/2.x/2.0.2.md) | 2026-07-23 | Patch | Skill invocation hardening, path hygiene, and workflow-lesson docs |
| [2.0.1](../../releases/development/2.x/2.0.1.md) | 2026-07-23 | Patch | Releases-overview grouping and the CI retrigger lesson |
| [2.0.0](../../releases/development/2.x/2.0.0.md) | 2026-07-23 | Major | Chapter 1 consolidated (v1.0 -> v1.18) |

#### 1.x

| Version | Date | Type | Title |
|---|---|---|---|
| [1.18.0](../../releases/development/1.x/1.18.0.md) | 2026-07-22 | Minor | Rename-proof lens scaffolds |
| [1.17.0](../../releases/development/1.x/1.17.0.md) | 2026-07-22 | Minor | E-commerce specialist group (Sergio, Craig, Sean) + Sean-to-Sebastian rename |
| [1.16.0](../../releases/development/1.x/1.16.0.md) | 2026-07-22 | Minor | ship-pr one-command flow, category-grouped release output, and the post-review doc consistency pass |
| [1.15.1](../../releases/development/1.x/1.15.1.md) | 2026-07-22 | Patch | Shared Invoke-NativeCapture helper across the release scripts, and a fully-English CHANGELOG and script layer |
| [1.15.0](../../releases/development/1.x/1.15.0.md) | 2026-07-21 | Minor | English script layer, Shopify dev-first, consumer-fit open-pr/fold, and shared release/check helpers |
| [1.14.0](../../releases/development/1.x/1.14.0.md) | 2026-07-21 | Minor | Cross-browser and automation-first shared rules, and a leaner, plugin-independent CLAUDE.md |
| [1.13.0](../../releases/development/1.x/1.13.0.md) | 2026-07-21 | Minor | Consumer release cards, branch-creates-changelog-entry, and English agent-shared block names |
| [1.12.1](../../releases/development/1.x/1.12.1.md) | 2026-07-20 | Patch | Ship the git/gh stderr-under-Stop sweep to consumers (the open-pr + fold shared-script mirrors from #113) |
| [1.12.0](../../releases/development/1.x/1.12.0.md) | 2026-07-20 | Minor | Workshop switched to English (phases A-C) and the roster-sync feature (detect, signal, stage recovery); plus the open-pr push-stderr fix and the shared language-directive block |
| [1.11.0](../../releases/development/1.x/1.11.0.md) | 2026-07-20 | Minor | Quieter session start (only FOUT/DRIFTED signals) and a slimmed-down connectors register without version bookkeeping |
| [1.10.0](../../releases/development/1.x/1.10.0.md) | 2026-07-19 | Minor | RepoName derivation from the git remote, durable body import, and a not-registered signal for unregistered consumers |
| [1.9.2](../../releases/development/1.x/1.9.2.md) | 2026-07-19 | Patch | Documentation: specialists-init SKILL.md aligned with the plugin-path/lens-only model (#88) |
| [1.9.1](../../releases/development/1.x/1.9.1.md) | 2026-07-19 | Patch | Clean-consumer fix: specialists-init scaffolds the script config and open-pr/fold pre-flight (#86) |
| [1.9.0](../../releases/development/1.x/1.9.0.md) | 2026-07-19 | Minor | Shared workflow scripts (SSOT): repo-config, branch-type source, and plugin mirrors for fold + open-pr |
| [1.8.0](../../releases/development/1.x/1.8.0.md) | 2026-07-18 | Minor | Adoption layer: bootstrap seeds the plugin path + lens-only |
| [1.7.0](../../releases/development/1.x/1.7.0.md) | 2026-07-18 | Minor | Ravi + lens migration: repo lenses on the plugin path, personas lens-only |
| [1.6.0](../../releases/development/1.x/1.6.0.md) | 2026-07-18 | Minor | Shared agent-def blocks from a single source (build-and-lint) |
| [1.5.2](../../releases/development/1.x/1.5.2.md) | 2026-07-18 | Patch | Persona index line location-independent (source fix inbound #64) |
| [1.5.1](../../releases/development/1.x/1.5.1.md) | 2026-07-18 | Patch | Lens-only model in the drift check and persona templates; inbound rule in all agent-defs |
| [1.5.0](../../releases/development/1.x/1.5.0.md) | 2026-07-17 | Minor | Consumer-ready: shareable quickstart, drift noise killed, and the first per-plugin CHANGELOGs |
| [1.4.1](../../releases/development/1.x/1.4.1.md) | 2026-07-16 | Patch | Version-sorting fix and scaffold follow-up corrections |
| [1.4.0](../../releases/development/1.x/1.4.0.md) | 2026-07-16 | Minor | Lens scaffolds on adoption and port follow-up corrections |
| [1.3.0](../../releases/development/1.x/1.3.0.md) | 2026-07-16 | Minor | Inbound route and register sync |
| [1.2.0](../../releases/development/1.x/1.2.0.md) | 2026-07-16 | Minor | Connectors register and session check |
| [1.1.1](../../releases/development/1.x/1.1.1.md) | 2026-07-15 | Patch | Security baseline processed: injection guardrail, cleaned-up example paths, and the CI gate |
| [1.1.0](../../releases/development/1.x/1.1.0.md) | 2026-07-15 | Minor | Sean the Security Engineer + the reload-plugins lesson |
| [1.0.0](../../releases/development/1.x/1.0.0.md) | 2026-07-14 | Major | First official release |
