## `fix/notes-grouping-is-a-decide-record` progress

### Steps

- [x] Verify inbound #560 still stands: the record is still `copy`, and the skill's own definition puts it on
      the other side of the line
- [x] Flip the marker to `decide`, with an `AdoptWhy` that carries the consumer measurement
- [x] Extend `Returns` so the answer is stated as readable off the existing `releases/development/`
      directories -- `<X>.x` is major, `<X.Y>` is minor
- [x] Rebuild the blueprint artefact and mirror `script-contract-lib.ps1` into the plugin
- [x] Tests: its own decide assert with its own reason; the copy example moved to `Get-RosterPath`; it joins
      the never-placed loop; the proposal document is asserted to carry it and the lookup advice
- [x] Confirm nothing else pinned the old marker (`script-contract`, `repo-config`, `release-lib`,
      `internal-note` suites, the skill's docs, the 22-record count)
- [x] Lint gate + all suites green

### Where I left off

Done. One test had to be rewired rather than added to: `config-blueprint.tests.ps1` read this function back
out of the fixture's seam as proof that "an adopted function answers". A decide record is deliberately not
placed there, so that read would now fail on a missing command -- it reads `Get-ReleaseHistoryPath` instead,
and the absence is asserted where it belongs, in the never-placed loop.
