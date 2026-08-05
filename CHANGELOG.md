# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it three
named sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the impact table, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — the impact table
under *Who is this for*. That is what orders this list: furthest reach first, and within a tier the most
consequential change first. It also decides what may be released: **a release needs at least one tier-1
entry**, **a minor needs a tier-2 one**, and a **major** recaps ten minors. So a changelog holding nothing
but tier 0 is a changelog with no release in it yet.

## #477 · A shared parser's change is probed against a consumer's document, not only this repo's

### What does this change do?

One hard rule added to [Sylvester #15's portable manual](plugins/specialists/manuals/05-15-manual.md):
**when a shared script changes what it recognises, probe it against a consumer's document.** A shared
script reaches a consumer through a plugin update rather than by their choosing, so a parser that has
learned a new shape meets their *old* one first — and the source repo is the worst possible place to
notice that, because it is the one repo that has already migrated. Its own files are the new shape by the
time the change is finished, and every test written alongside the change uses the new shape too.

**The rule names the failure mode, which is silence rather than an error.** A parser handed a shape it was
not written for produces a confident, well-formed, wrong answer, and the gates that might have caught it
are often reading that same answer.

**The measured instance is [#476](https://github.com/DaveKJohn/claude-code-specialists/pull/476),** where
`CHANGELOG.md` became one flat list of `##` entries. Probed against a consumer still on the pre-flat shape,
their `## Pull Requests` heading parsed as ONE entry swallowing every real entry and `## Releases` as a
second — so their whole release history would have been published into the release notes and the
per-plugin CHANGELOGs as a "change", and then deleted from `CHANGELOG.md`, because the cut keeps only the
intro. **And nothing refused:** blocks like that declare no impact, so the bump gate read the repo as never
having adopted the tier model and reported itself *inactive* — correct by its own rule, and the reason the
release would have proceeded. Found by building a synthetic consumer while scoring that branch's own entry,
not by a failing suite. The guard that now refuses it shipped in the same PR.

**And it states what makes the repair safe**, which is the half easiest to get wrong: a refusal that will
fire in repos you cannot see needs an *exact* discriminator, not "looks wrong". Name the shapes that are
legitimate, check that each declares something the old shape cannot, refuse the rest before writing
anything, and name both the offending part and the migration. A refusal that can fire on a legitimate
document is worse than the defect, because it arrives in someone else's repo.

**It goes to the portable manual rather than to this repo's lens**, per the August 4, 2026 rule: the source
is the default destination and the lens is the exception that needs a reason. Nothing about this rule is
specific to this repo — any repo maintaining scripts that travel to consumers meets it — and a portable
rule filed in a lens is not wrong anywhere, it simply never arrives.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | a colleague changing a shared script now has the check written down instead of rediscovering it the way this one was rediscovered -- noticed the moment they touch that part |

### Type of change

Docs

Plugins: specialists

[PR #477](https://github.com/DaveKJohn/claude-code-specialists/pull/477) · merged 2026-08-05

---

## #476 · Every change is an H2 with three named sections, and the tier sections are gone

### What does this change do?

`CHANGELOG.md` drops every `##` section heading. `## Latest Release` and the three
`## Tier N - Pull Requests` sections are gone; a change **is** the `##` heading now, and inside it three
`###` sections answer the questions a reader arrives with:

```text
## #475 · A significance score per entry, and the order follows it

### What does this change do?

…the description…

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | … |
| 1 | 4 | … |

### Type of change

Feat

Plugins: specialists

[PR #475](https://github.com/DaveKJohn/claude-code-specialists/pull/475) · merged 2026-08-05
```

`Plugins:` and the PR line stay **plain lines**: a heading around one fact is more structure than content,
and `Plugins:` is machine-read by the cut. Dave, August 5, 2026.

**The three tier sections lasted one day, and removing them takes nothing away.** They said exactly one
thing — how far each change reaches — and since [#467](https://github.com/DaveKJohn/claude-code-specialists/issues/467)
the entries say that themselves, in a table that also carries what the change is *worth*. So what the
headings did visually is kept as the **ordering**: furthest reach first, and within a tier the highest
significance first. The fold is the only moment that order can be decided, because the cut empties the
list — whatever order the fold leaves is what the release documents inherit, with nothing re-estimated
days later.

**The release block goes entirely**, and the reason is measured rather than aesthetic. It had grown to
**434 of the changelog's 1,062 lines** across 72 blocks that each said no more than "see the notes", while
[`releases/README.md`](releases/README.md) already listed every one of those 72 versions with a date, a
type and a descriptive title — the same coverage, verified in both directions, and richer per row. The
intro now carries a one-line pointer to that page, and a cut writes nothing at all: it empties the document
down to its intro, which passes through verbatim, so whatever a repo says about itself up there survives
every cut in whatever language it wrote it.

**The release documents follow the same flat shape, and that deletion is the point.** The category grouping
is gone, with `Format-CategorizedEntries`, the category labels and the `Get-ReleaseCategoryTitles` seam. It
grouped on the **branch prefix**, which this repo has measured does not predict impact — at v3.2.0 the
single most consequential change for a consumer arrived on a `chore/` branch — so a document's most
important change was filed third under whichever label its prefix produced, and #467's ranking could only
reorder the categories, not escape them. Each change states its own type inside itself now.

Six seams retire: `Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` (#178) named section
headings the document no longer has; `Get-ReleaseCategoryTitles` labelled the categories;
`Get-ReleaseLiveMarker`, `Get-ReleaseHistoryMode` and `Get-ChangelogReleaseWording` (#462) all described the
release block. A consumer that still defines one is unaffected — nothing calls them. **What #462's
non-English consumer loses is stated rather than glossed over:** the capability is not withdrawn, the
*output* is gone, and what replaced it is hand-written prose in a file they own outright.

#### The two defects this found, both silent and neither reported by a test

**A consumer's release history would have been published as a "change" and then deleted.** Found by probing
a synthetic consumer while scoring this entry, not by a failing suite. Every `##` below the intro is read as
one change now, and a document still carrying the pre-flat shape has headings at exactly that level —
reached through a plugin update rather than by that repo's choosing. Measured: `## Pull Requests` parsed as
ONE entry swallowing every real entry and `## Releases` as a second, so the whole release history went
outward into the notes and the per-plugin CHANGELOGs and was then removed from `CHANGELOG.md`, because the
cut keeps only the intro. **And nothing refused** — blocks like that declare no impact, so the bump gate
read the repo as never having adopted the model and reported itself inactive, correctly by its own rule.
`Split-Changelog` now refuses before returning anything, naming each block and the migration. The
discriminator is exact rather than a heuristic: the format has two legitimate shapes and both declare
something — the three named sections, or a pre-format entry's type in its heading — while a section heading
carries neither and cannot. Deliberately not keyed on the `#NN` the fold prepends, because the fold writes a
legitimate numberless entry when `gh` is unreachable.

**The lint gate had stopped recognising entry files at all.** `Test-IsChangelogEntryFile` in
`check-plugin-integrity.ps1` still looked for `^###\s`, with a comment explaining that restating the level
rather than importing it was deliberate — importing meant dot-sourcing the fold script, which would run a
release action to answer a lint question. Sound reasoning whose conclusion went stale the moment the entry
format moved into `entry-scaffold-lib.ps1`, a pure lib that file already loads. So since the format landed,
check 13 silently judged nothing and reported clean, and check 11 stopped excluding entry files from its
scan set.

#### Five reversals the plan did not carry, all for one reason

The section heading was the thing that used to state an entry's reach.

- **The `Tier: N` line is KEPT, not consumed.** With no heading above the entry, stripping it leaves the
  entry declaring nothing, and every downstream reader takes that as tier 0 — silent, correct-looking, and
  wrong in the direction that empties a release document. `Remove-EntryTierLine`'s caller moved to the
  outward renderers instead, beside `Remove-EntryImpactTable`: the line now reaches `CHANGELOG.md`, which
  puts a self-assigned tier on the path to a consumer's plugin cache unless it is dropped there.
- **A pre-format `###` entry file is PROMOTED to `##` as it folds**, outside the PR block. An `###` in a
  flat list of `##`s is not an entry boundary, so it would be absorbed into the block above and inherit that
  block's PR link. Doing it inside the PR block — where the `#NN` prepend lives — would have skipped it
  silently for a manual merge or an unreachable `gh`. Not hypothetical: a branch parked on the remote
  carried exactly such a file.
- **`Test-EntrySignificanceActive` had to be repaired in the same commit, and this was a landmine.** It
  answered "off where there is no tier split" by counting the changelog's sections. With no sections that
  read returns one section in *every* repo, so the scaffold's table, both validators and the cut's
  significance gate would all have switched themselves **off**, without erroring, in the same commit that
  made the ranking the document's only ordering. It defaults **on** now, with `Get-EntrySignificanceEnabled`
  as the opt-out. `Test-ReleaseBumpEarned`'s `Active` flag had the same defect and now keys on whether any
  pending entry **declared** its impact — a measurement rather than a flag, and one that keeps "declared
  tier 0" distinct from "declared nothing".
- **An unscored entry sinks to the BOTTOM of its tier**, not the top. The plan and two comments said the
  top; the code was right. The loop reads an entry already in the changelog with no score as 0 and sorts it
  below everything scored at its tier, so a top-insert would rank the same entry differently on either side
  of the fold.
- **`Get-ImpactInsertOffset`'s `-Undeclared` switch is gone.** In a flat list there is no unplaced entry:
  declaring nothing is tier 0, which the loop already lands correctly.

Two refusals disappeared, both structurally rather than by relaxation: **"could not find the heading"**
(there is no heading name left to mismatch) and **"this repo declares no section for tier N"** (a tier the
repo does not use is a position, not an error).

#### And the parser recognises both shapes while the writer only writes one

These are *shared* scripts, so a consumer who adopted the tier sections would otherwise get a plugin update
whose scripts cannot read their own changelog. The **declaration** is read in both shapes (table or
`Tier: N`) and a pre-format heading's type is still recognised, because every entry in this repo's history
and in every consumer's tree predates the table and the release notes are regenerated from that history.
The **structure** is deliberately read in the new shape only: an entry's own `###` sections and a pre-format
`###` entry heading are indistinguishable, so a parser accepting both would read every entry as four. That
is what the new refusal exists to say out loud instead of guessing.

#### What was measured, not assumed

- All **26 suites** and all four gates green. `release-lib.tests.ps1` was **rewritten rather than patched**
  (353 asserts): every fixture in it was the old document shape, and the machinery varying which sections a
  repo declared tested a seam that is gone. Patching would have left a suite whose fixtures nothing writes,
  passing by looking at a document that cannot occur. Its `New-FlatEntry` helper has its own shape asserted
  before the suite uses it — this file has already paid once for a fixture that did not contain what it was
  written to contain.
- This repo's own `CHANGELOG.md` is migrated: **6 entries, not the ~25 this branch's own note predicted** —
  v3.5.0 had already been cut, which is why the repo is read rather than the note. Structural only, with
  significance cells left **empty**, because filling them in would be exactly the guessed ranking #467
  removed. Verified with the real parsers: 6 entries read back, the scored one leads, the unscored sink below
  it in arrival order, and the bump gate reports itself active.
- Two things that looked like leaks in the outward documents were a **fence-blind probe**: the only
  survivors sit inside code fences, in the entries that document the format itself, while every real
  declaration is stripped.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | a consumer whose `CHANGELOG.md` still has section headings must migrate it: measured, their release history would otherwise be published as a change and then deleted, with nothing refusing. The cut now refuses instead and names the migration, so the action is required but the failure is loud |
| 1 | 4 | every entry this team writes changes shape, and the changelog stops being three sections to scan -- noticed the same day, without being told |

### Type of change

Feat

Plugins: specialists

[PR #476](https://github.com/DaveKJohn/claude-code-specialists/pull/476) · merged 2026-08-05

---

## #475 · A significance score per entry, and the order follows it

### What does this change do?

Closes [#467](https://github.com/DaveKJohn/claude-code-specialists/issues/467).

The tier model answers how far a change **reaches**, and therefore which document an entry appears in.
This adds the second axis: how much it **weighs** for that document's reader, and therefore **where in
it** the entry sits. Both are now declared in one **impact table**, which replaces the `Tier: N` line:

```text
| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | consumers must re-add the marketplace under its new name; installs break without it |
| 1 | 4 | the routine version bump stops needing a developer |
```

**The tier is the row, and that is what the shape buys.** The ladder is cumulative, so a change consumers
notice is also a change colleagues get something out of — as rows that is impossible to claim halfway. The
rows an entry has *are* the documents it appears in, and each row is that document's reader answering their
own question. The score cells are scaffolded **empty**, deliberately unlike the old `Tier: 0` default: 0
was a harmless final answer, while any scaffolded score would be a guess at a **ranking** — the exact
failure the retired highlights marker was measured on.

**1 to 5 against a written rubric** (`Get-EntrySignificanceRubric`, overridable per repo), in the shape
severity levels and ITIL impact levels use: 5 is *the reader must act*, 1 is *nothing changes for them
today*. That is what makes the number a measurement rather than a mood, and it is why the score is
comparable across releases. The **`Why` is required** and is the lasting half — the rubric says which band,
the `Why` says why *this* change is in it.

**The fold is the only moment `CHANGELOG.md` can be ordered**, because the cut empties the tier sections:
whatever order the fold leaves behind is what the release documents inherit, since they read the section in
document order and sort nothing. That makes the ordering reproducible across two moments days apart with
nothing re-estimated. Insert-only, never a re-sort — this commit lands directly on `main`, so a bug must be
able to misplace at most the one entry being folded rather than scramble a section it did not write.

**Where each score is read.** The highlights re-read the **tier-2** row (their reader is the consumer); the
internal note reads the **tier-1** row. **Tier 0 is never ranked** — the development note is the record:
complete and chronological. The table **survives into the record**, which is the last place each ranking's
justification lives, and is **stripped from everything that travels outward** (highlights, per-plugin
`CHANGELOG.md`, `RELEASE.md`), because a self-assigned number printed at a consumer is a marketing claim.

`cut-release.ps1` refuses a release whose tier-1-or-higher entries have not scored themselves, with
`-SkipSignificanceGate` as the escape valve — separate from `-SkipTierGate`, because one overrules whether
the release should exist and the other how its contents are ordered. `open-pr.ps1` refuses a *malformed*
table while the branch is still the only thing affected, but only **reports** a missing score: that is a
judgement about a finished change, and an author who has not settled it should not be blocked from merging.

**`Tier: N` is still read, and always will be** — "recognise both, write one". Every entry already in
`CHANGELOG.md` and in every consumer's tree predates the table, and a parser that only knew the new shape
would read all of them as tier 0: silent, correct-looking, and wrong in the direction that empties a
release. The whole mechanism switches itself **off** where a repo declares no tier split, and can be
switched off explicitly via `Get-EntrySignificanceEnabled`.

**Two bugs worth recording, both caught while building this and both now asserted.** An
`[ordered]@{ 5 = '...' }` indexer takes a **positional** index for an integer, so `$rubric[5]` asked for the
sixth element of a five-element map — the exact trap `Resolve-ChangelogTierSections` already warns about in
the same file, walked into one screen below the warning; on a longer map it would have silently returned a
neighbouring band's text instead of throwing. And `Sort-Object` is **not stable** in PowerShell 5.1, so
ordering on the score alone would let equal-scoring entries come out differently from one run to the next —
a regenerated release document differing from the published one with nothing having changed. The arrival
index is now the tie-break.

**The name was `Happiness` for one afternoon.** Dave rejected it as unprofessional, and he was right about
more than the word: *happiness* names an emotion in the reader, which an entry's author is in no position to
assert, while the weight of a change for an audience is something they can judge. Recorded alongside it
because it is the first thing anyone reaches for: **RICE and WSJF do not apply here.** They price work
*before* it is done, with effort in the denominator — they answer "what do we build next". Everything scored
here is already merged, so effort is spent and irrelevant.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | a consumer's next entry file looks different and their next cut asks for scores -- noticed the same day, without anything breaking: entries written before this still fold |
| 1 | 4 | the release documents now order themselves by consequence, so the most consequential change leads instead of sitting third under whichever heading its branch prefix produced |

### Type of change

Feat

Plugins: specialists

[PR #475](https://github.com/DaveKJohn/claude-code-specialists/pull/475) · merged 2026-08-05

---

## #474 · The lens scaffold's title carries no (VUL-IN) -- only its slot does

### What does this change do?

**`specialists-teardown -Apply` would have deleted written repo knowledge, and the dry run pointed at
the wrong files.** The lens template wrote `(VUL-IN)` into the H1 title *and* the slot heading;
filling a lens replaces only the slot; and `Test-LooksGenerated` matches `(VUL-IN)` at **any** heading
level. So the title outlived the filling and a lens somebody had written kept classifying as a
disposable scaffold — permanently, and more so the longer that repo worked with it. Inbound
[#451](https://github.com/DaveKJohn/claude-code-specialists/issues/451) measured it in a consumer with
24 lenses: three filled specialist lenses holding 153 lines between them all printed `[remove]`.

**The fix is the rule this same script already followed 320 lines further down**, for `SPECIALISTS.md`,
where the code comment spells out the reasoning it was breaking here — *"A (VUL-IN) title would survive
a filled-in roster and make the teardown delete somebody's work."* The lens template did exactly what
that comment forbids, for every lens instead of one file. The marker now sits on the slot alone, which
is also the only thing an unfilled scaffold needs: the slot heading is still there, so an untouched
lens is still recognised and still removed.

**The dangerous direction was the one that had no test, and the reason is worth keeping.** A filled
lens was already covered — but that fixture *hand-wrote* its lens, and gave it a title of its own
(`# 06-16 repo lens`) rather than the title the bootstrap produces. Inventing the boilerplate is what
made it blind: the only shape that reproduces this defect is the real generated file edited the way a
consumer edits it. The new test therefore runs the actual bootstrap, replaces only the slot heading,
and asserts the file survives `-Apply`. Verified by falsification rather than by passing: with the
marker put back, that assertion fails and the lens is deleted.

**And it is not retroactive, so the instructions carry the other half.** A repo bootstrapped before
this release keeps a marked title on every lens it fills from here on, and that repo cannot be reached
from this one. The bootstrap's closing hints and the `specialists-init` skill page now say that filling
a lens means the marker goes — and that on an older repo it has to come off the **title** too, with the
one-time sweep to find them. Of the two pairings #451 offered, this is the instructions one; the
alternative it also suggested — a check reporting "content beyond the boilerplate but still a
`(VUL-IN)` heading" — is deliberately **not** built here, because the obvious implementation
misclassifies an *untouched* `SPECIALISTS.md` as authored: that scaffold legitimately contains real
import lines, so "anything beyond headings and comments" is not boilerplate there. Doing it properly
means moving the scaffold wording into a shared source both scripts read, which is the
`Get-ClaudeMdScaffold` pattern and a larger change than this defect needs. The front-matter `filled:`
key stays with [#237](https://github.com/DaveKJohn/claude-code-specialists/issues/237), where it was
already proposed.

**In this repo the risk is latent rather than live**, which is why it went unnoticed here: six lenses
carry a marked title (02-09, 03-02, 04-11, 04-12, 04-13, 06-30) and all six are genuinely unfilled, so
they are classified correctly today. Each is one edit away from the trap.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | - | - |
| 1 | - | - |

### Type of change

Fix

Plugins: specialists

[PR #474](https://github.com/DaveKJohn/claude-code-specialists/pull/474) · merged 2026-08-05

---

## #473 · An inbound issue is verified as still standing before it is routed

### What does this change do?

**An inbound issue was picked up as open work an hour after it had been repaired.** #469 reported that
`fold-changelog-entry.ps1` kept the entry-creation date instead of the merge date. It was filed at
08:04; #472 repaired it on `main` at 09:24; it was still labelled open when the next session reached
for it. Nothing was built twice — the check that caught it was reading the code before starting — but
nothing in the intake required that reading either, and the outcome would have been a second repair
competing with the first on a defect nobody had.

**So the check is now the front of intake, in Chris's portable persona.** A filed report is a snapshot
of the moment somebody wrote it, and the gap between filing and pickup is exactly the window in which
the defect may already have gone — sometimes closed by the very work that was underway while the report
was being written. His first act on an inbound item is therefore to read the code, doc or output it
describes and establish that what it reports is still true, before classifying anything.

**This repo is where that gap is widest, which is why the rule is portable rather than local.** A
consumer *files* inbound issues; the source both receives them and does the repairing, so filing and
fixing can cross inside a single morning — and they did. But the rule is a timeless statement about
intake, not something only true here, so it goes to the source and the lens keeps just the citation
of where it was measured. The layer test in the
[Specialists handbook](.claude/specialists/README.md#where-a-new-rule-goes--the-source-is-the-default-the-lens-is-the-exception)
is what decided that, and it is the reason the persona text carries no issue numbers or dates at all.

**Closing an already-repaired item is stated as the assignment, with the evidence attached** — because
two things about #469's close showed that "check first, then close" is not enough on its own:

- **The repair had gone further than the report proposed.** #469 offered three options and preferred
  restamping the date at fold time; what shipped removed the date from the heading altogether and let
  the fold add it at the bottom. A silent close would have left the reporting repo applying the
  documentation fix it had planned — which was now the wrong wording, since the author no longer writes
  a date at all.
- **The audit the report suggested in passing was worth running.** #469 noted that anyone auditing an
  existing `CHANGELOG.md` could compare each heading's date against `gh pr view --json mergedAt`. Run
  here across `CHANGELOG.md` and `releases/`: **7 of 326** dated headings disagree, all by one or two
  days. They are deliberately left alone — they sit in published records that already travelled to
  consumers in the plugin cache, and moving a date by a day rewrites shipped history for no reader's
  benefit. Both entries still pending in `CHANGELOG.md` were correct.

**And the companion rule it does not replace.** This repo already required that a finding's *reason* be
verified before it is repaired, after an inbound report whose symptom was real and whose explanation was
wrong. That guards against repairing the wrong cause; this one guards against repairing a cause that is
already gone. The persona now names both in order: establish the report still stands, *then* verify the
reason it gives.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | - | - |
| 1 | - | - |

### Type of change

Docs

Plugins: specialists

[PR #473](https://github.com/DaveKJohn/claude-code-specialists/pull/473) · merged 2026-08-05

---

## #472 · The merge date is added by the fold, at the bottom, instead of scaffolded into the heading

### What does this change do?

**This entry's own heading is the specimen: it carries no date.** The scaffolder used to write one, and
it ran when the *branch* was created — so what it recorded was the branch's birth date, not the landing
date. A branch opened on Monday and merged on Thursday was filed as Monday's work, silently, in the one
document whose whole subject is when things happened. Dave, August 5, 2026.

**The date is now the fold's, and it goes at the bottom** — his second call, and the better one. The
heading was mixing two kinds of fact: the author knows the title and the type, while the PR number and
the merge date do not exist until the merge. That second kind already had a home at the end of the entry,
on the `[PR #NN](url)` line. So the two facts the fold owns now sit together:

```text
### #NNN · Short strong title · Feat

…the description…

[PR #NNN](https://github.com/DaveKJohn/claude-code-specialists/pull/NNN) · merged 2026-08-05
```

**It reads the PR's own `mergedAt`, not the clock**, and that distinction is not theoretical here. The
fold usually runs seconds after the merge, but this repo has measured it not doing so: unfolded entry
files were once found sitting in the repo root the morning *after* their merge — the silent half-state
that put `git status` into Chris's stand-verification rule. A clock reading would have dated those a day
late with nothing in the output to say so. `mergedAt` costs nothing: the fold already makes exactly one
`gh pr list` call, and gh returns whatever fields are asked for in one roundtrip.

**The dangerous half of this change was not the date at all.** `Format-CategorizedEntries` read each
entry's branch type as the **second-to-last** middot field of its heading — correct only because a date
happened to follow the type. Removing the date would have made that read return the type's neighbour, and
every entry in every release document would have landed in the `Other` catch-all: no error, no empty
output, one meaningless heading where the categories used to be. Found by reading the code before
touching it, not by a failing test. Both heading parses are now **content-based** rather than positional
— the type is recognised by matching the known branch types, the date by its shape — so the same code
path reads a dated heading and a dateless one. That is also why nothing had to be migrated: this repo's
entire history keeps parsing.

**`Convert-EntryHeadingToTitle` needed the same treatment and taught the sharper lesson.** The first
implementation walked in from the end eating anything that looked administrative, and a newly written
assert caught it on `### #12 · Fix · Fix` — an entry whose title *is* a type name. It ate both fields and
gave up. The tail has a grammar (at most one date, and before it at most one type), so it is matched
rather than walked; two types in a row cannot both be the type, which the grammar states and a greedy
loop cannot. `Other` is deliberately not treated as a type: it is the catch-all label this repo prints,
never a value a branch table produces.

**The closing line became `Format-EntryFoldFooter` in the entry-format lib, and the reason is testability
rather than tidiness.** The fold drives a live remote, so its own suite deliberately runs without a PR —
which would have left the only path this line has untested. Extracting the pure part is the same move,
for the same reason, as `Get-ExistingPrRecord` in `pr-issues-lib.ps1`. Its five asserts cover the normal
case, the PR timestamp beating the fallback, a fold that runs a day late, a PR with no timestamp yet, and
an unparseable one degrading instead of throwing — because a completed fold must not read as failed over
a cosmetic line.

**Four asserts in the branch suite got stricter rather than looser.** They pinned `· Feat ·` — a trailing
middot that only existed because a date followed. They now compare the whole heading line, which proves
both that the type is there and that nothing follows it; the malicious-title scenario in particular gains
from that, since a prefix match would have passed even if a broken argv boundary had appended something.
Plus one new assert stating the point outright: the scaffold writes no date.

**One cost, stated rather than smoothed over.** `CHANGELOG.md` can no longer be scanned for dates from the
headings alone — you read an entry's last line. That is acceptable because the tier sections only ever
hold what is pending since the last release, a window of days in which the dates sit close together. The
release notes, where the history actually lives, keep the line per entry.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | - | - |
| 1 | - | - |

### Type of change

Feat

Plugins: specialists

[PR #472](https://github.com/DaveKJohn/claude-code-specialists/pull/472) · merged 2026-08-05

---

## #471 · Publishing the GitHub Release is part of a cut that was already asked for

### What does this change do?

**Cutting a release is asked for; the closing steps of that cut are no longer asked for again.** The
version bump and the tag are the irreversible act and stay behind an explicit request. Once that is
given, the run goes through in one motion — generate the artefacts, ship the two hand-written documents
via their branch and PR, **publish the GitHub Release**. Stopping at the last step of a checklist the
requester started is a rubber stamp, and a rubber stamp trains everyone to stop reading it. The same
reasoning that made the PR merge a default rather than a checkpoint (July 27, 2026), applied one step
further along. Decision by Dave, August 5, 2026.

**The boundary that remains is Block 2 of the checklist, and it is a boundary rather than a carve-out.**
Where a repo sets `Get-LiveStage` it has a second stage — pushing to the live target — and that is a
different act with a different audience: a Release document describes a version, a live push changes
what customers see. This approval covers Block 1. A repo wanting another boundary states that in its
own lens.

**Four places said this and they had to stop disagreeing.** The constitution named "creating a tag or
GitHub Release" in one breath under *only on explicit request*, which would have outranked everything
else written elsewhere — the safety rules take precedence over any convenience, so leaving that line
standing would have made the new default unusable in exactly the sessions that read the rules
carefully. It now separates the tag from the publication. Rendall's **portable body** carries the
statement in his own terms, the release page's **portable half** carries it where the closing step is
described, and the **cut-release skill** carries it at step 5, which is where somebody actually reads
it mid-procedure.

**And the reason all four are portable is itself now a written rule, in Tessa's manual.** The first
draft of this change was headed for Rendall's *repo lens*, because that is where the decision was made.
Dave's correction: where a decision is made says nothing about where it applies, and what he wants in
this repo he wants in the others he runs the plugin in. The failure mode is quiet — a general rule
filed in a lens is not wrong anywhere, it simply never arrives, and nothing reports its absence.

**The corollary was the second correction, and it is the sharper one.** Knowing the rule was portable,
the next instinct was to *narrow* its wording so it could not surprise a consumer with a live deploy
stage. That is the wrong repair: it weakens the core for every reader to pre-empt one repo that has its
own place to speak. The core is stated in full here; the deviating consumer records the deviation in
its own lens. Both halves are in Tessa's hard rules now, because she is the one who guards which half a
sentence belongs in.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | - | - |
| 1 | - | - |

### Type of change

Docs

Plugins: specialists

[PR #471](https://github.com/DaveKJohn/claude-code-specialists/pull/471) · merged 2026-08-05

---

## #470 · The v3.5.0 release documents: the internal note and the edited highlights

### What does this change do?

The two documents `cut-release.ps1` deliberately does not write, for the release cut earlier today. Both
land here rather than on the release commit because that commit is already tagged, and neither is one of
the two named direct-on-`main` exceptions.

**The internal note (tier 1) is written from scratch, as it must be** -- the generated skeleton supplies
the metadata and the entry titles as bullets, and the one section carrying the tier's whole point, *what
it is worth*, is the one nothing can generate. Written in time, risk and reduced dependence on a
developer: the version number stopped being a matter of taste, three audiences stopped sharing one
document, and a gate we believed was running turned out not to be.

**The highlights (tier 2) went from 300 lines to 60, and that is the edit rather than a side effect of
it.** The generated draft is now the right *selection* -- the four tier-2 entries, chosen by their own
authors instead of guessed from branch prefixes -- but it is still their words, written for a reviewer.
The reader of this document decides whether to update, so the rewrite drops every file name, function
name and assert count, and keeps the four things that reader can act on: the changelog gains tiers and
the bump has to be earned, the shared release script stops assuming it runs in its home repo, two
workflow scripts resume instead of failing, and nothing changes for a repo that has adopted none of it.

**One line was deliberately not written into the internal note**, and its absence is the lesson from
v3.4.0's note holding. That tier warns that it is a *snapshot* and goes stale in hours where it is also
the published release body -- measured once by a line stating the previous release had no public page,
which its own author then published. So the open-points section names what sits with whom, and says
nothing about what has or has not been published as of the hour it was written.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Docs

[PR #470](https://github.com/DaveKJohn/claude-code-specialists/pull/470) · merged 2026-08-05

---

