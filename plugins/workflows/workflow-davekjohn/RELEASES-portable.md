# Releases — the portable half

**How a release works.** A release is not a deploy but a **recorded moment**: a git tag that marks the
state of the repo at that version. This page carries the **process** — the tier model, what a release must
earn, the release documents, and how one is cut — for every repo that runs this release workflow, naming
the *seam* wherever a repo owns the answer. **Your repo's own `releases/README.md` is its set of answers
to it**: the seam values in force there, its local decisions, and the **full list of releases** it has
actually cut — the one such list there is, on the page `Get-ReleaseHistoryPath` names.

[`scripts/release/cut-release.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/release/cut-release.ps1)
itself publishes nothing to GitHub Releases — that is a separate, manual closing step. Releases are cut
**only on the repo owner's explicit request**; see [Cutting a release](#cutting-a-release) below for the
full mechanics. Where the repo publishes plugins — `Get-ReleasePluginTier` answers that, and it gates the
whole plugin half — each release bumps every plugin's `version` in lockstep, and that number in
`.claude-plugin/plugin.json` is what tells a consumer which release they are on. Where it does not, the
current version is read from the newest `vX.Y.Z` tag instead, exactly as the script already does.

**How to read this page.** It travels with the plugin, so two conventions keep it true in every tree it
lands in. *This repo* always names the **source repo** the page was written in
([claude-code-specialists](https://github.com/DaveKJohn/claude-code-specialists)) — its measurements travel
as the evidence behind the rules, never as your repo's own record. And links into the source's script tree
are **absolute** on purpose, so they resolve from wherever this page is read; files every adopting repo has
of its own (`scripts/repo-config.ps1`, `CHANGELOG.md`, `releases/README.md`) are named in code rather than
linked, because the copy that matters is yours.

## The tier model

**One scale, used twice.** A change declares how far it reaches, and that number decides two things: which
document — and, where the document has more than one reader, which section of it — the change appears in,
and, together with its significance score, where within that section it sits.

| tier | who notices | where it is written | when |
|---|---|---|---|
| **2** | subscribers of the service | the *For consumers* section of `audience/<dir>/<X.Y.Z>.md` | minor/major |
| **1** | management and the employer/commissioner | the organisation's two sections of that same file | minor/major |
| **0** | only this repo's own developers | `development/<dir>/<X.Y.Z>.md` | every release |

**Tiers 1 and 2 are two KINDS of audience, and this repo has exactly one of them** (Dave, August 12, 2026;
inbound [#620](https://github.com/DaveKJohn/claude-code-specialists/issues/620)). They are not two rungs of a
ladder. Tier 1 is management and whoever commissions or pays for the work — the audience of a repo that
*delivers* something, or that sells a **product** whose buyers never read a release note. Tier 2 is the
subscriber of a **service**, who decides whether to upgrade. A repo answers one of them, once, in
`Get-ReleaseAudienceTier`, before any entry is written; **this repo answers 2**, being a service rather than
a product. `new-branch.ps1` then scaffolds tier 0 plus that tier alone, and `open-pr.ps1` and
`cut-release.ps1` ask for that tier rather than every rung from 1 up.

**A repo that has stated nothing is asked about all three**, exactly as before the knob existed — an
unstated seam means unchanged, never "switch the audience tier off". The loud channel is the script
contract, where this is a `decide` record that `adopt-config` puts to the repo rather than answering for it.

**The tier a repo no longer asks about is still read.** `Get-EntryTierMax` stays 2 and every validator keeps
using it: the maximum says which tier numbers are valid to *parse* — 97 entries in this repo's record were
written under the cumulative ladder — while the audience says which are *asked*. An extra answered tier is
accepted, never refused, so no finished dossier became unopenable on the day the knob landed.

**`CHANGELOG.md` has no sections to file into** (Dave, August 5, 2026). It is an intro followed by one `##`
per change, ranked furthest-reach-first and, within a tier, highest-significance-first — so what the three
`## Tier N - Pull Requests` sections used to say visually is now the ordering, and each entry states its own
reach in the `### Significance` section it carries, one `#### Tier N` sub-section per reach it claims. The
**fold** is the only moment that order can be decided, because the cut empties the list: whatever order it
leaves is what the release documents inherit, with nothing re-estimated days later.

**The cumulative ladder is gone, and the measurement is why.** Until August 12, 2026 a tier-2 entry *owed* a
tier-1 section, on the reasoning that something a consumer notices is something a colleague should hear
about too. That reasoning holds for a repo with two genuine audiences and produces nothing but duplication
for the far more common repo with one. Measured over the 97 scored entries in this repo's record: **81 top
out at tier 2 and only 8 at tier 1**, so 81 of the 89 tier-1 sections existed only because a scored tier-2
section sat above them — the same reach argued twice, in a second register, for a reader who here is the
same person. The reporting consumer measured the mirror image on its own side: 37 open entries, 15 at tier
1, zero ever at tier 2. The development note still carries everything, tier 0 included, because it is the
record rather than a summary of one.

**Counting per entry, not in aggregate, is what produced that answer.** In aggregate tier 1 looks like a
working axis here — 89 of 95 scored entries carry one — and that number argues *against* this change. It is
an artefact of the ladder that required them.

**Where the number comes from: the author of the entry, on the branch.** `new-branch.ps1` writes the
`#### Tier N` sub-sections this repo asks about with their scores left empty; whoever finishes the branch
answers each one, with a score or with `N/A` and the reason it reaches nobody there. **The reach is the highest tier carrying a
number**, so an `N/A` costs a sentence and keeps the reasoning behind a negative claim in the record.
`open-pr.ps1` refuses an entry whose description, body or any tier's reason is still blank, and
`fold-changelog-entry.ps1` folds the entry **verbatim** — so the declaration lives in exactly one place, the
entry itself, and no second definition of the format sits inside the fold.

**The older `Tier: N` line is still read and is deliberately not stripped.** Every entry written before
August 6, 2026 — here and in every consumer's tree — carries it instead of the sub-sections, and a parser
that only knew the new shape would read all of them as tier 0: silent, correct-looking, and wrong in the
direction that empties a release. Recognise both, write one.

**Deliberately not derived from the branch prefix**, which this repo has measured does not predict impact:
held against the 19 entries pending at v3.2.0, the single most consequential change for a consumer —
renaming the marketplace, which breaks every existing install — arrived on a `chore/` branch.

### What a release must earn

`cut-release.ps1` refuses a bump the pending entries have not earned. Three rules, all checked before
anything is written:

| bump | requires |
|---|---|
| **patch** | nothing — a release made entirely of tier-0 work is what a patch is for |
| **minor** | at least one entry of **tier 1 or higher** |
| **major** | at least **10 minors** cut in the current major line, on top of the general minimum |

**Why a tier-0-only release is a patch rather than a refusal** (Dave, August 7, 2026). It used to be refused
outright, on the grounds that such a release "has nobody to announce it to" — and the answer is that
announcing nothing is exactly what a patch is for. The version number still moves, the tag still marks the
moment, and the one document that gets written is the record.

**Why a minor needs tier 1 rather than tier 2.** It demanded a tier-2 entry until August 7, 2026, so work a
colleague on this project got something out of earned only a patch — while the version here speaks to all
stakeholders, not to consumers alone. The rule is written as **tier 1 or higher** rather than as "the
audience tier" on purpose: it then reads correctly in a tier-1 repo and a tier-2 repo alike, without either
having to translate it. What keeps the looser rule honest is that **the sections follow the tier and not the
bump**: a minor whose highest pending entry is tier 1 writes the note without its *For consumers* section,
so nobody outside is handed a section about work they cannot see.

**Why a major counts minors rather than pending work:** a major is a **recap** of the minors before it,
which is what both of this repo's majors actually were (`v2.0.0` consolidated v1.0–v1.18, `v3.0.0`
consolidated v2.2.0–v2.16.0). So a pending tier-2 entry is deliberately *not* required; the accumulation is.
The count is read off the current version's minor component — within major 3 the minors are 3.1 … 3.10, so
the component *is* the count.

