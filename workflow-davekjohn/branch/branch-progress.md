## `fix/session-status-tier-reader` progress

### Steps

#### PLAN

- [x] Verify the locked topic against the repo before building: the symptom at
      `scripts/task/session-status.ps1:225`, the seams it names, and whether the finding is one file or a
      class. Confirmed one file -- `new-internal-note.ps1` matches `^##\s+Tier\s+(\d+)`, which is the release
      document's own section heading and correct as it stands.
- [x] Establish how the repair reaches a consumer: the library at `..\lib` (the step `new-branch.ps1` already
      takes), `repo-config` loaded before it because a named tier heading resolves through
      `Get-ReleaseAudienceTier`.

#### CREATE

- [x] Replace the private tier-heading pattern with `Resolve-EntryImpact`, fed one whole `##` block per entry,
      and print `N/A`, an unanswered score and a malformed section as themselves rather than as a zero.
- [x] Probe both optional sources once, above the blocks that read them, and degrade to `tier not read`
      instead of to a silent tier 0.
- [x] Correct the header's retired claim that the script dot-sources nothing, and the two comments that argued
      from it.
- [x] Re-sync the plugin mirror via `build-shared-scripts.ps1`.

#### TEST

- [x] Point the suite's fixture at the format's own writer (`Get-EntryTierSectionMarker`,
      `Get-EntryScoreLabel`, `Get-EntryScoreNotApplicable`) instead of at `#### Tier 0` literals, so a format
      that moves again fails the suite rather than outrunning it.
- [x] Add the three cases the old fixture could not express -- the current named shape, the numbered fallback
      a repo with no audience tier keeps, and no library at all -- plus one pinning `N/A` as distinct from a
      score. 61 asserts, all green.
- [x] Verify against this repo's three real pending entries, and measure what the library load costs:
      68ms of a ~3.25s run (n=5), which is dominated by `gh` and `git ls-remote`.

### Where I left off

The repair and its tests are done, the mirror is in sync, and both gates are the next thing to run.
