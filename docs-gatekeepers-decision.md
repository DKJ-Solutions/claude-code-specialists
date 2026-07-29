### The gatekeepers repetition stays — decided, with the evidence · Docs · 2026-07-29

Closes [#217](https://github.com/DaveKJohn/davekjohns-workshop/issues/217). Its third item was reserved
for Dave, not a mechanical trim: Chris's lens restates safety rules `CLAUDE.md` already carries in full,
~600 always-on tokens that could be reclaimed — but the repetition sits at the point of use, and
instructions are context rather than enforced configuration, so cutting it trades tokens for adherence.
Dave's answer was **"decide after the trim."**

The trim is done ([PR #231](https://github.com/DaveKJohn/davekjohns-workshop/pull/231): `CLAUDE.md` 328 →
282 lines, the language detail path-scoped, and the remaining sections measured against the same test and
found to fail it). So the decision is now due, and the same session produced the evidence that settles it.

**Decided: keep the repetition. Do not revisit it as a token saving.**

The reasoning is not a preference but an observation from this session. The session-reply language rule
lives in `CLAUDE.md` — always-on, re-injected after every compaction, as prominent as an instruction can
be in this system. It was **broken anyway**, for an entire session, until Dave pointed it out. Always-on
presence therefore demonstrably does not guarantee adherence.

That cuts in one direction only. If a single always-on statement is not reliably enough, a second
statement at the point of use is not redundancy — it is the second chance the first one measurably needs.
The ~600 tokens are real and reclaimable; what they buy is worth more. Recorded in
[Nolan #25's lens](.claude/plugins/claude-specialists/specialists/06-25-extension.md) as a closed
question rather than an open saving, so a future cleanup pass does not quietly take it — which is exactly
what #217 asked for.

Reversible in one PR if Dave disagrees.

`CLAUDE.md` stays above the documented 200-line target at 282 lines. That is the accepted end state: the
sections still on the always-on path are there because each one fails the relocation test on its merits
— routing is needed at intake before any file is read, and the safety rules must survive compaction.
