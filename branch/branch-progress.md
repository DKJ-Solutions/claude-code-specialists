## `feat/releases-audience-root` progress

### Steps

- [x] `Get-ReleaseNoteRoot` answers `releases/audience`, with the naming rule and the deliberate
      non-movement of the shared default written above it
- [x] `git mv releases/notes releases/audience` — the three documents keep their history
- [x] Lint check 25 reads the seam instead of the literal `releases\notes`, walks the pre-rename root
      alongside it, and says so in its coverage line
- [x] The five links the move broke, repointed (Nolan's lens ×2, the release history table ×3) — and the
      link TEXT in Nolan's lens with them, since a label naming a path that no longer exists is drift
- [x] `CLAUDE.md`'s tier section: two kinds of audience, the per-entry measurement, the two separations,
      the gate's tolerance, and the root rename
- [x] The four other ladder assertions in `CLAUDE.md` (`all three tiers`, `the ladder stays cumulative`,
      `the ladder is cumulative`, tier 0 below tier 1) brought in line
- [x] `releases/README.md`: the tier table, the audience rule, the measurement, the three-root document
      table, and the section heading that named two tiers
- [x] The `cut-release` skill — the portable half a consumer receives: `Get-ReleaseAudienceTier` documented
      for the first time, the example block labelled as a tier-2 repo's, the note root read off the seam
- [x] Rendall's lens and the two `session-status` skill pages (`lock`, `continue`)
- [x] Contract record `Get-ReleaseNoteRoot`: `copy` → `decide`, with the expired reasoning written down
- [x] Regenerate the config blueprint — 26 records, 12 copy, 14 decide
- [x] Tests: the seam is followed, a repointed root cannot report a healthy zero, and both roots are held
      in one run
- [x] Lint gate green
- [x] All suites green — 31 in 296s
- [x] Close #620 with the evidence — posted as a comment before the merge, with both stated reasons
      re-measured rather than inherited: the bump claim refuted from `Test-ReleaseBumpEarned`'s own code
      (`tier >= 1` puts tier 1 and tier 2 in one bucket), and the mirror claim refuted from the record
      (tier 1 scored **89** times against tier 2's 83 — filled more often, not near-empty). The PR's
      closing keyword does the closing itself
- [~] The dead `$consumerFacing` at `scripts/lib/release-lib.ps1:259` — set and never read, the residue of
      when #620's "silently wrong bump" could have happened. Left alone deliberately: it is a separate
      cleanup, and naming it in the closure is worth more than folding it into this branch
- [~] The "26 suites" figure in `CLAUDE.md` and Sylvester's lens (there are 31) — flagged twice now, still
      its own `docs/` branch rather than scope creep here

### Where I left off

Chunk 3 of three, and the last of the #620 work. Everything is written and both gates are green; what
remains is the PR chain and closing the issue with its evidence.
