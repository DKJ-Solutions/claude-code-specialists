### Drop the agent descriptions the roster duplicates · Docs · 2026-07-28

Dave asked for a proposal on delivering the roster from the plugin instead of a hand-maintained table,
and then — decisively — *"meet het eerst"*. The measurement inverted the proposal.

**What was measured**, with `claude plugin details specialists@davekjohns-workshop` (authoritative:
`count_tokens` for the active model):

| | tokens, always-on |
|---|---|
| Plugin total | ~3.505 |
| — 15 agent descriptions | ~2.260 |
| — 7 skill descriptions | ~1.245 |
| SessionStart hook | 0 (*"harness-only — no model context cost"*) |

So **every enabled plugin's agent descriptions are already in every session**, whether or not anything
fires — visible in the running session's own context, not just in the docs. The `CLAUDE.md` roster spelled
those same 15 descriptions out again. It was paying twice.

**The proposal it killed.** The plan had been to generate the routing table from the plugin and inject it
via a hook's `additionalContext`. That would have added a *third* copy. Measuring first turned "inject
the roster" into its opposite: **remove what is already there.**

**What the measurement also exposed, which the proposal had wrong.** Only *agents* appear in the
always-on listing. The four persona-only specialists — Chris, Bianca, Derek, Rendall — appear in none, so
the roster table is the **only** place they exist for a session. Their rows are not duplication and must
stay. That asymmetry is exactly why inbound #204 existed at all, seen from the other side.

**The shape of the trim was constrained by the check**, which is why the rows are compacted rather than
deleted: `check-roster-sync` scans the roster text for each `<group>-<id>` token, so dropping the rows
outright would have produced 15 false "no roster row" errors. Keeping a compact id line and dropping only
the descriptions needed **no change to any shared script** — the roster check still validates all 19
specialists, `0 error(s)`.

**Result: `CLAUDE.md` is 2.799 characters smaller, ~750 tokens per session.** Honest provenance: the
~2.260 is a `count_tokens` measurement; the ~750 is a character-based estimate, since no equivalent
command measures a `CLAUDE.md`. Good enough to decide by, not the same class of number.

**One lever worth more than the saving itself.** The first attempt only reached ~660 tokens, because the
explanation that had to replace the rows — the "do not restore these" reasoning — was written *into*
`CLAUDE.md`, which loads every session. Moving it into
[Nolan #25's lens](.claude/plugins/claude-specialists/specialists/06-25-extension.md), read only when he
is called in, recovered the rest. Generalized there as: **the justification for a trim does not belong on
the always-on path.** `CLAUDE.md` keeps one line and a pointer; the method, the numbers and the reasoning
live with the specialist whose craft they are.

Left unmeasured and recorded as such in that lens: Chris's own lens carries a routing table and sits on
the automatic loading path, so it is always-on too. Its content is genuinely not duplication — a routing
signal is not a description — but its size has never been checked against what the routing needs.
