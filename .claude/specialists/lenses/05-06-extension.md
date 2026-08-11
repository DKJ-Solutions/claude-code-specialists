---
id: 06
group: 05
---

# Rendall 🎬 — the Release Manager (*Release Manager Rendall*)

> Repo-lens (lens-only persona) — the portable body lives in the plugin source:
> `~/.claude/plugins/marketplaces/claude-code-specialists/plugins/teams/team-alpha/personas/05-06-persona.md`.
> Rendall's body is read on demand from this path when Chris brings him in (no fixed `@` import).

## Specific to this repo (claude-code-specialists)

> *Everything above is Rendall's craft and travels with him to every repo. This part is the claude-code-specialists lens: if you copy Rendall to another repo, this is the part you replace — it describes not the release craft, but the specific mechanics with which he practices it here.*

A release manager does the same thing everywhere — maintain a changelog, bump SemVer, set tags, and
record releases. **What is repo-specific in claude-code-specialists is not that Rendall releases, but the
concrete mechanics and conventions this house chose.** Below is the implementation — this is what you
rewrite when copying. Managing branches, PRs, and merges up to and including the merge is
[Derek #05](05-05-extension.md)'s domain.

### Changelog

`CHANGELOG.md` (repo root) is an **intro followed by one `##` per change, with no section headings at all**
(Dave, August 5, 2026). A change *is* the `##`, and since August 6, 2026 its heading names the **branch** —
`` ## `feat/x` changelog `` — with six `###` sections under it: the branch's title, its ID, its type, what
the change brings to `main`, `Significance` (one `#### Tier N` sub-section per reach the change claims,
replacing the impact table because not every change has a tier 1 or a tier 2 and a missing row read as an
omission) and `Pull Request`, which the fold fills from the merge. Everything above the first `##` is the
intro, which is the only part a repo writes by hand and the only thing a cut leaves standing.

**This paragraph is why check 19 exists.** It described the pre-dossier shape — "just the title", three
sections, and two names that had been retired — for a day after the format moved, and it is one of the two
documents [#508](https://github.com/DaveKJohn/claude-code-specialists/issues/508) measured as stale. The
count is now held by the lint against `Get-EntrySectionHeadings`, so this cannot silently drift again; the
NAMES are not, and deliberately, for the reason that check's own comment records. **The shape itself is
written once**, in `branch/templates/branch_template_changelog.md`, which is generated — read it there
rather than trusting any prose, this paragraph included.

**Two sections went in the same movement, and each for a measured reason.**

- **`## Latest Release`.** It used to accumulate a block per release and had reached **434 of 1,062 lines**
  across 72 blocks that each said no more than "see the notes", while
  [`releases/README.md`](../../../releases/README.md) already listed all 72 with a date, a type and a
  descriptive title — the same coverage, verified in both directions, and richer per row. `'latest'` mode cut
  it to one block; this removes the last one. The intro's one-line pointer to that page is what answers
  "which version is current" now, and being hand-written prose it cannot go stale at a cut that no longer
  touches it.
- **The three `## Tier N - Pull Requests` sections**, which had lasted a day. They communicated exactly one
  thing — how far each change reaches — and the entries now say that themselves, in a table that also carries
  what the change is worth. What the headings did visually is kept as the **ordering**: furthest reach first,
  highest significance first within a tier.

**Branches never edit `CHANGELOG.md` directly** — with long-open branches that causes merge conflicts,
because every branch would modify the same region of the same file. Instead, every branch writes its own
entry file, which Rendall folds in after the merge.

**Where an entry lands is decided by its own impact table, and by nothing else** — no heading to choose, no
seam to configure (`Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` are retired). A
changelog holding nothing but tier 0 is a changelog with no release in it yet, and that now reads off the
entries rather than off which section they sit in.

#### How it works

- **`branch/branch-changelog.md`** — written when the branch is created; contains that branch's single
  entry and **nothing around it**, so it pastes into `CHANGELOG.md` in one go. A **fixed** path, the same
  on every branch: git already tracks it per branch, so two branches in flight cannot collide on it, and
  the repo root stops filling up with other people's work.
- **`branch/branch-progress.md`** — its companion: the branch's name, its step list, and where you left
  off. Never folded. The branch line is what the fold reads back to find the PR, since the file name no
  longer carries it.
- **Both live on `main` in an empty reset state**, opening with an `#` and carrying a warning not to write
  there until a branch exists. That `#` is load-bearing: the entry test only accepts the entry heading
  levels, so the trunk's own empty file can never be folded as if it were a change.
- **A pre-split root entry still folds.** Before August 6, 2026 the entry was a `<branch-name>.md` in the
  root — branch `feat/new-plugin` → `feat-new-plugin.md` — and the fold recognises both forms, deleting
  the root one and resetting the `branch/` pair. On such a branch: **never add a suffix like `-fix` or
  `-v2`** — without `-Branch` the fold recovers the branch from that file name, and a suffix breaks the
  PR lookup.
- **After the merge**: `scripts/release/fold-changelog-entry.ps1` reads the entry and inserts it at its
  **ranked position** in the list — the block as written, with `[PR #NN](url) · merged YYYY-MM-DD` appended
  as its last line and the heading **untouched**. (It used to prepend `#NN · ` to the heading too; that went
  on August 5, 2026 — the number is still in the entry, on that closing line, where the url makes it
  clickable, and the heading is left readable as a sentence.) **Nothing is consumed:** the impact table
  (or a pre-format entry's `Tier: N` line) travels into `CHANGELOG.md` intact, because with no heading above
  the entry, stripping the declaration would leave every downstream reader taking it as tier 0 — silent,
  correct-looking, and wrong in the direction that empties a release document. The outward-facing renderers
  strip both themselves, at the moment they render. A **pre-format `###` entry file is promoted to `##`** as
  it lands, because an `###` in a flat list of `##`s is not an entry boundary and would be absorbed into the
  entry above it, inheriting that entry's PR link. The
  PR number, url **and merge timestamp** are retrieved via one
  `gh pr list` on the branch name from the entry (only possible after the merge).
  **The date is the fold's and it sits at the bottom** (Dave, August 5, 2026): the scaffolder runs at
  branch creation, so a date it wrote was the branch's birth date rather than the landing date. The
  heading now carries what the author knows, the closing line what only the merge knows — and the date
  comes from the PR's `mergedAt`, not the clock, because a fold does not always run in the same minute as
  its merge (this repo has found entries still unfolded the next morning). The fold also
  automatically derives a **`Plugins:` line** from the PR's files (paths under
  `plugins/<plugin>/`; the `connectors/` directory does not count) — which the release notes read to
  say which plugins a change touched. It served the per-plugin CHANGELOGs too until those were retired
  on August 8, 2026; the line outlived them because the notes were always a second reader. This
  commit goes directly onto `main` (the only permitted exception — see
  [the safety rules](../../../CLAUDE.md#safety-rules)).

#### Entry format

**The format, the filename rule (including why a `-v2` suffix breaks the auto-delete), and the `##`-in-a-
body trap are all in the portable [`fold-changelog` skill](../../../plugins/workflows/workflow-davekjohn/skills/fold-changelog/SKILL.md)** —
they are properties of the shared scripts, so a consumer meets them identically. Local instances worth
keeping: the `##` trap was seen in **v2.13.2**, where a body's two subheadings came out looking like two
extra release categories next to `## Fixes`, and it is the same
[fold/release blind spot as #234](https://github.com/DaveKJohn/claude-code-specialists/issues/234) — the
artifact a reader finally sees is assembled past every gate that could have judged it. **The trap got worse
and gained a sibling on August 5, 2026**: a body `##` is now read as a *separate change* rather than as a
stray category, and a body `###` collides with the entry's own named sections — where a *misspelled* section
heading costs the entry its declaration in silence. Both halves are now gated by
`check-plugin-integrity.ps1`'s check 13, in the entry file and in `CHANGELOG.md`, so neither depends on
anyone remembering this paragraph. **This repo has no release categories any more**: the grouping came from
the branch prefix, which it measured does not predict impact, and each change states its own type inside
itself.

**Never merge without an entry**, not even for small changes. Since the branch-creation
improvement, the entry comes into being **at the moment the branch is created** — no
separate later scaffolding step: [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s
`new-branch.ps1` checks out the branch and, in the same move, calls the shared
`scripts/task/new-branch.ps1 -Title "…"` (which writes both `branch/` files, filling in the
title, the branch name and the type from the prefix automatically) as a child step. A branch is never
entry-less. Whoever builds on the
branch (often [Tessa #16](06-16-extension.md) or [Sylvester #15](05-15-extension.md)) fills in the
description while building; ownership of the entry mechanism stays Rendall's.

#### Lifecycle

1. **Branch** → both `branch/` files are written *at branch creation* (Derek's `new-branch.ps1`); you
   fill in the description and keep the step list current while building. Never touch `CHANGELOG.md`.
2. **Merge to `main`** ([Derek #05](05-05-extension.md#merging-to-main)) → the entry travels
   along. Rendall runs `fold-changelog-entry.ps1 -Branch <name> -Push` on `main`: that folds, commits
   (`fold: <branch> changelog (#NN)`) and pushes, in one step. **The `-Commit`/`-Push`
   opt-in, the path-scoped commit, the "check you are really on `main`" guard against
   `gh pr merge --delete-branch`, and the always-fold-with-`-Branch` rule for working from two machines
   are all in the portable [`fold-changelog` skill](../../../plugins/workflows/workflow-davekjohn/skills/fold-changelog/SKILL.md)** —
   properties of the shared script, met identically by any consumer. Measured here on July 16, 2026 (the
   stranded checkout) and PRs #46/#47 (the two-machine collision), and the flags arrived August 2, 2026
   after four hand-typed fold commits in one session. Repo-specific half: this fold commit runs under
   **this** repo's direct-on-`main` exception, which is what the path-scoped commit exists to keep honest,
   and the branch part of the two-machine lesson sits with
   [Derek #05](05-05-extension.md#branch--repo-hygiene).
   The fold also **resets both `branch/` files** to their empty state and names them in the same commit,
   so the trunk is ready for the next branch instead of showing the merged one's ticked-off steps.
3. **More branches merged** → each brings its entry; each gets inserted at the position its own impact
   table ranks it at, so the list stays ordered furthest-reach-first as it grows.

### Versioning & releases

A release here is a **recorded moment**: all plugins get the same version number
(**lockstep, repo-wide**) and the state is tagged as `vX.Y.Z`. `cut-release.ps1` itself publishes
nothing to GitHub Releases — only a git tag, the full notes in `releases/development/`, and a
reference to them in `CHANGELOG.md`. Publishing a GitHub Release is a manual closing step Rendall walks
through afterward, per the `cut-release` skill's checklist — not automated by the script.

**Here that happens at *every* release, patch included, and the body is GENERATED** (Dave, August 4,
2026, revised August 10, 2026). The two halves of that decision have separate reasons, so keep them apart:

- **Every release.** Until August 4 a patch skipped the step entirely (tag only). It no longer does, so
  the Release page becomes a continuous record rather than one with gaps where the patches were.
- **A generated body**, with every hand-written document and the development notes as **attachments**.
  `cut-release.ps1` writes `releases/development/<dir>/<X.Y.Z>-github-body.md` — the release title, a
  pointer at the attached notes where one is expected, and one linked line per change that landed, every
  tier included. Rendall edits nothing; he points `gh` at it, and the cut prints the exact command.
- **What this replaced, and why it is the more important half.** The body was the **internal note** from
  August 4 to August 10, and the reason given was that it is the only tier written at *every* release, so
  the only one that can be the body under a no-exceptions rule. That is a coupling dressed as a choice: it
  made the Release page depend on which tier existed, and it is the reason a patch nobody wanted a note
  for still needed one. A generated body cuts the dependency in the direction that matters — the page no
  longer needs any hand-written document to exist, which is what lets the *document* model be simplified
  separately from the *page*.
- **The cost that came with the internal note is gone with it.** That tier deliberately carries no file
  names, no commands and no code, so on a release requiring the reader to act — `v3.2.0`, where the
  marketplace rename breaks every existing install *with no error message* — the page carried no
  instruction and Rendall had to say so in prose. The generated body's pointer line does that
  structurally, and the acting instructions live in the attachment where they always did.

Never inline the development notes regardless: `gh release create`'s body has a hard
125,000-character limit and this repo's development notes have exceeded that.

**Copy each attachment to a unique filename before uploading** — all three tiers name their file
`<X.Y.Z>.md` and an asset's name is its basename, so two of them collide. The mechanism (including why
`gh`'s `file#label` syntax does not solve it) is in the `cut-release` skill's step 5, portable, with the
failing request that proves it. Measured here at `v3.3.0`. See
[releases/README.md](../../../releases/README.md#cutting-a-release) for the full mechanics. The
`version` in each
`.claude-plugin/plugin.json` remains the fine-grained marker, but on a release they move together.
Note: that number is one of **two** update gates — `claude plugin update` compares version numbers
only, so consumers (and this repo itself, which consumes itself) only receive merged changes after
a bump. If work must propagate to consumers, Rendall reports that to Dave as a reason for a release
(which remains at Dave's explicit request).

**The second gate is the consumer's marketplace cache, and the mechanism now lives in the portable
`cut-release` skill** (step 6) — including the per-command table showing that `install` does *not* refresh
the cached clone while `update` does, and why a stale cache is invisible by construction. It belongs there
rather than here: it is CLI behaviour every consumer meets, not something this repo does differently.
Measured here across `v3.0.2`, `v3.0.4` and `v3.0.5` (July 30–31, 2026) — the `install` half on two
independent releases, and the `update` half being the measurement that broke the tidier generalisation
this lens used to state as one rule. Rendall's local obligation is unchanged: **name the refresh command
in the closing report of every release.**

The `releases/` directory (modeled on life-hub):
- **`releases/development/<X>.x/<X.Y.Z>.md`** — the full release notes: **every** pending entry, tier 0
  included, grouped by **tier** and, inside a tier, a flat list in ranked order
  (`## Tier 2 - consumers` → `### <title>` → `#### What does this change do?`). Literally the whole
  changelog, which is what makes this the record rather than a summary of one — including each entry's
  impact table, since the cut empties `CHANGELOG.md` and this becomes the last place each ranking's
  justification lives. Repo-root-relative links in the entry bodies are rewritten with `../../../`
  so they resolve from that deeper location.
- **`releases/README.md`** — an overview table of all versions (newest at the top).
- In `CHANGELOG.md` the cut writes **nothing at all** — it empties the document down to its intro. The
  internal note's only inbound link is therefore the **Version cell of the `releases/README.md` row**,
  written by `new-internal-note.ps1`. That the cut cannot write it is unchanged and is the reason the step is
  separate: the note does not exist while the cut runs, and linking to it then would put a dead relative link
  inside an immutable tag. The cell was chosen over a fourth column because the table's shape is matched by
  one regex that three readers share — including the row inserter and the new-major guardrail — and only new
  rows are touched, so the existing 72 keep pointing where they always did.
- **`releases/notes/<X>.x/<X.Y.Z>.md`** — **the one hand-written document, since August 10, 2026**, drafted
  by the cut for every bump `Get-ReleaseConsumerBumps` names. Three sections: *For consumers* (pre-filled
  with the tier-2 entries, and absent where none reached tier 2), *What it is worth* and *What was still open
  at this release* (both empty — neither can be generated). Rendall's pass is a rewrite of the first and an
  authoring job on the other two. **A patch gets none of it**: the generated Release body announces it.
  - **The two documents below are the archive, and the measurement that merged them is in
    [`CLAUDE.md`](../../../CLAUDE.md#claude-code-specialistss-safety-implementation).** Short version: both
    were written at all twelve releases since the internal tier existed, about the same changes, and 38% of
    the internal note was material a consumer-facing section could carry — written twice, in two registers.
    A blended document was refused (62% could not travel, including the whole *what it is worth*); a
    sectioned one keeps both registers and writes the overlap once.
  - **The overview row now points here on the first write.** `Set-ReleaseInternalNoteLink` existed because
    the note did not exist while the cut ran; it does now, so the cut writes the Version cell correctly
    straight away and nothing repoints it afterwards. A patch's row keeps pointing at the development notes,
    which is the most readable document that release has.
- **`releases/consumer/<X>.x/<X.Y.Z>.md`** — *the archive of the two-document era.* Was the tier-2 document, generated **only for a minor or
  major** (`Get-ReleaseConsumerBumps`) and built from **the tier-2 entries**. Written for the reader who
  decides whether to *update*, not for the one who reviews the diff: the branch administration is stripped
  — the `Branch title`, `Branch ID`, `Branch type` and `Pull Request` sections plus the `Plugins:` line,
  alongside the significance scores.
  - **That sentence described the heading until August 10, 2026, and the sections outlived it.** The strip
    was aimed at the entry *heading*, where the PR number, type and date lived until the branch dossier
    (August 6) moved them into named `###` sections. Nothing followed them down, so the heading rewrite
    kept succeeding while the same facts arrived one line lower: **125 of the v4.2.0 draft's 396 rendered
    lines**, with `Branch title` printed directly beneath the heading it had just become. The lesson is the
    shape of the bug rather than the bug — **a format change moves what a reader reads and what a stripper
    strips at different speeds**, and the stripper is the half nobody opens afterwards. If a section is
    added or renamed, `Get-EntryAdminSectionKeys` is where that decision has to be made, and the default
    for a new section is *published*. **It is a draft and Rendall edits it before it is published** — the selection
  arrives already made, the prose does not. Turned on August 3, 2026, after this lens had briefly said the
  opposite. **Markdown only** — the tier generated a print-ready `.html` alongside it for exactly one
  release (v3.2.0) and no longer does; Dave does not want it anywhere. A PDF, if ever needed, comes from
  rendering the markdown with a tool built for it.
- **`releases/internal/<X>.x/<X.Y.Z>.md`** — *also the archive now; `new-internal-note.ps1` still ships and
  still works, for a repo running the two-document flow, and nothing in this repo's chain calls it.* Was the tier-1 document, for colleagues, employers and management:
  *what the work is worth*, at **every** release including a patch. It carries the **tier-1 and tier-2**
  entries, the ladder being cumulative, and leaves tier 0 to the development notes. Written by
  [`new-internal-note.ps1`](../../../scripts/release/new-internal-note.ps1), which lays down a skeleton —
  the metadata and the entry titles as bullets, plus three fixed headings — and leaves the rest to
  Rendall. **The middle heading is the tier**: "what it is worth" cannot be generated from a changelog,
  and the other two exist to keep it from growing back into the developer notes.
  - It runs **after** the cut, because the development notes are its input. `cut-release.ps1` prints the
    invocation at the end rather than doing it, and gates that line on the script existing.
  - It refuses to overwrite an existing note without `-Force`: this is the one document in the three
    tiers that cannot be regenerated from anything.
  - Think in time, risk and reduced dependence on a developer. A release with nothing for a consumer
    can still be the one where a routine change stopped needing one — that gap **is** why this tier
    exists, and it is the reason it covers patches while the consumer document does not.
  - **The third heading is past tense** — *"What was still open at this release"*, since August 4, 2026.
    The reason and the rule are in the `cut-release` skill and in the script's own skeleton hint, both
    portable. Local measurement that produced it: three present-tense lines went stale within hours on
    that one day, the last of them stating that the previous release had no public page — published
    minutes before it got one.
- **All three group per major (`3.x`)**, from the single answer in `Get-ReleaseNotesGrouping`. The
  consumer this model came from folders per minor; Dave chose to keep `<X>.x` here.

**What Rendall no longer has to do, and the measurement behind it.** Until August 5, 2026 the consumer
draft put `Feat`/`Fix` above a "remove before publishing" marker and everything else below it, and Rendall's
editing pass had to read both halves and promote what a consumer would want to know. In the repo this tier
was ported from that split is reliable, because a `Style` or `Content` branch there *is* a storefront
change. **Here it measurably was not.** Held against the 19 entries pending at v3.2.0, the most
consequential change a consumer could face — renaming the marketplace, which breaks every existing install
— came in on a `chore/` branch and landed *below* the marker; "a folder rename silently unlinks plugin
installs" did the same from a `docs/` branch.

So the question moved to where it can actually be answered: **the author of the entry declares the tier on
the branch**, and the draft is the tier-2 entries. The marker and its two seam knobs are retired. Rendall's
pass is now a rewrite rather than a rewrite *plus* a rescue — and the one thing to watch has changed shape:
not "did the marker put this in the wrong half", but "did whoever wrote this entry get its tier right".
A tier that is wrong is now a one-line edit on the branch, or a section move on `main` after the merge.

**And a release now has to earn its bump, so Rendall no longer decides whether a version number is
justified — the entries do.** `cut-release.ps1` refuses a bump the pending entries have not earned, before
it writes anything.

**The bump follows the highest tier pending** (Dave, August 7, 2026): **tier 0 only → patch**, **tier 1 or
higher → minor**, and a **major** additionally needs 10 minors in the current major line
(`Get-ReleaseMajorMinMinors`). Both of the first two loosened that day. A release made entirely of
repo-internal work used to be refused outright — the answer is that announcing nothing is precisely what a
patch is for. And a minor used to demand a tier-2 entry, so tier-1 work earned only a patch.

**What keeps the looser rule honest is that the documents follow the TIER, not the bump.** A tier-1-only
minor writes the internal note and no consumer document, because the consumer-document condition asks for a tier-2 entry
rather than for a bump type. So a consumer is never handed a document about work they cannot see, even
though their version number moved.
`-SkipTierGate` overrules it and should be a conversation, not a habit: the refusal names the bump the
pending work *does* earn, and taking that is nearly always the right move.

**Rendall's two hand-written documents land via a branch + PR, not on the release commit** (confirmed by
Dave, August 4, 2026). Both the edited consumer draft and the filled-in internal note are written
*after* the cut — `cut-release.ps1` commits and tags in one motion, and `new-internal-note.ps1` needs the
development notes as its input — so by the time either exists, the tag is already set. Neither is one of
the two named direct-on-`main` exceptions, so Rendall ships them the ordinary way: `new-branch` →
`ship-pr`. The alternative Dave was offered and declined was widening the release exception to cover "the
release *and* its written notes"; the reason for declining is the same one that forced the
August 2, 2026 repair of `ship-pr.ps1` — an exception is only safe while it stays the size it was granted
at. `v3.2.0`'s internal note is the worked instance
([PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432)): gates green, entry folded,
nothing about being post-tag causing friction. **Worth knowing why this is written down at all:** until
that date the route was an *assumption* presented as a rule in `CLAUDE.md`,
[`releases/README.md`](../../../releases/README.md) and the `cut-release` skill — asked twice, unanswered,
and written in anyway. This lens, the one place Rendall would actually look, was the one that never said it.

**Rendall notes the clock before he starts.** Step 0a of the
[`cut-release` skill](../../../plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md) asks for the
end-to-end duration — from before the cut to the published Release — written into the release document's
organisational section. It is his to capture because a baseline cannot be taken afterwards, and `v4.3.0` is
the instance: a whole cycle aimed at the thirty-minute release, improved it, and left no post-change figure
in minutes. See [Nolan #25](06-25-extension.md#wall-clock-here--the-gates-and-the-baseline-measured-at-v420-august-10-2026)
for the three numbers the next release owes.

A release is cut **only at Dave's explicit request** (a version bump falls under the
[safety rules](../../../CLAUDE.md#safety-rules)) and deliberately does **not go via a branch + PR**. Like the
fold commit, the release commit is a permitted **direct-on-`main` action** — the **second**
exception to "everything via branch + PR". `cut-release.ps1` therefore runs on `main` itself and
does everything in one motion:

`cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-SummaryFile <path>]` on
a clean `main`:
1. bumps all plugin versions in lockstep to `X.Y.Z`;
2. generates `releases/development/<X>.x/<X.Y.Z>.md`, adds a row to `releases/README.md`, and **empties
   `CHANGELOG.md` down to its intro** — the intro passes through verbatim, so whatever the repo says about
   itself up there survives every cut, in whatever language it wrote it;
3. **(retired, August 8, 2026 -- Dave)** steps 3 and 4 used to write a per-plugin `CHANGELOG.md` and
   regenerate a consumer-facing `RELEASE.md` card in every plugin folder. Both existed to put a history
   and a version signal *inside* the plugin cache, and the measurement that retired them is that the
   cache is not all a consumer has: the marketplace source is a git clone of the WHOLE repository, so
   `CHANGELOG.md` and `releases/` sit at `~/.claude/plugins/marketplaces/<marketplace>/`. Ten files,
   11,684 lines, second copies of a record the reader already held -- and free to disagree with it,
   which is what the lint gate's checks 9 and 17 existed to police. Both checks went with them. The
   repo has become the product, so it has one changelog.

   Two things survive the removal, and both are worth knowing. The `Plugins:` line is still derived at
   the fold and still read by the release notes -- it was never only for those files. And the defect
   the card carried is worth keeping in mind for whatever replaces it: it said *"You are on this
   release"* until August 2, 2026, which is the one thing a document written at cut time cannot know,
   since the documented update path installs from `main` (inbound
   [#384](https://github.com/DaveKJohn/claude-code-specialists/issues/384)). The question is answered
   by the `version` in `plugin.json` and by the INSTALL.md check;
5. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
6. pushes `main` + the tag (unless `-NoPush` for prior inspection).

**Before a MAJOR cut, two edits come first — the section and the pin.** A `X.0.0` cut stops before
writing anything, because the row would be filed under the previous major's table and nothing would
error — a silent misfile, which is why the guardrail speaks up. Both edits are made **by hand, directly
on `main`, ahead of the release commit** (deliberately unnumbered here, so they are not read as steps of
the list above — they run before its first one):

- add `#### <X>.x` plus its empty table header above the current top section in
  [`releases/README.md`](../../../releases/README.md) — the refusal prints the exact heading at the
  level the document uses, so follow what it prints rather than what this page says;
- repoint the live assert in [`release-lib.tests.ps1`](../../../scripts/tests/release-lib.tests.ps1)
  at the new major, **with a reason written above it** — the file asks for that in as many words.

**They run under the release exception, and only inside its bounds** (Dave, August 9, 2026): a major
only, those two paths only, once the cut has been asked for. Outside a cut they are ordinary changes on
an ordinary branch. **Neither is automated on purpose** — the section is the milestone moment the script
leaves to a person, and the assert is one fact deliberately written twice, so the day a script repoints
it is the day it stops catching a half-done edit. It caught exactly that at `v4.0.0`: the assertion went
red the moment the section was opened, which is what forced the second commit instead of letting the
pair land half-done.

Guardrails: on a clean `main`, no unfolded entry — neither a pre-split file in the root nor a filled
`branch/branch-changelog.md`, which is its own check because a filled one looks like the reset state at a
glance — lint gate green, and the tag must not exist yet. There is deliberately **no release branch and no `release` prefix** — the release
does not touch the branch workflow. A shared agent-def change still lands here first, gets
committed, and only then is picked up by the consuming repos.

**A milestone release: `-SummaryFile <path>`.** The mechanics — that the file normally lives outside the
repo, that a missing or empty one is a hard stop, that its links are left exactly as authored, and the rule
to say plainly whether anything breaks — are in the portable
[`cut-release` skill](../../../plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md#a-milestone-release---summaryfile).
The local instance behind that last rule: **the seam, the largest change in 2.x, broke nothing** — it is
backward compatible by construction, every reader accepts the old layouts — so a `major` bump here can be
one a consumer needs to do nothing about, and the summary has to say so or they sit on an old version
waiting for a migration that does not exist.

### Rendall's toolkit

**Where these live for a consumer, since August 8, 2026.** The paths below are this repo's own
`scripts/` and are unchanged — that is still the canonical source. The **mirror** moved: the fold, the
cut, the internal note and `release-lib` now ship in `workflow-davekjohn` rather than in
the core, and so do the `fold-changelog` and `cut-release` skill pages that document them. A consuming
repo that did not enable that pack has none of this, and that is correct: the changelog entry format,
the tier ladder and the release cut are one particular way of running a release, not the craft of
release management. Rendall's craft in such a repo is whatever *that* repo's release process is.

- `scripts/task/new-branch.ps1 [-Title <string>] [-Intent <string>]` — write the branch's
  two files in `branch/`. `-Intent` records where you left off / what is next in
  **`branch-progress.md`**, not in the entry (#162): an intent is a status, and the entry's text folds
  verbatim into `CHANGELOG.md`. Idempotent per file, judged on what each file says it belongs to rather
  than on its existing — both exist on `main` by design. Shared/mirrored to the plugin
  ([issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81)); normally reached
  indirectly, at branch creation, via
  [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s `new-branch.ps1` — you
  rarely call it standalone anymore.
- `scripts/release/fold-changelog-entry.ps1 [-Branch <name>] [-RepoRoot <path>] [-Commit] [-Push]` — fold
  entry(ies) into `CHANGELOG.md` on `main` after a merge, each at the **position its own impact table ranks
  it at** and with its declaration left intact. A malformed tier or an off-scale significance stops the run
  **before anything is written** — so a fold-all with one bad entry leaves nothing half-done. `-RepoRoot` is an
  explicit override for a consumer that runs the fold from a temporary/detached worktree (issue #101);
  omitted, it resolves the repo root as before.
- `scripts/release/cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-NoPush] [-SkipLint] [-SkipTierGate]`
  — cut a repo-wide release, directly on `main`: the **bump gate** (does the pending work earn this bump?)
  + lockstep bump + release notes in `releases/development/` + `releases/README.md` row +
  `CHANGELOG.md` emptied down to its intro + commit + tag `vX.Y.Z` + push. It wrote per-plugin
  `CHANGELOG.md`s and `RELEASE.md` cards until August 8, 2026 — see step 3 above for why it no longer does.
  The pure logic (version bump, CHANGELOG transformation, notes assembly) lives in
  [`scripts/lib/release-lib.ps1`](../../../scripts/lib/release-lib.ps1), covered by
  [`scripts/tests/release-lib.tests.ps1`](../../../scripts/tests/release-lib.tests.ps1).

A new recurring release chore? Rendall builds a script for it with the same guardrails.

In short: the **how** (changelog, SemVer, tags, and — where a release publishes one — a GitHub
Release) is portable; the **what** (these scripts, the per-branch entry + fold convention, and the
lockstep repo-wide release via `cut-release.ps1` with a git tag, and a `CHANGELOG.md` emptied down to its
intro) belongs to this repo. Publishing a GitHub Release here is a manual closing step at **every** release, per the
`cut-release` skill, that `cut-release.ps1` itself does not automate — with a **generated** body it
*does* write, and the hand-written tiers attached.
