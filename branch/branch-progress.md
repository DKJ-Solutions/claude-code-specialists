# Branch progress

**Branch:** `chore/score-the-unscored-entries`

## Steps

- [x] Establish that the significance gate refuses the v3.6.0 cut, and that it writes nothing when it does
- [x] Read the four unscored entries and score them against `Get-EntrySignificanceRubric`
- [x] Assert the parse-and-reassemble round trip is byte-identical before editing `CHANGELOG.md`
- [x] Write the eight score rows and stable-sort the entries into ranked order
- [x] Verify 21 entries in / 21 out, exactly four changed, no mojibake
- [x] Fill in this branch's own changelog entry and step list

## Where I left off

Done. `CHANGELOG.md` holds 21 entries, all tier-1-and-higher ones scored, ranked furthest-reach-first
and highest-significance-first within a tier. Ready for the gates and the PR; the v3.6.0 cut follows
after the fold.
