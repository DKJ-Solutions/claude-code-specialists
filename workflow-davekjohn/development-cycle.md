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

### Resolved (Dave, August 25, 2026)

- [x] **The `releases/` roots move in THIS cycle, not a follow-up.** Same argument as the changelog seam,
  and #885 is exactly the measurement `cut-release.ps1:357`'s refusal was waiting for. One cycle instead
  of two. Group E in CREATE is no longer gated.

### Scope recommended to CREATE

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

Ordered: group A's first step gates the rest of A, and group E is gated on the open PLAN decision.
Nothing here is built yet — this is the checklist only (Dave, August 25, 2026).

### A — The changelog seam

- [x] **Settle the seam-reading idiom first, because the changelog needs all four call sites and the
  tree has two idioms.** `Get-SeamValue` is defined **twice** — `cut-release.ps1:280` and
  `new-internal-note.ps1:114` — while `fold-changelog-entry.ps1`, `open-pr.ps1` and
  `session-status.ps1` probe inline with `Get-Command Get-X -ErrorAction SilentlyContinue`. Promote one
  `Get-SeamValue` into a shared lib and have the new seam use it. This is Ravi's call on the
  duplication; doing it first means the changelog work adds one idiom rather than a third. Done: new
  `scripts/lib/seam-lib.ps1`, array-capable version kept; both private copies removed, both callers
  dot-source the shared one; `open-pr.ps1`'s own inline probes are untouched (unrelated seams, out of
  scope).
- [x] **Add `Get-ChangelogPath` with a computed default** — `workflow-davekjohn/CHANGELOG.md` unless
  `.claude-plugin/marketplace.json` exists, the same one-file test `Get-ReleasePluginTier`'s fallback and
  `adopt-workflow-folder.ps1`'s source refusal already use. Zero configuration gives the source its root
  file and every consumer isolation. Done: `Get-DefaultChangelogPath` in `seam-lib.ps1`.
- [x] **Repoint the three hard-coded reads** at the seam: `cut-release.ps1:585`,
  `fold-changelog-entry.ps1:326`, `session-status.ps1:319`. Done, including the fold's own commit-scope
  path list (`$paths = @($changelogRel) + ...`) which was still a `'CHANGELOG.md'` literal one line past
  where the PLAN's own inventory looked.
- [x] **Add the missing `Test-Path` guard at `cut-release.ps1:586`.** Independently a defect: the read
  is unguarded, so a repo with no changelog gets an unhandled throw rather than a refusal that says what
  is wrong. The fold already reads defensively at its line 363; make the cut match. Done — same
  read-defensively-into-`''` pattern as the fold.
- [x] **Register the seam in the contract** — a record in `scripts/lib/script-contract-lib.ps1` with
  `Adopt`/`AdoptWhy`, and the mandatory/optional declaration in `scripts/sync/check-script-contract.ps1`
  if it belongs there. Done: `Adopt = 'copy'`, `check-script-contract.ps1` needed no change — it reads
  `Optional` off the record generically, nothing per-function to add there.
- [x] **Decide whether `scripts/repo-config.ps1` declares this repo's answer explicitly** or leans on
  the computed default. Explicit is the safer read for a source repo, but it duplicates a computation —
  answer it once, in the record's `AdoptWhy`. **Decided: lean on the computed default**, same as
  `Get-ReleaseHistoryPath`'s own precedent — this repo's `repo-config.ps1` declares nothing new.
- [x] **`adopt-workflow-folder.ps1`: place `workflow-davekjohn/CHANGELOG.md` with its intro.** One entry
  on the existing additive target list. Required, not cosmetic — without it a consumer's first cut reads
  a file that is not there. Done, plus a re-adoption migration note (a genuinely pending entry in an
  existing root `CHANGELOG.md` is not picked up by the next fold/cut) that the original checklist item
  did not name but the accepted-cost reasoning implied.
- [x] **Regenerate the derived artefacts**: `scripts/sync/build-config-blueprint.ps1` (the blueprint is
  derived and the lint gate reports any difference) and `scripts/sync/build-shared-scripts.ps1` (check 8
  of the lint gate holds every mirror LF-identical to its root source). Done, repeatedly, as each group
  landed.

### B — The permanence guarantee, written down

- [ ] **State the guarantee**: no command in this plugin removes `workflow-davekjohn/`, and no future
  teardown may. Uninstalling removes the plugin; the released record stays with the repo that released
  it.
- [ ] **Carry the `development-cycle.md` precision with it** wherever the guarantee is stated — the fold
  deletes that file on every merge by design, it is working state rather than history, and it is removed
  only after its content moves into the changelog. Omit this and the next reader finds a `Remove-Item`
  inside a folder documented as permanent.
- [ ] **Place it in the layers that actually reach a consumer**: `UNINSTALL.md`, the portable pages, and
  the folder README that `adopt-workflow-folder.ps1` writes. The root `CLAUDE.md` gets it only insofar as
  the fold exception's bounds change.
- [ ] **Amend the August 19 record** in `script-contract-lib.ps1`'s `Get-ReleaseHistoryPath` entry, which
  still argues from "a folder a teardown removes". Say why that premise no longer holds rather than
  silently flipping the value — whatever group E decides.

