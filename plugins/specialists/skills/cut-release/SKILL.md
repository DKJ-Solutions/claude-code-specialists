---
name: cut-release
description: >-
  Checklist for the closing steps of cutting a release: the git tag + push, and for a Minor/Major
  bump a GitHub Release (highlights as the release body, the full development notes as an
  attachment -- gh's release-notes body has a hard 125,000-character limit), plus branch cleanup.
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

There is no script to run here, and none is mirrored. Once a release has been cut (the version bump
is committed), walk through the two blocks below **in order** and print/paste each command as you
go — do not skip a step or reorder them from memory.

### Block 1 — cutting (always)

1. **Tag the release commit and push the tag:**

   ```powershell
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

2. **Minor or Major bump only — publish a GitHub Release.** A Patch release skips this step
   entirely (tag only, no GitHub Release):

   ```powershell
   gh release create vX.Y.Z --title "vX.Y.Z - <short title>" --notes-file <highlights-file>
   gh release upload vX.Y.Z <full-development-notes-file>
   ```

   **Highlights as the body, full notes as an attachment — never inline.** The **highlights** (a
   short summary of what the release contains) become the release **body** via `--notes-file`; the
   full development notes go along separately as an **attachment** via `gh release upload`. This
   split is not a style choice: `gh release create`'s notes body has a hard limit of **125,000
   characters**. At life-hub's v2.1.0, the development notes were **134,419 characters** and the
   plain "paste everything into the body" approach returned an HTTP 422 from `gh`. Splitting
   body/attachment is what keeps the command from failing on anything but the smallest release.

   **Where `<highlights-file>` comes from.** Where the repo sets `Get-ReleaseHighlightsBumps` in
   `scripts\repo-config.ps1`, `cut-release.ps1` has already generated it at
   `releases/highlights/<dir>/<X.Y.Z>.md` (plus a print-ready `.html` beside it) — **edit it before
   publishing**: it is written for non-developers and the generated draft still carries a
   developer-only block under an explicit remove-before-publishing marker. Where that knob is empty
   (this workshop, life-hub) there is no highlights file and no such document is wanted; use the
   development notes as the body and drop the attachment line.

3. **Branch cleanup** — the same fixed closing move as the `fold-changelog` skill's:

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
- `git` and a logged-in `gh` CLI for the Minor/Major GitHub Release step.

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
- **A release itself is cut only at explicit request** (a version bump is never automatic) — that
  governance rule is unchanged and sits upstream of this skill, not inside it.
