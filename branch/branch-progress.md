## `docs/skill-pages-state-the-audience-tier` progress

### Steps

- [x] Read `Get-EntryAskedTiers` before trusting the report: `@(0, audience)` when the seam answers,
      `@(0..2)` when it does not — so three sections is the unconfigured case, not a retired one
- [x] Sweep every portable doc and template for the same claim, rather than fixing only the reported file
- [x] `open-pr/SKILL.md`: the example led with `#### Tier 1` and omitted tier 0 — a shape no configuration
      produces. Rewritten to tier 0 + tier 2, with the retired shape named
- [x] `new-branch/SKILL.md`: the opening announced "each of the three reaches" forty lines above the page's
      own correct explanation of the knob. Opening now shows the two-section shape and points down
- [x] Remove the duplication that first draft introduced — the knob and the tier-1 variant are already
      stated further down, so the opening only names the shape
- [x] Check the anchor: the knob sits in a bold paragraph, not under a heading, so a `#`-link would have
      been a dead link at check 4. Written as prose instead
- [x] `branch/templates/`, `cut-release/SKILL.md`, `CONTRIBUTING-portable.md`, repo `CONTRIBUTING.md` —
      checked, all already correct, nothing touched

### Where I left off

**The PR chain is next** — `open-pr`, CI, merge, fold. Written here rather than as a step, per the
convention that landed in #638.

Nothing else is outstanding on this subject. The one item still genuinely with Dave is the duplicate local
gate run in `ship-pr` (~7 min/PR), which was never given a recommendation because it removes a
belt-and-braces run in front of a merge.