`-SkipTierGate` overrules all three. It is deliberately separate from `-SkipLint`, because it overrules a
judgement about **content** rather than skipping a tool — folding them into one flag would let someone
skipping a slow lint run also, silently, cut a minor with nothing in it for a consumer.

**The gate switches itself off where no pending entry declared its impact at all**, and that is what makes it
safe to share: a repo that never adopted the model is untouched rather than refused at every cut.

**The signal is a count of declarations, not a count of sections**, and the difference is not academic. The
test used to be "does this repo declare more than one changelog section", which had a real basis while the
tier headings existed and became a landmine the moment they went: a flat changelog gives an unadopted repo
and an adopting one exactly one group each, so the old line would have read **every** repo as not adopting
and switched the gate off in silence — in the same change that made the tier the model's primary fact.
Nothing would have errored. Counting declarations keeps "declared tier 0" distinct from "declared nothing",
which is the whole difference between a release with nobody to announce itself to and a repo that never
chose the model.

## The release documents

Which directory scheme groups them — `<X>.x` per major or `<X.Y>` per minor — is answered once by
`Get-ReleaseNotesGrouping` in your own `scripts/repo-config.ps1`, so `<dir>` below
stands for whichever this repo uses.

| document | for whom | when | generated by |
|---|---|---|---|
| `development/<dir>/<X.Y.Z>.md` | developers — the full per-PR record, auto-complete | every release | `cut-release.ps1` |
| `audience/<dir>/<X.Y.Z>.md` | whoever this repo publishes to — one hand-written note with a named section per reader | minor/major, where a pending entry earns one | drafted by `cut-release.ps1`, written by hand |
| `github/<dir>/<X.Y.Z>.md` | whoever opens the GitHub Releases page | every release | `cut-release.ps1` |

