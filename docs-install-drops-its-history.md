## INSTALL.md drops the history it was keeping a third copy of

### What does this change do?

`plugins/INSTALL.md` had grown a habit of explaining its own past to someone trying to install
something: *"It was five acts until August 1, 2026"*, *"And it was three steps until August 3"*,
*"Until August 3, 2026 this was not a step"*, and a two-paragraph account of the `QUICKSTART` →
`ADOPTION` → `INSTALL` renames. Interesting, and worth nothing at all to a reader running commands.

**They were a third copy, which is why the repair is a deletion rather than a move.** Each one
describes a change that already has a changelog entry and a release document — verified per issue
before cutting anything: `#327` appears in 4 of them, `#329` in 2, `#408` in 2, `#335` in 1. A
separate background page would have been a fourth copy, ageing independently, with nobody able to say
which one was current. The adoption half now carries one sentence pointing at
[`releases/README.md`](releases/README.md), which indexes every version with the changes behind it.

**The blockquotes that stayed are the ones that change what the reader does**, and the split was made
on that test rather than on shape: that `.claude` means two different directories in this document,
that an install record can read as perfectly healthy while the session is inert, and which of the
three machine states you are in. Two borderline blocks were rewritten instead of cut, because a
historical frame was wrapped around an operational fact — that a session start does *not* make the two
`claude plugin` commands redundant, and that Step 4's half hour is authoring rather than installing.
Cutting those wholesale would have taken the fact with the frame.

**The reading-time block is shorter and remeasured.** ~9,300 words (~47 min) against
`specialists-init`'s ~5,600 (~28 min), so ~75 minutes for a first-time adopter — down from ~77, and
the number moved *because* of this change, which is exactly the trap: the `measured-figure` check
holds a figure to naming what binds it, never to being right. `README.md` quotes the same figure and
was corrected with it.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 3 | the adoption manual stops narrating its own version history at someone trying to install; ~35 lines and five interruptions gone from the page a new consumer reads first |
| 1 | 2 | one fewer copy of history that would have drifted from the changelog and the release notes without anything reporting it |

### Type of change

Docs

Plugins: specialists
