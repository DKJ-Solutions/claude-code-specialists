### The route for the two hand-written release documents, confirmed · Docs · 2026-08-04

**A rule that was actually an unanswered assumption now has an answer.** The edited highlights draft and
the filled-in internal note are both written *after* the cut — `cut-release.ps1` commits and tags in one
motion, and `new-internal-note.ps1` takes the development notes as its input — so the question of how they
reach `main` is unavoidable. It was put to Dave twice on August 3, 2026, went unanswered, and the
answer-shaped text ("via a branch + PR") was written into the docs anyway. Asked once more and answered:
**branch + PR, confirmed.**

**The alternative was concrete, and declining it is the substance of the decision.** The other option was
widening the direct-on-`main` release exception to cover "the release *and* its written notes", which would
have let both documents ride along. Declined for the reason this repo has already had to learn the hard
way: an exception is only safe while it stays the size it was granted at — the same principle that forced
the August 2, 2026 repair of `ship-pr.ps1`, whose fold step was making an unscoped commit under an
exception granted for a scoped one.

**The route has a measured instance now, not only an argument.** `v3.2.0`'s internal note shipped this way
in [PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) — gates green, entry folded,
and nothing about being written post-tag causing friction. So the confirmation records something that has
been run, which is what the previous wording lacked.

**One of the four documents the rule was said to live in did not carry it — and it was the one that
mattered most.** Checking before editing (rather than trusting yesterday's own note about where the text
had been placed) found the claim in `CLAUDE.md`, `releases/README.md` and the `cut-release` skill, but
**not** in Rendall's lens: the single place the release manager doing this work would look. That gap is
closed here, and the two root documents gained the attribution and the declined alternative so the next
reader sees a decision instead of a sentence with no origin. The portable `cut-release` skill was
deliberately left alone — it is person-neutral by design and already derives the route from the rule
rather than from an attribution.