### C — TICKETWORK's optionality

- [ ] **`adopt-workflow-folder.ps1:119`**: three portable pages every consumer answers
  (`CONTRIBUTING`, `DEVELOPMENT-CYCLE`, `RELEASES`) and one that applies only where work arrives from
  somebody else's tracker. One string; it currently writes all four into every consumer's folder README
  as equals.
- [ ] **Check the plugin's own `README.md:47`** against the same distinction. Its table already
  describes TICKETWORK's scope per row, so this may need nothing — verify rather than assume, and record
  which it was.

### D — Provenance: the rule that makes the rest hold

- [ ] **Invert the root `*.md` sweep to an allowlist of paths the plugin itself placed.** Today every
  unrecognised root markdown file is read as an unfolded entry and refuses the release, with
  `Get-ReservedRootMd` as the escape hatch — a list whose own contract record admits it "has gone stale
  three times in the source alone".
- [ ] **Retire the two portable-page workarounds that exist only because of that sweep** —
  `TICKETWORK-portable.md`'s closing note and `CONTRIBUTING-portable.md:317`. They instruct consumers to
  dodge the plugin; once the sweep is an allowlist there is nothing to dodge, and leaving them in place
  would document a hazard that no longer exists.
- [ ] **The preflight itself**: refuse to write any path the plugin cannot show it created. Scope it
  deliberately — this is the largest item on the branch, and it is the backstop for the paths that
  cannot move (`.github/`, `scripts/`) rather than a replacement for groups A and E.

### E — The `releases/` roots · unblocked, Dave chose "now" over "follow-up cycle"

- [x] **`Get-ReleaseHistoryPath`** into the folder, with the August 19 record amended per group B.
  Done: `Get-DefaultReleaseHistoryPath` in `seam-lib.ps1` — `releases/README.md` for the source,
  `workflow-davekjohn/releases/history.md` for a consumer. **`history.md`, not `README.md`**: a real
  naming collision found while building this — `workflow-davekjohn/releases/README.md` already names
  this folder's hand-written seam-ANSWERS page (`adopt-workflow-folder.ps1`'s own scaffold target), so
  the list needed a filename of its own once both moved into the same directory. Same accepted-cost
  duplication as the changelog: an existing consumer's history splits at the point this default starts
  applying to them (old rows at their root file, new rows here) rather than moving under them silently a
  second time; repointing the seam back keeps one list for a consumer who would rather have that.
- [x] **Seams for the three hard-coded roots** — `releases/development/`, `releases/github/`,
  `releases/internal/`. Note that `releases/development/` was refused a seam *deliberately*
  (`cut-release.ps1:357`), so this step carries the reversal's reasoning, not just the code. Done:
  `Get-ReleaseDevelopmentNotesRoot`, `Get-ReleaseGithubNotesRoot`, `Get-ReleaseInternalNotesRoot`, each
  with a computed default in `seam-lib.ps1`. **Unlike the history path and the changelog, these three
  carried NO seam at all before this branch** — every existing consumer's notes already sit at the exact
  root literal the computed default still returns for the source, so there was no prior meaning to
  redefine and no accepted-cost duplication to name here.
- [~] **`Get-ReleaseNoteRoot`'s default repointed from `releases/notes` into the folder** — **dropped,
  found while building this, not in the original PLAN.** This seam's own contract record already argues
  against exactly this move, for a reason `#885`'s "expired objection" does not touch: *"the DEFAULT
  deliberately stays `releases/notes`... a repo that answers nothing must keep meaning what it meant
  yesterday."* Unlike the three roots above, `Get-ReleaseNoteRoot` already has real consumers configuring
  it or relying on its literal fallback — a computed default would silently redirect an EXISTING
  consumer's hand-written notes out from under them, which is the exact harm `#885` exists to prevent, not
  a case of it. `adopt-workflow-folder.ps1`'s existing explicit next-steps instruction (`Get-ReleaseNoteRoot
  -> 'workflow-davekjohn/releases/audience'`) remains the correct, opt-in way a *new* adoption isolates
  this one — unchanged by this branch.

### Non-goals, recorded so nobody builds them

- `projectmanagement/` and any `research/` folder in a consumer are **never** relocated into
  `workflow-davekjohn/`. They are the consumer's own, and annexing them would defeat the branch.
- `.github/workflows/branch-entry.yml`, `scripts/repo-config.ps1` and `scripts/lib/branch-info.ps1` stay
  where they are, documented as the two named exceptions.

## TEST

Deliberately not written yet — the checklist above is CREATE only (Dave, August 25, 2026). Each group
above has suites that already exist and will need extending: `fold-changelog.tests.ps1`,
`cut-release-guardrail.tests.ps1`, `cut-release-drive.tests.ps1`, `session-status.tests.ps1`,
`adopt-workflow-folder.tests.ps1`, `script-contract.tests.ps1`, `repo-config.tests.ps1`,
`config-blueprint.tests.ps1` and `shared-scripts.tests.ps1`.

## DEPLOY: `feat/isolate-workflow-from-consumer-root-v1`

**Score:**

### What makes this PR extra special

**Score:**

### Pull Request

Isolate the workflow from the consumer's repo root

