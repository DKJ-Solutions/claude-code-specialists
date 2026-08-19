## Branch `docs/claude-md-workflow-layer` changelog - 20260819-092006

### What does the change on this branch bring to main?

#### Tier 0

The root `CLAUDE.md` now states only what holds in this repo **whether or not a plugin is installed**,
and the `workflow-davekjohn` plugin's own mechanics moved down to
[`workflow-davekjohn/CLAUDE.md`](workflow-davekjohn/CLAUDE.md) — the layer that applies on top and wins on conflict.
It is the same split [`CONTRIBUTING.md`](CONTRIBUTING.md) has made since August 14, 2026, extended
to the operating guide (Dave, August 19, 2026).

**What moved:** the scaffold gate and the step-list gate in full, and the mechanics and measurements
behind the two direct-on-`main` exceptions — the fold commit's scope history, the major's two
preparation commits with `b2cea9c`/`1d2d3ff`, "neither half is automated", and "who writes what"
around a cut. **What deliberately stayed:** every *bound*. A session has to know that the fold is
limited to three named paths, that the release commit runs only on explicit request, that a major's
preparation covers a major only, two paths only, only under a requested cut, and that the hand-written
release documents are **not** covered — whether or not it ever opens that folder. Governance stays on
the always-on path; only the reasoning went down.

**Measured:** the root goes 29,536 B → 24,518 B, so 5,018 B (17%) leaves the path that loads on every
session; the folder page goes 2,612 B → 12,126 B on the path that loads only when a session touches
that folder. Same shape as the two moves already recorded in that section — Sylvester's 9,440 B and
Rendall's 41,168 B, both August 15, 2026.

**One repair the split forced, found by checking the citations rather than the anchors.**
[Rendall #06](.claude/specialists/lenses/05-06-extension.md) lists five things the root states
as "the operative half", and one of them — that the hand-written release documents land via a branch
+ PR rather than under the exception — had moved down with the rest of the release craft. It is back
in the root bullet, as a bound rather than as craft. The lint scans anchors and all seven still
resolve; it cannot see a claim that stopped being true, which is why the citations were read.

**Score:** 3

#### Higher than tier 0?

N/A — nothing here is plugin payload. Both files are this repo's own documents; the
`adopt-workflow-folder.ps1` scaffold that writes a fresh consumer's folder page is untouched, and its
`VUL-IN` slot for repo-specific rules is exactly what this repo filled in. A consumer receives
nothing from this branch.

**Score:** N/A

### Pull Request

The root CLAUDE.md holds without the workflow plugin
