## `fix/pr-body-heading-levels` progress

### Steps

- [x] Check what the level change would break before making it — found the `-RefreshBody` boundary
      scan and the `^##` template read, both of which fail silently
- [x] `Get-PrDescription`: promote every heading in the returned slice by one level, fence-aware,
      floored at H1
- [x] Template heading to `#`
- [x] `New-ResolvesBlock -Level`, and `Add-ResolvesBlock` deriving it from the body's first heading
      outside a fence — so the block stays a sibling of the description in every repo
- [x] `-RefreshBody`: locate the description heading at any level, not `^##` exactly
- [x] Fallback list gains the H2 form of the current wording, for the PRs opened under it today
- [x] Rebuild the plugin mirrors (`open-pr.ps1`, `pr-body-lib.ps1`, `pr-issues-lib.ps1`)
- [x] Tests: the promotion, the fence exemption, the level parameter, the derivation (H1/H2/no
      heading/fenced heading), and the any-level template read asserted from open-pr's own source
- [x] Two stale asserts from yesterday's branch updated rather than deleted — they pinned the old level
- [x] Verify the real output: this branch's entry rendered to `#` / `##` / `###`
- [x] Gates: lint, script contract, all 30 suites green
- [~] `CHANGELOG.md` and the release documents deliberately unchanged — the entry is one `##` block
      among many there, so its levels are correct in the record and only the PR copy shifts

### Where I left off

Done; gates green.
