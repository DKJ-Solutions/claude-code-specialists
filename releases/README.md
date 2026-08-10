# Releases

**How a release works.** A release is not a deploy but a **recorded moment**: a git tag that marks the
state of the marketplace, with all plugin versions in lockstep. This page carries both halves: the
**process** — the tier model, what a release must earn, the three documents, and how one is cut — and, under
the repo heading at the end, the **full list of releases** actually cut. The release block in
[`CHANGELOG.md`](../CHANGELOG.md) points here for everything but the current version.

[`scripts/release/cut-release.ps1`](../scripts/release/cut-release.ps1) itself publishes nothing to GitHub
Releases — that is a separate, manual closing step. Releases are cut **only on the repo owner's explicit
request**; see [Cutting a release](#cutting-a-release) below for the full mechanics. Each release bumps
every plugin's `version` in lockstep, and that number in `.claude-plugin/plugin.json` is what tells a
consumer which release they are on.

## The tier model

**One scale, used twice.** A change declares how far it reaches, and that number decides two things: which
release document it appears in, and — together with its significance score — where in that document it sits.

| tier | who notices | release document |
|---|---|---|
| **2** | consumers of the product | `consumer/<dir>/<X.Y.Z>.md` |
| **1** | colleagues working on this project | `internal/<dir>/<X.Y.Z>.md` |
| **0** | only this repo's own developers | `development/<dir>/<X.Y.Z>.md` |

**`CHANGELOG.md` has no sections to file into** (Dave, August 5, 2026). It is an intro followed by one `##`
per change, ranked furthest-reach-first and, within a tier, highest-significance-first — so what the three
`## Tier N - Pull Requests` sections used to say visually is now the ordering, and each entry states its own
reach in the `### Significance` section it carries, one `#### Tier N` sub-section per reach it claims. The
**fold** is the only moment that order can be decided, because the cut empties the list: whatever order it
leaves is what these three documents inherit, with nothing re-estimated days later.

**The ladder is cumulative, so the documents are not disjoint.** Something a consumer notices is something
a colleague should hear about too — a tier-2 entry therefore appears in the consumer document *and* in the internal
note. The development note carries everything, tier 0 included, because it is the record rather than a
summary of one.

**Where the number comes from: the author of the entry, on the branch.** `new-branch.ps1` writes all three
`#### Tier N` sub-sections with their scores left empty; whoever finishes the branch answers each one, with a
score or with `N/A` and the reason it reaches nobody there. **The reach is the highest tier carrying a
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
stakeholders, not to consumers alone. What keeps the looser rule honest is that **the documents follow the
tier and not the bump**: a tier-1-only minor writes the internal note and **no consumer document**, so nobody
outside is handed a document about work they cannot see.

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

## The three documents

Which directory scheme groups them — `<X>.x` per major or `<X.Y>` per minor — is answered once by
`Get-ReleaseNotesGrouping` in [`scripts/repo-config.ps1`](../scripts/repo-config.ps1), so `<dir>` below
stands for whichever this repo uses.

| document | for whom | when | generated by |
|---|---|---|---|
| `development/<dir>/<X.Y.Z>.md` | developers — the full per-PR record, auto-complete | every release | `cut-release.ps1` |
| `internal/<dir>/<X.Y.Z>.md` | colleagues, employers — what the work is worth | every release, patch included | `new-internal-note.ps1` |
| `consumer/<dir>/<X.Y.Z>.md` | consumers — what they actually notice | minor/major, **and** only with a tier-2 entry pending | `cut-release.ps1` |

### Tier 0 - development

**Raw and complete, and the only document nobody writes.** Every changelog entry as it was written, nothing
rewritten — literally the whole changelog, generated in full by `cut-release.ps1` at every release. It is
the per-PR record a developer goes back to, which is why it is never edited down: a summary of it is what
the other two are for.

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
not predict impact. Tier 0 is in it, unlike in the other two documents.

Its size is also why it is never the body of a GitHub Release but always an attachment: `gh`'s
release-notes body has a hard **125,000-character** limit, which a full notes file can exceed.

### Tier 1 - internal

**The tier that covers a release with nothing for a consumer, and that is the whole reason it exists next to
the consumer document.** The two answer different questions: the consumer document is *what a consumer notices*, internal is *what
the organisation gets out of it*. They come apart wherever a release has no tier-2 entry — a patch, or a
minor made of tier-1 work — and get no consumer document at all, while still being the release where a routine
change stopped needing a developer.

`new-internal-note.ps1` generates only the skeleton (metadata + the entry titles as bullets + three fixed
headings). The middle heading, **what it is worth**, cannot be derived from a changelog and is the point of
the document — so this tier is written by hand at **every** release, patch included.

**It carries over the tier-1 *and* tier-2 entries**, the ladder being cumulative, and skips tier 0. The empty
case is reachable and ordinary since August 7, 2026: a release made entirely of tier-0 work is a legitimate
patch, and its internal note has no entry to list. The script says so rather than handing you a blank list
without a reason — which used to mean "somebody bypassed the gate" and now usually means "this was a
tier-0 patch".

**It is published output, not an internal file.** It is the body of the GitHub Release, which has a
consequence worth stating: anything its "what is still open" section phrases as a *live* claim goes stale in
place within hours of publishing. Write that section as "open at the time of this release", not as a
statement about now.

### Tier 2 - the consumer document

**It is the tier-2 entries, and nothing else.** Entry metadata is stripped, and the document is written only
when **two** conditions hold at once: the bump is one the seam names (`Get-ReleaseConsumerBumps` — minor
or major here), **and** at least one pending entry actually declared tier 2. A patch has no consumer document, for
the same reason it is a patch.

**That second condition became load-bearing on August 7, 2026, and used to be belt-and-braces.** While
[a minor required a tier-2 entry](#what-a-release-must-earn), a release that earned a minor had a
consumer reading it by construction and the tier check could never fire on its own. Since a minor needs only
tier 1, it is the only thing standing between a tier-1-only release and a document written for consumers
about work no consumer can see — and a consumer document with a header and no content is worse than none.

**Still a draft to be edited, and the reason never depended on the selection.** Entry bodies are written for
whoever reviews the diff, even when the change reaches a consumer — so the *selection* is right and the
*prose* still needs rewriting from the reader's end. What is gone is the deleting, not the writing.

> **The "remove before publishing" marker was retired on August 5, 2026**, together with its two seam knobs
> (`Get-ReleaseHighlightsStakeholderTypes`, `Get-ReleaseHighlightsWording`). It existed because the generator
> had to guess from branch prefixes which entries a consumer cares about, so it wrote out both halves and
> left the release manager to cut one — explicitly a *proposal*, since the prefix
> [measurably does not predict impact here](#measured-instances-behind-the-portable-rules). The tier asks the
> entry's author instead, at the moment they know. Do not reintroduce a category-based split beside it: that
> is the guess this replaced.

### Where the two hand-written documents land

**Both go through a branch + PR.** `cut-release.ps1` commits and tags in one motion, so by the time you edit
the consumer document draft or run `new-internal-note.ps1` (which needs the development notes as input), the
release commit is already tagged. Neither is one of the two named direct-on-`main` exceptions, so they
travel the normal reviewed route. The alternative — widening the release exception to cover the written
notes as well — was offered and declined: an exception is only safe while it stays the size it was granted
at.

## Cutting a release

A release is a **captured moment**: all plugins get the same version number (**lockstep, repo-wide**) and
the state is tagged as `vX.Y.Z`. `cut-release.ps1` produces only a git tag, the full notes here in
`development/`, and a reference to them in [`CHANGELOG.md`](../CHANGELOG.md). A release is cut **only on the
owner's explicit request** and deliberately does **not** go through a branch + PR: like the fold commit, the
release commit is a permitted direct-on-`main` action (the second exception to "everything via branch + PR"
— see [`CONTRIBUTING.md`](../CONTRIBUTING.md)).

In one motion, on a clean `main`:
[`scripts/release/cut-release.ps1`](../scripts/release/cut-release.ps1)`(-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]`

1. bumps all `plugin.json` versions in lockstep to `X.Y.Z`;
2. generates the full release notes in `development/<dir>/<X.Y.Z>.md` (from the folded entries, grouped by
   tier and, within a tier, a flat list in the ranked order the fold left), adds a row to the release list at
   the end of this page, and **empties `CHANGELOG.md` down to its intro** — that intro passes through
   verbatim, so whatever the repo says about itself up there survives every cut. A cut writes no release
   block: the section that used to hold one had grown to 434 of the changelog's 1,062 lines across 72 blocks
   each saying no more than "see the notes", while this page already listed all 72 with a date, a type and a
   title. What replaced it is the intro's own one-line pointer to this page;
3. **(retired, August 8, 2026)** step 3 used to append, per plugin, the entries that touched it to a
   **per-plugin `CHANGELOG.md`** and regenerate that plugin's **`RELEASE.md`** card. Both were built to
   give a consumer a history inside the plugin cache — and measured against how a consumer actually
   receives this repo, they were a second copy of something already in reach: the marketplace source is
   a git clone of the WHOLE repository, so `CHANGELOG.md` and this entire `releases/` tree sit at
   `~/.claude/plugins/marketplaces/<marketplace>/`. Ten files, 11,684 lines, free to disagree with the
   original — which is exactly what lint checks 9 and 17 existed to police. One repository, one product,
   one changelog. The `Plugins:` line survives: the release notes still read it;
4. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
5. pushes `main` + the tag (unless `-NoPush` for inspection first).

**Closing step, after the script and after the two written documents have merged: publish a GitHub
Release.** Not run by `cut-release.ps1` and not automated; the release manager walks through the
[`cut-release` skill](../plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md)'s checklist: `gh release create`
with the **internal note** as the release body (`--notes-file`), then `gh release upload` with the full
development notes **and the edited consumer document, where the bump generated one**. Never inline the development
notes — see [Tier 0 - development](#tier-0---development) for the character limit that makes that fail.

**Upload the attachments under unique filenames.** All three tiers call their file `<X.Y.Z>.md` and an
asset's name is its basename, so uploading two of them straight from `releases/` collides — the second
upload returns `HTTP 404`. `gh`'s `file#label` syntax does not solve it (it sets the label, not the name).
Copy them to `vX.Y.Z-development-notes.md` and `vX.Y.Z-notes-for-users.md` and upload the copies.

**It comes last on the checklist for a reason that is easy to get wrong.** The body is a document written
*after* the cut and merged via a branch + PR, so a Release published straight after the tag would have no
body to publish.

**And it needs no separate approval** (Dave, August 5, 2026). Cutting the release is the act that is asked
for; publishing its Release is the last step of that same procedure, so stopping to ask there is a rubber
stamp. Once a cut has been requested, the whole run goes through in one motion — generate, ship the two
written documents, publish. **The boundary that remains is the live stage**, where a repo has one: that is
Block 2 of the checklist, a different act with a different audience, and this approval covers Block 1. A
repo wanting a different boundary states that in its own lens rather than softening this paragraph.

Guardrails: a clean `main`, no unfolded entry files, **[the bump earned by the pending
tiers](#what-a-release-must-earn)** (`-SkipTierGate` overrules), lint gate green, tag doesn't exist yet. All
of them run **before the first file is written**, deliberately: failing after the notes file exists would
leave a release half-cut on `main`.

**The lint gate is *your* repo's, read from `Get-LintScript` — the same seam `open-pr` uses.** This route
needs its own gate precisely because it does not travel via a PR, so nothing else on it ever meets that
copy. Until August 5, 2026 the cut resolved the gate by a fixed path to the script the *source* repo
happens to carry, which meant every consumer release ran with no gate at all and said so in a warning
(inbound [#464](https://github.com/DaveKJohn/claude-code-specialists/issues/464)). **A gate the seam names
but the tree does not have is a hard stop**, not a warning: skipping it is `-SkipLint`, and that choice
belongs in the command rather than in output that scrolls past.

The pure logic (version bump, CHANGELOG transformation, notes construction, and the bump rules in
`Test-ReleaseBumpEarned`) lives in
[`scripts/lib/release-lib.ps1`](../scripts/lib/release-lib.ps1) and is covered by
[`scripts/tests/release-lib.tests.ps1`](../scripts/tests/release-lib.tests.ps1). The tier line's own format
— writing it, validating it, and the section map it selects — lives in
[`scripts/lib/entry-scaffold-lib.ps1`](../scripts/lib/entry-scaffold-lib.ps1), shared with the three scripts
that must not disagree about it.

---

**Everything above this line travels to any repo that runs this release workflow. Everything below it does
not.** What follows is this repo's own answer to the choices the page leaves open — the seam values, the
decisions behind them, the measured instances, and the release list itself.

## claude-code-specialists (REPLACE WHEN MIRRORING)

### How to mirror this page

> **To an agent mirroring this workflow into another repo:** everything above the horizontal rule is
> portable and can be copied as-is. This section is not — it holds one repo's local decisions and its own
> release record, none of which is true of your repo. So keep the **shape** and replace the **content**:
> rename the heading after your own repo, state your own seam values, and start the release list empty
> rather than carrying these versions, dates and PR references across. Two things not to do: do not fold any
> of this upward into the portable half, and do not delete the section — a mirrored page without it has
> nowhere to put its own history, and the next release will write a row into a document that never declared
> where rows go.

### Seam values in force here

All three documents group **per major** (`3.x`) — the consumer this model came from folders per minor.
`Get-ReleaseHistoryPath` is left at its default, `releases/README.md` — this page — since the list lives
here, and since August 5, 2026 that default carries a second job: the **Version cell** of each new row is
where `new-internal-note.ps1` points the internal note, because removing the changelog's release block left
that note with no inbound link anywhere else.

**Six changelog seams retired on August 5, 2026 and are therefore not stated here either.**
`Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` (#178) named changelog section headings, and
the document has none; `Get-ReleaseCategoryTitles` labelled the release-notes categories, and the grouping is
gone with the branch-prefix guess behind it; `Get-ReleaseLiveMarker`, `Get-ReleaseHistoryMode` and
`Get-ChangelogReleaseWording` (#462) all described the release **block** a cut used to append, and a cut
writes none. A consumer that still defines one is unaffected — nothing calls them.

**`Get-ReleaseMajorMinMinors` is `10`.** Held against this repo's own history that is roughly right rather
than arbitrary: the `1.x` line ran to `1.18` and the `2.x` line to `2.16` before each was recapped into a
major.

**`Get-LintScript` is [`scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1),
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
rather than as guidance. And a patch has no consumer document by construction, so on a patch the attachment list is
the development notes alone.

> **Named `davekjohns-workshop` until August 3, 2026.** The marketplace was renamed with the
> [one-product decision](../README.md#one-product-one-repository); the older notes under `development/`
> still carry the old name and are deliberately not rewritten — they are history.

> **Markdown only.** For one release (v3.2.0) the tier also generated a print-ready `.html` beside the
> `.md`. That is gone and is not coming back — Dave's decision, August 3, 2026. A PDF, if ever needed, comes
> from rendering the markdown with a tool built for it rather than from a partial HTML renderer maintained
> here. `v3.2.0`'s `.html` was removed from `main`; the `v3.2.0` **tag** still contains it, because a tag is
> a record of a moment and is not rewritten.

### Measured instances behind the portable rules

- **The branch prefix does not predict impact here**, and this is the measurement the whole tier model rests
  on. Held against v3.2.0's 19 entries, the most consequential change for a consumer — renaming the
  marketplace, which breaks every existing install — arrived on a `chore/` branch. While the consumer document
  document was assembled from `Feat`/`Fix` that change landed *below* the remove-before-publishing marker, so
  the guidance here used to be "expect to promote `Docs`/`Chore` items". Since August 5, 2026 there is nothing
  to promote: the entry's author declares the tier, and the branch prefix decides nothing but the category
  heading an entry is grouped under. Kept as history because it is the evidence for that change, not a rule
  still in force.
- **Both of this repo's majors were already recaps**, which is what the 10-minor rule now requires up front:
  `v2.0.0` consolidated v1.0–v1.18 and `v3.0.0` consolidated v2.2.0–v2.16.0, both written that way after the
  fact. The rule states the practice rather than inventing one.
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
| [4.1.0](internal/4.x/4.1.0.md) | 2026-08-10 | Minor | The workflow's portable half: a consumer can copy the PR template and the contribution cycle, and three seams stop failing quietly |
| [4.0.0](internal/4.x/4.0.0.md) | 2026-08-09 | Major | Chapter 3 consolidated (v3.0.0 -> v3.10.0) |

#### 3.x

| Version | Date | Type | Title |
|---|---|---|---|
| [3.10.0](internal/3.x/3.10.0.md) | 2026-08-09 | Minor | Teams and workflows |
| [3.9.0](internal/3.x/3.9.0.md) | 2026-08-09 | Minor | A consumer can adopt the source's release config with one command |
| [3.8.0](internal/3.x/3.8.0.md) | 2026-08-08 | Minor | The workflow becomes opt-in, and the product has one changelog |
| [3.7.0](internal/3.x/3.7.0.md) | 2026-08-07 | Minor | The branch files take their designed form |
| [3.6.0](internal/3.x/3.6.0.md) | 2026-08-06 | Minor | The changelog ranks itself by reach and weight, a branch keeps its plan in branch/, and a filled lens survives the teardown |
| [3.5.0](development/3.x/3.5.0.md) | 2026-08-05 | Minor | The changelog gets three tiers and a release has to earn its bump, and the shared workflow stops assuming it runs in the repo it was written in |
| [3.4.0](development/3.x/3.4.0.md) | 2026-08-04 | Minor | Every shared script has a page, and the changelog leads with the release instead of archiving them |
| [3.3.0](development/3.x/3.3.0.md) | 2026-08-04 | Minor | A release now writes for three readers, and a third gate keeps scaffolding out of it |
| [3.2.0](development/3.x/3.2.0.md) | 2026-08-03 | Minor | One product, one marketplace: renamed and flattened, with the release cut shared and three tiers deep |
| [3.1.2](development/3.x/3.1.2.md) | 2026-08-02 | Patch | Round v12 processed: the teardown papers corrected, and the staleness gate reaches into prose |
| [3.1.1](development/3.x/3.1.1.md) | 2026-08-02 | Patch | The v11 follow-up: the gates see what they claim to see |
| [3.1.0](development/3.x/3.1.0.md) | 2026-08-01 | Minor | Every finding of test rounds v9 and v10, processed -- and a gate so a PR closes what it fixes |
| [3.0.9](development/3.x/3.0.9.md) | 2026-08-01 | Patch | Round v8: the install record now says what you are actually running -- plus the gate for the class behind all three findings |
| [3.0.8](development/3.x/3.0.8.md) | 2026-07-31 | Patch | a crafted plugin id can no longer forge a line, and a repo-wide guard keeps every native call site honest |
| [3.0.7](development/3.x/3.0.7.md) | 2026-07-31 | Patch | the checks read the install record, and three adoption claims match the measurement |
| [3.0.6](development/3.x/3.0.6.md) | 2026-07-31 | Patch | the enable state is read from the whole settings chain, and three claims are corrected to what was measured |
| [3.0.5](development/3.x/3.0.5.md) | 2026-07-31 | Patch | what the refresh was measured to do, per command |
| [3.0.4](development/3.x/3.0.4.md) | 2026-07-31 | Patch | the checks that reported the wrong answer -- and a gate for the class |
| [3.0.3](development/3.x/3.0.3.md) | 2026-07-30 | Patch | the second update gate: refresh the marketplace before you update |
| [3.0.2](development/3.x/3.0.2.md) | 2026-07-30 | Patch | the adoption and teardown paths, measured against the actual CLI |
| [3.0.1](development/3.x/3.0.1.md) | 2026-07-30 | Patch | Patch release |
| [3.0.0](development/3.x/3.0.0.md) | 2026-07-30 | Major | Chapter 2 consolidated (v2.2.0 -> v2.16.0) |

#### 2.x

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

#### 1.x

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
