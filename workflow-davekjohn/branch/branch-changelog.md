## `docs/the-always-on-budget-remeasured` changelog

### Branch title

the always-on context budget is re-measured, and the best-practice page is held against what this repo already does

### Branch ID

20260814-232023

### Branch type

docs

### What does the change on this branch bring to main?

[#657](https://github.com/DaveKJohn/claude-code-specialists/issues/657) asked for the official Claude Code
best practices to be **measured against what this repo already does** rather than adopted wholesale. Both
halves are now in [Nolan's lens](.claude/specialists/lenses/06-25-extension.md), which is where the
context budget belongs and which loads on demand rather than on every session.

**The page's central claim is that the context window is the resource everything else serves — and this
repo had already measured itself against it, on July 28, 2026, with a verdict.** That measurement is now
seventeen days old and wrong by a factor:

| always-on | July 28 | today |
|---|---|---|
| `CLAUDE.md` | 24,388 chars · 277 lines | **73,298 · 875 lines** |
| Chris's repo lens | 12,274 | 19,405 |
| Chris's portable body | 6,628 | 11,075 |
| the seam (`SPECIALISTS.md`) | *did not exist* | 7,982 |
| **total** | **~11,700 tokens** | **~30,205 tokens** |

**+158%, and `CLAUDE.md` sits at 4.4× the target this repo set itself.** The old note names *"under 200
lines"* as the documented target and identifies the lever; both are unchanged, so this is a
re-measurement rather than a new proposal.

**A stale measurement is worse than none, which is why this is a branch and not a note.** The July 28
table reads as current, and a reader planning against ~11,700 tokens is planning against a number that
has not been true for a fortnight — the same reason this repo keeps its superseded measurements in the
past tense with their date attached.

**The cut is deliberately not made.** The one body that is genuinely path-scopeable now is the release,
changelog and tier machinery — inert until somebody touches `workflow-davekjohn/**`, `CHANGELOG.md` or
runs a cut. It also has the worst failure mode if scoped: a `paths:` rule is gone after a `/compact`, and
for release rules that means gone *during a release*, which is exactly when they are being followed. That
is a trade between context cost and a rule vanishing mid-cut, on Dave's own governance document, and it is
his call rather than a tidying job.

**The other half is the map, and it says the page is already implemented.** Eight practices held against
the tree: verification (three gates, 36 suites, CI as a required check — the page's escalation ladder ends
where this repo starts), explore-then-plan, environment, interview-to-spec (an entire specialist),
session management (`lock`/`continue`), an adversarial review step (Marlowe reviews the *conclusion* while
the others check the craft). **Exactly one practice is diverged from, knowingly: the pruned `CLAUDE.md`** —
because the page's own test, *"would removing this cause mistakes?"*, has an uncomfortable answer for a
document whose bulk is the recorded reasoning behind decisions this repo has repeatedly paid for
re-deriving.

### Significance

#### Tier 0

The number a maintainer plans against is correct again, and the practice map means the next person asking
"should we adopt the best-practices page" gets an answer with evidence instead of re-running the
comparison. The one open trade is stated as a trade rather than as a backlog item.

**Score:** 3

#### Tier 2

Nothing reaches a consumer: a repo lens does not travel with the plugin, and no shipped file changes.

**Score:** N/A

### Pull Request