**Every root under `releases/` names its READER, and `audience/` was the last one that did not** (Dave,
August 12, 2026). It was `notes/`, which names the form rather than the reader — the same mistake
`highlights/` made, and one this repo had already fixed in that sibling two days earlier without noticing it
in this one. `development/` names the developers, `github/` names the page, `audience/` names whoever the
repo publishes to, whichever of the two audience tiers that is. The root is stated in `Get-ReleaseNoteRoot`;
**the shared default is deliberately still `releases/notes`**, so a consumer who never answered the knob is
not silently pointed at a directory they do not have.

**`consumer/` and `internal/` are gone, and the twelve pairs in them are now twelve documents in
`audience/`** (Dave, August 12, 2026). They had been written up as *frozen archives* of the two-document
era — a freeze nobody had actually decided, recorded in three places and attributed to no one, while the
`notes/` → `audience/` rename standing beside it in the same entry was Dave's. Asked directly, he chose the
merge: `releases/` holds three reader-named roots and nothing else.

**The identical filenames are why this was a merge rather than a rename.** `3.x/3.2.0.md` existed in both
trees, so 24 documents became 12 and no `git mv` could do it. Each pair kept both registers intact — the
consumer body under *For consumers*, the organisational prose under *What it is worth* and *What was still
open at this release* — and dropped exactly one thing: the internal note's `## What is different now`, which
the 62/38 measurement below identifies as the duplicated half. The prose of a published record was otherwise
left as written, so a merged document may still name `releases/highlights/` or describe itself as one of
three tiers; that is what it said on the day it went out.

