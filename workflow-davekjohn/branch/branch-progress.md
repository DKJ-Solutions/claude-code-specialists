## `feat/contributing-into-workflow-folder` progress

### Steps

- [x] Root `CONTRIBUTING.md` rewritten as the standard workflow (branch + PR, CI, merge) with the layering rule: the workflow's page applies on top and wins on conflict
- [x] `workflow-davekjohn/CONTRIBUTING.md` added as the workflow's layer, carrying the plugin mechanics and this repo's seam answers (the content the root page used to hold), opening with the precedence rule
- [x] The earlier misread (a move) reverted: `Get-ReservedRootMd` keeps `CONTRIBUTING`, README/SECURITY point at the root page, no live doc lost its target
- [x] `CONTRIBUTING-portable.md` gained the "two contributing pages, and which one wins" section; the `adopt-workflow-folder` scaffold's consumer template opens with the same rule
- [x] `CHANGELOG.md` intro points its mechanism sentence at the workflow layer; sibling links in `workflow-davekjohn/{branch,releases}/README.md` follow
- [x] Stacked on phase 3, merged `main` back in after PR #659 folded (dossier kept over the fold reset)
- [x] Mirror rebuilt; gates green: full lint (0 findings) + the scaffold suite; open-pr re-proves the full set before anything is pushed

### Where I left off

The workflow folder now carries all four residents Dave's original spec named: README/CLAUDE (consumer
scaffold), CONTRIBUTING (two-layer model, this branch), branch/ (PR #654) and releases/ (PR #659).
Ideas parked as issues: #655 (SDLC phases), #657 (best practices), #660 (GitHub Projects board).
