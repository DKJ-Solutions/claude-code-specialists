### shared cut-release skill · Feat · 2026-07-25

**To do / where I left off:**

Branch opened for **inbound issue #177** (source: DaveKJohn/djcylow-react — "cut-release as a shared
skill"). **Nothing implemented yet**: the investigation below came first and turned up a premise in
the issue that does not hold, so the scope needs Dave's decision before any code is written.

**The finding.** The issue assumes there is one shareable `cut-release.ps1`. There is not:

- `scripts/release/cut-release.ps1` in this workshop is **284 lines and deeply
  marketplace-specific**. It reads `.claude-plugin/marketplace.json` as the source of truth for what
  a plugin is, bumps every `<plugin>/.claude-plugin/plugin.json` in lockstep, writes per-plugin
  `CHANGELOG.md` sections and `RELEASE.md` cards, fills the overview table in `releases/README.md`,
  and hardcodes `check-plugin-integrity.ps1` as its lint gate.
- It dot-sources `scripts/lib/release-lib.ps1`, which is **deliberately not mirrored** into the
  plugin (workshop-specific tooling — see `scripts/lib/shared-scripts-lib.ps1` and the
  out-of-scope note in `check-script-contract.ps1`).
- It does **no** `gh release create` at all; the tag/release commands the issue praises live in its
  closing output text, not in its actions.
- The "413 lines, proven in life-hub" the issue refers to is therefore a **separate, diverged copy**,
  not a version of this file.

Mirroring it as-is would hand `djcylow-react` a script that stops immediately on
`.claude-plugin/marketplace.json is missing`.

**The three scopes put to Dave (decision pending):**

1. **Checklist skill + `Get-LiveStage`** (the recommendation). A `cut-release` skill that codifies
   the release procedure and prints the closing steps as ready-to-paste blocks: block 1 *cutting*
   (`git tag -a`, push tag, `gh release create` + `gh release upload` for Minor/Major, branch
   cleanup), block 2 *going live* (the push to the live target, then moving the `← LIVE` marker).
   Block 2 is driven by a new optional `Get-LiveStage` in `scripts/repo-config.ps1` (empty by
   default, so life-hub and this workshop get block 1 only) — same shape as `Get-LintScript`, and
   declared in `check-script-contract.ps1` as an **Optional** record, the mechanism just introduced
   on the `fix/fold-changelog-heading` branch for `Get-ChangelogHeading` (#178). Also bakes in
   life-hub's split: the **highlights** as the GitHub Release body and the development notes as an
   **attachment** — at v2.1.0 the notes were 134,419 characters and `gh` returned HTTP 422 (limit
   125,000). Matches the issue's own words: *"not automation, but a checklist that imposes itself."*
   No script mirrored.
2. **Full generalization.** Split `cut-release.ps1` into a generic core plus repo hooks (version
   sources, notes path, lint gate, live stage) and mirror that, so consumers run the real script.
   Literally what the issue asks, but a large rebuild of the most sensitive script in the repo.
3. **`Get-LiveStage` only.** Add the config slot + scaffold + contract record now, plan the skill
   separately. Smallest diff, but does not yet solve the forgotten tag in `djcylow-react`.

**State of the sibling branches** (both committed, neither has a PR — waiting on Dave's word):

- `fix/lens-path-family` — #179 done: `Get-LensFamily`/`Get-LensDirCandidates` in
  `check-report-lib.ps1`, writers and readers on one source, off-path lenses found + one soft INFO
  per directory, regression tests. Lint + all 15 suites green.
- `fix/fold-changelog-heading` — #178 done: `Get-ChangelogHeading` (optional, defaulted), structural
  section boundary, Optional record type in the script contract, Keep-a-Changelog tests. Lint + all
  15 suites green.

**Next step here:** Dave picks scope 1, 2 or 3; then Sylvester #15 builds it, Tycho #18 adds tests,
Victor #19 / Edith #17 / Sebastian #23 review, Derek #05 opens the PR on Dave's word.
