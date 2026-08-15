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
written once**, in `workflow-davekjohn/branch/templates/branch_template_changelog.md`, which is generated — read it there
rather than trusting any prose, this paragraph included.

**Two sections went in the same movement, and each for a measured reason.**

- **`## Latest Release`.** It used to accumulate a block per release and had reached **434 of 1,062 lines**
  across 72 blocks that each said no more than "see the notes", while
  [`releases/README.md`](../../../workflow-davekjohn/releases/README.md) already listed all 72 with a date, a type and a
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

- **`workflow-davekjohn/branch/branch-changelog.md`** — written when the branch is created; contains that branch's single
  entry and **nothing around it**, so it pastes into `CHANGELOG.md` in one go. A **fixed** path, the same
  on every branch: git already tracks it per branch, so two branches in flight cannot collide on it, and
  the repo root stops filling up with other people's work.
- **`workflow-davekjohn/branch/branch-progress.md`** — its companion: the branch's name, its step list, and where you left
  off. Never folded. The branch line is what the fold reads back to find the PR, since the file name no
  longer carries it.
- **Both live on `main` in an empty reset state**, opening with an `#` and carrying a warning not to write
  there until a branch exists. That `#` is load-bearing: the entry test only accepts the entry heading
  levels, so the trunk's own empty file can never be folded as if it were a change.
