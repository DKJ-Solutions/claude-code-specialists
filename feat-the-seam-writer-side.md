### The seam: the bootstrap writes it and the teardown removes it · Feat · 2026-07-29

The writer half of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221), after the
readable half landed in #253. A **fresh** consumer now gets one directory and one line, and a teardown
takes both away.

**What the bootstrap writes for a fresh consumer.** Lenses flat in `.claude/specialists/lenses/` (no
per-plugin segment — `<group>-<id>` is unique family-wide, so several enabled plugins share one
directory, which is what makes "remove one directory" true for a multi-plugin consumer too),
`.claude/specialists/SPECIALISTS.md` carrying the body import, a lens import relative to itself, and a
`## The roster (VUL-IN)` slot, plus exactly **one** `@`-import in `CLAUDE.md`. One detail is load-bearing:
the inclusion's **title carries no marker, only the roster slot does.** Filling in the roster therefore
removes the marker, so the teardown reads the file as authored — a `(VUL-IN)` title would have survived a
filled-in roster and made the teardown delete somebody's work.

**An already-adopted consumer is untouched** and keeps both its lens tree and its two imports.
`Get-LensWriteDir` makes that call, so nothing is relocated and the surface never splits across two
paths. Once the owner migrates by hand, the writer follows automatically.

**What the teardown does.** It reads the seam's literals from `Get-SeamPaths` rather than retyping them —
the bootstrap writes them and the teardown matches them, and a drift between the two would leave a
dangling import that nothing errors on. `SPECIALISTS.md` is classified exactly like a lens: unfilled slot
heading → removed; authored → kept, with the import **still** removed, because that line is what makes
the content live. The report then says outright that nothing loads the file any more. So the orphan does
not disappear, it *shrinks*: one named file holding the roster in one piece, instead of 43 lines scattered
through six sections. That trade is the seam's actual payoff, and the report names it.

**Measured end to end** before the suites were touched: a fresh fixture bootstraps to 19 lenses in the
seam and a single import, and a teardown leaves 27 items removed, 0 kept, and nothing but the owner's own
two files.

**The suites.** The estimate was ~30 assertions across five suites; the reality was two suites.
`connectors`, `sync-roster`, `roster-sync` and `release-lib` pass **unchanged** because they build
fixtures on the pre-seam path, which readers still accept — the back-compat promise, verified by accident.
`bootstrap-drift` (87 asserts) and `teardown` (101) were updated, and the new coverage pins what B2 adds:
CLAUDE.md carries exactly one import **as a count**, nothing lands on the pre-seam path for a fresh
consumer, the body import now lives in `SPECIALISTS.md` (so the durable-body-path assertion reads the right
file instead of passing vacuously), the whole `.claude/specialists` directory is gone after `-Apply`, and an
authored inclusion is kept while its import is removed.

Two boundaries stated rather than quietly crossed. The **57 agent defs and manuals** that name the
pre-seam lens path are left alone: both layouts are read and every existing consumer's lenses really are
still there, so those texts are accurate, not stale — sweeping them is a documentation pass for after the
consumers migrate. And this repo has **not** migrated itself yet; that is the next step, by hand, and it
only becomes visible in a later session because the plugin loads from the pushed `github` source.
