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
  reach into the other's cache"; and `workflow-davekjohn` ships no teardown among its sixteen skills.
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

- [x] **State the guarantee**: no command in this plugin removes `workflow-davekjohn/`, and no future
  teardown may. Uninstalling removes the plugin; the released record stays with the repo that released
  it. Done: a bullet in `adopt-workflow-folder.ps1`'s scaffolded `$folderClaude` and `$folderReadme`
  arrays (so every new consumer reads it on day one) and in the `adopt-workflow-folder` skill's own
  "rules it works under" list.
- [x] **Carry the `development-cycle.md` precision with it** wherever the guarantee is stated — the fold
  deletes that file on every merge by design, it is working state rather than history, and it is removed
  only after its content moves into the changelog. Omit this and the next reader finds a `Remove-Item`
  inside a folder documented as permanent. Done, in the same three places as above.
- [x] **Place it in the layers that actually reach a consumer**: `UNINSTALL.md`, the portable pages, and
  the folder README that `adopt-workflow-folder.ps1` writes. The root `CLAUDE.md` gets it only insofar as
  the fold exception's bounds change. Done: a new bullet in `UNINSTALL.md`'s "What is left behind,
  honestly" list, bounded to `workflow-davekjohn`'s own uninstall step; the skill carries the portable
  half. The root `workflow-davekjohn/CLAUDE.md` fold-exception bounds are unchanged by this branch (still
  `CHANGELOG.md` + `development-cycle.md` inside the folder) — verified rather than skipped, no edit
  needed.
- [x] **Amend the August 19 record** in `script-contract-lib.ps1`'s `Get-ReleaseHistoryPath` entry, which
  still argues from "a folder a teardown removes". Say why that premise no longer holds rather than
  silently flipping the value — whatever group E decides. **Already done, inside `fa322cb0`** (group E's
  own commit) — the record reads "REVERSED AGAIN, ISSUE #885 ... the durability worry that sent the list
  back to the root is answered a different way". Found while re-reading it for this step: the
  `adopt-workflow-folder` SKILL.md had **not** been updated to match — it still told a reader to "leave
  [`Get-ReleaseHistoryPath`] at its default, `releases/README.md`" and argued from the exact premise the
  contract record had already reversed. Not on this list originally, but the same file and the same
  defect class this step exists to close — repaired alongside it rather than filed separately.

### C — TICKETWORK's optionality

- [x] **`adopt-workflow-folder.ps1:119`**: three portable pages every consumer answers
  (`CONTRIBUTING`, `DEVELOPMENT-CYCLE`, `RELEASES`) and one that applies only where work arrives from
  somebody else's tracker. One string; it currently writes all four into every consumer's folder README
  as equals. **Already resolved, as a side effect of group A's rewrite of the same paragraph** (commit
  `fa322cb0`, blamed): the changelog-seam edit touched this exact prose block and, while rewriting it to
  add `CHANGELOG.md`, split the four into "three are unconditional ... a fourth, `TICKETWORK-portable.md`,
  applies only where work arrives from somebody else's tracker; skip it if yours does not." No further
  edit needed — verified against the current file rather than assumed from the PLAN's snapshot.
- [x] **Check the plugin's own `README.md:47`** against the same distinction. Its table already
  describes TICKETWORK's scope per row, so this may need nothing — verify rather than assume, and record
  which it was. **Verified: needs nothing.** Row already reads "the rules for the layer *before* a
  branch, in a repo whose work arrives from somebody else's tracker" — distinct from the other three
  rows, unchanged by this branch.

### D — Provenance: the rule that makes the rest hold

**Scoped with Dave first (August 25, 2026)**, per his "durable over easy" instruction: not a runtime
provenance log (rejected — it cannot even answer the question for a consumer's OWN permanent docs, which
the plugin never created either way, and it adds state that itself can drift), but two content/seam-based
mechanisms that need no consumer maintenance to stay correct.

- [x] **Invert the root `*.md` sweep to an allowlist of paths the plugin itself placed.** Done, but as a
  CONTENT test rather than a name allowlist: `cut-release.ps1`'s `$strayEntries` check now calls
  `Test-BranchChangelogIsFilled` (the same pure predicate the branch's own live document is held to) on
  every root `*.md` not on `$reservedRootMd`, instead of treating "not listed" as the danger signal.
  `Get-ReservedRootMd` survives as an optional manual override, no longer load-bearing — its contract
  record in `script-contract-lib.ps1` is amended accordingly. New/updated tests in
  `cut-release-guardrail.tests.ps1`: the wiring (calls the predicate, still consults the override list
  first), a run of the real predicate against every one of THIS repo's own tracked root docs (zero false
  positives — `CHANGELOG.md` is the worked case for why the override step can't be skipped, since its own
  content, read outside that filter, genuinely fails the check), and the positive case (a legacy
  pre-split root entry still reads as stray). All green (73 asserts).
- [x] **Retire the two portable-page workarounds that exist only because of that sweep** —
  `TICKETWORK-portable.md`'s closing note and `CONTRIBUTING-portable.md:317`. Done: both removed outright
  (no dangling links; checked). The hazard they warned about (a consumer's own root doc misread as an
  entry) no longer exists once the sweep reads content instead of a name list.
