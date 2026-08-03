# Changelog — specialists-lifehub

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (claude-code-specialists); the
full repository history lives there in `CHANGELOG.md` and `releases/`.

## v3.2.0 — 2026-08-03

### Features

#### #418 · Flatten the plugin directory layer into plugins/ and give the repo one landing page · Feat · 2026-08-03

Steps 3 and 4 of the repository rename (#405 + #406), in one movement because they rewrite the same
page. `claude-code-plugins/claude-specialists/` existed to hold several product *families* side by
side; with one product per repository both levels were empty scaffolding, so they collapse into one:

- **`plugins/<plugin>/`** for the four plugins and `agent-shared/` (plugin source — its generator
  writes the shared blocks into plugin agent defs), **`connectors/` at the repo root** (consumer
  register read by `scripts/sync/`, deliberately not payload that travels in the plugin cache). Moved
  with `git mv`, so history follows. Every path in the repo loses 31 characters — net 27 shorter than
  before the rename began, the longer marketplace name included.
- **The three family-level documents moved to the root**: `QUICKSTART.md`, `UNINSTALL.md`, and the
  735-line family `README.md`, which **becomes** the root README (the old 151-line one contributed
  only `Consumption`, `Versioning`, `Contributing` and the repo layout). One ~800-line landing page
  whose first screen now *routes* — a "Start here" table — rather than explains.
- **The one-product-per-repository rule is recorded** in `README.md`, `CLAUDE.md`,
  `.claude-plugin/marketplace.json` and `CONTRIBUTING.md`, with the nuance that stops the wrong repair
  later: lockstep *within* this product is correct, `cut-release.ps1` needs no change, and the
  versioning problem dissolved with the reorganisation instead of needing a fix.

**Three defects a mechanical path sweep would have shipped, each caught by reading rather than by
replacing.** They are the reason this entry is longer than a move deserves:

1. **`bootstrap.ps1` derived the plugin from a named path segment**, and the new name is not unique.
   It looked up the index of `claude-code-plugins` and took two segments further to skip the family
   level; renamed to `plugins`, that segment occurs a **second** time in every real install path
   (`~/.claude/plugins/marketplaces/<mp>/plugins/<plugin>/personas`), `IndexOf` returns the first, and
   the derivation would have yielded the **marketplace** name — precisely the defect #179 fixed, back
   again through a rename. The segment lookup was already redundant: the parent walk beside it derives
   the plugin correctly in the source, clone and cache layouts alike, so it is gone rather than
   renamed.
2. **The lint gate's parse check matched `plugins` as a path segment**, which now also matches
   `.claude/plugins/` — it is anchored on the plugins root instead.
3. **`Get-TouchedPlugins` excluded the wrong sibling.** `connectors` left the plugins tree (so its
   exclusion guarded nothing) while `agent-shared` moved in (and would have been reported as a touched
   plugin on release). The exclusion follows the directory now, asserted from both sides.

**The lint gate got the root-level `*.md` glob** that #405 asked for, replacing a named list of four
root documents *plus* a glob over the family directory. That directory's glob existed because a
hardcoded list of two had gone stale the moment `UNINSTALL.md` was written beside them and no gate saw
it; moving those documents into the root would have left the named list as the only rule over exactly
the directory where that class of defect lives. It also picks up `SECURITY.md`, which no rule had ever
covered.

**Two measurements in #405 turned out low, and the repo won.** The archived release notes carry **19**
relative links into the old paths, not 8 — all repaired as link *targets* only, since a target is
machinery that has to resolve while the backtick prose around it states where a file stood at the time
and stays untouched (42 such mentions remain, deliberately). And `QUICKSTART.md` and `UNINSTALL.md`
carried relative links of their own that changed meaning **without changing text** — `../../` used to
reach the root from the family directory, and a bare `specialists/…` used to be a sibling. A path sweep
cannot see those; the dead-link gate is what found them.

Not touched, deliberately: `CHANGELOG.md` and every per-plugin `CHANGELOG.md`, the prose in
`releases/**`, and `cut-release.ps1`. Closes #405, #406 and tracking issue #407.

[PR #418](https://github.com/DaveKJohn/claude-code-specialists/pull/418)

### Fixes

#### #419 · Repair the stale marketplace name in generated intros · Fix · 2026-08-03

Found while verifying the post-restart state after the rename series (#403–#406) closed: the rename
swept `davekjohns-workshop` out of 59 files, and all four **per-plugin `CHANGELOG.md` files still
opened by naming it** — in a sentence describing the present mechanism, in the most consumer-facing
file each plugin has.

**The reason, verified in the code rather than inferred from the symptom.** `Add-PluginChangelogSection`
emits the intro only when the file does not exist yet (`if (-not $Existing)`), so every later release
appends *below* it and never revisits it. Editing the template reaches future plugins and no current
one — the template had in fact already been corrected, and the correction could not arrive. Every
existing gate looked past it for a defensible reason: checks 11 and 12 exclude per-plugin CHANGELOGs as
history, and they are right about the entries. **The intro is the one part of those files that is not
history**, and no rule covered it.

**Repaired as a class, not as four strings:**

- **`Build-PluginChangelogIntro` extracted** as the single source of that header, with the marketplace
  name a **parameter** rather than a literal — a copy of the name is exactly what went stale. Its
  authority is `name` in `.claude-plugin/marketplace.json`, read through the new pure
  `Get-MarketplaceName`, which throws on a missing *or blank* name instead of yielding a plausible
  `()` in a published file.
- **Check 17 in the lint gate** holds every `plugins/<plugin>/CHANGELOG.md` intro against that
  function, deriving the expected text from the same manifest field `cut-release.ps1` writes — so the
  two agree by construction instead of by upkeep. There is deliberately **no expected value written
  down in the gate**: a literal there would be another copy of the string whose copies are the bug.
  Compared whitespace-normalized, so it judges content and never becomes a wrapping police over a file
  no human should be rewrapping. Everything below the first `## vX.Y.Z` heading is left alone — that
  half *is* history.
- **The six stale statements themselves**: the four plugin intros, `CHANGELOG.md`'s own opening line,
  and the handbook's outlier note in `.claude/specialists/README.md`, which additionally still called
  the plugins "the first product family" — the framing the
  [one-product rule](https://github.com/DaveKJohn/claude-code-specialists/blob/main/README.md#one-product-one-repository) retired the same day.

**Five test scenarios (33–37), and one of them is the design rather than a bug guard.** #37 renames the
marketplace in the fixture manifest and *nothing else*, and the same file must flip from failing to
passing: without that case the check could carry a hardcoded copy of the name and all four other
scenarios would still pass — precisely the shape of the defect it exists to catch. #36 locks in that a
CHANGELOG with no version heading is *reported* rather than silently skipped, since a check that quietly
asserts nothing is the failure mode this gate is here to prevent. #35's own first failure is recorded in
its comment: the fixture retyped the em-dash title as a plain hyphen, making a content difference
masquerade as the layout difference the case was meant to prove.

**The general rule, written into `release-lib.ps1` for the next template added there:** ask whether the
string is rewritten on every release. A section, a reference line, a fully regenerated card all reach
their file again and self-heal; anything written once needs a gate rather than a good intention. The
library's own header claimed "only FUTURE output from these templates changed" — true of every template
in it except this one, and that single exception cost four consumer-facing files.

**Also closed a smaller drift found on the way:** the gate's `.SYNOPSIS` indexed checks 1–12 while the
script ran 17. Checks 13–16 (entry-heading, encoding, unbound output samples, measured figures) were
documented at their definitions but absent from the index a reader consults first, so all five are now
listed rather than only the new one.

**Deliberately not done, and it is a decision rather than an omission.** "Workshop" survives as internal
shorthand for this repo in 278 places across 58 files — including the parameter name
`-WorkshopPathOverride` (a live contract between `connector-sessioncheck.ps1` and
`check-connectors.ps1`, mirrored into the plugin) and the test helper `New-StubWorkshop`. Retiring the
*word* is a vocabulary migration needing a chosen replacement term; retiring the stale *statements* is a
defect repair. Only the second is in this branch. Dave's call, August 3, 2026.

[PR #419](https://github.com/DaveKJohn/claude-code-specialists/pull/419)

---

#### #399 · the release card states what it describes, not where you are · Fix · 2026-08-02

Every plugin's `RELEASE.md` card carried the line *"You are on this release."* — written at cut time,
about a reader the card has never met. Round v13 measured it false in the ordinary case (inbound
[#384](https://github.com/DaveKJohn/davekjohns-workshop/issues/384)): the payload came from `main`,
three commits past the tag whose number both the card and `plugin.json` were carrying.

What makes it more than cosmetic is *where* the reader meets it. The QUICKSTART already documents
that **the documented update path cannot deliver a tagged release**, because the source it reads is a
branch — and v13 was the first round in which a consumer ran that tag comparison and reached the right
conclusion: *I am on `main`, not on the release*. Two minutes later the card of that same release told
them the opposite. Two documents of one family contradicting each other about one measurement, with
the wrong one being the one that cannot know.

`Build-PluginReleaseCard` now writes what the card *can* know — the version its manifest carries — and
hands the "where am I" question to the check that can answer it, linked as an absolute URL because the
card is read from a plugin cache where the QUICKSTART does not ship. The fix is in the generator, so
it holds for every future release instead of being retyped; the four cards on disk were regenerated to
match, and `cut-release.ps1`'s own description, [Rendall #06's lens](https://github.com/DaveKJohn/claude-code-specialists/blob/main/.claude/specialists/lenses/05-06-extension.md)
and the QUICKSTART line pointing at the card all follow the behaviour.

The test that pinned the old sentence now pins the new one **plus its negative**: the card must not
claim the reader is on this release. A line this one is only a repair for as long as nothing puts it
back.

[PR #399](https://github.com/DaveKJohn/davekjohns-workshop/pull/399)

### Documentation

#### #424 · QUICKSTART becomes ADOPTION.md, with a real quickstart beside it · Docs · 2026-08-03

Closes inbound [#408](https://github.com/DaveKJohn/claude-code-specialists/issues/408),
[#402](https://github.com/DaveKJohn/claude-code-specialists/issues/402) and
[#401](https://github.com/DaveKJohn/claude-code-specialists/issues/401) — three findings from the same
adoption round, all on the same page, and one of them restructures it, so they travel together.

**The page is renamed, and the name was the defect (#408).** `QUICKSTART.md` is a thorough,
measurement-backed adoption manual; "quickstart" set an expectation it never tried to meet, and the
consumer who had just adopted through it said so in as many words. It is now `ADOPTION.md`, and it
states its own reading time at the top — ~44 minutes at 200 wpm, plus ~27 for `specialists-init`'s
`SKILL.md`, measured August 3, 2026 and framed as an order of magnitude because both pages grow. That
is the one number a first-time reader would plan with, on a page meticulous about every other count.
The short page comes out at ~4 minutes, so the split is a factor of eleven rather than the "roughly
twenty lines" the issue estimated.

**`QUICKSTART.md` still exists, and now the name is true**: a commands-only page — the two settings
keys, the four commands, the verification query, the two restarts — that links out to `ADOPTION.md`
for every caveat. Keeping the filename is also what keeps ~19 inbound links alive, including the
`#staying-up-to-date` anchor cited from archived release notes and the per-plugin CHANGELOGs, which
are history and are not rewritten. Both pages carry that anchor; living docs point at the detailed
one.

**Three steps became four.** Filling the lenses was always part of the procedure and was disclosed in
a trailing clause reading *"then, at your own pace"*, after the page had framed itself as complete.
That is how an owner came to attribute half an hour of *authoring* to the *installer* —
`specialists-init` places the whole seam in seconds. It is Step 4 now, with its cost stated and with
the two things that reliably surface while doing it (a `.gitignore` that swallows the seam, a
`repo-config.ps1` behind the script contract) named as things to plan for rather than diagnose. Per
#297's lesson the count moved on all three pages in one change — here, in the README, and in the
skill.

**Where a delegated adoption has to stop (#402).** The page addressed the agent-reader once, about
*reading* it. It now also addresses *executing* it: a table splitting the procedure by who can perform
each act. Of Step 1's six acts an agent can do four; the two restarts it structurally cannot, because
it runs inside the session it would restart, and Steps 2–3 follow from that. Named with it: what the
agent hands back, and why the state it stops in is the one this page devotes a blockquote to as
reading healthy from every angle — three correct records, right sha, payload present, and an inert
session.

**The third machine state (#401).** *Before you start* knew a virgin profile and a machine satisfied
long ago. It did not know the one that is the *expected* condition of any second adoption: a leftover
**user-scope** marketplace registration, because `UNINSTALL.md` Step 5 is the removal no command
performs. In that state the restart act and its `marketplace add` alternative are silently
unnecessary, #329's failure message never appears — so its absence proves nothing — and, the sharper
half, the repo's own `extraKnownMarketplaces` key is never exercised at all. A mistyped slug then
survives every check on the page. Act 3 gains the one-line close: after the refresh, `claude plugin
marketplace list`, and confirm the entry came from your repo's settings.

**Two allowlists needed the new file, and both are the same class of bug this repo has now hit three
times.** `cut-release.ps1`'s `$reservedRootMd` treats every unlisted root `*.md` as an unfolded
changelog entry, so without `ADOPTION.md` the next release would have refused to cut, complaining
about a document nobody failed to fold (#165, then #405, now this). And the lint gate's
`$consumerDocs` — the set checks 15 and 16 examine for unbound samples and unbound measured figures —
listed `QUICKSTART.md`; the page carrying almost all of those samples had just been renamed out from
under it, which would have left both checks reporting green over their own subject. The comment above
that list warned about exactly this arriving.

`release-lib.ps1` now generates the `RELEASE.md` card's "the version is not the code" link against
`ADOPTION.md`; the four committed cards were brought in line by hand so the next generation is a
no-op, and the test asserting that URL moved with it.

**To do / where I left off:** done — lint gate and all 23 test suites green.

[PR #424](https://github.com/DaveKJohn/claude-code-specialists/pull/424)

### Maintenance

#### #412 · rename the marketplace to claude-code-specialists · Chore · 2026-08-03

Step 2 of the four-step rename ([#404](https://github.com/DaveKJohn/claude-code-specialists/issues/404),
tracked from [#407](https://github.com/DaveKJohn/claude-code-specialists/issues/407)). The repository was
renamed on GitHub in step 1 ([#403](https://github.com/DaveKJohn/claude-code-specialists/issues/403));
this change makes the repository's own contents agree with its new name. Marketplace name and repository
name are now identical on purpose — when they differ, you have to remember forever which marketplace
lives in which repository, and that is exactly what bites while debugging a plugin that will not load.

**Why the rename at all.** The workshop was meant to become the home for every future plugin. With one
`CHANGELOG.md`, one `vX.Y.Z` tag and a lockstep version bump, that design breaks the moment a second,
unrelated product lands: it gets bumped for work it never had, one tag covers two products, and one
changelog mixes two histories. Measurement showed there was nothing here that is *not* the specialists
product — `scripts/` is its machinery, `releases/` its notes, `CHANGELOG.md` its history, and
`claude-code-plugins/` holds only `claude-specialists/`. So this was never a split; it was a rename, and
a `git push --mirror` would have been the expensive route — it loses the issues, the pull requests, the
releases metadata, the `main` ruleset and the CI history that a rename keeps.

**What changed.** `davekjohns-workshop` → `claude-code-specialists` in 59 files, 370 replacements: the
`name` in `.claude-plugin/marketplace.json`, every `specialists*@davekjohns-workshop` plugin ID, the
repository slug, the six live hard-coded `~/.claude/plugins/marketplaces/…` import paths (including
Chris's body import, which every session loads), the self-consumption entry in `.claude/settings.json`,
and the connector registry — where `connectors/davekjohns-workshop.json` was renamed with `git mv` so
its history follows it.

**What deliberately did not change.**

- `releases/**` and every `CHANGELOG.md`, root and per-plugin. These are the historical record: a note
  that says where a file stood in version 1.7.0 is true about that moment, and rewriting it would make
  it false. The one archived cache path in `releases/development/1.x/1.7.0.md` therefore still reads
  `davekjohns-workshop`, which is correct — the language-layer rule in
  [`.claude/rules/language-layers.md`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/.claude/rules/language-layers.md) already names archived release
  notes as a deliberate exception.
- `scripts/release/cut-release.ps1`. The lockstep bump across all four plugins under a single tag is
  what triggered this reorganisation, but with one repository holding one product the lockstep is
  **correct** — the four plugins are one system, and a consumer running group 1 plus group 3 needs
  matching versions. The versioning problem dissolves with the rename instead of needing a fix. Recorded
  here because the obvious next move is to "repair" a script that is not broken.

**Verified.** The ruleset survived the repository rename — `main-ci-gate` is still `active` with
`lint-en-tests` required, so the CI gate and the no-`--admin` merge work unchanged. Lint gate: 0 errors
across 26 agent defs, 26 manuals, 4 personas, 148 link-scanned files and 19 checks. Test gate: 23 of 23
suites pass.

**What this does not do, and cannot.** The machine-side re-adoption — removing the old marketplace,
adding `DaveKJohn/claude-code-specialists`, dropping the stale user-scope registration, and confirming a
fresh session loads Chris from the new path — needs a session restart, and an agent runs inside the
session it would have to restart. That is the same structural limit inbound
[#402](https://github.com/DaveKJohn/claude-code-specialists/issues/402) reports about the Quickstart
itself, met here rather than read about. Those four acts are the handoff, written out in the run-book
[#409](https://github.com/DaveKJohn/claude-code-specialists/issues/409).

Two consequences worth stating rather than discovering. Until that handoff runs, a session in this repo
loads no specialists at all: `.claude/settings.json` now asks for
`specialists@claude-code-specialists` while the machine still knows only the old marketplace and the old
install record. And the flattening of `claude-code-plugins/claude-specialists/` is still ahead
([#405](https://github.com/DaveKJohn/claude-code-specialists/issues/405)), so the import paths this
change corrected will move once more — which is why the three family-level documents move to the root in
that step rather than this one.

Closes #404.

[PR #412](https://github.com/DaveKJohn/claude-code-specialists/pull/412)

---

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

---

## v1.15.0 — 2026-07-21

### #123 · Translate the GEGENEREERD, bewerk sentinel marker to English across the agent defs · Docs · 2026-07-21

Translated the last Dutch fragment in the agent-def shared-block sentinel comments to English, in
line with the repo-wide English-content norm: `<!-- BEGIN shared:NAME -- GEGENEREERD, bewerk
agent-shared/NAME.md -->` becomes `<!-- BEGIN shared:NAME -- GENERATED, edit agent-shared/NAME.md
-->`. The marker is literal per-file text (the generator preserves the BEGIN/END sentinel lines
as-is and only fills the body between them), so all 21 agent-defs across the three plugins were
updated directly, plus the one docstring example in `agent-shared-lib.ps1` and the one test
fixture string in `agent-shared.tests.ps1`. No regex in the generator or the lint gate matched the
Dutch text, so nothing there needed changing. Verified: `build-agent-defs.ps1 -Check` (in sync),
`check-plugin-integrity.ps1` (0 errors), and all `scripts/tests/*.tests.ps1` suites green.

[PR #123](https://github.com/DaveKJohn/davekjohns-workshop/pull/123)

---

## v1.14.0 — 2026-07-21

### #121 · Make the automation-first (lazy) rule a plugin-owned shared block, like inbound-behaviour · Feat · 2026-07-21

The automation-first ("stay lazy") behavioral rule is now plugin-owned via a new shared block,
`claude-code-plugins/claude-specialists/agent-shared/laziness-automation.md`, wired into the
subagent agent-defs via `<!-- BEGIN/END shared:... -->` sentinels — the same circle as
`shared:inbound-behaviour` — so the rule travels along to consuming repos instead of living only
in this repo's own `CLAUDE.md`. The per-specialist "X is lazy" examples in the manuals stay in
place as elaboration; `CLAUDE.md`'s own "Shared trait — all of them incredibly lazy" paragraph
remains as the governance narrative for the main loop (Chris and the main-loop personas, who carry
no agent-shared blocks), with a light note added that it is the same rule carried by every
specialist's shared playbook, not a second canonical copy.

[PR #121](https://github.com/DaveKJohn/davekjohns-workshop/pull/121)

---

## v1.13.0 — 2026-07-21

### #119 · Ship a per-plugin RELEASE.md card so consumers see which release they are on · Feat · 2026-07-21

Every plugin now carries a `RELEASE.md` card (version, one-line summary, and the entries for that
version) right next to its `CHANGELOG.md`. Chosen approach: **Model A, plugin-authored** — the card
lives inside the plugin folder and travels with the plugin cache via `claude plugin update`, so a
consumer can see exactly which release they're on without cross-referencing the workshop's own
`releases/` history. `cut-release.ps1` (re)generates the card for every plugin, in lockstep, on
every release; the lint gate's new check 9 guards that the card is present and its `vX.Y.Z` matches
that plugin's `plugin.json`. Deliberately **no SessionStart hook** announces this — the card is
discovered by opening the file in the plugin cache. Seeded on v1.12.1.

[PR #119](https://github.com/DaveKJohn/davekjohns-workshop/pull/119)

---

### #117 · English names for agent-shared blocks + script-comment translations · Docs · 2026-07-21

Completed the in-progress English-norm cleanup of the agent-shared machinery. Renamed the four verbatim-shared source blocks to English file names (`grens-inbound` → `inbound-behaviour`, `gedrag-taalkeuze` → `language-behavior`, `grens-webcontent` → `webcontent-boundary`, `grens-artifact-publish` → `artifact-publishing-boundary`) and pulled the whole chain along: the `shared:<name>` sentinels in all 21 agent defs across the three plugins, the generator-lib docstring, and the current-doc references in `README.md` and Ravi's lens. Also folded in the NL→EN comment translation of `connector-sessioncheck.ps1` and `bootstrap.ps1`. Functional/canonical markers deliberately keep their original form per the language convention's technical-identifier exception — the `VUL-IN` scaffold sentinel and a couple of marker phrases the drift tests key on stay as-is. History (`CHANGELOG.md` files, `releases/`) is left untouched. Generator, lint (0 errors), and all test suites are green.

[PR #117](https://github.com/DaveKJohn/davekjohns-workshop/pull/117)

---

## v1.12.0 — 2026-07-20

### #109 · Shared block for the language directive (Ravi) · Feat · 2026-07-20

Phase B left the closing "respond in the user's language" line verbatim-identical in 19 of the 20
agent defs. Ravi's duplication check recommended promoting it to a single source via the existing
`agent-shared/` mechanism — no new machinery needed, since the generator is line-based.

- **New source `agent-shared/gedrag-taalkeuze.md`** with the canonical line; the 19 identical agent
  defs now carry it between `<!-- BEGIN/END shared:gedrag-taalkeuze -->` sentinels, filled and
  verified by `build-agent-defs.ps1` like the `grens-*` blocks.
- **03-07 (Rebecca) stays local:** its line has a deliberate source-quoting nuance ("...quoting
  sources in another language is fine") — a near-duplicate that Ravi's own rule says not to force-merge.
- **Ravi's lens (06-24)** scope updated: the shared-block circle now names a third category
  (standalone behavior directives outside Boundaries/Working method) and lists `gedrag-taalkeuze`.

Naming note: the new source keeps the Dutch-style name of its `grens-*` siblings for uniformity;
renaming the whole `agent-shared/` set to English is a later-phase consistency item.

[PR #109](https://github.com/DaveKJohn/davekjohns-workshop/pull/109)

---

### #106 · Workshop switched to English — phase B: plugin content · Feat · 2026-07-20

Follow-up to phase A (#105): the shipped plugin content itself is now English, so consumers
worldwide read an English team. Covers all three plugins.

- **Translated:** the 20 agent definitions (prose outside the shared sentinel blocks), all 26
  manuals/playbooks, the 4 personas, `agent-shared/` (the canonical shared-bullet source), the
  three core skills + the shopify `start-task` skill, `specialists/scripts/README.md`, and the
  intro paragraphs of the three plugin `CHANGELOG.md` files (release history left as written).
- **Shared blocks regenerated:** `build-agent-defs.ps1` refilled every `<!-- BEGIN/END shared -->`
  region from the translated `agent-shared/`, so the sentinel content is English and byte-in-sync
  in all 20 agent defs.
- **Language directive aligned with the approved policy:** each agent def ended with a hard
  "work in Dutch" instruction. That contradicts the phase-A Language policy (specialists reply in
  the language the user writes in) and the worldwide-sharing goal, so all 20 now read "Respond in
  the language the user addresses you in." This is a behavior change beyond pure translation —
  flagged for review.
- **Slot-heading canon:** the human-readable `## Specific to this repo` section heading is now
  used consistently across manuals, lenses, and CLAUDE.md.

**Deliberately deferred to a later phase (scripts):** the machine-coupled Dutch marker
`## Eigen aan deze repo` still lives in `bootstrap.ps1` (the scaffold it writes),
`check-consumer-drift.ps1` (`Get-PortableBody` splits on it) and its test fixture; likewise the
`[FOUT]`/`[DRIFTED]` signal tokens, the `VUL-IN` scaffold marker, and the three Dutch PR-template
strings `open-pr.ps1` matches. Migrating those to English needs bilingual back-compat for
consumers that still carry the Dutch slot — a dedicated scripts phase. Lint and all seven test
suites pass.

[PR #106](https://github.com/DaveKJohn/davekjohns-workshop/pull/106)

---

## v1.7.0 — 2026-07-18

### #77 · Repo-lenzen naar het plugin-pad als standaard (primair + legacy-fallback) · Feat · 2026-07-18

De repo-lenzen van deze repo verhuizen van het legacy-pad (`.claude/extensions/`) naar het
**plugin-pad** (`.claude/plugins/claude-specialists/specialists/`) — de nieuwe standaard-locatie
(pariteit met life-hub). Om de andere consumerende repo's (life-hub, smartwatchbanden) niet te breken,
verwijst het gedeelde contract voortaan naar het **plugin-pad als primair, met het legacy-pad als
fallback** — een repo die nog op legacy staat blijft dus gewoon werken.

**Deze repo:**
- De 11 lenzen (incl. Ravi 06-24) + het handboek verplaatst naar het plugin-pad, met de relatieve
  link-diepte bijgesteld (2 → 4 niveaus). De 5 lege stubs (Paula/Bianca/Vera/Gwen/Cody) opgeruimd.
- De `@`-import onderaan `CLAUDE.md` → plugin-pad. Alle doc-verwijzingen (`CLAUDE.md`, `README.md`,
  het handboek) → plugin-pad. De persona-lens-index-regels naar locatie-onafhankelijke platte tekst.
- `check-plugin-integrity.ps1` scant nu de lenzen op het plugin-pad **én** het legacy-pad.

**Het gedeelde contract (raakt alle repo's, via de volgende release):**
- De ~20 agent-defs en de ~20 manuals verwijzen subagents nu naar het plugin-pad (primair) met het
  legacy-pad als fallback. De generieke lens-mention in het gedeelde `grens-inbound`-blok idem.

**Bewust uitgesteld (blijft werken via de fallback):** de **adoptie-laag** — `bootstrap.ps1` seedt
nieuwe consumenten nog op het legacy-pad, en `QUICKSTART.md` / `connectors/README.md` beschrijven dat
zo. Dat volledig omzetten (incl. de bootstrap-tests) is een aparte vervolgstap; tot die tijd landt een
verse consument op legacy en werkt hij via de fallback.

Lint en alle testsuites groen. De `## Releases`-CHANGELOG-entries zijn als historisch record ongemoeid
gelaten.

[PR #77](https://github.com/DaveKJohn/davekjohns-workshop/pull/77)

---

## v1.6.0 — 2026-07-18

### #74 · Gedeelde agent-def-blokken uit een enkele bron (build-en-lint) · Feat · 2026-07-18

Verbatim-gedeelde bullets onder **Grenzen** — de inbound-regel (19/19 agent-defs), de
webcontent-regel (3) en de Artifact-publiceer-regel (2) — werden tot nu toe in elke agent-def
handmatig gedupliceerd; één regel wijzigen betekende tot 19 bestanden aanraken. Ze komen nu uit
**één bron**, ingevuld door een generator en bewaakt door de lint-poort.

- **`claude-code-plugins/claude-specialists/agent-shared/<naam>.md`** — de canonieke bron van elk
  gedeeld blok (naast de plugin-mappen, zodat het niet met de plugin-cache meereist).
- **In de agent-defs** verschijnt elk blok tussen `<!-- BEGIN/END shared:<naam> -->`-sentinels. De
  inhoud staat er letterlijk (altijd-geladen, self-contained — Claude Code kent geen native
  transclusie in een agent-def), maar is als gegenereerd gemarkeerd.
- **`scripts/agents/build-agent-defs.ps1`** (+ `scripts/lib/agent-shared-lib.ps1`) — vult elke
  gemarkeerde regio uit zijn bron. Wijzig het bronbestand → draai het script → alle agent-defs bij.
  `-Check` meldt drift zonder te schrijven.
- **`check-plugin-integrity.ps1` (check 7)** faalt zodra een gemarkeerde regio afwijkt van zijn bron
  (hand-edit binnen de sentinels of een vergeten rebuild) — dezelfde poort die `open-pr.ps1` en CI
  al draaien.
- Regressietests in `scripts/tests/agent-shared.tests.ps1` (10 asserts) dekken de expansie, de
  drift-detectie, een BEGIN-zonder-END, een onbekend blok en de repo-in-sync-smoke.

De 19 agent-defs zijn puur omwikkeld met sentinels — nul inhoudelijke wijziging. Aanpassen van een
gedeelde grens kost voortaan één edit + één build in plaats van 19 handmatige wijzigingen.

[PR #74](https://github.com/DaveKJohn/davekjohns-workshop/pull/74)

---

## v1.5.1 — 2026-07-18

### #71 · Inbound-regel toegevoegd aan alle agent-defs · Docs · 2026-07-17

Elk van de 19 agent-defs in de drie plugins (`specialists`, `specialists-lifehub`,
`specialists-shopify`) heeft nu een eigen bullet in zijn **Grenzen**-sectie die de
inbound-route benoemt: verbeterpunten aan de gedeelde kern (de eigen agent-def en vakboek,
die van collega's, en alle andere onderdelen die de plugin draagt) bouwt een specialist
niet lokaal om; hij meldt ze via de vaste, afgesproken route — een issue met het label
`inbound` op de bron-repo van de plugin (het issue-sjabloon staat er al klaar), generiek
beschreven en zonder repo-eigen, persoonlijke of gevoelige details uit de eigen repo.
Werkt hij al in de bron-repo zelf, dan volgt hij daar gewoon de normale keten. Repo-eigen
aanvullingen horen in de repo-lens. Zo kent ook een rechtstreeks aangeroepen
werker-subagent deze regel, niet alleen Chris' persona-body en de QUICKSTART. De
formulering is na twee correctierondes (Edith's eindredactie: generieke plugin-onderdelen
+ collega's-agent-defs; Sean's security-review: standing-route-framing + de
anonimiseringscaveat) tot deze definitieve tekst gekomen.

[PR #71](https://github.com/DaveKJohn/davekjohns-workshop/pull/71)

---

## v1.5.0 — 2026-07-17

### #61 · Per-plugin CHANGELOGs: consument-gerichte release-geschiedenis die meereist · Feat · 2026-07-16

Elke plugin draagt nu een eigen `CHANGELOG.md` die met de plugin-cache meereist: de
consument-gerichte selectie uit de werkplaats-geschiedenis. De fold leidt per entry automatisch
een `Plugins:`-regel af uit de PR-bestanden (`gh pr view --json files`; de `connectors/`-map telt
niet mee), en `cut-release.ps1` schrijft bij elke release per plugin de rakende entries bij —
nieuwste bovenaan, met root-relatieve links herschreven naar absolute GitHub-URLs zodat ze in een
consument-cache blijven werken. Vier nieuwe pure functies in `release-lib.ps1` met twaalf nieuwe
asserts (50 totaal); drie seed-CHANGELOGs; Rendall's lens en het root-README beschrijven het
mechaniek. De root-`CHANGELOG.md` en `releases/` blijven de volledige werkplaats-geschiedenis.

[PR #61](https://github.com/DaveKJohn/davekjohns-workshop/pull/61)
