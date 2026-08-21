# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with — what the change deploys to `main`, and the PR.
The first holds the change's two audiences, the second of them under `#### What makes this change extra
special`; the tier numbers live in the parser rather than in any heading. Entries written before
August 16, 2026 carry the longer set of headings that shape replaced, and every earlier shape is read
exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## `feat/release-page-second-pass` deployment

### What does the change on this branch deploy to main?

The release-notes page gets its second editorial pass. It began as the four inbound issues one consumer
filed after reading the deployed page --
[#809](https://github.com/DaveKJohn/claude-code-specialists/issues/809),
[#811](https://github.com/DaveKJohn/claude-code-specialists/issues/811),
[#813](https://github.com/DaveKJohn/claude-code-specialists/issues/813),
[#816](https://github.com/DaveKJohn/claude-code-specialists/issues/816) -- taken as **one pass and not
four**, because #816 says so itself: dropping the type chip from the row and `**Type:**` from the note
independently would leave the newest release with no type anywhere. It then went through eight rounds of
Dave reading the built page, and two of those **replaced** an answer rather than adding one, which is the
part worth keeping.

**The masthead says one thing per line.** The eyebrow carries the product name and the heading says
`Release notes` -- the other way round from how it shipped, where the product name was the `h1` over a
hardcoded eyebrow, so a repo whose title said what the page was printed those words twice. This repo's own
answer did exactly that. `Get-ReleasePageTitle` therefore answers **whose** releases the page carries, not
what it is, and all four layers that document it now say so. The window title joins the two, where a tab
has no duplication to make because it shows one line.

**The row carries only what differs between releases**: the version, the date, and at most one chip. The
title left the summary and lives in the note, which retired two things the first draft carried -- the
three-row phone layout #811 asked for existed *because* the title was the longest field, and the chip had
to be written as two spans with one hidden by CSS *because* a grid cannot move an inline child of one cell
into another. With no title cell the row fits on one line at every width. The title still travels as the
row's accessible name, where it costs no width.

**The chevron moved to the trailing edge** and stopped reserving a gutter -- `1rem` plus a `.9rem` gap
ahead of every row, which the narrow query kept, so a phone spent 9.4% of its usable text width on a glyph
where space is scarcest. **The version column hugs its content** rather than carrying a stated width: it
was `4.25rem`, then `6.5rem` once the label became `Version 2.39`, and a number that has to be raised
whenever the label grows is one that will one day be too small without saying so. That removed the last
magic number with it -- the note used to be indented to line up with a title column that no longer exists,
so it starts at the row's own left edge now, with its breathing room as padding on the article rather than
as the first paragraph's margin, so it does not depend on whether a note opens with a paragraph, a heading
or a list. **And `.sheet`'s top margin is gone rather than made responsive**, which is how #811's ask 6 was
answered in the end: `2rem` over the masthead's own `1.5rem` of bottom padding was 3.5rem of air above a
list, and that padding is the separation.

**The version reads `Version 4.17`** rather than `v4.17`: the short form is developer shorthand and this
page's reader is management and the commissioner, for whom a lone `v` is a convention they have no reason
to know. It still drops a trailing `.0` where every release on the page has one (#813) -- a patch gets no
hand-written note, so the third digit is a constant -- derived from the data rather than from
`Get-ReleaseConsumerBumps`, because that seam is overridable and a repo writing notes for patches
genuinely needs three digits. **The `id` keeps the full semver**, since it is the target of links people
already hold, and the deep-link handler accepts the short spelling too.

**The chip marks what is UNUSUAL, and the first version of this rule shipped nothing.** It was built as
"render it where the type varies", which is #811's own wording -- and that page has two distinct types, so
a variance test answers *varies* and leaves all 39 chips exactly where they were. The report's figure was
**38 of 40**, not "two values". Caught by Dave asking why the label was still there. The rule now
suppresses the chip on every row carrying the page's most common type and keeps it where a row differs,
which is the rule the `live` chip already follows -- its absence meaning "not live". Measured here:
**27 chips became 2**, one `LIVE` and one `Major`.

**`LIVE` falls back to the newest release** where the history table marks none, and the marker still wins
where there is one -- in a Shopify repo the live theme is genuinely not always the latest cut, which is
why that marker exists. Derived rather than marked because a marker has to be moved by hand at every cut,
in a file the cut itself writes into: right on the day it is set, silently wrong at the next release. The
cost is stated in the code: a repo whose live version is older and which never marked it now gets a label
that is wrong where before it got none, and marking the row is the override that stops the derivation.

**Both halves of reading a note work on a phone now.** An open row's summary is `position: sticky`, so the
one control that closes a `<details>` stays in reach -- median note 317 words, longest 1,018, which is one
to six phone screens between a reader and their way out. And **closing puts the reader back on the row they
opened**: without it the document has just got several screens shorter and they land in the middle of the
index with no idea which row was theirs. Only when the row has scrolled off the top, and instantly, because
this restores a position rather than travelling to a new one. The sticky half is pure CSS so the index keeps
reading with JavaScript off; the scroll half is an enhancement in a script that already renders the bodies.

**The note stops restating the row it is inside** (#816). Every note opens with `# Release notes vX.Y.Z`,
the date in a second format, the type, and a `**For whom:**` sentence -- measured across 40 notes, that
last one had exactly **two** distinct strings whose only difference was `--` versus an em dash. It is
dropped **on render**, not in the document: the note is read in two places and the block is redundant in
only one, so the markdown in the repository keeps it and the page does not. That is also the only version
of this fix that reaches the notes **already published**, which are records and are not rewritten.
Conservative by construction -- nothing is stripped unless the body opens with an H1 naming its own version
-- and it takes forty `article h1` elements and a rocket off a page that goes to a commissioner.

