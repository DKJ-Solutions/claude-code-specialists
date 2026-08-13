## `docs/post-merge-steps-convention` progress

### Steps

- [x] Measure it before writing it: 105 branches with a step list, 17 with a post-merge step, 4 blocked,
      14 ticked in advance, 1 branch on record going from `- [ ]` to `- [x]` in a commit that changed
      nothing else (`0efeff8` → `e2d633e`)
- [x] Rule 5 in `branch/README.md`, with the "neither mark fits" argument and the measurement; renumber
      the two rules below it (nothing cross-references them — checked)
- [x] The portable half in the `new-branch` skill, so a consumer receives the rule and the reasoning
- [x] State why no gate enforces it: the matcher would need an exclusion list, and ordinary steps are
      legitimately about `open-pr`/`merge`/`fold`

### Where I left off

**The chain after this is the PR itself** — `open-pr`, CI, merge, fold. Written here rather than as a step,
which is this branch's own rule applied to itself.

**One separate defect found in passing, deliberately NOT fixed here.** The `new-branch` skill's Significance
section still says the entry gets a sub-section for *"each of the three reaches"* and shows `#### Tier 0`,
`#### Tier 1` and `#### Tier 2` in its example block. The audience-tier decision of August 12, 2026 made
the scaffolder write **tier 0 plus the repo's one audience tier** — measured on both branches scaffolded
this session, which produced Tier 0 and Tier 2 and no Tier 1. So a consumer-facing page describes a
cumulative ladder that was retired. It is a distinct defect with its own evidence and belongs in its own
entry where a reader can find it, not folded in behind this branch's title.
