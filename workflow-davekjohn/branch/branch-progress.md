## `feat/changelog-newest-first` progress

### Steps

#### PLAN

- [x] Ask where chronological applies, since the ranking also drives the release documents -- Dave:
      CHANGELOG.md only, the release notes keep ranking themselves, tiers and scores unchanged
- [x] Check which consumers of the ranking actually consume it: four of five re-rank themselves, and the
      fifth (development notes, tier 0) asks for chronological and was getting score order

#### CREATE

- [x] The stamp loses its quotes -- one line in the writer
- [x] `Get-ImpactInsertOffset` -> `Get-EntryInsertOffset`, returning the first entry boundary; `-Score`
      and `-Tier` kept and ignored, so a consumer's fold does not throw on the trunk
- [x] Re-sort the seven pending entries into landing order, read off the fold commits on `main`
- [x] The one-off re-sort verified before writing: 7 blocks in, 7 out, every block placed
- [x] Docs: the intro, Rendall's lens, `CONTRIBUTING-portable.md`, `BRANCH-portable.md`, the
      `fold-changelog` skill and the plugin's `scripts/README.md`
- [x] Regenerate the template through `new-branch` and re-sync the plugin mirrors

#### TEST

- [x] Re-aim the fence asserts: they proved fence-awareness through the rank, which no longer exists --
      they now pin that the top is the real entry and never the heading quoted inside the fence
- [x] Move the no-trailing-newline scenario to the fold that still reaches the end of the list (the first
      one, into an empty list) instead of deleting it
- [x] Full gate: 43 suites green in 140s, lint 0 errors

### Where I left off

Done and green.