**A patch writes no hand-written note at all**, and is announced by the generated GitHub Release body alone
(see [Cutting a release](#cutting-a-release)). The **sections** inside the note follow the tier; **whether
the note exists at all** follows the bump.

### Tier 0 - development

**Raw and complete, and the only document nobody writes.** Every changelog entry as it was written, nothing
rewritten — literally the whole changelog, generated in full by `cut-release.ps1` at every release. It is
the per-PR record a developer goes back to, which is why it is never edited down: a summary of it is what
the hand-written note is for.

**It is the one document that still groups by tier**, and that is a difference from `CHANGELOG.md` rather
than a copy of it: `## Tier <n> - <audience>` first, then that tier's entries as a flat ranked list in the
order the fold left them. The changelog dropped its tier headings in the same change that made the entry
declare its own reach; this document keeps them because it carries all three tiers at once and is the only
place a reader needs them separated.

Each entry arrives whole, exactly as it was folded — its `###` heading naming the **branch**, and beneath it
the same six `####` sections the scaffolder writes: `Branch title`, `Branch ID`, `Branch type`, `What does
the change on this branch bring to main?`, `Significance` and `Pull Request`, one heading level deeper than
in `CHANGELOG.md`. Nothing is rewritten and nothing is cut, which is what "the record" means. There are no
branch-type categories in between — the grouping came from the branch prefix, which this repo measured does
not predict impact. Tier 0 is in it, unlike in the hand-written note below.

Its size is also why it is never the body of a GitHub Release but always an attachment: `gh`'s
release-notes body has a hard **125,000-character** limit, which a full notes file can exceed.

### The audience tier - the hand-written note

**One document since August 10, 2026, with a named section per reader** (Dave). It replaced two separate
documents — an internal note for the organisation and a consumer document — and at all twelve releases
since the internal tier existed, **both were written, about the same changes**. Measured before merging
them: one release's internal note (962 words) held against test 2 of the writing norm in the
[cut-release skill](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md)
(*does this describe our effort or their outcome*) gave:

| | words | |
|---|---|---|
| could appear in a consumer-facing section | ~365 (38%) | and **did**, rewritten in a second register in the other document — that is the duplication |
| could not | ~597 (62%) | including *what it is worth* (316 words), which is not an outlier but the entire reason the organisational sections exist |

So a **blended** document was refused, since it would have had to drop the 62% or break the writing norm; a
**sectioned** one keeps each register intact and writes the shared 38% once. The heading *"what is different
now"* is gone rather than moved — it **was** the duplicated half, and the *For consumers* section is what
replaced it.

`cut-release.ps1` drafts a note under `Get-ReleaseNoteRoot` — `releases/audience/<dir>/<X.Y.Z>.md` here —
for every bump `Get-ReleaseConsumerBumps` names. Three sections, in this order:

| section | for whom | how it arrives |
|---|---|---|
| *For consumers* | whoever decides whether to update | **pre-filled** — the tier-2 entries, still in the words their authors wrote for a diff reviewer. Absent where no entry reached tier 2. |
| *What it is worth* | the organisation | **empty** — it cannot be generated. Think in time, risk and reduced dependence on a developer. |
| *What was still open at this release* | the organisation | **empty**, and past tense on purpose: a published document does not move with reality, so a present-tense line goes stale in hours rather than months. |

**A minor with no tier-2 entry gets the note with no *For consumers* section** — which is every minor in a
repo whose audience is tier 1, and an occasional one here. The organisational two sections belong to every
bump the seam names — the version moves for everyone, so the organisation's question is always answered —
while a section about work no consumer can see would be worse than none, because it looks written.

**Still a draft to be edited, and the reason never depended on the selection.** Entry bodies are written for
whoever reviews the diff, even when the change reaches a consumer — so the *For consumers* section's
*selection* is right and its *prose* still needs rewriting from the reader's end. What is gone is the
deleting, not the writing.

**It is published output, not an internal file.** Where the bump wrote one, the note is uploaded as an
attachment to the GitHub Release (the release body itself is generated separately — see
[Cutting a release](#cutting-a-release)), which has a consequence worth stating: anything the *What was
still open* section phrases as a *live* claim goes stale in place within hours of publishing. Write it as
"open at the time of this release", not as a statement about now.

> **The "remove before publishing" marker was retired on August 5, 2026**, together with its two seam knobs
> (`Get-ReleaseHighlightsStakeholderTypes`, `Get-ReleaseHighlightsWording`). It existed because the generator
> had to guess from branch prefixes which entries a consumer cares about, so it wrote out both halves and
> left the release manager to cut one — explicitly a *proposal*, since the prefix
> measurably does not predict impact here (the marketplace-rename measurement under
> [The tier model](#the-tier-model)). The tier asks the
> entry's author instead, at the moment they know. Do not reintroduce a category-based split beside it: that
> is the guess this replaced.

**`new-internal-note.ps1` is still shipped and still works**, for a repo running the two-document flow — a
separate organisational note alongside a separate consumer document. Nothing in this repo's chain calls it
any more; it is documented here rather than dropped, because a consumer receives a plugin update rather than
choosing one, and deleting a working entry point is a breaking change.

### Where the hand-written note lands

**It goes through a branch + PR.** `cut-release.ps1` commits and tags in one motion, so by the time you edit
the note draft, the release commit is already tagged. It is not one of the two named direct-on-`main`
exceptions, so it travels the normal reviewed route. The alternative — widening the release exception to
cover the written note as well — was offered and declined: an exception is only safe while it stays the size
it was granted at.

## Cutting a release

A release is a **captured moment**: the state is tagged as `vX.Y.Z`, and where the repo publishes plugins
they all get the same version number (**lockstep, repo-wide**). `cut-release.ps1` produces only a git tag,
the full notes here in
`development/`, and a reference to them in the repo's own `CHANGELOG.md`. A release is cut **only on the
owner's explicit request** and deliberately does **not** go through a branch + PR: like the fold commit, the
release commit is a permitted direct-on-`main` action (the second exception to "everything via branch + PR"
— see [the contribution cycle](CONTRIBUTING-portable.md#releases--a-different-cycle)).

In one motion, on a clean `main`:
[`scripts/release/cut-release.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/release/cut-release.ps1)`(-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]`

1. where `Get-ReleasePluginTier` is true, bumps all `plugin.json` versions in lockstep to `X.Y.Z` —
   otherwise there is nothing to bump and the version lives in the tag alone;
2. generates the full release notes in `development/<dir>/<X.Y.Z>.md` (from the folded entries, grouped by
   tier and, within a tier, a flat list in the ranked order the fold left), adds a row to the release list
   on the page `Get-ReleaseHistoryPath` names — your `releases/README.md` — and **empties `CHANGELOG.md`
   down to its intro** — that intro passes through
   verbatim, so whatever the repo says about itself up there survives every cut. A cut writes no release
   block: the section that used to hold one had grown in the source repo to 434 of the changelog's 1,062
   lines across 72 blocks
   each saying no more than "see the notes", while its release list already carried all 72 with a date, a
   type and a title. What replaced it is the intro's own one-line pointer to the release list;
3. **(retired, August 8, 2026)** step 3 used to append, per plugin, the entries that touched it to a
   **per-plugin `CHANGELOG.md`** and regenerate that plugin's **`RELEASE.md`** card — a second copy of a
   history the consumer already receives, since a marketplace source arrives as a git clone of the whole
   repository. One repository, one product, one changelog; the measurement that retired it is with the
   source repo's other measured instances, in its own `releases/README.md`. The `Plugins:` line survives:
   the release notes still read it;
4. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
5. pushes `main` + the tag (unless `-NoPush` for inspection first).

**Closing step, after the script and after the hand-written note has merged, where the bump wrote one:
publish a GitHub Release.** Not run by `cut-release.ps1` and not automated; the release manager walks
through the
[`cut-release` skill](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md)'s
checklist: `gh release create`
with the **generated body** (`--notes-file` pointing at the `releases/github/<dir>/<X.Y.Z>.md` the cut already
wrote — nothing to edit), then `gh release upload` with the full development notes **and the hand-written note,
where the bump generated one**. Never inline the development notes — see
[Tier 0 - development](#tier-0---development) for the character limit that makes that fail.

**Upload the attachments under unique filenames.** Every document a release produces shares the basename
`<X.Y.Z>.md`, so uploading two of them straight from `releases/` collides — the second upload returns
`HTTP 404`. `gh`'s `file#label` syntax does not solve it (it sets the label, not the name). Copy them to
`vX.Y.Z-development-notes.md` and `vX.Y.Z-notes-for-users.md` and upload the copies.

**It comes last on the checklist, and the reason has outlived one rewrite already.** The body used to be a
hand-written document merged via its own branch + PR, so publishing straight after the tag would have had no
body to publish. The body is generated by the cut itself now, so that particular impossibility is gone — but
publishing early would still publish a page whose attachments are missing the hand-written note and whose
pointer line names a document nobody can download yet.

**And it needs no separate approval** (Dave, August 5, 2026). Cutting the release is the act that is asked
for; publishing its Release is the last step of that same procedure, so stopping to ask there is a rubber
stamp. Once a cut has been requested, the whole run goes through in one motion — generate, ship the
hand-written note, publish. **The boundaries that remain are the live stage (Block 2 of the checklist)
and, in a marketplace source, the business publication (Block 3)** — different acts with different
audiences, and this approval covers Block 1. A repo wanting a different boundary states that in its own
lens rather than softening this paragraph.

**Where the repo is itself a marketplace source with a business publication target, one more step exists
after the cut — and it is a boundary, not a tail.**
[`scripts/release/publish-to-business.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/release/publish-to-business.ps1)
overwrites the business repo with the marketplace subset of the source, so an organisation's Claude
Enterprise can sync it as a plugin marketplace for colleagues without GitHub access. It runs **after** a
release and **only on the owner's explicit request** — releasing without publishing is a normal outcome,
not a half-finished one (Dave, August 14, 2026). The target is repo data (`Get-BusinessMarketplaceRepo`
in `scripts/repo-config.ps1`, with `-TargetRepo` as the override for a second organisation); a repo
without one simply has no such step. The mechanics are Block 3 of the
[`cut-release` skill](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md)'s
checklist.

Guardrails: a clean `main`, no unfolded entry files, **[the bump earned by the pending
tiers](#what-a-release-must-earn)** (`-SkipTierGate` overrules), lint gate green, **all test suites green**
(`-SkipTests` overrules), tag doesn't exist yet. All
of them run **before the first file is written**, deliberately: failing after the notes file exists would
leave a release half-cut on `main` — and for the test gate this is the last moment a red suite can still
stop anything, because CI fires only after the tagged commit is already pushed.

**The lint gate is *your* repo's, read from `Get-LintScript` — the same seam `open-pr` uses.** This route
needs its own gate precisely because it does not travel via a PR, so nothing else on it ever meets that
copy. Until August 5, 2026 the cut resolved the gate by a fixed path to the script the *source* repo
happens to carry, which meant every consumer release ran with no gate at all and said so in a warning
(inbound [#464](https://github.com/DaveKJohn/claude-code-specialists/issues/464)). **A gate the seam names
but the tree does not have is a hard stop**, not a warning: skipping it is `-SkipLint`, and that choice
belongs in the command rather than in output that scrolls past.

**And so is the test gate: the `*.tests.ps1` suites in `scripts/tests`, plus whatever the optional
`Get-TestCommands` names** — extra command lines (an `npm test`, a `pytest`) for a repo whose tests are not
all PowerShell, each failing the gate exactly like a failing suite. The seam is read inside the one shared
gate function, so the PR gate and the release gate cannot drift into checking different things; a repo that
states nothing keeps exactly the gate it had.

The pure logic (version bump, CHANGELOG transformation, notes construction, and the bump rules in
`Test-ReleaseBumpEarned`) lives in
[`scripts/lib/release-lib.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/lib/release-lib.ps1)
and is covered by
[`scripts/tests/release-lib.tests.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/tests/release-lib.tests.ps1).
The tier line's own format
— writing it, validating it, and the section map it selects — lives in
[`scripts/lib/entry-scaffold-lib.ps1`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/scripts/lib/entry-scaffold-lib.ps1),
shared with the three scripts
that must not disagree about it.

