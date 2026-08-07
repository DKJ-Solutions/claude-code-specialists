---
name: cut-release
description: >-
  Checklist for the closing steps of cutting a release: the git tag + push, the internal summary and
  the highlights edit, then a GitHub Release (body = the highest tier the repo has, every other tier
  as an attachment -- gh's release-notes body has a hard 125,000-character limit), plus branch cleanup.
  Where the repo has a separate "go live" stage (Get-LiveStage in scripts/repo-config.ps1), also the
  push to that live target and moving the "<- LIVE" marker. Prints ready-to-paste command blocks in
  a fixed order -- a checklist that imposes itself, not automation: no script is run or mirrored.
  Use this once a release has been cut (version bumped, committed) and its closing git/gh steps need
  to be walked through without skipping one. Inbound issue #177.
disable-model-invocation: true
---

# cut-release — the closing-steps checklist for a release

Inbound [issue #177](https://github.com/DaveKJohn/claude-code-specialists/issues/177) (source:
`DaveKJohn/djcylow-react`) asked for `cut-release.ps1` as a shared skill, on the assumption that a
shareable version of it exists. It does not: this workshop's own
`scripts/release/cut-release.ps1` is 284 lines of marketplace-specific machinery (it reads
`.claude-plugin/marketplace.json` as the source of truth for what a plugin is, bumps every
`plugin.json` in lockstep, writes per-plugin `CHANGELOG.md` sections and `RELEASE.md` cards) and
dot-sources `scripts/lib/release-lib.ps1`, which is deliberately not mirrored into the plugin
(workshop-specific tooling). Mirroring it as-is would have handed a fresh consumer a script that
stops on its very first line (`.claude-plugin/marketplace.json is missing`).

**This skill is not that mirror.** It is the recommendation that came out of that finding: codify the
*procedure* — the closing steps every release shares, regardless of what cut the version bump itself
— as a checklist, rather than generalizing the workshop's own release script. Matches the issue's own
words: *"not automation, but a checklist that imposes itself."*

## What the skill does

**Two scripts ARE mirrored now** (this line said the opposite until August 3, 2026): `cut-release.ps1`
does the cut itself, and `new-internal-note.ps1` lays down the internal summary's skeleton. What this
page adds is the part no script performs — the GitHub Release, the live push, the branch cleanup, and
the order. Once a release has been cut, walk through the two blocks below **in order** and print/paste
each command as you go — do not skip a step or reorder them from memory.

### Block 1 — cutting (always)

1. **Cut the release.** On a clean main branch:

   ```powershell
   powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/cut-release.ps1" -Bump <major|minor|patch> -Title "<one sentence>"
   ```

   **Run it from the plugin, not from a repo path.** This page used to print
   `./scripts/release/cut-release.ps1`, which is a real file in the repo the script is *maintained* in
   and nothing at all in the repo you are cutting a release for — a consumer runs the mirrored copy and
   keeps none of its own. So the first command of the checklist failed for exactly the reader this page
   is written for. The `${CLAUDE_PLUGIN_ROOT}` form is what the other shared skills already use, and it
   resolves **only inside a plugin-owned component**: typing this by hand in a terminal means spelling
   out the absolute path to the plugin cache instead. In the source repo itself, `./scripts/release/…`
   remains the same file and works as before.

   Give it **either** `-Bump` **or** `-Version <X.Y.Z>` when you want to name the number yourself.
   `-SummaryFile` turns it into a milestone (see below). Four escape valves:

   - **`-NoPush` — inspect before publishing, and use it when anything is unusual.** The script otherwise
     commits, tags **and pushes** in one motion. With `-NoPush` it stops after the commit and tag and
     prints the two push commands for you, which is the moment to read the generated notes. That is not
     optional caution: an entry body's stray `##` is read as a change of its own, and this is the only step
     where a human sees the assembled artifact before it is public.
   - **`-SkipLint`** skips the integrity gate that otherwise runs first. It exists for a genuinely broken
     gate, not for a hurry — the gate is what stops a release refusing to cut halfway through.
   - **`-SkipTierGate`** cuts a bump the pending changelog entries have not earned. **Expect not to need
     it.** Where the pending entries declare their impact, **the bump follows the highest tier pending**:

     | highest tier pending | bump | documents written |
     |---|---|---|
     | `0` | patch | the development notes |
     | `1` | minor | + the internal note |
     | `2` | minor | + the highlights, for consumers |

     A major additionally needs enough minors behind the line. So a refusal usually means the bump is
     wrong, not the gate — the script names the bump the work *does* earn; take that instead.

     **The documents follow the TIER, not the bump**, which is why a tier-1-only minor writes no
     highlights: the version moves for everyone, but nobody outside is handed a document about work they
     cannot see. Deliberately a separate flag from `-SkipLint`, because it overrules a judgement about
     **content** rather than skipping a tool.
   - **`-SkipSignificanceGate`** cuts even though a pending entry that reaches tier 1 or higher has not said
     **how much it weighs** there. Every tier an entry reaches is a document with its own reader, so every
     one owes a `#### Tier N` sub-section under the entry's `### Significance` — a reason it matters at
     that reach, plus a significance from 1 to 5 against the rubric:

     ```text
     #### Tier 1

     The routine version bump stops needing a developer.

     **Score:** 4

     #### Tier 2

     Consumers must re-add the marketplace under its new name.

     **Score:** 5
     ```

     That score is what orders the release documents, so an unscored entry cannot be placed. The gate
     **refuses** rather than quietly sorting it last, because demoting a forgotten line is worst in the one
     document whose subject is which change matters most. The fix is an edit in `CHANGELOG.md`, and the
     refusal names every entry and every missing cell. Separate from both flags above: `-SkipLint` skips a
     tool, `-SkipTierGate` overrules whether the release should exist, and this overrules how its contents
     are **ordered**.

   **A refusal here has cost nothing.** All the guardrails run before the first file is written, so a
   rejected cut leaves the tree exactly as it was — no notes file, no version bump, no half-cut release to
   unpick on main.

   **So there is normally no tag command to type.** If you did use `-NoPush`, finish with what the script
   printed:

   ```powershell
   git push origin main; git push origin vX.Y.Z
   ```

2. **The internal summary — at EVERY release, patch included.** `cut-release.ps1` has printed this
   invocation at the end of its run, with the path already resolved for wherever it found the script —
   paste that rather than retyping it:

   ```powershell
   powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/new-internal-note.ps1" -Version X.Y.Z
   ```

   `-Force` overwrites an existing note — needed rarely and deliberately, since this is the one tier that
   cannot be regenerated from anything. `-RepoRoot <path>` points it at another checkout, the same override
   the fold script carries, for a run from a temporary or detached worktree.

   It writes a **skeleton** to `releases/internal/<dir>/<X.Y.Z>.md`: the metadata copied from the
   development notes, the entry titles as bullets, and three fixed headings. **The middle one is the
   tier** — "what it is worth" cannot be generated from a changelog. Think in time, risk and reduced
   dependence on a developer.

   **The third heading is past tense on purpose** — *"What was still open at this release"*. Where this
   note is the Release body (step 5), it is published output and does not move with reality, so a
   present-tense line in it goes stale in hours rather than months. Write that section as a snapshot of
   the release, and expect to re-read the *previous* note whenever something it called open closes. The
   development notes and the highlights need no such pass: they are written once and left alone.

   **This is the tier that covers a patch, and that is why it exists.** Highlights answers *what a
   consumer notices*; this answers *what the organisation gets out of it*. A release with nothing for a
   consumer — correctly a patch, so no highlights — can still be the one where a routine change stopped
   needing a developer. It refuses to overwrite an existing note without `-Force`: this is the one
   document of the three that cannot be regenerated from anything.

3. **Edit the highlights draft — where the repo generates one.** Where the repo sets
   `Get-ReleaseHighlightsBumps` in `scripts\repo-config.ps1` and this bump is one of them,
   `cut-release.ps1` has already written `releases/highlights/<dir>/<X.Y.Z>.md` — markdown only. It is the
   release's **tier-2 entries**: the ones whose author declared that a consumer notices them.

   **Nothing to delete, and that is the change.** This document used to carry a developer-only block under
   a "remove before publishing" marker, because the generator had to guess from branch types which entries
   a consumer cares about — a guess that fails in both directions (in a storefront repo a `Style` branch
   *is* customer-visible; in a tooling repo a `chore/` branch can carry the most consequential change
   there is). The tier asks the entry's author instead, so the selection arrives already made. Retired
   August 5, 2026, along with the two seam knobs that configured it.

   **It is still a draft, for the reason that never depended on the marker:** the prose is the entry
   bodies, written for whoever reviews the diff.

   **Budget for a rewrite rather than a trim.** This document renders the release a *second time*, it does
   not translate it. Turning entries written for someone reviewing a diff into a document for someone
   deciding whether to update is an authoring job. Measured at this repo's v3.2.0, while the draft still
   held every category: 1,098 draft lines became 153, and the heaviest item for a consumer sat at line
   1,034, below the marker, because it arrived on a `chore/` branch. The tier selection removes the second
   half of that problem; the rewrite is still yours.

4. **Ship the hand-written documents via a branch + PR.** The internal note and the edited highlights
   draft are both written after the cut, and `cut-release.ps1` has already committed and tagged by
   then — so neither can ride along on the release commit, and neither is one of the two named
   direct-on-`main` exceptions. Use the normal `new-branch` → `ship-pr` route.

5. **Publish the GitHub Release — after step 4, never before it.** The body is one of the documents
   step 4 just merged, so publishing earlier means publishing a body that does not exist yet. Which bumps
   get a Release is **repo policy** — see the release manager's repo lens; some repos publish at every
   release, others at Minor/Major only.

   **Do not stop to ask permission here.** Cutting the release is what was asked for, and this is the last
   step of that same procedure — a second approval at the end of a checklist the requester started is a
   rubber stamp (Dave, August 5, 2026). Steps 1 to 5 therefore run in one motion. The approval that
   remains is **Block 2 below**, where a repo has a live stage: publishing a document that describes a
   version and pushing to a target customers see are different acts.

   ```powershell
   gh release create vX.Y.Z --title "vX.Y.Z - <short title>" --notes-file <body-file>
   # copy each attachment to a UNIQUE filename first -- see the collision note below
   gh release upload vX.Y.Z <vX.Y.Z-development-notes.md> [<vX.Y.Z-notes-for-users.md>]
   ```

   **Two attachments cannot share a filename, and all three tiers name their file `<X.Y.Z>.md`** — so
   uploading two of them straight from `releases/` fails. Measured at this repo's `v3.3.0`: the first
   upload succeeded and the second returned `HTTP 404` on
   `assets?label=…&name=3.3.0.md`. The asset name is the **basename**, and `gh`'s `file#label` syntax does
   not help — it sets the *label* and leaves `name` as the basename, which is why the request above still
   carried the colliding name. **Copy each attachment to a distinct filename and upload the copies**
   (`vX.Y.Z-development-notes.md`, `vX.Y.Z-notes-for-users.md`). That is worth doing on its own merits: a
   reader downloading `3.3.0.md` cannot tell which of the three tiers they got.

   **The body is the highest tier the repo actually has, and every other tier goes along as an
   attachment.** Take them in this order:

   | the repo has | body | attachments |
   |---|---|---|
   | an internal note | `releases/internal/<dir>/<X.Y.Z>.md` | the development notes + the highlights, where one exists |
   | highlights but no internal note | the edited `releases/highlights/<dir>/<X.Y.Z>.md` | the development notes |
   | neither | the development notes | — |

   **Never inline the development notes**, whichever row applies: `gh release create`'s notes body has a
   hard limit of **125,000 characters**. At life-hub's v2.1.0 the development notes were **134,419
   characters** and the "paste everything into the body" approach returned an HTTP 422 from `gh`. The
   body/attachment split is what keeps the command from failing on anything but the smallest release.

   **Why the internal note outranks the highlights as the body, where both exist.** It is the only tier
   written at *every* release, so the page reads the same way whether the release was a patch or a major —
   and it answers what the work is worth, which is what a Release page is read as. The cost is real and
   worth naming: the internal tier deliberately carries no file names, no commands and no code, so on a
   release that requires the reader to *act*, the instruction lives in the attached highlights rather than
   on the page. Say so in the body when that applies, rather than leaving the reader to find it.

6. **Name the cache refresh in the closing report — pushing the tag is not the end of a release.** A
   `github` marketplace source is a **cached clone**, and `plugin install` compares against *that*, not
   against the repo you just tagged. So the safe closing line for a consumer is one idempotent command
   before they update:

   ```powershell
   claude plugin marketplace update <marketplace>
   ```

   **State it as two measurements rather than one rule, because the obvious generalisation was tested and
   broke.** They are not the same for `install` and `update`:

   | command | refreshes the cached clone? | how it was measured |
   |---|---|---|
   | `plugin install` | **no** | a controlled pair, same machine, same minute, two fresh folders: without the refresh the install produced the **previous** release and left the clone where it was; with it, the new one. Confirmed on two separate releases. |
   | `plugin update` | **yes** | with the clone verifiably still on the pre-release commit and not even containing the new version, a bare update moved to the new version **and advanced the clone during the run**. |

   So the earlier, tidier claim — "skip the refresh and you get the previous version" — holds for
   `install` and is **false** for `update`. Report the refresh as the *safe first step*, not as a
   mechanism claim about what breaks without it.

   **Why it has to be said out loud at all: a stale cache is invisible by construction.** It reports
   success with a plausible version number, and an install's success line names the scope and **no
   version at all** — so a consumer cannot detect staleness from the output even in principle, only from
   the install record. This is the one thing a release cannot do for its consumers, which is exactly why
   the closing report must name it.

   **A practical note for whoever cuts the next release:** the stale window a release opens lasts only
   until something refreshes it. If a question about cache behaviour is open, the minutes after the tag is
   pushed are when it can be answered; an hour later the cache has moved on and the answer waits for the
   next release.

7. **Branch cleanup** — the same fixed closing move as the `fold-changelog` skill's:

   ```powershell
   git fetch --prune
   git branch -d <merged-branch-name>
   ```

### Block 2 — going live (only where this repo has a live stage)

This block is driven by `Get-LiveStage` in the consumer's `scripts\repo-config.ps1` — **optional**,
**empty by default**. Most repos (this workshop, life-hub) cut a release without a separate live
stage, so `Get-LiveStage` returns `''` and Block 2 does not apply — stop after Block 1.

A repo that *does* have one (e.g. a repo that pushes a live deploy target as a step distinct from
tagging) fills in `Get-LiveStage` with a short description of that target. Where it is filled in:

1. **Push to the live target** described by `Get-LiveStage`.
2. **Mark which recorded version is the one actually live**, wherever this repo records that, so its
   releases overview shows it at a glance. `cut-release.ps1` briefly did this itself, via a
   `Get-ReleaseLiveMarker` seam that moved a marker from the previous release heading onto the new one; that
   seam **retired on August 5, 2026** together with the `CHANGELOG.md` release block it wrote into — a cut
   now empties the changelog and writes no release heading for a marker to sit on. So this is a hand step
   again, which is where it started: the marker is the one release artefact whose correctness a script cannot
   confirm, because only the person who did the push knows it succeeded.

## A milestone release — `-SummaryFile`

An ordinary release's notes are the diff since the last one: `-Title` gives it one sentence and the
entries carry the detail. A **milestone** is a different claim — the arc across many releases, which fits
in neither. `-SummaryFile <path>` puts an authored markdown block between the title line and the
generated entries, closed off with a horizontal rule so a reader can see where the authored part stops
and the per-PR record begins. Three things to know:

- **The file may live outside the repo, and normally should.** Its canonical home becomes the generated
  notes file; a second copy kept under `releases/` purely to feed the parameter is duplication.
- **A missing or empty file is a hard stop.** An empty one would otherwise produce an ordinary release
  while you believe you cut a milestone.
- **Links in the summary are left exactly as authored.** Unlike an entry — written in the root changelog
  and then moved several folders deeper, so its relative links are rewritten — a summary is written *for*
  the notes file. Rewriting its links would break the ones that were already right.

**And say plainly whether anything breaks.** A `major` bump reads as "breaking" to anyone applying semver
mechanically, and a milestone may well break nothing — a large change can be backward compatible by
construction. If nothing breaks, the summary's opening lines have to say so, or a consumer sits on an old
version waiting for a migration that does not exist.

## Requirements in the consumer

- `scripts\repo-config.ps1` with, optionally, `Get-LiveStage` — same shape as the existing `Get-LintScript`
  getter. Absent or empty: only Block 1 applies. Declared in
  `check-script-contract.ps1` as an **Optional** record (the mechanism introduced for
  `Get-ChangelogHeading`, issue #178): a consumer without the function gets `[INFO]` naming the
  fallback (`''`, i.e. no live stage), never `[ERROR]`.
- The script's own getters are separate from this skill's and all optional in the same way:
  `Get-ReservedRootMd`, `Get-ReleaseNotesGrouping`, `Get-ReleaseHistoryPath`, `Get-ReleasePluginTier`,
  `Get-ReleaseHighlightsBumps` and `Get-ReleaseMajorMinMinors`. Define none of them and the cut behaves
  exactly as it does in the source repo. Run `check-script-contract.ps1` to see which ones this repo answers
  and which fall back.
- **Six seams retired on August 5, 2026, and a consumer that still defines one is unaffected** — nothing
  calls them, so they are simply dead code in that repo's config. `Get-ChangelogTierHeadings` and the legacy
  `Get-ChangelogHeading` (#178) configured changelog section headings, and the document has none;
  `Get-ReleaseCategoryTitles` labelled the release-notes categories, and the grouping is gone;
  `Get-ReleaseLiveMarker`, `Get-ReleaseHistoryMode` and `Get-ChangelogReleaseWording` (#462) all described
  the release **block** a cut used to append to `CHANGELOG.md`, and a cut writes none. The capability behind
  that last one is not being taken away from the non-English repo that asked for it: what replaced the
  generated block is the changelog intro's own one-line pointer to the release history — hand-written prose
  in a file the repo owns outright, so it needs no seam to be in their language.
- **`Get-LintScript` is the one that is NOT optional, and the cut now reads it.** The release route does not
  travel via a PR, so this is the only gate it meets; before August 5, 2026 the cut looked for the *source*
  repo's lint script by a fixed path and skipped the gate with a warning wherever it did not find one
  (inbound #464). A named gate that is not on disk is now a hard stop — use `-SkipLint` to cut without one,
  so the choice is in the command.
- **What switches the bump gate on is the entries, not a setting.** `cut-release.ps1` starts requiring the
  bump to be earned (see `-SkipTierGate` in step 1) as soon as **any** pending entry has declared its impact
  — an impact table, or the older `Tier: N` line. A repo whose entries declare nothing has no tier
  information to judge, so the gate reports itself inactive and the cut behaves exactly as it always did.
  That test used to be "does this repo declare more than one changelog section", which stopped working the
  day the sections went: a flat document gives an adopting repo and an unadopted one one group each, so the
  old test would have read every repo as unadopted and switched the gate off in silence. Counting
  declarations keeps *"declared tier 0"* distinct from *"declared nothing"*, which is the whole difference
  between a release that announces nothing on purpose — a patch — and a repo that never chose the model.
- `git` and a logged-in `gh` CLI for the GitHub Release step. **Which bumps get a Release is repo
  policy, not part of this checklist** — it is stated in the release manager's repo lens, because a repo
  that publishes at every release and one that publishes at Minor/Major only are both coherent, and the
  choice follows from who reads the page rather than from the mechanics.

## Important

- **The script IS mirrored now** (issue #417, August 3, 2026). This page used to say the opposite —
  "no script mirrored, deliberately", because the lockstep `plugin.json` bump is meaningless in a
  consumer. That turned out not to require a fork, only a seam function: a repo with no marketplace
  manifest skips that half. So `cut-release.ps1` travels with the plugin like the rest of the workflow,
  and what differs per repo is read from optional getters in the consumer's `scripts\repo-config.ps1`.
  This page remains the *procedure* around the script — the parts no script performs: the GitHub
  Release, the live push, the branch cleanup.
- **Order matters.** Block 1 always runs first; Block 2 only follows it, and only where
  `Get-LiveStage` says there is one to run.
- **And inside Block 1 the GitHub Release moved to last, which is a correction rather than a
  preference** (August 4, 2026). It used to be step 2, directly after the tag, because its body was the
  highlights file that `cut-release.ps1` had already generated. Once the body is the internal note — a
  document step 2 only *starts* and step 4 merges — publishing from step 2 would publish a body that does
  not exist yet. A checklist meant to impose itself has to be walked in an order that is possible.
- **A release itself is cut only at explicit request** (a version bump is never automatic) — that
  governance rule is unchanged and sits upstream of this skill, not inside it.
