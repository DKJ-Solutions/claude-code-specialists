# Changelog — specialists-ecomm

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (davekjohns-workshop); the full
workshop history lives there in `CHANGELOG.md` and `releases/`.

## v2.16.0 — 2026-07-30

### Documentation

#### #261 · The seam migration left stale lens paths in the prose · Docs · 2026-07-30

The seam shipped its **machinery** in v2.15.0 ([#253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)
specified it, [#254](https://github.com/DaveKJohn/davekjohns-workshop/pull/254) taught the bootstrap
and the teardown to write and remove it, [#255](https://github.com/DaveKJohn/davekjohns-workshop/pull/255)
migrated this repo onto it). Its **prose** did not come along. Measured today: **120 occurrences of the
pre-seam lens path across 57 files**, in all four plugins — every agent def, every manual, `QUICKSTART.md`,
the family README, the connectors README, and the shared `agent-shared/inbound-behaviour.md` block that
is filled verbatim into 19 agent defs.

That is not cosmetic. Those texts are the instruction a specialist reads *while working in a consuming
repo*: "repo-specific additions belong in the repo lens
(`.claude/plugins/claude-specialists/<plugin>/<group>-<id>-extension.md`)". A specialist who follows it
writes a file the seam does not hold and `check-roster-sync` reports as off-path.

**Why no gate caught it.** Two independent reasons, and both are worth keeping:

1. **The paths appear in prose and in code spans, not as links.** The dead-link scan resolves link
   *targets*; it never reads a label or a backticked path. So a document may describe a layout that no
   longer exists and stay green.
2. **In this repo's own `.claude/specialists/`, the labels were wrong while the targets were right.**
   `README.md` was still titled `# .claude/plugins/claude-specialists`, its layout section still
   described `plugins/claude-specialists/specialists/`, and its whole index table used
   `specialists/<id>-extension.md` labels over `lenses/<id>-extension.md` targets. Every link resolved.
   Exactly the class [#260](https://github.com/DaveKJohn/davekjohns-workshop/pull/260) named a day
   earlier: the description and the thing described drift apart, and nothing announces it.

**History is left alone.** The per-plugin `CHANGELOG.md` files and the archived release notes keep the
pre-seam path — they record what was true then, and this repo does not rewrite history (the same
reasoning that lets those notes keep their original language). Two analytical mentions are also kept
deliberately, because the old path is their *subject* rather than their instruction: the teardown-gap
bullet in the family README (now marked settled) and the #227 lesson in
[Sylvester's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/specialists/lenses/05-15-extension.md), where the citation now says which
path the bootstrap wrote at the time.

**Two things found while chasing the prose, both bigger than a path:**

- **`sync-roster` still writes to the pre-seam path** — a real defect, not a wording slip, and split off
  to its own `fix/` branch rather than buried here. Its `SKILL.md` line is therefore the one stale path
  left in this diff: the doc follows the behaviour, not the other way round.
- **`specialists-init`'s SKILL.md still carried the claim [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215)
  disproved** — *"what a plugin cannot do is inject always-on main-loop context"*. The family README has
  carried the correction since July 29; the skill a consumer actually reads did not. Corrected with a
  pointer to both, and stating that the switch is deliberately off — the wording was wrong regardless of
  whether Dave ever flips it.

Also reworded: "on the plugin path" as a *description of the seam*, in `QUICKSTART.md` (3),
`specialists-init/SKILL.md` (3) and the connectors README (1). The seam is not the plugin path — that
was the point of moving it, so calling it that undoes the sentence.

**One regression the sweep would have introduced, caught on the copy-edit pass.** Every agent def and
manual tells its specialist where the repo lens lives, with a fallback: *"or the legacy path
`.claude/extensions/…`"*. Before the sweep that sentence named the **pre-seam plugin path** as the
primary and the pre-plugin-path one as the fallback; a naive replacement left it naming the seam and the
oldest path while dropping the middle one — which is exactly where the two un-migrated consumers
(`life-hub`, `smartwatchbanden`) keep their lenses today. A specialist reading only the new sentence
would look in two places and miss the one holding the file. `Get-LensDirCandidates` reads all three
regardless, so no check would have failed. The parenthetical now names both fallbacks in one shape across
all 27 files: *"or, if this repo has not migrated to the seam, at its pre-seam
`.claude/plugins/<family>/<plugin>/` or `.claude/extensions/` location"*. **A mechanical replacement
inherits the old sentence's assumptions — read what the sentence claimed, not just the token you
changed.**

**Found and deliberately left alone:** `check-consumer-drift` reports `03-02-extension.md` (Bianca) as
`[DRIFTED]` — her lens carries a body copy instead of following the lens-only model. Informational, it
does not affect the exit code, and it predates this branch: she was adopted onto the roster on July 28,
2026. Recorded here so it is on the record rather than in a session.

[PR #261](https://github.com/DaveKJohn/davekjohns-workshop/pull/261)

---

## v2.0.2 — 2026-07-23

### Maintenance

#### #154 · Flatten release notes into per-major folders · Chore · 2026-07-23

Flattens the release-notes layout from per-minor folders
(`releases/development/<X.Y>/<X.Y.Z>.md`) to one folder per major
(`releases/development/<X>.x/<X.Y.Z>.md`) — so all 1.x notes now live in `1.x/` and all 2.x notes
in `2.x/`, matching the per-major grouping already applied to the overview table (#152). The 27
existing 1.x notes and the two 2.x notes were moved via `git mv` (renames preserved); the empty
minor folders are gone.

Because the depth is unchanged (a single `<X>.x` folder replaces the single `<X.Y>` folder), the
root-relative links inside the notes (`../../../`) keep resolving — no note body was touched.
Updated: `cut-release.ps1` + `release-lib.ps1` now derive `<major>.x` (was `<major>.<minor>`); the
29 note-path links in `releases/README.md` + the `## Releases` block in `CHANGELOG.md`, the four
per-plugin `RELEASE.md` cards, the descriptive `<X.Y>` references in `README.md`/`05-06-extension.md`,
and the `release-lib` test's expected paths. Git tags (`vX.Y.Z`) are unaffected — they point to
commits, not paths. Archived note bodies keep their original (historical, sometimes Dutch) path
mentions on purpose. Lint gate green (dead-link scan clean); all test suites pass.

[PR #154](https://github.com/DaveKJohn/davekjohns-workshop/pull/154)

---

## v1.17.0 — 2026-07-22

### Features

#### #143 · New specialists-ecomm plugin with three e-commerce specialists (SEO, CRO, SEA) · Feat · 2026-07-22

New fourth domain group — the plugin `specialists-ecomm`, for commercial webshop repos of any
platform (not Shopify-only) — with its first three specialists, all group 06 (the
measure-and-optimize family):

- **Sergio 📈 #26 — SEO Specialist.** Technical/on-site SEO: anchor links and internal linking,
  canonical tags, structured data (schema.org/JSON-LD), XML sitemaps, and pagespeed. Auditor and
  builder: measure first, fix at the source, validate, white-hat only.
- **Craig 🎯 #27 — CRO Specialist.** Conversion Rate Optimization: funnel/drop-off analysis, A/B
  experiments, checkout and landing-page optimization. Test, don't guess — keep only what a measured
  experiment proves.
- **Sean 💸 #28 — Performance / SEA Specialist.** The paid side of acquisition and its in-repo
  footprint: conversion tracking, product feeds, UTM conventions, ad-to-landing-page alignment.
  Honest about the boundary that live campaigns live in the ad platforms, and coordinates with
  Sergio so paid doesn't cannibalize organic.

All three carry the standard shared blocks (inbound-behaviour, laziness-automation,
language-behavior), defer visual/front-end changes to the design owner, and defer any preview/live
push to the platform's store owner.

**Rename to free the name for the SEA pun:** the existing Security Engineer **Sean 🛡️ #23** is
renamed to **Sebastian** (keeps 🛡️, #23, and its call name changes `@specialists:sean` →
`@specialists:sebastian`), so the new SEA specialist can be "Sean". Updated across the living
team-definition surfaces — the #23 agent def, manual, and repo lens; the roster in `CLAUDE.md`; the
family handbook; Chris's routing/chains lens; and the cross-references in the Ravi/Victor/Edith
lenses; plus the group-1 listing in `README.md`. History (CHANGELOG/releases, the dated security
baseline) and past-advice attribution comments in scripts/hooks/tests/CI are deliberately left as
records.

- **New plugin:** `claude-code-plugins/claude-specialists/specialists-ecomm/` with `plugin.json`
  (version 1.16.0, lockstep), `CHANGELOG.md`, and `RELEASE.md` card; registered as the fourth entry
  in `.claude-plugin/marketplace.json`.
- **Specialists:** agent defs `agents/06-26|27|28-agent.md` and portable manuals
  `manuals/06-26|27|28-manual.md`.
- Group deliberately set up to grow further (lifecycle/email, analytics) without restructuring.

**Quality-round follow-ups (Victor/Edith/Sebastian/Ravi/Nolan on the diff):**
- Registered the new plugin in the docs that describe the family — root `README.md`, the family
  `README.md`, and `QUICKSTART.md` now say "four plugins" and list `specialists-ecomm`; reframed
  "a repo needs at most one domain group" as **complementary** (a Shopify repo can enable
  `specialists-shopify` + `specialists-ecomm`).
- Fixed a real functional gap: `check-consumer-drift.ps1` hardcoded three plugins, so a consumer's
  drift check would never cover ids 26/27/28 — added `specialists-ecomm`.
- Language norm: translated the three pre-existing Dutch manifests (`marketplace.json` + the
  `specialists`/`lifehub`/`shopify` `plugin.json`) to English, closing the mixed-language state
  instead of extending it; generalized stale "three plugins" wording in scripts and lenses.
- Ravi: promoted three verbatim-shared boundaries across the ecomm agent-defs to `agent-shared/`
  blocks (`design-owner-boundary`, `changelog-entry-boundary`, `storefront-preview-boundary`),
  scoped to Sergio/Craig/Sean.

Verified: `build-agent-defs.ps1 -Check` (shared blocks in sync), `check-plugin-integrity.ps1`
(0 errors), and all test suites green.

[PR #143](https://github.com/DaveKJohn/davekjohns-workshop/pull/143)