**`## For consumers` became `## What changed`, at both tiers.** A heading that names its reader tells that
reader nothing they do not already know, and the section *below* it does name a reader -- on purpose,
because that one is the half the audience section may not contain. This finishes
[#747](https://github.com/DaveKJohn/claude-code-specialists/issues/747) rather than undoing it: that
finding was that `For consumers` names the wrong reader in a tier-1 repo, and both tiers answering the same
thing is what lets the key stop being tier-dependent at all. **Notes already published keep the heading
they were written with**, so the page shows the new wording from the next cut onward and the old wording
above it. Renaming a generated heading at render time was considered and left out of this branch.

**`Get-ReleasePageMasthead`** is the new seam (#809), so a consumer can keep its own wordmark(s) above the
title. Data-URIs and base64 only -- the page is self-contained because a request to a third party leaks who
is reading it, and a raw svg payload is markup inside an attribute. Three documented ceilings, each
enforced with a **warning and never a build failure**: two marks, 32 KB each, 64 KB in total. Two rather
than five is a measurement: the consumer's own editorial round tried five and cut back, because five read
as a page about the brands rather than about the releases.

The page suite went from 87 to **143 asserts**, including every way the masthead seam can be answered
wrongly and a pin on the chip rule that the retired variance test would fail -- so the version that fixed
nothing cannot come back looking like a simplification.

**Score:** 3

#### What makes this change extra special

This page is what management and the commissioner read, and since 2026-08-21 it is the **only**
release-notes page that consumer has: the hand-edited edition that used to carry these editorial decisions
was deleted, deliberately, because a fork of the shared template in one repo is drift -- that copy had
already served pre-renumbering version numbers to management for five days. Having ended the fork, every
one of these adjustments has exactly one correct home, and this is it.

So the reader gets a row that carries only what differs between releases, a version number written the way
somebody who is not a developer reads one, a masthead where each line says one thing, a way out of a note
they have finished, and a page that puts them back where they were when they close it. **Most of the pass
was subtractive** -- a word that repeated 38 times, a tenth of a phone's line, 3.5rem of air, a title
printed twice, three magic numbers -- which is the shape of an editorial round rather than a feature.

**Score:** 4

### Pull Request · 20260821-175005

The release-notes page: a leaner index row, a masthead seam, and notes that stop restating their row

Plugins: workflow-davekjohn

[PR #820](https://github.com/DaveKJohn/claude-code-specialists/pull/820)

---

## `fix/sync-content-provenance` deployment

### What does the change on this branch deploy to main?

The Shopify pre-task sync stops deciding who wins a file by **when** the trunk last touched it and starts
deciding by **whose content live is holding**. Reported as inbound
[#807](https://github.com/DaveKJohn/claude-code-specialists/issues/807); the report's urgent half
(`--no-merges` on the floor lookup) was already repaired on `main` by
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801) and this is the second half it
named as the next release.

The old rule was the **wrong measurement** rather than a buggy one, and that is why repairing the floor
could not have been enough. Nothing pushes the trunk *to* live except the per-file release step, and a
deletion cannot be pushed that way at all -- so the trunk's changes are permanently invisible to live and
sink below the floor as soon as one more sync commit lands. From that moment on, every future sync tries to
overwrite them again, forever.

What replaced it:

> Has this path ever held live's content in the trunk's history? Then the trunk wins. Otherwise live wins
> -- and if the trunk also changed it, nobody wins and a human looks.

`scripts/lib/sync-rules.ps1` gains five functions for that (`Get-GitRawBlobId`, `Get-CrStrippedBytes`,
`Get-GitStoredBlobId`, `Test-LiveContentIsOurs`, `Get-SyncFileVerdict`) and `scripts/task/sync-main.ps1` is
rewritten around them. **The floor survives, demoted:** its only remaining job is to notice that live's
content is foreign *and* the trunk changed the same path recently -- both sides moved -- and refuse. A
wrong floor now costs an extra conflict report instead of silent data loss.

Three structural changes make the script unable to destroy work rather than merely unlikely to:

- **Live is pulled into a mirror outside the repo**, and the working tree is written only for the paths
  whose verdict is `take-live`. The wholesale version pulled over the tree and then restored what it should
  not have taken, so every bug in the rule was a bug that had *already* overwritten the file.
- **It never deletes.** A path the trunk has and live does not is reported, not acted on.
- **The branch name is decided before the pull**, so a collision stops the run while the tree is clean.

`-DryRun` is new and is the first thing to run: every verdict, nothing written, and allowed on a dirty tree
because that is exactly when somebody wants to ask what the sync would do to it. `-MirrorPath` and
`-KeepMirror` come with it. **`-SkipPull` is retired** -- it meant "run the rule over the working tree",
which cannot mean anything now -- and is still accepted so the refusal can name what replaced it.

**Two mechanisms in the reference implementation were verified against git rather than adopted on trust,
and one of them was broken.** `git check-ignore --stdin <paths>` answers `fatal: cannot specify pathnames
with --stdin` and exits 128, which the quiet wrapper swallows -- so that filter silently reported nothing
ignored, and a repo ignoring `config/settings_data.json` would have captured live's copy as foreign drift
on every run. Feeding real stdin is not available either: Windows PowerShell 5.1 does not connect a
pipeline to a native executable's stdin here and has no `<` redirect. The batched argument form is what
ships, with a test that proves it. `git ls-tree --format` was the second: it needs git 2.36, and the
default output carries the same fields behind a tab, so this reads the default.

**A third came out of writing the comparison rather than out of the report**, and it fails in the losing
direction: git quotes any path holding a byte above `0x7F`, so an accented theme filename arrives from
`ls-tree` as `"assets/caf\303\251.js"` and matches nothing the mirror walk produces. The trunk's copy would
read as a path live does not have while live's *identical* file read as content the trunk has never held --
foreign, taken, trunk overwritten. `core.quotePath=false` on both path queries fixes it, and the assert
that pins it was checked the only way worth checking: with the flag removed again, where it fails.

The two suites grew from 24 to **78 asserts** together. The headline case is `ours/buried`, which is the
whole change in one fixture: the trunk fixed a file, a later sync commit buried the fix below the floor,
and live still holds the trunk's old copy. It asserts both halves -- that the content rule holds the file
back, *and* that the time rule has already lost it -- so the fixture cannot rot into agreeing with itself.

**Score:** 4

#### What makes this change extra special

For a consumer running `sync-main.ps1`, this is the difference between a sync that protects merged work and
one that reverts it on every run until somebody notices. And "merged but not live yet" is not an edge case
there: it is a **designed** state, which is what a pending `CHANGELOG.md` entry means -- so adopting this
marketplace's changelog model is what made the naive sync strictly more dangerous in the first place.

It was measured both ways in `xoxowildhearts` before it was built, and the false-negative half is the one
that matters, because a rule that is safe by capturing nothing is useless. Against live on 2026-08-21: 31
differing files, all 31 content that repo has held, so the new rule captures **zero** -- correctly, since
there was no third-party drift, only the trunk having moved forward. The old rule captured all 31 and was
about to revert three merged PRs. Replayed over every past "from live" commit: **10 of 11** real drift
files come back foreign and are captured; the 11th reverted a single trailing blank line.

Two Shopify consumers load `team-shopify`, and only one of them has a local repair plus the temporary
`PreToolUse` hook that routes its sessions away from the shipped skill. The other runs the shipped copy as
it stands. That hook is marked temporary in its own header with its removal condition stated -- an
installed `team-shopify` that ships the repaired rule -- which is this.

**Score:** 5

### Pull Request · 20260821-153417

The Shopify pre-task sync decides by content provenance instead of a time window

Plugins: team-shopify

[PR #818](https://github.com/DaveKJohn/claude-code-specialists/pull/818)

---

## `feat/team-shopify-push-preview` deployment

### What does the change on this branch deploy to main?

Pushing a branch to its own unpublished preview theme is the same call in every Shopify repo, and until now
every Shopify consumer wrote it themselves. `team-shopify` owns it from this release:

- **[`scripts/lib/preview-theme.ps1`](scripts/lib/preview-theme.ps1)** builds the two `shopify theme push`
  calls and holds every `--*` token against a whitelist measured off `shopify theme push --help`. Plus two
  readers of the CLI's own output that were inline expressions in the consumer's copy: the id of a theme
  that was created-and-pushed in one call, and the theme-list lookup.
- **[`scripts/task/push-preview.ps1`](scripts/task/push-preview.ps1)** resolves the target in four steps
  — an explicit id, the id remembered in the branch's git config, a name lookup, else it creates the
  theme — refuses the trunk, refuses live, and prints the preview URL(s).
- **[the `push-preview` skill](plugins/teams/team-shopify/skills/push-preview/SKILL.md)**, with the
  `Get-ShopifyPreviewUrls` seam written out.

**Lazy creation is the design, and it is measured.** A preview theme used to be created for every branch at
the moment the branch was made, including branches that could never touch a theme file. Measured on the day
the rule was made: 49 themes on one store, 47 unpublished, 16 named after a branch — and of the 12 real
branch previews, **6 belonged to branches that never needed one**. A Shopify store has a hard ceiling of 20
themes, so that estate eventually refuses the next push. A preview theme is a consequence of *"I want to
show this"*, not of *"I am starting work"*.

**Two things went further than [#805](https://github.com/DaveKJohn/claude-code-specialists/issues/805)
asked for**, and both are the same argument the report itself makes for the whitelist — the code that
cannot be run without a store is the code that has to be testable:

1. **Two more functions moved into the lib.** Parsing the new theme's id out of `--json` is the half that
   *cannot be re-run*, because the create call pushes at the same moment it creates. And the theme-list
   lookup carries a PowerShell 5.1 member-enumeration trap — `$parsed.themes` yields an array of `$null`
   that is truthy, so a bare `if` throws away the right list — which made a consumer's fallback report
   "no preview theme found" every single time. Both were untestable inline; both are pinned now, including
   the duplicate-name case, which **throws** rather than picking one, since pushing to the wrong of two
   identically named themes is invisible until somebody opens the preview.
2. **`start-task` was rewritten.** Not in #805's scope, but its page still said `team-shopify` ships no
   script because *"which markets get a preview URL … are facts about a store estate"* and told the reader
   to create a theme by hand at branch time. With lazy creation that is the opposite of the rule, so the
   two skills would have contradicted each other. It opens the branch now and states that the theme is
   `push-preview`'s job — and the reason that page's argument no longer holds is worth keeping: what made
   the step unshareable *was* the preview theme, and lazy creation is what separated the two.

**The market table is deliberately NOT shipped.** `Get-ShopifyPreviewUrls` is an optional seam because that
table genuinely is per-store: one consumer runs a single domain with locale-prefixed paths, another runs
five separate domains, so a shared table would have produced four domains that do not exist. What *is*
shared is that a preview link needs `_ab=0&_fd=0&_sc=1` to survive the first internal click — without them
you are looking at live while believing you are looking at the preview, which cost a consumer a whole
review. So a repo without the seam still gets one working URL rather than none.

**Score:** 4

#### What makes this change extra special

The reason to ship this rather than let each repo keep its copy is the failure that produced the report. A
consumer's create path spelled the flag `--theme-name`, which the Shopify CLI has never had. It failed the
**first** time anybody needed a preview theme created — written one day, reached the next, by the first
branch that actually wanted one. Nothing was wrong with the reasoning; the code had simply never run, and
a per-consumer copy means every consumer gets to discover that independently.

The whitelist earned its place immediately: on its first run it refused the lib's **own** call, because
`--unpublished` had been left out of the list. Same class of error, caught in three seconds instead of a
day.

Two design points from the consumer's review are kept deliberately. The whitelist answers *"is this a real
CLI flag"* and never *"may this repo use it"*, so it **admits** `--allow-live` — refusing a live push is
the guard hook's job, and a validator answering both questions would give two different answers to the
same one. And `Get-ShopifyLiveThemeId` is **recommended** here rather than required, unlike for `sync-main`:
that script reads *from* live and cannot work without it, while this one pushes to an unpublished theme and
wants the id for a belt-and-braces refusal the guard hook makes anyway. So it warns and continues instead
of blocking a preview.

**Score:** 4

### Pull Request · 20260821-144911

team-shopify owns push-preview, and validates the CLI flags it builds

Plugins: team-shopify

[PR #814](https://github.com/DaveKJohn/claude-code-specialists/pull/814)

---

## `fix/entry-link-destination-gate` deployment

### What does the change on this branch deploy to main?

A branch writes its entry in `workflow-davekjohn/branch/branch-deployment.md`, two directories down, and
the fold copies that text **verbatim** into `CHANGELOG.md` at the repo root. So a relative link in an entry
has to be written root-relative — which means it looks wrong in the file being edited and only becomes
right after it moves. Nothing said so, and the natural instinct produces the broken form.

Three parts, in the order an author meets them:

- **The convention is stated where the body is typed.** The guidance block above the entry's first section
  ([`scripts/lib/entry-scaffold-lib.ps1`](scripts/lib/entry-scaffold-lib.ps1)) now names the rule with both
  forms side by side, so it reaches the author before any gate does — and because the templates are
  generated from that block, it travels to every consumer through the same plugin update as the scripts.
- **`open-pr` gains a link gate.** `Get-EntryLinkTargets` and `Get-EntryLinkFindings` read the entry's
  relative links and hold them against the repo root; [`scripts/release/open-pr.ps1`](scripts/release/open-pr.ps1)
  refuses to push while one of them is dead. The message prints the **root-relative form**, not only the
  dead one — a finding that says merely *"does not exist"* sends the author to add another `../`, which
  breaks a link that was right.
- **The portable half says it too**, in
  [`BRANCH-portable.md`](plugins/workflows/workflow-davekjohn/BRANCH-portable.md) and in
  [the `open-pr` skill](plugins/workflows/workflow-davekjohn/skills/open-pr/SKILL.md), including why
  `branch-cycle.md` is deliberately **not** subject to the rule: that file never travels, so `../` is
  correct there.

**Two departures from what inbound
[#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806) asked for, both measured.**

It reported that *"a consumer-side linter structurally cannot [check this] — it runs before the move"*, and
proposed the fold as the only place that knows both paths. This repo's own lint has resolved the entry's
links **from the repo root** since August 6, 2026 —
[`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) carries that branch
with the measurement of the day the `branch/` split broke it, and even names the base in its finding for
exactly the reason above. So a linter can; what the reporting consumer lacked was not a mechanism but the
**rule**, and a rule is what a plugin can ship. Building the fold check would have been a second
implementation of a rule the lint already owns — the double-registration failure #805 names in the same
batch.

And the gate sits in `open-pr` rather than in the fold because that is the fold's **own** doctrine on this
kind of fault, stated in its own words about a missing significance score: a defect decidable before the
merge is refused while the branch is still the only thing affected, since refusing an already-merged
branch's fold leaves an unfolded entry on the trunk with `main` looking finished. The report's preferred
option — rewriting the links as it folds — is declined for a second reason: the fold copies the entry
verbatim on purpose, and an author whose link is silently corrected writes the same link again into the
next document, where nothing corrects it.

**Score:** 3

#### What makes this change extra special

`open-pr.ps1` and `entry-scaffold-lib.ps1` are both mirrored into `workflow-davekjohn`, so every consumer
gets the gate and the guidance — including the one that filed this, whose PR #43 would have been refused
before the push instead of leaving two dead links in the file nobody re-reads.

The exclusion set was measured rather than assumed, and the measurement is what makes the gate usable:
across the last **80 revisions** of this repo's own entry file, a scan that strips only fenced code
produces exactly **one** finding, and it is false — `[PR #N](url)` in inline backticks, in an entry
explaining what the fold writes. So inline code and HTML comments are stripped as well, which is the same
three-way exclusion this repo's link lint arrived at from the same case.

**Score:** 3

### Pull Request · 20260821-142425

an entry's relative links are held against the destination they fold into

Plugins: workflow-davekjohn

[PR #812](https://github.com/DaveKJohn/claude-code-specialists/pull/812)

---

## `fix/cut-release-baseline-crosscheck` deployment

### What does the change on this branch deploy to main?

`cut-release.ps1` read the version it bumps **from** out of the plugin manifests, or failing those out
of the highest `v*` git tag — and never held that number against the release overview it is about to
write a row into. Neither of those is the document that says which release is which, and where one
disagrees the cut still succeeds: the number can be right while the bump **type** is wrong in four
places at once and in silence. The `**Type:**` line in the generated notes, the `Type` cell of the
overview row, the question `Test-ReleaseBumpEarned` answers, and whether the hand-written consumer
document is drafted at all.

Three changes, one guardrail and two diagnostics:

- **[`scripts/lib/release-lib.ps1`](scripts/lib/release-lib.ps1)** gains `Get-OverviewLatestVersion`:
  the release the overview records as newest. It walks on to the next table where the first is empty,
  because that is exactly the state a freshly opened major section is in — the highest-stakes cut there
  is, and the one a first-table-only reader would leave unguarded.
- **[`scripts/release/cut-release.ps1`](scripts/release/cut-release.ps1)** refuses on a disagreement,
  naming both numbers and where each came from, with the other guardrails and before the first write.
  `-Type <major|minor|patch>` is the way through, deliberately **not** a `-Skip` switch: a bypass would
  hand back the very label the check caught, while stating the type produces a correct release. And the
  `-NoPush` path now closes with `($current -> $new, $typeLabel)` — the flag whose whole purpose is
  reading a release before it is public was the one path that hid the number every label hangs on.
- **[the `cut-release` skill](plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md)**
  documents `-Type`, and repairs a claim that had gone stale in the other direction: it said
  `release-lib.ps1` was deliberately **not** mirrored into the plugin, while the reporting consumer read
  `Get-BumpType` at line 136 of its own install cache. A page that talks a reader out of looking where
  the answer is costs more than one that says nothing.

**It refuses on both routes in, which goes further than inbound
[#802](https://github.com/DaveKJohn/claude-code-specialists/issues/802) asked for** — it proposed
refusing only where `-Version` was passed. `-Bump` is the worse of the two, not the safer one: with
`-Version` the author has named the number and only its label is wrong, while `-Bump` computes the
number **from** the baseline, so a wrong baseline produces a version belonging to a different release
altogether. The reporting consumer met exactly that and was saved by an unrelated refusal downstream,
which is luck rather than a guard.

**Score:** 4

#### What makes this change extra special

`cut-release.ps1` is mirrored into `workflow-davekjohn`, so every consumer cuts its releases with this
script — and **one stray tag is enough** to trigger the whole failure. `--sort=-v:refname` takes the
highest `v*` tag in the repo, so a single mistyped `v99.0.0`, a per-component tag in a monorepo, or
imported history relabels every later release as a Major, silently, with no policy decision by anyone.
Two of the four consequences are the ones a consumer cannot see: a guardrail evaluating a bump type
that is not being cut, and a document appearing (or failing to appear) for the wrong reader.

The reporting consumer had to correct a cut by hand afterwards — delete an audience document that
should never have been drafted, change `Minor` to `Patch` in two files, and repoint an overview cell
whose link would otherwise have failed their own lint gate on a dead link.

**Score:** 4

### Pull Request · 20260821-135831

cut-release cross-checks its bump baseline against the release overview

Plugins: workflow-davekjohn

[PR #808](https://github.com/DaveKJohn/claude-code-specialists/pull/808)

---

## `feat/register-xoxowildhearts-workflow-slot` deployment

### What does the change on this branch deploy to main?

The workflow slot in `connectors/xoxowildhearts.json`, which that manifest deliberately left blank on
2026-08-20 -- inbound [#800](https://github.com/DaveKJohn/claude-code-specialists/issues/800), and the
follow-up the manifest's own note asked for rather than a defect report. The deferral was right and the
answer it predicted was the losing one: `feat-harness-hardening` merged as PR #7, `ad315a1` did switch the
slot to `workflow-default`, and the same day the consumer reversed it -- `463e091` adopts
`workflow-davekjohn`, `01a2723` disables `workflow-default` so exactly one workflow holds the slot. All
four commits were read in the consumer's own history rather than taken from the report, and
`extensions: []` is the measured answer: the plugin ships no `agents/` directory.

**The condition the deferral set is now measured wider than the report could.** It said to write the block
once the branch had merged, because a state about to move records an `[ERROR]` half the time. Rather than
check `main` alone, all **16** of the consumer's remote branches were read: every one carries
`workflow-davekjohn: true`, so nothing in flight moves the slot back. `check-connectors.ps1` now reports
four plugins `[OK]` for this consumer where it reported three.

**Why registering it is the repair and not a formality.** `check-connectors.ps1` loops over the plugins a
manifest *lists*, so an enabled plugin absent from that array is invisible to the version check -- and the
report walked into it: a session-start `[ERROR]` named three drifted plugins where four had drifted, and
the one it could not name was `workflow-davekjohn`, the plugin that ships `connector-sessioncheck` itself.
**Measured across all five connectors, this was the only enabled-but-unregistered plugin anywhere**, so
registering it empties the class. The asymmetry is named and not repaired: the analogous case one level
down -- a lens present but unregistered -- already prints an `[INVENTORY]` line, and the plugin level has
none. A risk whose population is now zero gets written down, not built.

**And the recount found more than the issue asked about, which is the half worth reading.** #800 asked for
one block. Verifying the manifest around it showed that **all three** "differences" it records for this
consumer had become false, each overtaken by the very branch the slot note named as in-flight:

| the manifest said | measured 2026-08-21 |
|---|---|
| no `CHANGELOG.md` at all, a flat `update_log.txt` | `CHANGELOG.md`, 15 `##` sections, the workflow's own intro (`8541994`) |
| has not adopted `workflow-davekjohn/` | present and fully scaffolded -- `branch/`, `prompts/`, `releases/`, three docs |
| lint gate at `--fail-level crash`, 1504 pre-existing offences | `--fail-level error` since `ad315a1`, green on five consecutive runs |

They are corrected in the same change, because a register whose whole purpose is to record what a consumer
**has** cannot carry three claims it no longer has while a fourth accurate one is added beside them. One of
the three also carried a wrong reading of inbound #763 -- it recorded that the missing-folder `[ERROR]` had
been answered by disabling the hook's own plugin, and the consumer did the opposite and adopted the folder.

**Score:** 3

#### What makes this change extra special

Nothing here travels to a consumer -- the register lives in the source and only this repo can write to it,
which is why the issue placed no bridging note anywhere. What travels is the shape of the mistake, and it
is the one the workflow's own folder page already warns about in a different document: **a stale line
copied forward becomes a false line.** Every one of those three claims was true when written. Each was
measured against `main` on a day when a named, in-flight branch was about to change the answer -- the same
branch the slot note was deliberately waiting on -- and none was re-read when it merged. So the note that
correctly deferred the one field it knew would move sat directly above three fields that moved for exactly
the same reason.

The transferable rule is narrower than "re-verify everything": **when you defer one field because a branch
is in flight, the other fields that branch touches are deferred too, whether or not you wrote them down.**
Waiting on a branch and then reading only the field you were waiting on is how a record ends up
three-quarters wrong while its one careful sentence looks like diligence.

**Score:** 2

### Pull Request · 20260821-130211

the register records xoxowildhearts' workflow slot

[PR #804](https://github.com/DaveKJohn/claude-code-specialists/pull/804)

---

## `fix/sync-reference-point-no-merges` deployment

### What does the change on this branch deploy to main?

`--no-merges` in the `git log` lookup inside `Get-SyncReferencePoint`, and it is a one-flag repair for the
worst failure this script can have: the exclusion rule keeping **nothing** back while printing a reference
point as though all were well. Reported from `xoxowildhearts` as inbound
[#801](https://github.com/DaveKJohn/claude-code-specialists/issues/801) against the 4.17.0 payload.

`--grep` matches any **line** of a commit message rather than the subject, and a sync branch merged with a
merge commit carries the sync commit's own subject in its body. So the merge matches `^[Ss]ync`. Right after
a sync PR lands that merge is `HEAD`, the floor becomes `HEAD`, `Test-MainTouchedSince` answers `$false` for
every path, and every file on live wins -- including every file a merged PR had just changed on the trunk.

**The reason was verified before the repair, and the file predicted its own defect twice.**
`Get-SyncDefaultReferencePattern`'s docstring already says a floor that is too recent "is the direction that
loses work", and `Get-SyncReferencePoint`'s already says that without a floor "the exclusion rule silently
passes everything through -- which is precisely the failure it exists to stop". Both were written about the
pattern and neither covered the merge. The seam cannot close it either: no `--grep` pattern separates a
subject from a body line, and `--no-merges` does. Skipping merges can only move the floor **backward**, onto
the sync commit the merge brought in, which is the protective direction.

The suite pins **both halves** -- that the shipped lookup finds the sync commit, and that the same lookup
*without* the flag genuinely picks the merge -- so `--no-merges` cannot be tidied away later as a style
choice. The consumer's own report asked for that second assert and it earns its place.

Two smaller things came off the same report. The `--` pitfall note now sits beside `Invoke-SyncGitQuiet`
itself rather than only at the one caller that had learned it: a bare `--` typed inline never reaches git,
and for a path the trunk has **deleted** the resulting error goes to the stderr this wrapper swallows by
design -- a silent `$null` and the losing answer.

**Two of the report's four items are deliberately not built, both with their measurement.** Its
`> $tmp` byte-mangling trap does not apply here -- these scripts never redirect blob content, and
`sync-main.ps1` contains no `cat-file` and no redirect to a temp file at all, so there was nothing to
repair. And its section 2 replaces the time-window measurement wholesale with a content-history rule, moves
the live pull into a mirror outside the repo, and forbids deletion. That is a redesign of the sync policy,
not a defect repair, and it goes to Dave as a proposal rather than riding in on a one-flag fix. The floor
repair here is what makes waiting on that decision safe.

**Score:** 4

#### What makes this change extra special

For a consumer running `sync-main.ps1` from 4.17.0, this is the difference between a sync that protects
merged work and one that quietly reverts it, and the failure was measured rather than reasoned about. In
`xoxowildhearts` on 2026-08-21 the next sync was about to delete 21 lines from `locales/de.json` and 20 from
`locales/nl.json` -- the twelve translation keys a PR had merged the previous day -- revert two `| raw`
removals in `snippets/switch-module.liquid`, and resurrect 23 locale files a commit had deliberately
dropped. Thirty-one files, three merged PRs, and a green run.

**The second Shopify consumer is exposed and not yet bitten, which is the part worth reading.** In
`smartwatchbanden` the newest matching commit is the same with and without the flag, because that sync
landed as a squash rather than a merge commit -- so nothing is wrong there today, and the first sync PR that
lands as a real merge poisons its floor. It has `Get-ShopifySyncMerges = $true`, which is the path that
produces exactly that merge. Update before the next sync rather than after it.

The transferable lesson sits one level up from Shopify: **a guard whose failure mode is a green run has to
be tested from the failing side too.** This one had a suite, six asserts on the reference point, and a
docstring naming the losing direction -- and it shipped with a hole, because every case asked what the
lookup finds and none asked what it must not find.

**Score:** 5

### Pull Request · 20260821-123711

the sync floor no longer lands on a merge commit

Plugins: team-shopify

[PR #803](https://github.com/DaveKJohn/claude-code-specialists/pull/803)

---

## `docs/v4-17-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.17.0 release
document froze at a subtotal of **11m 12s** because three of its legs were still running on the file it was
written into -- its local gates, its CI and merge, and the publish. Those legs now have clock readings, so the
total goes in: **32m 19s** end to end, with the local gates and push **4m 03s**, CI and the merge **15m 22s**,
and the fold plus publish **40s**. There was no requester gap to separate out this time; the run was
continuous, so wall clock and working time are the same number.

**The reading worth the branch is which check governed the wait.** `lint-en-tests` is the only required check
on `main` and it passed in **9m 29s**. `claude-review` is not required and took **15m 09s**, and `ship-pr`
waits for every check rather than for the required one -- so the merge landed 15m 22s after the pull request
opened, and that single leg is **48%** of the release. Both figures were read from `gh pr checks` and the
ruleset rather than inferred from the wall clock.

**It is named and not repaired**, under the rule that a risk which has not bitten gets written down rather
than fixed. One measurement is not evidence for changing what the merge path waits on, and the same wait is
what a reviewer would want if the review were the point. It is recorded in the release document's open
section so the next release has something to compare against.

Two readings the first pass could not produce. The head came to **18%** of the total, the lowest of the six
releases timed so far (`v4.15.0` 21%, `v4.12.0` 24%, `v4.16.0` 26%, `v4.13.0` 30%, `v4.14.0` 32%) -- and the
reason is stated rather than left to read as an improvement: the head did not get faster, the tail got longer.
And the frozen subtotal was 65% short of the total, in line with 66% at `v4.4.0` and 70% at `v4.16.0`.

**Score:** 2

#### What makes this change extra special

It puts a third consecutive end-to-end measurement beside the first two, and this one complicates the
fixed-cost claim in a useful direction rather than confirming it: **24m 34s** for v4.15.0's thirteen entries,
**25m 29s** for v4.16.0's four, **32m 19s** for v4.17.0's nine. The spread still does not track the entry
count, which is the claim -- but the longest of the three is longest for a reason that has nothing to do with
its contents, and a reader who saw only the three totals would draw the wrong conclusion about batching.

For a consumer running this workflow, the transferable part is the diagnostic rather than the number: when a
release feels slow, check which check is governing the merge wait before assuming the work grew. The required
gate and the slowest gate are not necessarily the same one, and only the first is the one anybody chose.

**Score:** 2

### Pull Request · 20260820-200637

The v4.17.0 release note gains its end-to-end total

[PR #799](https://github.com/DaveKJohn/claude-code-specialists/pull/799)

---

## `docs/v4-17-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.17.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

All nine of this release's entries reach tier 2, which is the largest set this document has had to order.
Five of them carry an action, so those five open the page -- the `team-shopify` pre-task sync first, since it
is the only item where the thing being replaced has already destroyed work in both repos that hand-wrote it.
The four that carry none say **no action needed** in as many words rather than leaving it to be inferred, and
the theme-delete marker gets the same treatment despite being a new capability, because doing nothing is a
complete answer to it.

Every mechanism the page instructs a reader to invoke was read in the tree before it was written down, not
carried over from the entry bodies: `adopt-shopify-floor`'s `-StoreDomain` and `-LiveThemeId`, `sync-main`'s
six seams and which two of them refuse to guess, `adopt-workflow-folder` as the placer of
`.github/workflows/branch-entry.yml`, and `Get-EntryGateExemptPrefixes` defaulting to `sync`. That check is
the reason the sync section names two required seams rather than the one the entry emphasises.

Both organisation sections are written. *What it is worth* leads on the distinction between the guard this
family shipped in v4.15.0 and the sync it ships now -- one prevents a bad act, the other prevents a good act
from silently reverting finished work -- and on the two-consumers-derived-the-same-artefact pattern appearing
for the second release running, this time with both consumers making the same mistake. *What was still open*
is a snapshot, with every figure read at its source: the organisation's publication target at `84e6316` with
all four team plugins at 4.16.0, and the registered consumer three releases behind, read from the session
check rather than from a document.

**Step 0a's baseline was taken before starting this time**, which the v4.16.0 record notes was missed, so this
page's timing legs are clock readings rather than reconstructions from file timestamps.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where the cost of doing nothing is invisible until it has
already happened. A `team-shopify` consumer who keeps their own sync keeps an implementation whose first
version destroyed work in both repos that wrote one, over a failure -- a deletion is also a touch -- that
produces no error and no warning, only quietly reverted files. The page gives them the command, names the two
seams the script refuses to guess, and states what it never does, so converging onto it does not read as
handing a script the authority to push.

The page also carries the correction the previous release could not: v4.16.0's Release was published one step
early and its attachment was the generated draft. This one follows the checklist's order, so what a reader
downloads is this document rather than the entry bodies.

**Score:** 3

### Pull Request · 20260820-194607

The v4.17.0 release note

[PR #798](https://github.com/DaveKJohn/claude-code-specialists/pull/798)

---