- **A pre-split root entry still folds.** Before August 6, 2026 the entry was a `<branch-name>.md` in the
  root — branch `feat/new-plugin` → `feat-new-plugin.md` — and the fold recognises both forms, deleting
  the root one and resetting the `workflow-davekjohn/branch/` pair. On such a branch: **never add a suffix like `-fix` or
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
`scripts/task/new-branch.ps1 -Title "…"` (which writes both `workflow-davekjohn/branch/` files, filling in the
title, the branch name and the type from the prefix automatically) as a child step. A branch is never
entry-less. Whoever builds on the
branch (often [Tessa #16](06-16-extension.md) or [Sylvester #15](05-15-extension.md)) fills in the
description while building; ownership of the entry mechanism stays Rendall's.

#### Lifecycle

1. **Branch** → both `workflow-davekjohn/branch/` files are written *at branch creation* (Derek's `new-branch.ps1`); you
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
   The fold also **resets both `workflow-davekjohn/branch/` files** to their empty state and names them in the same commit,
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
  `cut-release.ps1` writes `releases/github/<dir>/<X.Y.Z>.md` — the release title, a
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
[RELEASES-portable.md](../../../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#cutting-a-release)
for the full mechanics. The
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
- **`workflow-davekjohn/releases/README.md`** — an overview table of all versions (newest at the top).
- In `CHANGELOG.md` the cut writes **nothing at all** — it empties the document down to its intro. The
  internal note's only inbound link is therefore the **Version cell of the `workflow-davekjohn/releases/README.md` row**,
  written by `new-internal-note.ps1`. That the cut cannot write it is unchanged and is the reason the step is
  separate: the note does not exist while the cut runs, and linking to it then would put a dead relative link
  inside an immutable tag. The cell was chosen over a fourth column because the table's shape is matched by
  one regex that three readers share — including the row inserter and the new-major guardrail — and only new
  rows are touched, so the existing 72 keep pointing where they always did.
- **`workflow-davekjohn/releases/audience/<X>.x/<X.Y.Z>.md`** — **the one hand-written document, since August 10, 2026**, drafted
  by the cut for every bump `Get-ReleaseConsumerBumps` names. Three sections: *For consumers* (pre-filled
  with the tier-2 entries, and absent where none reached tier 2), *What it is worth* and *What was still open
  at this release* (both empty — neither can be generated). Rendall's pass is a rewrite of the first and an
  authoring job on the other two. **A patch gets none of it**: the generated Release body announces it.
  - **It was `releases/notes/` until August 12, 2026**, and the root is stated in `Get-ReleaseNoteRoot` —
    never hardcoded, which is a rule with a measured instance behind it: lint check 25 named the old root as
    a literal, so on the day of the rename it would have found no live tree, checked the archive alone, and
    reported a healthy-looking coverage count. Read the seam. The **shared default** stays `releases/notes`,
    so a consumer who never answered the knob is not silently repointed.
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
- **`workflow-davekjohn/releases/audience/<X>.x/<X.Y.Z>.md`, the *For consumers* section** — *what the two-document era's
  `releases/consumer/` document became.* **That directory no longer exists**: on August 12, 2026 Dave had its
  twelve documents merged with their `releases/internal/` counterparts, one merged document per version, so
  `releases/` holds three reader-named roots and nothing else. Read the paragraph below as history — it
  describes how the separate document was generated, and every word of it still explains why the section
  reads the way it does.
  Was the tier-2 document, generated **only for a minor or
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
- **`workflow-davekjohn/releases/audience/<X>.x/<X.Y.Z>.md`, the *What it is worth* and *What was still open* sections** — *what
  the two-document era's `releases/internal/` document became.* **That directory no longer exists either**,
  merged in the same movement (Dave, August 12, 2026). `new-internal-note.ps1` still ships and still works for
  a repo running the two-document flow, and nothing in this repo's chain calls it — **its `releases/internal/`
  path is that consumer's archive and must not be repointed at `audience/`.** Read the paragraph below as
  history. Was the tier-1 document, for colleagues, employers and management:
  *what the work is worth*, at **every** release including a patch. It carried the **tier-1 and tier-2**
  entries — written while the ladder was cumulative, which it stopped being on August 12, 2026 — and left
  tier 0 to the development notes. Written by
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
[`releases/README.md`](../../../workflow-davekjohn/releases/README.md) and the `cut-release` skill — asked twice, unanswered,
and written in anyway. This lens, the one place Rendall would actually look, was the one that never said it.

**Rendall notes the clock before he starts.** Step 0a of the
[`cut-release` skill](../../../plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md) asks for the
end-to-end duration — from before the cut to the published Release — written into the release document's
organisational section. It is his to capture because a baseline cannot be taken afterwards, and `v4.3.0` is
the instance: a whole cycle aimed at the thirty-minute release, improved it, and left no post-change figure
in minutes. See [Nolan #25](06-25-extension.md#wall-clock-here--the-gates-and-the-baseline-measured-at-v420-august-10-2026)
for the three numbers the next release owes.

**And it takes him TWO passes, because the note is frozen before the Release is published** (measured at
`v4.4.0`, August 11, 2026 — the first release run under step 0a). At step 4 he writes the clock start, the
legs he can already read off timestamps, the subtotal to freeze, and which legs blocked a person. After step
5 he comes back with the total in its own small pull request, because at freeze the note's CI gate, its merge
and the publish are all still running on the file he is writing. **At `v4.4.0` that unmeasurable tail was two
thirds of the release** — 9m 42s frozen of **28m 03s** total — so the second pass is not a tidy-up, it is
most of the answer. The wrong repair, and the first one that suggests itself, is publishing the Release
earlier; step 5's ordering exists for the attachments and the skill refuses it explicitly.

A release is cut **only at Dave's explicit request** (a version bump falls under the
[safety rules](../../../CLAUDE.md#safety-rules)) and deliberately does **not go via a branch + PR**. Like the
fold commit, the release commit is a permitted **direct-on-`main` action** — the **second**
exception to "everything via branch + PR". `cut-release.ps1` therefore runs on `main` itself and
does everything in one motion:

`cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-SummaryFile <path>]` on
a clean `main`:
1. bumps all plugin versions in lockstep to `X.Y.Z`;
2. generates `releases/development/<X>.x/<X.Y.Z>.md`, adds a row to `workflow-davekjohn/releases/README.md`, and **empties
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
  [`releases/README.md`](../../../workflow-davekjohn/releases/README.md) — the refusal prints the exact heading at the
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
`workflow-davekjohn/branch/branch-changelog.md`, which is its own check because a filled one looks like the reset state at a
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

### The release craft, received from `CLAUDE.md` (August 15, 2026)

**This section was moved here, verbatim, out of the always-on path.** It lived inside `CLAUDE.md`'s
release-commit exception, where it was measured at **41,168 B over 474 lines** -- 56% of that document and
**32% of everything loaded before a single word of work**, paid on every turn of every session. The rule
applied is the one this repo wrote for itself on July 28, 2026 and then used once:
**the decision belongs on the always-on path, the evidence for it does not.**

**What stayed behind is the operative half, and the split is the thing to preserve**: `CLAUDE.md` keeps
that the release commit is a direct-on-`main` exception, that it runs **only on explicit request**, the
**bound** on it (a major only, those two paths only, only once a cut has been asked for), that a **major
needs two commits ahead of it**, and that the hand-written documents land **via a branch + PR** rather than
under the exception. Everything below explains *why* those rules are what they are. **If a rule ever
reads as arbitrary at the point of use, its reasoning is here** -- and if you are about to change one of
them, read this first: most of it records an alternative that was weighed and declined, several after
measurement.

The prose is unchanged from the day each paragraph was written; only relative links were repointed, which
is the published-record rule this repo already applies to `releases/`. Dates and attributions stand as
written.

See [the safety rules](../../../CLAUDE.md#claude-code-specialistss-safety-implementation) for the operative half.

---

**It also used to write a per-plugin `CHANGELOG.md` and a consumer-facing `RELEASE.md` card into
every plugin folder; both were retired on August 8, 2026 (Dave).** The repo has become the product,
so there is one changelog. And measured before removing them: a consumer receives the marketplace
source as a git clone of the **whole repository**, so `CHANGELOG.md` and `releases/` were always in
their reach — those ten files were a second copy, 11,684 lines, free to disagree with the original.
Lint checks 9 and 17 existed to police exactly that disagreement and went with them. A plugin's
version now has one statement: `plugin.json`.

#### Why the release commit takes no pull request

**Why no PR, in Dave's own words (August 7, 2026): "aan het product zelf verandert verder niks."**
A release republishes what is already merged — it bumps versions, generates documents and moves a
tag. There is no change to review, so a PR would add a checkpoint over a diff nobody has to judge.
Weighed against the alternative the same day rather than assumed: routing it through a PR would need
a `release/` prefix that the table deliberately excludes, would conflict on `CHANGELOG.md` with every
branch that folds while the release PR is open (the cut empties that file), and would meet two gates
— the scaffold gate and the step-list gate — that a release branch cannot satisfy by construction,
since its changelog is empty by design.

**What the PR route WOULD have bought is real, and is being closed another way.** Measured on
August 7, 2026: `open-pr` runs the lint *and* every test suite, and CI runs both again — while
`cut-release` runs the lint alone and its push to `main` bypasses the required check. The release
commit is therefore the least-gated commit in the workflow, and it is the one that empties the
changelog and bumps every plugin. The repair is coverage, not route: the cut runs the
suites too, and CI runs on `main` pushes so the artefacts the cut itself generates are checked after
they land.
Since August 3, 2026 it is a **shared** script, mirrored into the plugin like the rest of the
workflow ([#417](https://github.com/DaveKJohn/claude-code-specialists/issues/417)): everything
that legitimately differs per repo — which root docs are permanent, how the notes are foldered,
whether there is a plugin tier at all, for which bumps a
stakeholder-facing **consumer** document is generated, and how many minors a major must recap — is
read from optional functions in [`scripts/repo-config.ps1`](../../../scripts/repo-config.ps1), each falling
back to what this repo already did.

**A cut writes no release block, and that is deliberate** (Dave, August 5, 2026). It used to append a
`## Latest Release` block naming the version, the date, the type and a pointer to the notes. Measured
before removing it: that accumulating section had grown to **434 of the changelog's 1,062 lines**
across 72 blocks that each said no more than "see the notes", while
[`releases/README.md`](../../../workflow-davekjohn/releases/README.md) already listed every one of those 72 versions with a date,
a type and a descriptive title — the same coverage, verified in both directions, and richer per row.
So the intro carries a one-line pointer to that page and the cut leaves the document at its intro.
One consequence worth knowing: the hand-written note's only inbound link is the **Version cell** of
that page's history row — and **the cut writes it itself, on the first write** (August 10, 2026). This
paragraph said the opposite until August 11, naming `new-internal-note.ps1` as the writer and
`Set-ReleaseInternalNoteLink` as the reason it *could not* be the cut's job. That reason was real and it
expired: it could not be the cut's job while the note did not exist during the cut, and since the two
hand-written documents merged the cut **drafts** the note, so there is a real file to point at by the
time the row is written. `Set-ReleaseInternalNoteLink` still exists and is still called by
`new-internal-note.ps1`, for a repo running the two-document flow — recognise both, write one.
**Measured rather than assumed**: `v4.4.0`'s row pointed at `notes/4.x/4.4.0.md` on the first write,
with nothing repointing it afterwards. **The exception it runs under did not widen**: same scope, same
"only on explicit request", and the release artefacts it produces here were verified
byte-identical to the unshared script's, both when the script was shared and again when the
consumer tier joined it.

#### The entry, and the shape `CHANGELOG.md` receives

**The document is one change per `##` heading, with no section headings at all** (Dave, August 5,
2026). `CHANGELOG.md` is an intro followed by a **flat ranked list**: a change *is* the `##`. The three
`## Tier N - Pull Requests` sections it replaced said exactly one thing — how far each change reaches —
and the entries now say that themselves, in a form that also carries what the change is worth.
**What the sections communicated visually is kept as the ordering**: furthest reach first, and within a
tier the highest significance first.

**And since August 6, 2026 the entry is the branch's own dossier, folded in as it stands.** The heading
names the **branch** — `` ## `feat/x` changelog `` — and six `###` sections answer, in order:
`Branch title` (the human-readable name of the change, which the heading used to carry),
`Branch ID` (a timestamp stamped at creation), `Branch type` (the prefix, lowercase),
`What does the change on this branch bring to main?`, `Significance` (one `#### Tier N` sub-section per
reach the change claims, each closing with `**Score:**`) and `Pull Request`, which the **fold** fills
from the merge itself. `Plugins:` stays a plain line, because a heading around one fact is more
structure than content.

**That first section is called `Branch title`, and it IS the PR title** (Dave, August 7, 2026;
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506) +
[#505](https://github.com/DaveKJohn/claude-code-specialists/issues/505)). `open-pr.ps1` composes
`<branch type>: <this section>` instead of taking a title on the command line, so the sentence is typed
once — at `new-branch -Title` — and the PR, `CHANGELOG.md` and the release documents cannot disagree
about what the change is called. It also closes a rule that had lived in a document and was never
measured: Derek's manual has always said the PR title mirrors the branch type, and the five PRs before
this change all merged without one. `-Title` is accepted and ignored rather than removed, because every
branch in flight — here and in every consumer — passes one right now. The section was named
`Branch description` for one day and is **still read** under that name, for the standing reason.

**Dave chose that `CHANGELOG.md` receives this shape verbatim**, asked and answered before any of it was
built. The alternative he was offered — a fold that reads the dossier and derives a slimmer entry from
it — was declined, and the reason is one this repo has already paid for three times: a fold that rewrote
the entry would put a **second definition of the entry format** inside the fold, free to drift from the
one the scaffolder writes. One shape, written once, read everywhere.

**The form writes no visible placeholder at all.** Every field is a heading with an HTML guidance
comment above the space where the answer goes; the fold strips those comments, so leaving one standing
is not a defect and there is nothing to tidy before the PR. What replaced the `TODO:` strings as the
gate is a **measurement**: `open-pr` refuses an entry whose description, body or any tier's reason is
still empty once the comments are stripped — strictly more than the strings caught, since it also
catches a placeholder that was deleted rather than answered. The retired strings are still refused, for
the standing reason: every branch in flight, here and in every consumer, carries one right now.

#### The tier model, and the audience knob

**The tier model** (Dave, August 5, 2026). Every change declares **how far it reaches**, and that one
number decides which release document it appears in:

| tier | who notices | where it is written | when |
|---|---|---|---|
| **2** | subscribers of the service | the *For consumers* section of `workflow-davekjohn/releases/audience/<X>.x/<X.Y.Z>.md` | minor/major |
| **1** | management and the employer/commissioner | the organisation's two sections of that same file | minor/major |
| **0** | only this repo's developers | `releases/development/<X>.x/<X.Y.Z>.md` | every release |

**TIERS 1 AND 2 ARE TWO KINDS OF AUDIENCE, NOT TWO RUNGS, AND A REPO HAS EXACTLY ONE** (Dave, August 12,
2026; inbound [#620](https://github.com/DaveKJohn/claude-code-specialists/issues/620)). Tier 1 is
management and whoever commissions or pays for the work — the audience of a repo that *delivers*
something, or that sells a **product** whose buyers never read a release note. Tier 2 is the subscriber
of a **service**, who decides whether to upgrade. The answer is fixed per repo, before any entry is
written, in `Get-ReleaseAudienceTier`; **this repo answers 2**, the webshop that filed #620 answers 1.
Same model, opposite answer — which is exactly why it is a knob and not a constant. `new-branch`
scaffolds tier 0 plus that tier alone, the routing question under tier 0 points at it, and `open-pr` and
`cut-release` require that tier rather than every rung from 1 up.

**THE MEASUREMENT, AND IT REVERSED AN ARGUMENT MADE AGAINST THIS CHANGE THREE HOURS EARLIER.** Counting
tier sections **in aggregate** says tier 1 is a working axis here — 89 of 95 scored — and produces a case
for keeping the ladder. Counting the highest scored tier **per entry** over the same 97 says the
opposite: **81 top out at tier 2, 8 at tier 1, 8 at tier 0**, so 81 of those 89 tier-1 sections existed
only because the ladder demanded one under a scored tier 2 — the same reach argued twice, in a second
register, for a reader who here is the same person. The consumer measured the mirror image: 37 open
entries, 15 at tier 1, zero ever at tier 2. **Count per entry, never in aggregate**; the aggregate is an
artefact of the rule being questioned.

**TWO SEPARATIONS CARRY THE WHOLE SAFETY OF IT.** `Get-EntryTierMax` stays **2** and every validator
keeps reading it: the MAX says which tier numbers are valid to *read* — a tier-1 repo must still parse
the tier-2 entries in its own history — while the audience says which tiers a repo is *asked* about. And
**an unstated seam means ask about all of them**, exactly as before the knob existed: reading absence as
"no audience enabled" would switch the tier off in every consumer the moment they took the plugin update,
with nothing erroring and a release document going out empty. The loud channel is the contract, where
this is a `decide` record that `adopt-config` scaffolds rather than copies.

**THE GATE NARROWED WHAT IT ASKS WITHOUT NARROWING WHAT IT ACCEPTS**, which is the half that would
otherwise have cost real work: the entries pending when this landed each carried all three tiers, and a
gate that began refusing an *extra* answered tier would have turned finished dossiers into PRs that
cannot be opened. An asserted test holds exactly that case — do not "tighten" it.

**`releases/notes/` BECAME `releases/audience/` IN THE SAME MOVEMENT** (August 12, 2026), completing the
rule that every root under `releases/` names its **reader**: `development/` the developers, `github/` the
Release page, `audience/` whoever this repo publishes to. `notes/` named the *form* — the same mistake
`highlights/` made, fixed in that sibling two days earlier and missed in this one. **The shared default
stays `releases/notes`** in `cut-release.ps1`, `session-status.ps1` and the contract record: an unstated
seam has to keep meaning what it meant yesterday, and a consumer receives these scripts through a plugin
update rather than by choosing to.

**AND `consumer/` + `internal/` WERE MERGED INTO `audience/` TWO HOURS LATER, WHICH IS WHY THAT MOVEMENT
WAS NOT FINISHED** (Dave, August 12, 2026). This paragraph said they *stay as frozen archives* — and that
freeze was the assistant's call written as settled, in three places, **none of which named Dave**, while
the rename standing beside it in the same entry was attributed to him. Asked why `releases/` still had
five folders, he was offered the freeze as one of three options and chose the merge instead: the twelve
`consumer/`+`internal/` pairs are now twelve documents in `audience/`, and `releases/` holds three
reader-named roots and nothing else. **The identical filenames are why it was a merge and not a rename** —
`3.x/3.2.0.md` existed in both trees, so 24 documents became 12 and no `git mv` could do it.

**The published-record rule is what made it safe, and it is the half to copy.** Each pair kept both
registers verbatim — the consumer body under *For consumers*, the organisational prose under *What it is
worth* and *What was still open at this release* — and dropped exactly one section, `## What is different
now`, which the 62/38 measurement below identifies as the duplicated half. Prose was otherwise left as
written, so a merged document may still name `releases/highlights/` or describe itself as one of three
tiers; **links** were repointed, because a dead link in a record is worse than a relocated one and
repointing one changes no claim the record makes. That is the same rule the `highlights/` → `consumer/`
move ran under on August 10, and the same one that left the seven wrong merge dates standing. The one
thing genuinely rewritten was a clause that had become **false**: an internal note whose lead said the
commands *"are not on this page"* now sits one section below the page that carries them.

**ONE HAND-WRITTEN DOCUMENT SINCE AUGUST 10, 2026, WITH A NAMED SECTION PER READER** (Dave). Tier 1 and
tier 2 had a document each — `releases/internal/` and `releases/consumer/` — and at **all twelve**
releases since the internal tier existed, both were written, about the same changes. The merge was
measured rather than argued: `v4.2.0`'s internal note (962 words) held against the writing norm's test 2
gave **~365 words (38%) that could appear in a consumer-facing section** — and did, rewritten in a second
register in the other document — against **~597 (62%) that could not**, including the 316-word *what it
is worth*, which is not an outlier but the whole reason the organisational tier exists. So a **blended**
document was refused and a **sectioned** one built: each register intact, the shared 38% written once.
The heading *"what is different now"* is gone rather than moved — it *was* the duplicated half.
`new-internal-note.ps1` is still shipped for a repo running the two-document flow; nothing here calls
it, and **its `releases/internal/` path must not be repointed at `audience/`** — that is a consumer's
archive, not this repo's, and switching it would be the one failure here that produces no error message.
The same holds for `Get-ReleaseNoteRoot`'s shared `releases/notes` default.

**A patch writes no hand-written document at all**, and is announced by the generated GitHub Release
body alone — which is what made this possible in the first place: while the body *was* the internal
note, that note had to exist at every release or the page had none. The **sections** follow the tier;
whether there is a document follows the bump.

The grouping is per **major** (`3.x`) for all three, deliberately differing from the consumer this
model came from, which folders per minor. `Get-ReleaseNotesGrouping` answers that once.

**EACH DOCUMENT IS NAMED FOR ITS READER, AND TIER 2 WAS THE ONE THAT WAS NOT** (Dave, August 10,
2026). It was `releases/highlights/` — the directory, the seam, the renderer and some ten documents of
prose — while its neighbours name their audience and this very table has always said tier 2 is
*consumers*. So the name disagreed with the model it belongs to, and it named the **form** (a selection
of the nice bits) rather than the reader. **Measured before renaming rather than argued:** five
dev-tool changelogs in the field — Linear, Stripe, Vercel, Raycast, GitHub — and **not one publishes
anything called "highlights"**; the live names are *Changelog*, *Release notes* and *What's new*, all
of which name the document or its reader. That same pass found the split this repo already runs:
GitHub keeps a terse engineering changelog beside readable announcements, which is
`development`/`internal` beside this tier. The form-name was also earning its keep in the wrong
direction — it invites the register a self-selected best-of invites, which is what a review of
`v4.0.0`'s own document had just found it guilty of.

**THE SEAM IS THE HALF THAT COULD HAVE BROKEN A CONSUMER IN SILENCE**, so it is read under both names:
`Get-ReleaseConsumerBumps` first, `Get-ReleaseHighlightsBumps` second. The fallback for an undefined
seam is `@()` — *the tier switched off* — so a repo still carrying the old name would cut a minor,
write no document for the very consumer it was cut for, and report success. That is the same
failure-with-no-error-message class the previous release was about, and it is why "recognise both,
write one" is not politeness here: consumers receive a rename through a plugin update rather than by
choosing to. `Get-SeamValue` takes a **list** of names now, the current one first, and three asserts in
`cut-release-guardrail.tests.ps1` hold exactly that.

**What was deliberately NOT renamed, and the rule behind it.** No GitHub Release body links to a
`releases/highlights/…` path — checked rather than assumed, which is what made moving all eleven
documents safe. The **prose** in the archived `releases/development/` notes and in the already-folded
`CHANGELOG.md` entries keeps the old word, because those describe what the document was called on the
day they were written; that is the same published-record rule that left the seven wrong merge dates
standing that [Chris's lens](01-01-extension.md#the-dave-rules) records.
Their **links** were repointed, since a dead link
in a record is worse than a relocated one and repointing one changes no claim the record makes.
`Get-ReleaseHighlightsStakeholderTypes` and `Get-ReleaseHighlightsWording` keep their names too — they
name functions that no longer exist under any name.

**AND THE DOCUMENT NOW HAS A WRITING NORM, WITH EXACTLY ONE OF ITS SEVEN TESTS AS A GATE** (Dave,
August 10, 2026). The rename came out of reviewing `v4.0.0`'s own consumer document against the
question *"is this written for someone who paid for the product?"*, and the answer was: partly. Of its
four substantive blocks one was in the second person; it opened with **"twenty-one releases and
fifty-one pull requests in ten days"** (our effort, not their outcome), carried a full block about a
lint check we measured and declined (tier-0 material in a tier-2 document), used in-house vocabulary
(*"against the tree they describe"*), had to tell the reader to skip to the bottom for the useful part,
and linked them into the development notes. The seven tests are in the
[`cut-release` skill](../../../plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md) — the portable
half, so a consumer receives them — each one carried by what a named dev-tool changelog actually does.

**The split between prose and gate was measured, not assumed, and that is the transferable part.**
Three candidate rules were run over this repo's eleven consumer documents:

| candidate rule | findings | true | verdict |
|---|---|---|---|
| links into `development/` or `internal/` | 2 | **2** | **built** — lint check 25 |
| a significance score in the document | 4 | 0 | declined |
| a branch name or PR number in the document | 3 | 0 | declined |

Both declined rules fail on the same document and for the same reason: `v3.7.0`'s release **was about
the entry format**, so its consumer document correctly quotes `#### Tier 2`, `**Score:** N/A` and
`` ## `feat/your-branch` changelog `` as illustrations of the shape it was announcing. **No regex
separates an illustration from a leak**, and both would have needed an exemption list on the day they
landed — the shape this repo has already been bitten by. Check 25 escapes it by reading the link
**target** only: a path in prose is
[check 4's declined territory](../../../CLAUDE.md#claude-code-specialistss-safety-implementation) (124 findings, none
real), while a link is not a path being discussed but a destination being offered, and whose repo it
lives in stops being ambiguous. The other six tests stay prose that a person applies.

**The release documents follow the same flat shape**, and that deletion is part of the decision rather
than a tidy-up alongside it: the category grouping (`## Features`, `## Fixes`, …) is gone, together with
`Format-CategorizedEntries`, the category labels and the `Get-ReleaseCategoryTitles` seam. It grouped on
the **branch prefix**, which this repo has measured does not predict impact, so a document's most
consequential change was filed third under whichever label its prefix produced — and the ranking could
only reorder the categories, not escape them. Each change states its own type inside itself now, so
nothing is lost by not grouping on it.

**The audience tier decides which sections of the hand-written note the entry reaches**; the
development note carries everything, tier 0 included, because it is the record rather than a summary.
**The number comes from the author of the entry, on the branch** — and deliberately **not** from the
branch prefix, which this repo has measured does not predict impact.

#### Significance, and how the list is ordered

**The second axis: significance, and the order follows it** (Dave, August 5, 2026;
[#467](https://github.com/DaveKJohn/claude-code-specialists/issues/467)). The tier says how far a change
**reaches**, and therefore which document it appears in. A significance score says how much it
**weighs** for that document's reader, and therefore **where in it** the entry sits — so the most
consequential change leads instead of sitting third under whichever heading its branch prefix produced.
Both are declared under **`### Significance`**, one `#### Tier N` sub-section per reach the model has,
each carrying why it matters there and then its score:

```text
#### Tier 0

The routine version bump stops needing a developer.

**Score:** 4

#### Tier 1

Nobody but this repo's own developers can observe it.

**Score:** N/A
```

**The score label is bold** (Dave, August 6, 2026). `Score:` sat as bare prose in a section that is
otherwise all prose, so it did not read as the field it is. The plain form is still **read**, because
`CHANGELOG.md` and every consumer's tree are full of entries carrying it.

**Every tier the repo asks about is present, and `N/A` is how one says it reaches nobody** (Dave,
August 7, 2026; narrowed from "all three" to tier 0 plus the audience tier on August 12). Tier 1 and
tier 2 used to be commented out, and uncommenting one *was* the claim — so an
unreached tier and an unfinished one looked identical, and no gate could tell "this reaches no
consumer" from "nobody got to tier 2 yet". Each tier is answered now: a score, or `N/A` with a line
saying why. **The reach is the highest tier carrying a number**, so an `N/A` costs a sentence and
nothing else — and the reasoning behind a *negative* claim survives into the record, which the
absence model threw away. A `Yes/No` field was drafted alongside the score the same day and dropped:
a score and a yes are one fact, free to contradict each other.

**The scaffolded working files carry no comments at all** (Dave, August 7, 2026). Guidance is written
only into `workflow-davekjohn/branch/templates/`, which is what those copies are for; the file a branch gets is the
headings and the space under them. The routing questions went with the guidance — the trade being
that the ladder is now learned from the template and this document rather than from the file in front
of you. The fold keeps its comment stripper regardless: every branch in flight carries comments, and
they reach the new scripts through a plugin update rather than by choosing to.

**SUB-SECTIONS RATHER THAN A TABLE** (Dave, August 6, 2026), which replaced the impact table that had
itself replaced the `Tier: N` line the day before. The table forced a rectangle onto something that is
not always rectangular: **not every change has a tier 1 or a tier 2**, and a missing row reads as an
omission while a missing section reads as a decision. The heading also stopped naming an audience —
it was `Who is this for` — because each sub-section names its own by its number, and what the section
carries is how much the change *weighs* for each of them.

**Each section closes by asking whether there is a next one**, and that question is written even where
the next tier is already there. An author who has answered does not need it; a reader at the fold, at
the cut and in the record does — a question that disappears once answered leaves them unable to see
that it was asked. **The LAST written tier has no successor and carries none** — which used to be a
statement about tier 2 specifically and is now about whichever audience tier the repo asked for. The
question is keyed on what is actually written rather than on a fixed pair, so a tier-2 repo no longer
prints *"continue to Tier 1"* above a file whose next section is Tier 2.

**The cumulative ladder is gone** (August 12, 2026), and with it the rule that a tier-2 entry owed a
tier-1 section. What remains is that every tier the file *does* carry is answered, `N/A` ones included.
The score is scaffolded **empty**, unlike the tier: 0 is a harmless final answer about
reach, while any scaffolded *score* would be a guess at a ranking, and this repo has measured what a
guessed ranking costs (the retired remove-before-publishing marker, below).

**Three shapes are read and one is written.** The sub-sections, the table, and the older `Tier: N`
line — because `CHANGELOG.md` holds all three right now and every consumer's tree holds at least one.
The retired section heading is recognised too (`Get-EntryRetiredSectionHeadings`): without that, the
lint reported all 24 pending entries as *misspelled* headings the moment the name changed, which is
how a check gets switched off rather than heeded.

**1 to 5 against a written rubric** (`Get-EntrySignificanceRubric`, overridable per repo), because an
unanchored ordinal scale invites false precision — 5 is *the reader must act*, 1 is *cosmetic, or names
the failure it prevents*. That is what makes the number a measurement rather than a mood, and it is also
why the score is comparable **across** releases. Dave reversed his own earlier "no anchors" answer the same day,
and the reversal is the reasoning: without anchors there is nothing to drift, but also nothing to check.
The **`Why` is required** and is the lasting half — the rubric says which band, the `Why` says why *this*
change is in it.

**Band 1 asks what is prevented, and that is the repair of a band that invited its own abuse** (Dave,
August 7, 2026; [#509](https://github.com/DaveKJohn/claude-code-specialists/issues/509)). It used to read
*"cosmetic or preventative — nothing changes for them today"*, and the second half is exactly the sentence
the rubric exists to stop: [PR #503](https://github.com/DaveKJohn/claude-code-specialists/pull/503)'s entry
scored its tier 0 with "Nothing changes here" — inside the band, and useless to a reader a year later.
Four of the five bands describe something the reader can observe; this one describes an **absence**, and
an absence has to be named or it cannot be told apart from having nothing to say.

**The tiers are not nested audiences, so tier 0 may legitimately score below the audience tier.** Dave asked whether
that should be refused — if nothing changes for this repo's own developers, how can it change for anyone
further out? PR #503 is the counterexample: the defect existed **only outside this repo** (consumers had
no `branch/templates/`; this repo always did), so it was worth 4 to a consumer and almost nothing here. A
consumer is not a colleague of this project. That gate would have refused a correct entry, and the
instinct behind it is already encoded one level down and correctly: **tier 0 is the one tier that cannot
be `N/A`**, because every change reaches this repo's own developers at least a little. The floor is a
score of 1 — and band 1 now asks what that 1 buys.

**Who reads it where.** The fold places the entry at its ranked position in `CHANGELOG.md`, and that is
the *only* moment it can: the cut **empties the list**, so whatever order the fold leaves is
what the release documents inherit — reproducible across two moments days apart with nothing
re-estimated. Insert-only, never a re-sort: the fold commit lands directly on `main`, so a bug there
must be able to misplace at most the one entry being folded rather than scramble a list it did not write. The **consumer** re-read the tier-2 row (its reader is the consumer); the **internal
note** reads the tier-1 row. **Tier 0 is never ranked** — the development note is the record: complete
and chronological. The table **survives into the record** because that is the last place each ranking's
justification lives, and is **stripped from everything that travels outward** (the consumer document),
because a self-assigned number printed at a consumer is a marketing claim. It used to be stripped
from the per-plugin `CHANGELOG.md` and `RELEASE.md` too; those were retired on August 8, 2026, so
the consumer document is the only outward document left to strip. `cut-release.ps1` refuses a release whose tier-1-or-higher entries have not scored themselves;
`-SkipSignificanceGate` overrules it, separate from `-SkipTierGate` because one overrules whether the
release should exist and the other how its contents are ordered.

**`Tier: N` is still read, and always will be** — "recognise both, write one". Every entry already in
`CHANGELOG.md` and in every consumer's tree predates the table, and a parser that only knew the new
shape would read all of them as tier 0: silent, correct-looking, and wrong in the direction that empties
a release.

**The name was `Happiness` for one afternoon.** Dave rejected it as unprofessional, and he was right
about more than the word: *happiness* names an emotion in the reader, which an entry's author is in no
position to assert, while the weight of a change for an audience is something they can judge. Worth
recording alongside it, because it is the first thing anyone reaches for: **RICE and WSJF do not apply
here.** They price work *before* it is done, with effort in the denominator — they answer "what do we
build next". Everything scored here is already merged, so effort is spent and irrelevant. Reach ×
significance is the decomposition incident practice makes when it derives a priority from impact and
urgency rather than asking for one number.

**And a release now has to earn its bump.** `cut-release.ps1` refuses one that the pending entries do
not justify, before it writes anything:

- **the bump follows the highest tier pending** (Dave, August 7, 2026): **tier 0 only → patch**,
  **tier 1 or higher → minor**. A release made entirely of repo-internal work used to be refused
  outright, on the grounds that it "has nobody to announce it to" — the answer is that announcing
  nothing is exactly what a patch is for. And a minor used to demand a **tier-2** entry, so tier-1
  work earned only a patch. It is written as **tier 1 or higher** rather than as "the audience tier"
  deliberately: `Test-ReleaseBumpEarned` then reads correctly in a tier-1 repo and a tier-2 repo alike,
  with neither having to translate it, and **#620's "silently wrong bump" cannot happen** — that was the
  one claim in the report which measurement did not support;
- **the sections of the note follow the TIER, not the bump**, and that is what keeps the looser
  rule honest. A minor whose highest pending entry is tier 1 writes the note **without its *For
  consumers* section**, so nobody outside is handed a section about work they cannot see —
  which is every minor in a repo whose audience is tier 1. `cut-release.ps1` keys that section on a tier-2
  entry being present rather than on the bump type — a condition that was belt-and-braces while a
  minor required tier 2, and is now the whole mechanism;
- a **major** needs **10 minors** in the current major line, on top of that minimum. A major is a
  *recap* — which is what both of this repo's majors already were — so what earns it is the
  accumulation, not any single pending change. `Get-ReleaseMajorMinMinors` owns the number.

`-SkipTierGate` overrules it, deliberately separate from `-SkipLint`: that one skips a tool, this one
overrules a judgement about content. **The gate switches itself off where no pending entry declared its
impact at all**, so a consumer that has not adopted the model is untouched. That test used to be "does
this repo declare more than one changelog section", which had a real basis while the sections existed
and became a landmine the moment they went: a flat document gives an unadopted repo and an adopting one
one group each, so the old line would have read every repo as not adopting and switched the gate off in
silence, in the same change that made the tier the model's primary fact. Nothing would have errored.
Counting **declarations** is a measurement rather than a flag, and it keeps "declared tier 0" distinct
from "declared nothing" — which is the whole difference between a release that has nobody to announce
itself to and a repo that never chose the model.

**And that same ladder is why the internal document exists at every release.** Tier 2 and tier 1 are
not the same question: the consumer document is *what a consumer notices*, internal is *what the organisation
gets out of it*. They come apart most clearly on a patch — a release with nothing for a consumer can
still be the one where a routine change stopped needing a developer.

#### The measurement the whole model rests on

**The measurement the whole tier model rests on: the branch prefix does not predict impact in this
repo.** Until August 5, 2026 the consumer document put `Feat`/`Fix` above a "remove before
publishing" marker and everything else below it, explicitly as a *proposal* rather than a verdict.
Measured against the 19 entries pending at v3.2.0, the single most consequential change for a consumer
— renaming the marketplace, which breaks every existing install — arrived on a `chore/` branch and
therefore landed below the marker. The tier asks the entry's author instead, so the marker and its two
seam knobs are retired; a `docs/` branch carrying a tier-2 change now says so, and the prefix decides
nothing but which category heading the entry is grouped under.

### Rendall's toolkit

**Where these live for a consumer, since August 8, 2026.** The paths below are this repo's own
`scripts/` and are unchanged — that is still the canonical source. The **mirror** moved: the fold, the
cut, the internal note and `release-lib` now ship in `workflow-davekjohn` rather than in
the core, and so do the `fold-changelog` and `cut-release` skill pages that document them. A consuming
repo that did not enable that pack has none of this, and that is correct: the changelog entry format,
the tier ladder and the release cut are one particular way of running a release, not the craft of
release management. Rendall's craft in such a repo is whatever *that* repo's release process is.

- `scripts/task/new-branch.ps1 [-Title <string>] [-Intent <string>]` — write the branch's
  two files in `workflow-davekjohn/branch/`. `-Intent` records where you left off / what is next in
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
  + lockstep bump + release notes in `releases/development/` + `workflow-davekjohn/releases/README.md` row +
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
