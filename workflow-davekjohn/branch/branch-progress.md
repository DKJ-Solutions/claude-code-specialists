## `feat/releases-into-workflow-folder` progress

### Steps

- [x] `git mv releases/README.md` and `releases/audience/` into `workflow-davekjohn/releases/`
- [x] Repoint the two seams in `scripts/repo-config.ps1` (`Get-ReleaseHistoryPath`, `Get-ReleaseNoteRoot`); shared defaults untouched
- [x] Link arithmetic: moved files one level deeper (records: links only), six dead links in `releases/development/` archives repointed
- [x] Lint: link scan derives the whole workflow folder from the branch seam; history exclusions of checks 11/12/20 recognise the new address; the lifecycle exclusion's separator defect (latent since phase 1) normalised
- [x] `find-specialist-mentions`: moved records file as history, the README stays live, both addresses recognised
- [x] Live docs and lenses name the new paths; the moved README's own seam prose updated; `Get-ReleaseHistoryPath` copy record carries the folder answer (blueprint + mirror rebuilt, `config-blueprint` expectation follows)
- [x] Gates green: full lint (0 findings) + the affected suites; open-pr re-proves the full set before anything is pushed

### Where I left off

Phases 1-3 of the workflow folder are done after this merges: branch/ (PR #654), the consumer scaffold +
session signal (PR #656), and this repo's own releases/ half. Still root here by Dave's earlier word:
`CONTRIBUTING.md` and the generated `releases/development/` + `releases/github/` trees.
