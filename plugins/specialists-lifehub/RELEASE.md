# Release v3.2.0

**Date:** 2026-08-03  
**Type:** Minor

One product, one marketplace: renamed and flattened, with the release cut shared and three tiers deep

This card describes v3.2.0, the version your plugin manifest carries. Whether it is the code you are running is a separate question: the documented update path installs from `main`, so a `main` that has moved past the tag reports this same number. [The version is not the code](https://github.com/DaveKJohn/claude-code-specialists/blob/main/ADOPTION.md#staying-up-to-date) in ADOPTION.md is the check.

## Features

### #418 · Flatten the plugin directory layer into plugins/ and give the repo one landing page · Feat · 2026-08-03

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

## Fixes

### #419 · Repair the stale marketplace name in generated intros · Fix · 2026-08-03

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

### #399 · the release card states what it describes, not where you are · Fix · 2026-08-02

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

## Documentation

### #424 · QUICKSTART becomes ADOPTION.md, with a real quickstart beside it · Docs · 2026-08-03

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

## Maintenance

### #412 · rename the marketplace to claude-code-specialists · Chore · 2026-08-03

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

Full workshop notes: [releases/development/3.x/3.2.0.md](https://github.com/DaveKJohn/claude-code-specialists/blob/main/releases/development/3.x/3.2.0.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
