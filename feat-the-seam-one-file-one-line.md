### The seam, specified and readable · Feat · 2026-07-29

The first half of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s remaining work:
the seam is **specified** in the family README and **readable** by every reader, with no behaviour change
for any existing consumer. What is deliberately not in this change is the writer flip — see the end.

**The shape.** A fresh consumer's whole specialist surface becomes one directory and one line:
`.claude/specialists/SPECIALISTS.md` (the inclusion: body import, lens import, roster slot) plus
`.claude/specialists/lenses/<group>-<id>-extension.md`, flat because `<group>-<id>` is unique
family-wide. `CLAUDE.md` carries `@.claude/specialists/SPECIALISTS.md` and nothing else, so a teardown
becomes *remove one directory and one line* instead of hand-cutting a roster woven through 6 sections.

**Four facts were verified from the reference before any of this was designed, and each could have sunk
it.** Nested imports work (*"a maximum depth of four hops"* — the seam spends two). A path in backticks
is not an import, so the docs can name the seam line safely. A project-root `CLAUDE.md` is re-read after
`/compact`, so the roster comes back with it. And it is **not a token saving**: *"imported files still
load and enter the context window at launch"* — the seam buys removability, nothing else, and claiming
otherwise would be the kind of unearned win this repo keeps catching elsewhere.

**One fragility the seam concentrates rather than removes,** now written down: the body import resolves
into the marketplace cache, outside the working directory, and such an import is gated by a one-time
approval dialog whose refusal is sticky — *"If you decline, the imports stay disabled and the dialog
doesn't appear again."* With one line instead of two, a single decline delivers nothing at all, silently.
Worth knowing before diagnosing that as a bug in this repo.

**The mechanism, in one place.** `check-report-lib.ps1` gains `Get-SeamPaths` (the literals the bootstrap
will write and the teardown must match — one source, because a drift between those two leaves a dangling
import that nothing errors on) and `Get-LensWriteDir`. `Get-LensDirCandidates` gains the seam as its most
canonical candidate ahead of the three it already walked, so **a consumer who migrates by hand works
immediately** — the roster check, the drift lint and the teardown all find lenses there today. The
mirrored plugin copy is back in step.

`Get-LensWriteDir` encodes the promise that keeps this safe: a fresh consumer gets the seam, a consumer
that already has lenses keeps writing where they are. The bootstrap never relocates a tree the repo owner
owns, because seam lenses written beside a legacy tree would split the surface in two — worse than either
layout alone, with the teardown then reasoning about both at once.

A new suite covers all of it (`check-report-lib.tests.ps1`, 12 asserts) — these shared helpers previously
had no direct test at all, only indirect coverage from suites that happen to call them. The pinned
properties: the seam is candidate 0, the legacy locations still resolve and `extensions/` stays last, the
import line never picks up a backslash from `Join-Path`, an *empty* legacy directory does not count as
adopted, and after a hand migration the writer follows to the seam without being told.

**Deliberately still to come, and why the split.** Flipping the bootstrap to write the seam by default
(and teaching the teardown its one-line/one-directory form) changes 30 assertions across five suites that
encode the current layout. Landing the readable half first means the seam can be proved on a real repo —
this one, by hand — before the default moves under every consumer at once.
