# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #193 · Translate ci.yml to English, closing the last gap in the repo-wide language norm · Chore · 2026-07-26

A documentation audit found that `CLAUDE.md`'s Language section claimed the repo-wide English norm
covers "unambiguously everything," with exactly three named exceptions, while
`.github/workflows/ci.yml` was still entirely Dutch and matched none of those three. Sylvester
translated `ci.yml` (comments, step names, and console output all English now; the job id
`lint-en-tests` deliberately kept as-is — see below). This entry covers the accompanying doc fix
in `CLAUDE.md`'s `### Language` slot, so the norm's own text matches the repo state again.

**The scope enumeration now actually covers what the heading promises.** The "script layer is
fully in scope" bullet named only `scripts/**`, the hooks, and the tests — `.github/**` (the
workflows, the issue templates, the PR template) was missing from the list even though nothing
in the norm ever meant to exclude it. Added, with `ci.yml`'s translation in this pass noted as the
concrete instance that surfaced the gap.

**A technical identifier is now recorded, not just fixed.** The CI job id `lint-en-tests` is the
exact name GitHub's `main` ruleset requires as a passing status check before any PR can merge.
Renaming it to something more English-shaped would silently break that binding: every future PR
would sit unmergeable, waiting on a check that no longer exists — a failure that would only surface
at the next PR, not at the moment of the rename. `CLAUDE.md`'s technical-identifiers bullet now
names it explicitly alongside the existing `VUL-IN` example, with that consequence spelled out, so
a future language pass does not "fix" it into a merge-blocking regression.

**On the "unambiguously everything" phrasing itself:** reworded to "every layer of the repo," with
the enumeration described as meant to be exhaustive and any future undercount named as a gap to
close on discovery — not a quiet exception. The norm itself (repo-wide English) is unchanged; only
the self-description of the list's completeness was softened, since an absolute claim had now
failed twice (once for script-generated document content, once for `ci.yml`).

**A second language gap, found while drafting the `.github/**` scope-bullet above and closed in
the same branch:** the issue template `.github/ISSUE_TEMPLATE/inbound-verbeterpunt.md` had fully
English frontmatter and body, but a Dutch filename. Flagged as a follow-up finding; Sylvester
picked it up directly (a git rename, `inbound-verbeterpunt.md` → `inbound-improvement.md`) rather
than leaving it as a loose end. That broke two links the lint gate then caught: the reference in
`claude-code-plugins/claude-specialists/QUICKSTART.md` and the reference (path plus visible link
text) in `claude-code-plugins/claude-specialists/connectors/README.md`. Both updated to the new
filename. The third reference, in the archived `releases/development/1.x/1.3.0.md`, is
deliberately left as-is: archived release history isn't rewritten to match a later rename (and the
lint gate doesn't scan that directory, confirmed by it flagging only the two live docs above).

**A third technical identifier, found by Edith's copy edit and re-checked before acting on her
read:** `.claude/plugins/claude-specialists/specialists/05-15-extension.md` names the GitHub
ruleset `main-ci-poort` as the required-status-check enforcer. Edith initially read that as
translation debt. The coordinator queried GitHub's API directly to check: the ruleset is really
named `main-ci-poort` there (id 19008062, target `branch`) — the lens quotes reality rather than
lagging behind a norm. Translating the doc's mention would make it false (a ruleset by that English name
does not exist); making the name itself English requires renaming the ruleset in GitHub's
branch-protection settings first, which touches `main`'s merge security and is Dave's decision, not
something this documentation pass can decide on its own. Added to `CLAUDE.md`'s
technical-identifiers bullet, alongside `VUL-IN` and `lint-en-tests`, with the distinction spelled
out explicitly: `lint-en-tests` may not change because the ruleset *binds on* that job name;
`main-ci-poort` may not change because the doc *describes* that ruleset's actual name — two
different reasons, both valid, worth keeping apart rather than folding into one blanket "don't
translate identifiers" rule.

Also, on Edith's copy-edit: the closing sentence under `### Language` now names this pass's own
scope-sharpening (`.github/**` explicitly covered, July 26, 2026) as a third dated milestone
alongside the July 20 decision and the July 21 sharpening — the identifier bookkeeping and the
completeness-wording revision are left out of that milestone list, since they document existing
practice rather than move the norm's boundary. One wording nit taken as proposed: "had stayed
untranslated regardless" → "had simply been missed" (redundant with "matching none of the
exceptions below").

