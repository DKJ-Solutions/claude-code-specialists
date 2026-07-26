### cut-release skill: the closing-steps checklist, not a mirrored script · Feat · 2026-07-26

Inbound issue #177 (source: `DaveKJohn/djcylow-react`) asked for `cut-release.ps1` as a shared
skill, on the assumption that a shareable version of it exists. It does not: this workshop's own
`scripts/release/cut-release.ps1` is 284 lines of marketplace-specific machinery — it reads
`.claude-plugin/marketplace.json` as the source of truth for what a plugin is, bumps every
`plugin.json` in lockstep, writes per-plugin `CHANGELOG.md` sections and `RELEASE.md` cards, and
fills `releases/README.md` — and dot-sources `scripts/lib/release-lib.ps1`, which is deliberately
not mirrored into the plugin. Mirroring it as-is would have handed a fresh consumer a script that
stops on `.claude-plugin/marketplace.json is missing` on its very first line. Rebecca's research put
three scopes to Dave: mirror a generalized script (a large rebuild of the most sensitive script in
the repo, and more than the issue's real problem needs), add only the config slot without a skill
(leaves the actual forgotten-tag problem unsolved), or codify the closing procedure as a checklist.
Dave picked the recommendation — the checklist.

**What shipped is a checklist, not automation** — the issue's own words: *"not automation, but a
checklist that imposes itself."* The new `cut-release` skill
(`claude-code-plugins/claude-specialists/specialists/skills/cut-release/`) prints the closing steps
of a release as ready-to-paste command blocks, in a fixed order, and mirrors no script:

- **Block 1 — cutting (always):** the annotated tag + push, a `gh release create` +
  `gh release upload` for a Minor/Major bump, and branch cleanup.
- **Block 2 — going live (only where applicable):** the push to the live target, then moving the
  `<- LIVE` marker. Driven by a new optional `Get-LiveStage` in `scripts/repo-config.ps1` (empty by
  default, so this workshop and life-hub get Block 1 only) — the same optional pattern
  `Get-ChangelogHeading` established for #178, added to the `specialists-init` bootstrap scaffold and
  declared in `check-script-contract.ps1` as an `Optional` record, so a consumer without the function
  gets `[INFO]` naming the fallback, never `[ERROR]`.

Bakes in life-hub's hard-won split: the **highlights** become the GitHub Release body, the full
development notes go along as an **attachment** — at life-hub's v2.1.0 the notes were 134,419
characters and `gh` returned HTTP 422 (the release-notes body limit is 125,000 characters). The
skill prescribes that split explicitly so no consumer trips over it again.
