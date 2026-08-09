## `fix/pr-body-starts-at-the-answer` progress

### Steps

- [x] Read PR #540's published body to see what actually sits under the wrapper heading, rather than
      reasoning about it from the entry file
- [x] `Get-PrDescription` in `pr-body-lib.ps1`: the entry from its `What does the change...` section to
      the `Pull Request` section, fence-aware, `''` when that section is absent
- [x] `open-pr.ps1`: use it, falling back to `Get-EntryDescription` on `''`
- [x] Template heading becomes the entry's own question, now that it no longer sits above a copy of it
- [x] `-RefreshBody` fallback list gains `## Changelog entry`, for the PRs opened under it today
- [x] Rebuild the plugin mirrors (`open-pr.ps1`, `pr-body-lib.ps1`)
- [x] Tests: what is dropped, what is kept, the fence case, the pre-dossier fallback, the retired
      section name, and the heading-fallback string
- [x] Verify the real output: this branch's own entry rendered through `Get-PrDescription`
- [x] Gates: lint, script contract, all 30 suites green
- [~] `### Significance` deliberately NOT dropped — it is the author's statement of reach and worth,
      which is what a reviewer is deciding about, not front matter
- [~] `CHANGELOG.md` deliberately unchanged — the fold keeps receiving the dossier verbatim; the two
      readers differ because a record wants provenance and a review wants the argument

### Where I left off

Done; gates green.