Corrected in `CLAUDE.md`, `claude-code-plugins/claude-specialists/QUICKSTART.md`, and
`claude-code-plugins/claude-specialists/connectors/README.md`; the rename itself in
`.github/ISSUE_TEMPLATE/` is Sylvester's terrain and was done by him.

[PR #193](https://github.com/DaveKJohn/davekjohns-workshop/pull/193)

---

### #192 · Correct stale counts, enumerations and a legacy path across lenses and READMEs · Fix · 2026-07-26

A repo-wide documentation audit found eight stale counts, enumerations, and one wrong path, all of
the same kind: the repo grew and the surrounding text did not grow with it. Each was verified
against the actual repo state (agent-def counts, test-file counts, hook registrations, script
signatures) before correcting.

**The two findings that could actually mislead a specialist into a wrong action:** Ravi #24's own
repo lens — his tool for tracking duplicated behavioral rules — named only 4 shared blocks with 3 of
4 counts wrong, when there are 11 shared blocks sourced under `agent-shared/` (`inbound-behaviour`
and `laziness-automation` in all 26 agent defs, `language-behavior` in all but Rebecca's deliberate
local variant, plus `no-conversation-history`, `no-commit-push-pr`, `browser-compatibility`,
`webcontent-boundary`, `changelog-entry-boundary`, `design-owner-boundary`,
`storefront-preview-boundary`, and `artifact-publishing-boundary`) — a sweep against the old text
would have missed seven of them. Chris #01's own repo lens listed the callable-but-unrostered rest of
the `specialists` plugin as four names (Paula, Vera, Gwen, Cody), omitting Auden #30 (the
Academic & Long-form Writer) even though `CLAUDE.md` already counts "those five callable subagents" —
exactly the kind of gap that could make Chris conclude no specialist covers long-form/academic
writing and improvise one, against the rule that new specialists are never invented on his own
initiative.

**Also corrected, lower-stakes but still wrong:** Tycho #18's lens described the test suite as having
"only just begun" with one member, when `scripts/tests/` now holds 15 suites covering nearly
everything Sylvester's lens lists — left as-is, that text would have had Tycho treat well-tested
ground as backlog. Liam's agent-def (`specialists-shopify`) pointed to Gwen's style guide via only
the legacy path `.claude/extensions/04-12-extension.md`, the one cross-reference among all 26 agent
defs that didn't also carry the current plugin path — a consumer that never adopted the legacy layout
would follow it to a file that may not exist. The root `README.md` still said "two" informational
SessionStart hooks, naming only `connector-sessioncheck` and `roster-sessioncheck`, when `hooks.json`
registers a third, `script-contract-sessioncheck` (`CLAUDE.md` already had all three). The family
README undercounted the shared-block circle twice over: "the inbound rule even across all 19" (it's
26, and `laziness-automation` shares that same full reach, so the sentence no longer marked anything
as distinctive), and a "Current blocks" list naming 6 of the 11. Rendall #06's lens listed
`cut-release.ps1` and `fold-changelog-entry.ps1` without their `-SkipLint` and `-RepoRoot` flags
respectively, and the `fold-changelog` skill — which travels to every consumer — likewise omitted
`-RepoRoot`.

**A deliberate judgment call on the two heaviest sections (Ravi's and Tycho's):** rather than
re-hardcoding fresh counts that would only go stale again at the next agent-def or test suite added,
both now name the blocks/suites themselves and point at a live way to re-check the count (a search
over the sentinel, or `Get-ChildItem scripts/tests/*.tests.ps1`) — the same kind of drift this
finding exists to stop from recurring.

**Left alone:** `specialists/scripts/README.md`'s mirrored-script count mismatch is Sylvester #15's
terrain (script/README boundary), not touched here.

Plugins: specialists, specialists-shopify

[PR #192](https://github.com/DaveKJohn/davekjohns-workshop/pull/192)

---

### #191 · Correct the claim that this workshop publishes no GitHub Releases · Fix · 2026-07-26

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

[PR #191](https://github.com/DaveKJohn/davekjohns-workshop/pull/191)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
