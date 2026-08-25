# Development cycle: `feat/isolate-workflow-from-consumer-root-v1` · 20260825-142313

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

**Subject — issue [#885](https://github.com/DaveKJohn/claude-code-specialists/issues/885).** The
`workflow-davekjohn` plugin must not be able to get in the way of a consumer's repo root. Everything the
plugin creates belongs inside `workflow-davekjohn/`, that folder is permanent, and the plugin never
writes a file it did not create.

Explored on `main` before this branch existed. The full findings are recorded in two comments on #885
(`issuecomment-5410141976` and `issuecomment-5410243269`); the steps below are what was read and what it
said, so this file stands on its own if the issue is ever unavailable.

### Verified against the tree (at `459bf667`)

- [x] **The scaffold already obeys the rule, and cannot overwrite.**
  `plugins/workflows/workflow-davekjohn/scripts/task/adopt-workflow-folder.ps1` opens with
  "EVERYTHING PORTABLE ABOUT THE WORKFLOW GATHERS IN ONE FOLDER (Dave, August 14, 2026)", and its
  placement loop puts every target behind a `Test-Path`, reporting `[exists] ... left as it is`. So the
  overwrite the issue describes — a consumer's existing `releases/` being replaced — cannot happen at
  adoption. The issue's premise is repaired for the scaffold; what remains is elsewhere.
- [x] **`research/` and `projectmanagement/` are created by nobody in this plugin — and
  `projectmanagement/` nevertheless exists, in a consumer.** Corrected after Dave pointed at
  `BWJ-ecommerce/smartwatchbanden` (August 25, 2026); the first measurement grepped this tree, and a
  consumer-owned folder is invisible to that. What the tree does say:
  `TICKETWORK-portable.md` governs that layer and prescribes **no folder, no filename and no script** —
  "Nothing below prescribes a filename, a folder, a language, or a set of section headings. Those are
  yours" — and its closing section declines a template and a scaffolding script explicitly, pending a
  second consumer. So the folder is that consumer's own naming choice, not plugin payload.
- [x] **Which inverts that part of the issue, and is the most important thing this exploration found.**
  The issue reads "everything that the plugin creates, like the releases, research, projectmanagement
  folders, has to be placed inside the workflow-davekjohn folder." `projectmanagement/` is **not**
  plugin-created, so moving it into `workflow-davekjohn/` would be the plugin annexing a folder the
  consumer built — the exact opposite of the isolation this branch exists for. The rule protects it
  where it stands; it does not relocate it. This is also why the rule has to be stated as provenance
  ("never write a path it did not create") rather than as location: a location rule cannot tell these
  two cases apart.
- [x] **TICKETWORK is optional and single-consumer, and the scaffolded README misrepresents that**
  (Dave, August 25, 2026). Every repo that installs the workflow always uses `CONTRIBUTING-portable.md`,
  `DEVELOPMENT-CYCLE-portable.md` and `RELEASES-portable.md`; `TICKETWORK-portable.md` is used by
  `smartwatchbanden` alone, and its own provenance section says so — built there on 2026-08-11 and
  donated upward "without the duplication that normally earns a promotion", one repo rather than two.
  But `adopt-workflow-folder.ps1:119` writes the four into every consumer's folder README as one flat
  row of equals, so a repo that will never run a tracker is told it has four portable pages to answer.
  Fix belongs in this cycle: it is one string in the scaffold, and it is the same defect class as the
  rest of the branch — the plugin overstating what it needs from a consumer.
- [x] **The root `*.md` namespace claim is already a known hazard, with two documented workarounds
  telling the consumer to dodge the plugin.** `TICKETWORK-portable.md`'s closing note: "if your ticket
  files live in the repo root as `*.md`, they will look like unfolded changelog entries to the release
  cut. Put them in a directory, or add them to your `Get-ReservedRootMd`." And
  `CONTRIBUTING-portable.md:317` says the same for a root `CONTRIBUTING.md`: a repo that overrides the
  list and forgets its own document "meets a refusal at its next release, naming the new document as an
  entry somebody failed to fold." Two portable pages carrying workarounds for one namespace claim is the
  evidence for inverting that sweep to an allowlist of paths the plugin itself placed — and it is likely
  why `smartwatchbanden` put its tickets in a directory to begin with.
- [x] **The real surface is ten root paths, not three**, failing in four different ways: hard-coded with
  no seam (`CHANGELOG.md`), hard-coded by deliberate decision (`releases/development/`,
  `releases/github/`, `releases/internal/`), repointable but defaulting to the root
  (`Get-ReleaseNoteRoot` → `releases/notes`, `Get-ReleaseHistoryPath` → `releases/README.md`), and
  structurally immovable (`.github/workflows/branch-entry.yml`, `scripts/repo-config.ps1`,
  `scripts/lib/branch-info.ps1`). Plus `scripts/maintenance/baselines/skill-cost.json` and the root
  `*.md` sweep. One rule cannot cover all four, which is why the answer below is three rules.
- [x] **There is no `Get-ChangelogPath` anywhere in the plugin.** The root changelog is hard-coded in
  three places: `cut-release.ps1:585-586` (read, **with no `Test-Path` guard**, written back emptied at
  `:1024`), `fold-changelog-entry.ps1:326` (read, guarded; entry inserted; written back) and
  `session-status.ps1:319` (read to report pending entries).
- [x] **The collision is measured, not hypothetical.** `fold-changelog-entry.ps1`'s own comment records a
  consumer on 2026-08-09, one day after they adopted the entry convention: their `## Pull Requests` and
  `## Releases` section headings sit at the level an entry occupies, so the fold reported "placed above 2
  existing entries" and inserted **outside the section they keep their entries in**. Exit 0, no warning —
  "the only way to see it is to open the file afterwards, which is precisely what nobody does after a
  green fold."
- [x] **And the repair we shipped for it is the thing #885 objects to.** Inbound #561 made the fold refuse
  in a pre-pass, deliberately with **no `-Force`** ("there is no state in which writing into the wrong
  section is what the caller wanted. The cut has no valve for it either"). The refusal tells the consumer
  to migrate their own changelog into the plugin's shape or paste entries by hand. Because the fold runs
  after a merge, a refusal parks an unfolded entry on their trunk. So today the collision is resolved in
  the plugin's favour with a migration bill attached.
- [x] **Nothing can remove `workflow-davekjohn/` today — but only by absence of a mechanism.** Three
  independent reasons: an uninstall writes nothing into the tree (`adopt-workflow-folder.ps1`'s header
  states the mirror image — "an install is a clone into the plugin cache and writes nothing into the
  repo"); `specialists-teardown` ships in `team-alpha` and `UNINSTALL.md` says it "deliberately does not
  reach into the other's cache"; and `workflow-davekjohn` ships no teardown among its seventeen skills.
  Nothing *forbids* one, which is what needs writing down.
- [x] **The one file the plugin does delete inside the folder is `development-cycle.md`**, removed by the
  fold on every merge since August 23. That is working state, not history, and it is deleted only after
  its content moves into the changelog — so it is a precision on the permanence rule, not an exception to
  it. Stated explicitly or a later reader finds a `Remove-Item` in a folder documented as permanent and
  assumes one of the two is a bug.
- [x] **A computed default has a precedent.** `Get-ReleasePluginTier`'s fallback tests whether
  `.claude-plugin/marketplace.json` exists, and `adopt-workflow-folder.ps1` uses that same one-file test
  to refuse in a source repo. So "source keeps its root file, consumer is isolated" can be the
  zero-configuration answer rather than something every consumer must remember to set.

### Decisions taken (Dave, August 25, 2026)

- [x] **The folder gets its own `CHANGELOG.md`.** Every consumer is expected to keep their own, and the
  two must not collide. Folding the changelog in two different ways is preferred over any chance of the
  plugin getting in the way of the consumer's file. **Accepted cost, recorded so nobody later "fixes"
  it:** a change may appear in both files. That duplication is the chosen trade, not an oversight.
- [x] **The folder is permanent.** Uninstalling the plugin never removes `workflow-davekjohn/`, because
  the consumer would otherwise lose history that is theirs. No command in this plugin removes it and no
  future teardown may.
- [x] **Therefore the isolation rule is about provenance, not only location** — the plugin never writes a
  path it did not create. This is the only rule that can protect a root `CHANGELOG.md`, since a changelog
  at the root is a perfectly reasonable place for a consumer to keep one, and it holds even for the paths
  that cannot move.

### The decision that unblocked itself

- [x] **The August 19 objection has expired, and permanence is what expired it.** That decision kept
  `Get-ReleaseHistoryPath` at root because "an index of files in `releases/` does not belong in a folder
  **a teardown removes**". The load-bearing clause is the last one, and the permanence decision makes it
  false. It was a durability worry — the same worry as "anders verliest de consumer belangrijke
  geschiedenis" — reaching the opposite conclusion only because it assumed the folder could disappear.
  With permanence guaranteed the folder becomes the safest place for history rather than the riskiest, so
  this is the newer decision removing the older one's premise rather than overruling it.

### Still open — blocks the CREATE step list

- [ ] **Decide how far the `releases/` roots move in this cycle.** The changelog seam and the permanence
  guarantee are settled. What is not: whether `Get-ReleaseHistoryPath`, the three hard-coded roots
  (`releases/development/`, `releases/github/`, `releases/internal/`) and `Get-ReleaseNoteRoot`'s default
  come along now or in a follow-up cycle. They are the same argument as the changelog and the objection
  against them has expired, but `releases/development/` was given no seam *deliberately*
  (`cut-release.ps1:357`: "a seam nobody can be shown to need is a knob a consumer has to read past. It
  comes back when somebody measures it") — and #885 is that measurement, so reversing it is a decision
  rather than a consequence.

### Scope recommended to CREATE, once the step above is answered

1. `Get-ChangelogPath` with a computed default, plus `adopt-workflow-folder` placing
   `workflow-davekjohn/CHANGELOG.md` with its intro — required, because `cut-release.ps1:586` has no
   `Test-Path` and a consumer's first cut would otherwise throw.
2. The permanence guarantee written into `CLAUDE.md`, the portable pages and `UNINSTALL.md`, including
   the `development-cycle.md` precision.
3. The `releases/` roots, per the open decision above.
4. The provenance preflight, as the backstop rather than the primary defence — and the root `*.md` sweep
   inverted to an allowlist, which retires both portable-page workarounds instead of documenting them
   better.
5. **TICKETWORK's optionality in the scaffolded folder README** (`adopt-workflow-folder.ps1:119`): three
   pages every consumer answers, one they answer only if their work arrives from somebody else's
   tracker. One string, and it belongs to this branch's subject.
6. `.github/` and `scripts/` stay where they are, documented as the two named exceptions — so the rule is
   stated as "never touches anything it did not create, and everything it creates is either inside its
   folder or in a path the consumer named" rather than the unachievable "never touches the root".

**And one explicit non-goal, so nobody builds it:** `projectmanagement/` and any `research/` folder in a
consumer are **not** relocated into `workflow-davekjohn/`. They are the consumer's, and annexing them
would be this branch defeating its own purpose.

## CREATE

- [ ] TODO: the first step of this branch

## TEST

## DEPLOY: `feat/isolate-workflow-from-consumer-root-v1`

**Score:**

### What makes this PR extra special

**Score:**

### Pull Request

Isolate the workflow from the consumer's repo root

