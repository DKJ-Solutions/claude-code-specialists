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

1. **Tag the release commit and push the tag:**

   ```powershell
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

2. **The internal summary — at EVERY release, patch included.** Where the repo carries
   `scripts/release/new-internal-note.ps1`, `cut-release.ps1` has printed this invocation at the end of
   its run:

   ```powershell
   ./scripts/release/new-internal-note.ps1 -Version X.Y.Z
   ```

   It writes a **skeleton** to `releases/internal/<dir>/<X.Y.Z>.md`: the metadata copied from the
   development notes, the entry titles as bullets, and three fixed headings. **The middle one is the
   tier** — "what it is worth" cannot be generated from a changelog. Think in time, risk and reduced
   dependence on a developer.

   **This is the tier that covers a patch, and that is why it exists.** Highlights answers *what a
   consumer notices*; this answers *what the organisation gets out of it*. A release with nothing for a
   consumer — correctly a patch, so no highlights — can still be the one where a routine change stopped
   needing a developer. It refuses to overwrite an existing note without `-Force`: this is the one
   document of the three that cannot be regenerated from anything.

3. **Edit the highlights draft — where the repo generates one.** Where the repo sets
   `Get-ReleaseHighlightsBumps` in `scripts\repo-config.ps1` and this bump is one of them,
   `cut-release.ps1` has already written `releases/highlights/<dir>/<X.Y.Z>.md` — markdown only. It is a
   **draft**: it is written for non-developers and still carries a developer-only block under an explicit
   remove-before-publishing marker.

   **Read the marker as a proposal, not a verdict.** The split is keyed on branch type, and how well
   that predicts consumer impact varies per repo: in a storefront repo a `Style` branch *is* a customer-
   visible change, while in a tooling repo a `chore/` branch can carry the most consequential change
   there is. Read both halves and promote what matters; do not simply delete the bottom one.

   **Budget for a rewrite rather than a trim.** The tier renders the release a *second time*, it does not
   translate it — the draft is the same prose the development notes carry, regrouped. Turning entries
   written for someone reviewing a diff into a document for someone deciding whether to update is an
   authoring job. Measured at this repo's v3.2.0: 1,098 draft lines became 153, and the heaviest item for
   a consumer sat at line 1,034, below the marker, because it arrived on a `chore/` branch.

4. **Ship the hand-written documents via a branch + PR.** The internal note and the edited highlights
   draft are both written after the cut, and `cut-release.ps1` has already committed and tagged by
   then — so neither can ride along on the release commit, and neither is one of the two named
   direct-on-`main` exceptions. Use the normal `new-branch` → `ship-pr` route.

5. **Publish the GitHub Release — after step 4, never before it.** The body is one of the documents
   step 4 just merged, so publishing earlier means publishing a body that does not exist yet. Which bumps
   get a Release is **repo policy** — see the release manager's repo lens; some repos publish at every
   release, others at Minor/Major only.

   ```powershell
   gh release create vX.Y.Z --title "vX.Y.Z - <short title>" --notes-file <body-file>
   gh release upload vX.Y.Z <full-development-notes-file> [<highlights-file>]
   ```

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

6. **Branch cleanup** — the same fixed closing move as the `fold-changelog` skill's:

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
2. **Check the `<- LIVE` marker** in this repo's releases overview, so it shows at a glance which
   recorded version is the one actually live. Since #417 `cut-release.ps1` **moves this marker itself**
   where the repo sets `Get-ReleaseLiveMarker` — it strips it from the previous release heading and
   writes it onto the new one. This step is therefore a verification, not a hand edit; it stays on the
   checklist because the marker is the one release artefact whose correctness a script cannot confirm
   (only the person who did the push knows it succeeded).

## Requirements in the consumer

- `scripts\repo-config.ps1` with, optionally, `Get-LiveStage` — same shape as the existing
  `Get-LintScript`/`Get-ChangelogHeading` getters. Absent or empty: only Block 1 applies. Declared in
  `check-script-contract.ps1` as an **Optional** record (the mechanism introduced for
  `Get-ChangelogHeading`, issue #178): a consumer without the function gets `[INFO]` naming the
  fallback (`''`, i.e. no live stage), never `[ERROR]`.
- The script's own getters are separate from this skill's and all optional in the same way:
  `Get-ReservedRootMd`, `Get-ReleaseNotesGrouping`, `Get-ReleaseLiveMarker`, `Get-ReleasePluginTier`,
  `Get-ReleaseCategoryTitles` and the three highlights knobs (`Get-ReleaseHighlightsBumps`,
  `Get-ReleaseHighlightsStakeholderTypes`, `Get-ReleaseHighlightsWording`). Define none of them and the
  cut behaves exactly as it does in the source repo. Run `check-script-contract.ps1` to see which ones
  this repo answers and which fall back.
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
