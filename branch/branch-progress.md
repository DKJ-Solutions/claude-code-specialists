## `docs/the-release-overview-describes-one-document` progress

### Steps

- [x] Read CLAUDE.md's release-commit section, the `cut-release` skill (step 2 + the writing-norm
      measurement), and Rendall's lens (05-06-extension.md) as the source of truth for the merged
      note model.
- [x] Verified the merged-note mechanics directly against the tree rather than the summary:
      `cut-release.ps1` (the `releases/notes/<dir>/<X.Y.Z>.md` path, the `$cutNote` gate, the
      Version-cell write) and `release-lib.ps1`'s `Build-ReleaseNoteDraft` (the three section
      headings and their fill state).
- [x] Rewrote `releases/README.md` lines 1-190-equivalent: the tier table, `## The three documents`
      (renamed `## The release documents`), its `### Tier N` sub-sections merged into one
      `### Tiers 1 and 2 - the hand-written note` section, and `### Where the hand-written note lands`.
- [x] Read-and-corrected (not rewritten) the "Cutting a release" section and the repo-specific block:
      fixed the GitHub Release closing-step paragraph (body is generated, not the internal note) and
      the seam-values paragraph (the cut writes the Version cell itself now); left already-correct
      past-tense history standing (the per-plugin CHANGELOG/RELEASE.md retirement, the branch-prefix
      measurement, the v3.2.0/v3.3.0/PR #432 instances).
      Cross-checked `### Seam values in force here` against `scripts/repo-config.ps1` directly.
- [x] Left `### The release list` (the `#### 4.x` heading, the table rows, and everything below)
      untouched — published records, and `release-lib.tests.ps1` pins the major heading live.
- [x] Filled in `branch/branch-changelog.md` (description + all three Significance tiers) and this
      step list.
- [x] Review found the same August 10 drift one document further in: `CLAUDE.md` claimed the overview's
      Version cell is written by `new-internal-note.ps1` and that it *could not* be the cut's job.
      Corrected, with the expired reasoning kept as the record — verified against `cut-release.ps1:794`,
      the sole remaining caller of `Set-ReleaseInternalNoteLink`, and `v4.4.0`'s own first-write row.
- [x] Review corrected the tier-2 claim from `N/A` to a score of 2: the premise that a consumer cannot
      reach this page is disproved by the page's own mirroring instruction, which invites copying its
      portable half as-is, and by `releases/` sitting in every consumer's plugin cache.

### Where I left off

Done. The page's portable half now describes the one document the scripts actually write, and the two
sentences elsewhere that still claimed otherwise are corrected with their expired reasoning kept.

