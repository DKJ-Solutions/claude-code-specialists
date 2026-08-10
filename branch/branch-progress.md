## `docs/the-contribution-cycle-lives-with-the-plugin` progress

### Steps

- [x] Write the portable contribution cycle into the workflow plugin, naming each seam instead of this repo's answer to it
- [x] Shrink the root `CONTRIBUTING.md` to a pointer plus this repo's own answers, under a `## Specific to this repo` slot
- [x] Extend check 4's scan set so a plugin-level document is read (five were unscanned, the new one would have been the sixth)
- [x] Pin that coverage with a test — scenario B5, including the dedupe witness; all 185 asserts pass
- [x] Point the workflow plugin's own `README.md` at the new document
- [x] Name the `Get-ReservedRootMd` trap where a consumer adopting a root doc will read it
- [x] Fill in the changelog entry: description and all three Significance sections
- [x] Copy-edit pass on the diff — three content corrections, two of language (see below)

### Where I left off

Done; ready for the PR.

Inbound #566 (`BWJ-ecommerce/smartwatchbanden`). Dave chose the plugin model over restructuring in place:
the portable cycle moved into `plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md`, the root
document keeps only this repo's answers — the manual/lens split applied to the contribution cycle.

Verified before starting: the issue stood, and five of its six named seams exist under those names.
`Resolve-PluginScript` does **not** exist — the real form is `${CLAUDE_PLUGIN_ROOT}`. The
`Get-ReservedRootMd` trap it reports was already documented in the contract table as `Adopt = 'decide'`, so
that half needed surfacing rather than building.

The copy edit caught the same class of defect the issue is about, in the new text: the portable half claimed
`Test-BranchName` validates branch names *portably*, while that function lives in the repo-owned
`branch-info.ps1` — so the hard refusals are the consumer's too, not the plugin's. Also corrected: four
content gates named instead of two, and no gate *count* in the opening line, since the plugin README counts
only the content gates and two numbers side by side is the drift being removed.