- [x] **The preflight itself**: refuse to write any path the plugin cannot show it created. Scope it
  deliberately — this is the largest item on the branch, and it is the backstop for the paths that
  cannot move (`.github/`, `scripts/`) rather than a replacement for groups A and E. **Built narrower
  than the literal wording, deliberately**: `Assert-WorkflowIsolatedSeamPath` (new, `seam-lib.ps1`) is the
  backstop specifically for the FOUR seams groups A/E made isolate-by-default
  (`Get-ChangelogPath`, `Get-ReleaseHistoryPath`, `Get-ReleaseDevelopmentNotesRoot`,
  `Get-ReleaseGithubNotesRoot`, plus the internal-note root read the same way) — refuses before any
  read/write if a CONSUMER's own explicit seam override resolves outside `workflow-davekjohn/` (a source
  repo is always exempt, matching every other source/consumer test in this codebase). Wired right after
  each of those five seam reads, in `cut-release.ps1`, `fold-changelog-entry.ps1` and
  `new-internal-note.ps1`. **Deliberately does NOT touch `Get-ReleaseNoteRoot`** — that seam's own
  contract record argues its root default must stay put for real existing consumers, and forcing it
  through this assert would refuse the one seam whose whole point is not moving. `.github/` and
  `scripts/` themselves needed no new guard: the one write there (`branch-entry.yml`) is already
  `Test-Path`-guarded additive-only in `adopt-workflow-folder.ps1`, and nothing in this workflow writes
  under `scripts/`.
  **Resolved, on resuming after the parked session.** `scripts/tests/seam-lib.tests.ps1` is new: a
  dedicated, dependency-free fixture for `Assert-WorkflowIsolatedSeamPath` (8 asserts) — the passing
  cases (in-folder, the exact-match `workflow-davekjohn`, the backslash-normalized path, and a source
  repo exempt outright even for the identical outside-the-folder path that gets refused for a consumer)
  exercised in-process by dot-sourcing `seam-lib.ps1` directly, since the function returns normally
  there; the refusal case exercised via a child process (same pattern as `internal-note.tests.ps1`'s
  `Invoke-Script`) because that path calls `exit 1` and would abort an in-process runner. Deliberately
  does not cover the `Get-Default*` computed defaults in the same file — those are already exercised for
  real by the other group-D suites. The mirrors are regenerated
  (`build-shared-scripts.ps1`, `build-config-blueprint.ps1`) and every suite this branch touches is now
  green: `cut-release-guardrail` (73), `fold-changelog` (132), `internal-note` (90), `config-blueprint`
  (91), `script-contract` (282), `shared-scripts` (443), `repo-config` (44), `seam-lib` (8, new),
  `session-status` (61), `cut-release-drive` (45), `adopt-workflow-folder` (22, rerun after group D's
  edits to `cut-release.ps1` rather than trusted from its earlier pre-group-D pass).

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

The suites CREATE's groups extended (or, for `seam-lib.tests.ps1`, added) are all green:
`fold-changelog.tests.ps1` (132), `cut-release-guardrail.tests.ps1` (73),
`cut-release-drive.tests.ps1` (45), `session-status.tests.ps1` (61),
`adopt-workflow-folder.tests.ps1` (22), `script-contract.tests.ps1` (282),
`repo-config.tests.ps1` (44), `config-blueprint.tests.ps1` (91), `shared-scripts.tests.ps1` (443),
`internal-note.tests.ps1` (90), and the new `seam-lib.tests.ps1` (8, group D's dedicated fixture for
`Assert-WorkflowIsolatedSeamPath`). 1,291 asserts total, none failing.

## DEPLOY: `feat/isolate-workflow-from-consumer-root-v1`

Nothing changes for this repo's own release runs today — the computed defaults exempt the source repo
outright, so `CHANGELOG.md` and `releases/` keep resolving to the exact root paths they always did. What
a developer here meets is the plumbing underneath: the two duplicate `Get-SeamValue` copies collapse into
one shared `seam-lib.ps1`, which also carries the four isolate-by-default seams and the new
`Assert-WorkflowIsolatedSeamPath` provenance preflight, backed by its own dedicated suite
(`seam-lib.tests.ps1`, 8 asserts) among the eleven suites this branch touched. Noticed the next time
somebody works in a release script, not before.

**Score:** 2

### What makes this PR extra special

A consumer no longer risks the plugin reaching into their repo root: the changelog, the three release-note
roots (`releases/development/`, `releases/github/`, `releases/internal/`) and the release-history index
all default inside `workflow-davekjohn/` now, and the provenance preflight refuses outright if a
consumer's own explicit override still resolves outside that folder. This closes a hazard that was
measured rather than theoretical — the root `*.md` sweep could misread a consumer's own permanent doc as a
stray, unfolded changelog entry, and two portable pages (`TICKETWORK-portable.md`,
`CONTRIBUTING-portable.md`) carried hand-written workarounds telling consumers how to dodge it; both are
gone now because the sweep itself no longer needs them — it reads content, not a name list. An
already-adopted consumer does have to notice this on their next fold or cut: entries land in
`workflow-davekjohn/CHANGELOG.md` rather than their root file from here on, and a pending entry already
sitting in their old root `CHANGELOG.md` is not picked up automatically — the re-adoption migration note
this branch added documents exactly that. The same split reaches `releases/README.md`: an already-adopted
consumer's release history moves to `workflow-davekjohn/releases/history.md` from here on (named
`history.md`, not `README.md`, because that folder already uses `README.md` for its own hand-written
seam-answers page) — old rows stay at the root file, new rows land in the folder, the same accepted-cost
duplication as the changelog rather than a silent redirect.

**Score:** 5

### Pull Request

Isolate the workflow from the consumer's repo root

