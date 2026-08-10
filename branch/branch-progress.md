## `docs/a-record-is-cited-where-it-lives` progress

### Steps

- [x] `README.md`: point each half of the sentence at its real home -- the record moved to
      `script-contract-lib.ps1`, the "out of scope" retirement note stayed in the check
- [x] `cut-release/SKILL.md`: the Get-LiveStage record is declared in `script-contract-lib.ps1`; this
      one ships to consumers, so it is the more consequential of the two
- [x] Lint + suites green
- [x] Fill in the changelog entry: body + a score per tier

### Where I left off

Done. Both citations were verified against the tree before being changed, and the README one needed a
split rather than a rename: its sentence made two claims, and issue #456 sent them to two different
files, so swapping the filename would have repaired one half and broken the other.

Swept for the same class rather than fixing only the line that was noticed -- two documents tree-wide,
both repaired here.
