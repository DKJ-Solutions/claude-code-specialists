### Follow the ruleset rename to main-ci-gate in the docs that cite it · Docs · 2026-07-26

PR #193 recorded the repo ruleset `main-ci-poort` as a deliberate exception to the repo-wide
English norm: the doc cited the actual, live name of an external GitHub object rather than binding
to it, and translating that name unilaterally would have made the doc false. Dave has now renamed
the ruleset itself to `main-ci-gate`. **Reality moved first, the docs follow it, not the other way
around** — the order this exception always insisted on.

**Verified before touching anything.** Queried the GitHub API and compared the ruleset field by
field against the state recorded before the rename: only the name changed. The required status
check is still `lint-en-tests`, enforcement is still `active`, it still targets the default branch,
all three rules (deletion, non-fast-forward, required status checks) are unchanged, and both
bypass actors are still set to "Always allow."

**Corrected in `.claude/plugins/claude-specialists/specialists/05-15-extension.md`:** the ruleset
name updated to `main-ci-gate`, with the rename (and its date) noted inline; the surrounding
sentence about GitHub → Settings → Rules and the required check `lint-en-tests` needed no other
change.

**A judgment call in `CLAUDE.md`.** The `main-ci-poort` passage was a *third* technical-identifier
exception, justified only by the name being Dutch-shaped. With the rename, that justification is
gone — there is no longer a non-English name to except from the norm, so the passage no longer
belongs in the exceptions bullet and was removed from there. But the reasoning behind it was a real
lesson, discovered the hard way: Edith's copy edit read the ruleset's Dutch-looking name as
ordinary translation debt and nearly proposed renaming the doc's mention outright, which would have
made the doc cite a ruleset that does not exist. Only querying the GitHub API caught that before it
shipped. That is exactly the kind of lesson this repo's working practice says belongs in the docs,
not just in memory, so rather than deleting it outright it now lives on as a short, general
verification rule in `CLAUDE.md`'s closing paragraph under `### Language`: before treating a
non-English-looking name as translation debt, check whether it is the live name of an external
object first; if it is, that object gets renamed by whoever owns it, and only then does the doc
follow — never the reverse. The `main-ci-poort` → `main-ci-gate` rename is named there as the
historical case that produced the rule, not as a currently open exception — the exception itself
is fully closed, and `lint-en-tests` remains the one identifier in that bullet with a live,
still-binding justification (renaming it would break the required-status-check binding itself).

**Left alone, deliberately:** the three mentions of `main-ci-poort` in `research/copilot/bevindingen.md`
and `research/plugin-sharing/vervolgstappen.md` are dated research/logbook entries describing a
mid-July 2026 event under the name that was current then — closer to history than to living
documentation. Whether `research/` falls under the language norm at all is a separate, open
question for Dave; it was outside every partition of the original audit.

Corrected in `.claude/plugins/claude-specialists/specialists/05-15-extension.md` and `CLAUDE.md`.
