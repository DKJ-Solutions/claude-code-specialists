### The teardown papers, corrected against round v12 · Docs · 2026-08-02

Two findings from test round v12 ([#375](https://github.com/DaveKJohn/davekjohns-workshop/issues/375)),
plus the two measurements the round-up asked to be folded back in. All four are the same defect class:
**a sentence that was true of the machine it was written on, stated as if it were true of every reader.**

**[#373](https://github.com/DaveKJohn/davekjohns-workshop/issues/373) — `UNINSTALL.md` was wrong about when
its own instruments die, and it contradicted itself inside a single step.** Step 1 said the audit is
*"the last point at which you can produce it"* because `teardown.ps1` lives in the payload Step 2 removes.
Measured in v11 and again in v12: after `claude plugin uninstall … --scope project`, both `teardown.ps1`
and `UNINSTALL.md` are still on disk. The tool sits in the version-pinned **cache** — the very `<plugin>`
path Step 1 makes the reader resolve three paragraphs earlier — and the cache follows the *marketplace*,
not the install, which is exactly what this page's own #339 table has said all along. Step 2 takes the
record and the **data** directory and drops an `.orphaned_at` marker; the instruments survive until the
manual cache delete in Step 5.

The advice was never the problem and it stays: keeping the audit output is cheap. What changed is the
**reason**, and the cost of getting it wrong was concrete — Step 4 told a reader who had not kept the
output that their only route was re-install → re-audit → uninstall again, a full cycle for a script sitting
on their disk. Step 4 now offers the re-run from the cache first. #328's observation survives intact, one
step further down the page than it was filed: the procedure does remove its own instruments, at the end
rather than in the middle.

**[#374](https://github.com/DaveKJohn/davekjohns-workshop/issues/374) — Step 5's empty-key warning cannot
fire on the path this family prescribes.** #357's repair was correct about the behaviour and wrong about
its audience: a *user-scope* declaration does leave `"extraKnownMarketplaces": {}` behind, but the
QUICKSTART puts that key in the **repo's** `.claude/settings.json` and gives `marketplace add` as
`--scope project` precisely to avoid the #279 defect — and Step 3 has already removed it several steps
before Step 5 runs. The claim is now conditional, and the stronger half (*"**never** literally clean"*) is
gone: on a virgin profile every one of the six clean-machine rows came back literally clean.

That sentence mattered more than its size, because it is the one that tells a future round what its
step-0 table is *allowed* to look like. A round trusting it would have filed v12's fully clean baseline as
an anomaly. The mirror of the same over-generalisation, further down the page (*"a torn-down profile is not
byte-identical to a virgin one"*, with three byte figures from one machine), is now a two-column table
bracketing the range, with the instruction to read your own numbers against your own starting point.

**Folded back in, both from the round-up.** #336's honest note said v10 never captured a hash pair at the
moment of the install, so the page described what changed rather than proving it; v12 captured the pair,
and the 22-byte delta is exactly the two documented changes — *behaviourally equivalent, textually
different* is now measured rather than inferred. And #327's self-healing trap is refined from "an enable
key is enough" to the two conditions it actually needs: marketplace registered **and** cache present.
Three states measured on one profile pin it down, and the useful half was documented nowhere — **finishing
the teardown through Step 5 disarms the mechanism**, stray key or not. The warning is therefore about the
*half-finished* teardown, which is a sharper and more actionable thing to warn about.
