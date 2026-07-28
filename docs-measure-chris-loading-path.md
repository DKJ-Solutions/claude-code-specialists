### Measure Chris's always-on loading path · Docs · 2026-07-28

Closes the open question PR #214 left behind: Chris's lens sits on the automatic loading path, so it is
always-on, and its size had never been checked. Measured now — **and the answer is to leave it alone**,
which is the part worth writing down.

**What loads before a single assignment is given:** `CLAUDE.md` (~6.600 tok) plus its two `@`-imports,
Chris's portable body (~1.800) and Chris's repo lens (~3.300) — **~11.700 tokens of documents**, plus
~3.505 of plugin listing, so roughly **~15.200 tokens**. Chris's lens is the largest single specialist
file in the repo and the only one on the automatic path.

**Two traps, both hit while measuring.** The roster trim in #214 made this look like the same kind of
target. It is not:

- **The routing table's "Repo lens" column looks like duplication and is load-bearing.** Thirteen links
  of an apparently uniform `<g>-<id>-extension.md` shape, so the obvious move is to state the pattern
  once and drop the column. That breaks it: **the group prefix is not derivable from the display
  number.** Derek #05 is `05-05`, but Rebecca #07 is `03-07`, Rendall #06 is `05-06`, Tycho #18 is
  `04-18`. That column is the only always-on place the group lives. It nearly got "optimised" away here.
- **The gatekeepers section restates safety rules `CLAUDE.md` already carries in full** — both always-on,
  and the one genuinely reducible ~600 tokens. But that repetition sits at the point of use, and Claude
  Code's own guidance is explicit that instructions are context rather than enforced configuration, so
  how they are written affects how reliably they are followed. Cutting it trades tokens for adherence,
  which is a different decision from removing a description that was already in context twice. Left to
  Dave, not taken as a mechanical trim.

So: no change to Chris's lens, and the measurement plus both traps recorded in
[Nolan #25's lens](.claude/plugins/claude-specialists/specialists/06-25-extension.md) — precisely so the
next session that goes looking for savings does not re-derive the first trap the hard way.

**The lever it does leave**, recorded with it: reduce cost by moving content *off* the automatic path
rather than deleting it. `CLAUDE.md` is the biggest item at ~6.600 tokens and runs 277 lines against a
documented target of under 200, and path-scoped `.claude/rules/` files load only when Claude touches
matching files. That is where the room is.

Filed alongside this: [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215), the other half
of the research — a plugin *can* activate its own agent as the main thread via a root `settings.json`,
which would remove the `@`-import from every consumer's `CLAUDE.md`. Not actionable as configuration:
Chris's body says he never executes anything himself, which is fine as a role inside a main loop and
crippling as the main thread's system prompt. It needs a rewritten body first, so it belongs in the
backlog rather than in this branch.
