# Release notes — davekjohns-workshop

The release history of the davekjohns-workshop marketplace. A release here is not a deploy but a
**recorded moment**: a git tag that marks the state of the marketplace, with all plugin versions in
lockstep. The full notes live below in `development/<X>.x/<X.Y.Z>.md`, and the `## Releases` block in
[`CHANGELOG.md`](../CHANGELOG.md) references them. [`scripts/release/cut-release.ps1`](../scripts/release/cut-release.ps1)
itself publishes nothing to GitHub Releases — that is a separate, manual closing step: for a
**Minor or Major** bump, the [`cut-release` skill](../claude-code-plugins/claude-specialists/specialists/skills/cut-release/SKILL.md)'s
checklist walks through `gh release create` + `gh release upload` (the highlights as the release
body, the full development notes as an attachment); a **Patch** release skips that step (tag only).
Releases are cut only at Dave's explicit request — see [Cutting a release](#cutting-a-release)
below for the full mechanics. Each release also refreshes, per plugin, the `RELEASE.md` card that
consumers see (version + short notes, travelling along with the plugin cache via
`claude plugin update`).

## Overview

Grouped by major version, newest first. New releases are added to the current major's table (the
top one) — which is why **opening a new major's section is a deliberate act, done before the release is
cut**: `cut-release.ps1` inserts the new row after the first table header it finds, so without the
section below a `v3.0.0` row would be filed under `### 2.x` without anything erroring. A guardrail now
refuses that rather than doing it quietly (see [Cutting a release](#cutting-a-release)).

### 3.x

| Version | Date | Type | Title |
|---|---|---|---|
| [3.0.7](development/3.x/3.0.7.md) | 2026-07-31 | Patch | the checks read the install record, and three adoption claims match the measurement |
| [3.0.6](development/3.x/3.0.6.md) | 2026-07-31 | Patch | the enable state is read from the whole settings chain, and three claims are corrected to what was measured |
| [3.0.5](development/3.x/3.0.5.md) | 2026-07-31 | Patch | what the refresh was measured to do, per command |
| [3.0.4](development/3.x/3.0.4.md) | 2026-07-31 | Patch | the checks that reported the wrong answer -- and a gate for the class |
| [3.0.3](development/3.x/3.0.3.md) | 2026-07-30 | Patch | the second update gate: refresh the marketplace before you update |
| [3.0.2](development/3.x/3.0.2.md) | 2026-07-30 | Patch | the adoption and teardown paths, measured against the actual CLI |
| [3.0.1](development/3.x/3.0.1.md) | 2026-07-30 | Patch | Patch release |
| [3.0.0](development/3.x/3.0.0.md) | 2026-07-30 | Major | Chapter 2 consolidated (v2.2.0 -> v2.16.0) |

### 2.x

| Version | Date | Type | Title |
|---|---|---|---|
| [2.16.0](development/2.x/2.16.0.md) | 2026-07-30 | Minor | Adoption is reversible by design, and a gate now says what it checked |
| [2.15.1](development/2.x/2.15.1.md) | 2026-07-29 | Patch | Three silent failures made visible |
| [2.15.0](development/2.x/2.15.0.md) | 2026-07-29 | Minor | The seam: a consumer's whole specialist surface becomes one directory and one line, and the orchestrator can be delivered by the plugin |
| [2.14.1](development/2.x/2.14.1.md) | 2026-07-29 | Patch | Three checks now see what they claimed to cover: the entry scan, the machine records, and the settings proposal |
| [2.14.0](development/2.x/2.14.0.md) | 2026-07-29 | Minor | Teardown becomes a real exit: it warns about the runtime dependency and can hand the shared scripts back |
| [2.13.3](development/2.x/2.13.3.md) | 2026-07-29 | Patch | Entry heading levels corrected, the round-trip protocol moved into the skill, and the notes parser no longer reads quoted markdown as structure |
| [2.13.2](development/2.x/2.13.2.md) | 2026-07-29 | Patch | The teardown-init round trip is honest and idempotent: no false authorship claim, no accumulation, no line-ending drift |
| [2.13.1](development/2.x/2.13.1.md) | 2026-07-29 | Patch | The teardown no longer deletes a filled-in scaffold that merely mentions VUL-IN |
| [2.13.0](development/2.x/2.13.0.md) | 2026-07-29 | Minor | Adoption becomes reversible: a teardown skill, a fresh consumer told what to do instead of shown 44 errors, and a lighter always-on path |
| [2.12.0](development/2.x/2.12.0.md) | 2026-07-29 | Minor | Inventory drift in a repo's own connector entry becomes visible at session start, and the register catches up with reality |
| [2.11.0](development/2.x/2.11.0.md) | 2026-07-28 | Minor | Session hooks survive compaction, the consumer is served instead of put to work, and the ignore-list is empty |
| [2.10.0](development/2.x/2.10.0.md) | 2026-07-28 | Minor | An unregistered consumer no longer reads as 'no errors', plus the register handover in specialists-init |
| [2.9.0](development/2.x/2.9.0.md) | 2026-07-28 | Minor | Two inbound fixes: session checks name the repo a finding is about, and the roster check covers persona-only specialists |
| [2.8.0](development/2.x/2.8.0.md) | 2026-07-27 | Minor | Relaxed PR flow and Sylvester permission rules |
| [2.7.3](development/2.x/2.7.3.md) | 2026-07-26 | Patch | Follow the ruleset rename in the docs and retire the dated research dossiers |
| [2.7.2](development/2.x/2.7.2.md) | 2026-07-26 | Patch | Documentation audit: correct the GitHub Release doctrine, stale enumerations, and the last language gap |
| [2.7.1](development/2.x/2.7.1.md) | 2026-07-26 | Patch | Cross-link the new-skill restart rule from the connectors README |
| [2.7.0](development/2.x/2.7.0.md) | 2026-07-26 | Minor | Skill-enumeration lint check, plus the corrected cut-release skill claim in the family README |
| [2.6.1](development/2.x/2.6.1.md) | 2026-07-26 | Patch | Document that a new skill from an updated plugin needs a session restart |
| [2.6.0](development/2.x/2.6.0.md) | 2026-07-26 | Minor | Four inbound fixes from consuming repos: lens paths, changelog heading, roster token boundary, and the shared cut-release checklist |
| [2.5.0](development/2.x/2.5.0.md) | 2026-07-24 | Minor | Shared park-branch script + park skill for the branch-workflow layer |
| [2.4.1](development/2.x/2.4.1.md) | 2026-07-24 | Patch | Allow cut-release.ps1 in settings.json to bypass the auto-mode classifier |
| [2.4.0](development/2.x/2.4.0.md) | 2026-07-24 | Minor | THESIS.md convention for Auden (#30) and the isolated-worktree parallel-PR pattern for Derek (#05) |
| [2.3.0](development/2.x/2.3.0.md) | 2026-07-24 | Minor | Auden #30, the academic/long-form content author (resolves inbound #169) |
| [2.2.1](development/2.x/2.2.1.md) | 2026-07-24 | Patch | Globalize two shared boundary rules into agent-shared/ (DRY cleanup) |
| [2.2.0](development/2.x/2.2.0.md) | 2026-07-24 | Minor | Marlowe #29, the investigative-journalist reviewer, plus a fold-changelog entry-detection fix |
| [2.1.0](development/2.x/2.1.0.md) | 2026-07-23 | Minor | Park move + portable post-merge branch cleanup, plus repo-meta and docs housekeeping |
| [2.0.2](development/2.x/2.0.2.md) | 2026-07-23 | Patch | Skill invocation hardening, path hygiene, and workflow-lesson docs |
| [2.0.1](development/2.x/2.0.1.md) | 2026-07-23 | Patch | Releases-overview grouping and the CI retrigger lesson |
| [2.0.0](development/2.x/2.0.0.md) | 2026-07-23 | Major | Chapter 1 consolidated (v1.0 -> v1.18) |

### 1.x

| Version | Date | Type | Title |
|---|---|---|---|
| [1.18.0](development/1.x/1.18.0.md) | 2026-07-22 | Minor | Rename-proof lens scaffolds |
| [1.17.0](development/1.x/1.17.0.md) | 2026-07-22 | Minor | E-commerce specialist group (Sergio, Craig, Sean) + Sean-to-Sebastian rename |
| [1.16.0](development/1.x/1.16.0.md) | 2026-07-22 | Minor | ship-pr one-command flow, category-grouped release output, and the post-review doc consistency pass |
| [1.15.1](development/1.x/1.15.1.md) | 2026-07-22 | Patch | Shared Invoke-NativeCapture helper across the release scripts, and a fully-English CHANGELOG and script layer |
| [1.15.0](development/1.x/1.15.0.md) | 2026-07-21 | Minor | English script layer, Shopify dev-first, consumer-fit open-pr/fold, and shared release/check helpers |
| [1.14.0](development/1.x/1.14.0.md) | 2026-07-21 | Minor | Cross-browser and automation-first shared rules, and a leaner, plugin-independent CLAUDE.md |
| [1.13.0](development/1.x/1.13.0.md) | 2026-07-21 | Minor | Consumer release cards, branch-creates-changelog-entry, and English agent-shared block names |
| [1.12.1](development/1.x/1.12.1.md) | 2026-07-20 | Patch | Ship the git/gh stderr-under-Stop sweep to consumers (the open-pr + fold shared-script mirrors from #113) |
| [1.12.0](development/1.x/1.12.0.md) | 2026-07-20 | Minor | Workshop switched to English (phases A-C) and the roster-sync feature (detect, signal, stage recovery); plus the open-pr push-stderr fix and the shared language-directive block |
| [1.11.0](development/1.x/1.11.0.md) | 2026-07-20 | Minor | Quieter session start (only FOUT/DRIFTED signals) and a slimmed-down connectors register without version bookkeeping |
| [1.10.0](development/1.x/1.10.0.md) | 2026-07-19 | Minor | RepoName derivation from the git remote, durable body import, and a not-registered signal for unregistered consumers |
| [1.9.2](development/1.x/1.9.2.md) | 2026-07-19 | Patch | Documentation: specialists-init SKILL.md aligned with the plugin-path/lens-only model (#88) |
| [1.9.1](development/1.x/1.9.1.md) | 2026-07-19 | Patch | Clean-consumer fix: specialists-init scaffolds the script config and open-pr/fold pre-flight (#86) |
| [1.9.0](development/1.x/1.9.0.md) | 2026-07-19 | Minor | Shared workflow scripts (SSOT): repo-config, branch-type source, and plugin mirrors for fold + open-pr |
| [1.8.0](development/1.x/1.8.0.md) | 2026-07-18 | Minor | Adoption layer: bootstrap seeds the plugin path + lens-only |
| [1.7.0](development/1.x/1.7.0.md) | 2026-07-18 | Minor | Ravi + lens migration: repo lenses on the plugin path, personas lens-only |
| [1.6.0](development/1.x/1.6.0.md) | 2026-07-18 | Minor | Shared agent-def blocks from a single source (build-and-lint) |
| [1.5.2](development/1.x/1.5.2.md) | 2026-07-18 | Patch | Persona index line location-independent (source fix inbound #64) |
| [1.5.1](development/1.x/1.5.1.md) | 2026-07-18 | Patch | Lens-only model in the drift check and persona templates; inbound rule in all agent-defs |
| [1.5.0](development/1.x/1.5.0.md) | 2026-07-17 | Minor | Consumer-ready: shareable quickstart, drift noise killed, and the first per-plugin CHANGELOGs |
| [1.4.1](development/1.x/1.4.1.md) | 2026-07-16 | Patch | Version-sorting fix and scaffold follow-up corrections |
| [1.4.0](development/1.x/1.4.0.md) | 2026-07-16 | Minor | Lens scaffolds on adoption and port follow-up corrections |
| [1.3.0](development/1.x/1.3.0.md) | 2026-07-16 | Minor | Inbound route and register sync |
| [1.2.0](development/1.x/1.2.0.md) | 2026-07-16 | Minor | Connectors register and session check |
| [1.1.1](development/1.x/1.1.1.md) | 2026-07-15 | Patch | Security baseline processed: injection guardrail, cleaned-up example paths, and the CI gate |
| [1.1.0](development/1.x/1.1.0.md) | 2026-07-15 | Minor | Sean the Security Engineer + the reload-plugins lesson |
| [1.0.0](development/1.x/1.0.0.md) | 2026-07-14 | Major | First official release |

## Cutting a release

A release is a **captured moment**: all plugins get the same version number
(**lockstep, repo-wide**) and the state is tagged as `vX.Y.Z`. `cut-release.ps1` itself publishes
nothing to GitHub Releases — it produces only a git tag, the full notes here in `development/`, and
a reference to them in [`CHANGELOG.md`](../CHANGELOG.md). A release is cut **only on Dave's explicit
request** and deliberately does **not** go through a branch + PR: like the fold commit, the
release commit is a permitted direct-on-`main` action (the second exception to "everything via
branch + PR" — see [`CONTRIBUTING.md`](../CONTRIBUTING.md)).

In one motion, on a clean `main`:
[`scripts/release/cut-release.ps1`](../scripts/release/cut-release.ps1)`(-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]`

1. bumps all `plugin.json` versions in lockstep to `X.Y.Z`;
2. generates the full release notes in `development/<X>.x/<X.Y.Z>.md` (from the folded
   `## Pull Requests` entries, per branch type), adds a row to this page's [Overview](#overview),
   and places in `CHANGELOG.md` a reference under `## Releases` (the Pull Requests section is
   emptied down to its intro);
3. appends, per plugin, the entries that touched that plugin (selected via the `Plugins:` line that
   the fold derives from the PR's files; as internal bookkeeping, the line itself doesn't travel along)
   to the **per-plugin `CHANGELOG.md`**, and regenerates that plugin's **`RELEASE.md`** card (version,
   one-line summary, and the entries for that version) — both consumer-facing artifacts that travel
   along with the plugin cache. In all three outputs (the full notes, the per-plugin CHANGELOG, and
   the RELEASE.md card) the entries are grouped by category — Features, Fixes, Documentation,
   Maintenance, Other — with features and fixes at the top;
4. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
5. pushes `main` + the tag (unless `-NoPush` for inspection first).

**Closing step, after the script, for a Minor/Major bump: publish a GitHub Release.** Not run by
`cut-release.ps1` and not automated — the release manager walks through the
[`cut-release` skill](../claude-code-plugins/claude-specialists/specialists/skills/cut-release/SKILL.md)'s
checklist: `gh release create` with the highlights as the release body (`--notes-file`), then
`gh release upload` with the full development notes file as an attachment. That split is not a
style choice: `gh`'s release-notes body has a hard 125,000-character limit, which a full notes file
can exceed. A **Patch** release skips this step entirely (tag only, no GitHub Release) — which is
why, for example, `v2.6.1` and `v2.7.1` have no GitHub Release while `v2.6.0` and `v2.7.0` do.

Guardrails: a clean `main`, no unfolded entry files, lint gate green, tag doesn't exist yet. The
lint gate ([`scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1),
check 9) also guards that every plugin's `RELEASE.md` card is present and its version matches
`plugin.json`, since the two only ever change together via `cut-release.ps1`.

The pure logic (version bump, CHANGELOG transformation, notes construction) lives in
[`scripts/lib/release-lib.ps1`](../scripts/lib/release-lib.ps1) and is covered by
[`scripts/tests/release-lib.tests.ps1`](../scripts/tests/release-lib.tests.ps1).
