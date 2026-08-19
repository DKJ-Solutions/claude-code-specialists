## `feat/entry-format-two-sections` progress

### Steps

#### PLAN

- [x] Read the hand-edited template as the spec, and measure which seams it moves: the section headings, the
      tier heading level, the stamp separator, the guidance wording
- [x] Settle the two wording forks with Dave: the audience sentence resolves to the repo's own tier, and
      `(was tier 0)` does not stay in the form

#### CREATE

- [x] `entry-scaffold-lib.ps1`: rename the `What` heading and retire the old one, drop tier 0's own heading,
      retext the audience tier's `####` sub-heading, add `Get-EntryIdSeparator` and the audience descriptions,
      and rename `Test-EntryTierHeadingAsksRoute` to `Test-EntryTierSectionsAreNamed`
- [~] Model the audience tier as a revived `### Significance` section -- dropped on Dave's word mid-branch: he
      asked for `####`, so it stays a sub-heading of the question and the entry keeps two `###` sections. The
      parser still recognises the `###` form, since an entry may have been written against it today
- [x] The parser reads the new shape, guarded on the score label so no table- or line-shaped entry is
      misread as an unscored tier 0
- [x] `pr-body-lib.ps1`, `open-pr.ps1` and both PR templates follow the heading rename, with the old H1 on
      open-pr's legacy list
- [~] Make the lint's entry-shape count read repo-config -- dropped with the `###` version above: the count is
      back to 2 for every repo, so it is a property of the format again and needs no repo lookup
- [x] Propagate the format to the prose: `CHANGELOG.md`, the release lens, `BRANCH-`/`CONTRIBUTING-`/
      `RELEASES-portable.md`, the four skill pages, `branch/README.md` and the script contract
- [~] Migrate the entries already in `CHANGELOG.md` -- dropped: they are read as they stand, and rewriting a
      folded entry edits the record rather than the format

#### TEST

- [x] All seven entry shapes round-tripped through `Resolve-EntryImpact`, plus the writer round-trip with and
      without a migration body
- [x] The unconfigured-consumer path verified to produce the pre-change file byte for byte
- [x] Update the suites that assert the *written* shape, leaving the ones that feed legacy shapes as input
- [x] Lint gate green, all suites green

### Where I left off

Gates are green and the entry is written. Still to happen after the merge, so deliberately not steps: the
fold, and the plugin update in `smartwatchbanden` -- its machine record is on v4.13.0 against v4.14.0 here, so
it takes this format on its next update rather than now.

One thing found and deliberately left alone, per the no-pre-emptive-fixes rule:
`scripts/lib/pr-issues-lib.ps1:146-147` matches en/em dashes as literal non-ASCII bytes inside a regex, in a
`.ps1` that Windows PowerShell 5.1 decodes as CP1252. It predates this branch, nothing has reported it, and
the repair is a code-point escape exactly like the one this branch used for the middle dot.
