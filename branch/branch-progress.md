## `feat/the-fold-commit-says-fold` progress

### Steps

- [x] Check what reads the fold subject before renaming it (nothing does; the discovery script keys on
      the shape `^[a-z]+:`, `branch-info.ps1` matches a branch name)
- [x] `fold-changelog-entry.ps1`: `fold: <branch> changelog (#NN)` and the plural form, with the PR
      number at the END of the singular line rather than mid-sentence
- [x] `fold-changelog.tests.ps1`: assert the new shape, and the type separately from the branch name
- [x] `ship-pr.ps1`: the two comments that quote the fold subject as the merge subject's pair
- [x] `branch-info.ps1`: keep the August 7 measurement, in the past tense, saying why it no longer
      reproduces
- [x] Docs: Rendall's lens, the `ship-pr` skill, and the `fold-changelog` skill — which did not state
      the subject shape at all, so a consumer had nowhere to read it
- [x] Mirror into the plugin and run the suites
- [x] Test the PLURAL subject too (Dave's question): measured at 1 multi-entry fold in 410, under
      wording replaced twice since — so the shape the script writes had never been produced or asserted

### Where I left off

Done; the entry is written and the gates are next.
