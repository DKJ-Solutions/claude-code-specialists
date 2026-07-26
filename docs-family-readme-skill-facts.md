### Family README: correct the cut-release skill claim and cross-link the restart rule · Docs · 2026-07-26

Edith's copy edit on #187 recommended cross-linking the family README to QUICKSTART.md's
restart-on-new-skill rule. Following up on that surfaced two further problems in
`claude-code-plugins/claude-specialists/README.md`.

**The `cut-release` claim was stale and self-contradicting.** `## How we use skills — and what we
deliberately don't` still called `cut-release` "deliberately not a skill" and cited
`scripts/sync/check-script-contract.ps1` as the source for that — but the `cut-release` skill has
existed since v2.6.0 (issue #177, PR #184), and that same script's own comment draws the opposite
distinction: the workshop-only *script* `scripts/release/cut-release.ps1` is not mirrored, while the
shared `cut-release` skill is "a different thing entirely". Rewrote the living example to state the
actual split — the marketplace-specific script (reading `.claude-plugin/marketplace.json` as the
source of truth for what a plugin is and bumping every `plugin.json` it lists in lockstep) stays
workshop-only, while the closing-steps *procedure* around it shipped as the `cut-release` skill
because that value covered the maintenance cost.

**The skill enumeration was missing one, in two places.** The list of "every skill" in the same
section did not include `cut-release`, and the claim that every skill is "a thin wrapper around a
script" no longer held for it (the skill's own description: "a checklist ... no script is run or
mirrored"). Added it and marked it as the deliberate exception to that generalization. The identical,
equally stale list turned up one section up too, in `## Where this runs: Chat, Cowork, and Claude
Code` (which enumerates the skills that remain available in a plain Claude.ai Chat session) — added
`cut-release` there as well, in the same order. `disable-model-invocation: true` only removes a
skill from autonomous model invocation (and from the `/reload-*` skill counters), not from
availability as an explicit slash command, which four of the seven skills already in that list
(`fold-changelog`, `open-pr`, `park`, and `start-task`) demonstrate.

**The cross-link (Edith's original point).** Added a short pointer from `## Which release am I on?`
to QUICKSTART.md's `## Staying up to date` section, for readers of the family README who would
otherwise miss the restart requirement for a newly added skill and the unreliability of the skill
counters as evidence.

**Two inaccuracies of my own, flagged on review before this landed.** The living-example paragraph
claimed the script "would crash on its very first line" in a fresh consumer — untrue: line 1 is a
comment block, and the actual repo-specific dependency (a missing `marketplace.json`) is a
controlled `Write-Error` + `exit 1`, not a crash. Dropped that clause, and the line-count figure
alongside it, since a number like that goes stale with every edit to the script. Separately, the
paragraph listed the skill's Minor/Major GitHub Release step as part of the portable procedure
without noting that this workshop itself deliberately does not publish GitHub Releases
(`releases/README.md`) — reworded so that step reads as being for a consumer that does, and split
into its own sentence so the paragraph does not nest a parenthetical inside an em-dash inside a
parenthetical.
