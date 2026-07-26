### Correct stale counts, enumerations and a legacy path across lenses and READMEs · Fix · 2026-07-26

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
