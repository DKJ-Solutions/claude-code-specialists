### Correct the claim that this workshop publishes no GitHub Releases · Fix · 2026-07-26

A repo-wide documentation audit found that docs stated flatly that this workshop does not publish
GitHub Releases, while it does: `gh release list` confirms `v2.6.0` and `v2.7.0` have a GitHub
Release, `v2.6.1` and `v2.7.1` do not. The claim was an overcorrection from #188, which framed the
GitHub Release step as belonging only to a consumer, citing `releases/README.md` and the
`cut-release.ps1` docstring — both stale at the time and not checked against the actual releases.
Four docs carried it in total; the fourth (Rendall's own repo lens) turned up while fixing the
first three and was folded into this same branch rather than split into a separate PR.

**What was untrue:** `releases/README.md` (the intro and the "Cutting a release" section),
`claude-code-plugins/claude-specialists/README.md` (the Skills section), and
`.claude/plugins/claude-specialists/specialists/05-06-extension.md` (Rendall's own repo lens) all
said, in one form or another, that this workshop deliberately publishes no GitHub Releases.

**What is true, and now documented:** `cut-release.ps1` itself indeed publishes nothing to GitHub
Releases — that part of the old text was correct and is unchanged. What was missing is the manual
closing step that follows it: for a **Minor or Major** bump, the release manager walks through the
`cut-release` skill's checklist and runs `gh release create` (highlights as the body, via
`--notes-file`) + `gh release upload` (the full development notes as an attachment — `gh`'s
release-notes body has a hard 125,000-character limit). A **Patch** release skips that step
entirely (tag only), which is why `v2.6.1` and `v2.7.1` have no GitHub Release while `v2.6.0` and
`v2.7.0` do.

**Consequence this already had:** at `v2.7.0` (a Minor), the GitHub Release step was initially
skipped because the "this workshop publishes no GitHub Releases" doctrine text was followed at cut
time; it was published afterward once the gap was noticed.

Corrected in `releases/README.md` (the intro paragraph and the "Cutting a release" section, which
also gained a short closing-step note naming the skill), in
`claude-code-plugins/claude-specialists/README.md` (the Skills section, which now points at
`releases/README.md#cutting-a-release` instead of the false contrast), and in
`.claude/plugins/claude-specialists/specialists/05-06-extension.md` (the "Versioning & releases"
intro, the `releases/` directory line, and the closing how-vs-what sentence — the last one needed a
structural fix too, not just a factual one: it had "GitHub Releases" on the portable *how* side while
the repo-specific *what* side said they don't happen here, a contrast that only held under the false
doctrine. Split into two sentences on Edith's copy-edit suggestion: the how/what contrast now stays
clean — *what* is just the scripts/entry/fold/lockstep mechanics — and a separate sentence states
this repo's actual GitHub Release mechanics, a manual Minor/Major-only closing step). Rendall's lens
carries the most direct consequence of the three: as the release manager he follows it directly, and
the old text is exactly what led him to skip the GitHub Release step at `v2.7.0`. The archived
release notes and the published GitHub Release bodies are left untouched — those are history, not a
live claim.
