### An `@`-import no longer passes for a roster row · Fix · 2026-07-29

Resolves [#227](https://github.com/DaveKJohn/davekjohns-workshop/issues/227). `bootstrap.ps1` writes
`@.claude/plugins/<family>/<plugin>/01-01-extension.md` into `CLAUDE.md`, and that path *contains* the
token `01-01`. `Test-InRoster` scans the roster file for the token, so the import line satisfied it:
Chris counted as rostered with no roster row anywhere in the file. Measured on a bootstrapped consumer,
19 specialists produced **18** missing-roster findings, and the one that silently passed was the worst
possible id to lose — a persona appears in no always-on listing, so the roster row is the only thing
that makes them exist for a session. The check was blind exactly where blindness costs most, and blind
*because* the bootstrap had correctly done its job.

`check-roster-sync.ps1` now strips `^\s*@` lines from the roster text before anything reads it, which
fixes both directions: the missing row is reported, and an import naming an id with no backing
specialist no longer manufactures a phantom orphan.

**The fix is narrow on purpose, and that is the interesting part.** The obvious repair — bind the token
to a roster-row/table shape — is exactly what `Get-RosterIdTokenPattern`'s docstring records as
**deliberately rejected** under inbound #182: `Test-InRoster` is asked about an id in free prose, and a
table shape would change behaviour for consumers who format their roster as a list. That reasoning still
holds and is not overturned here. An `@`-import is a different animal: a line the bootstrap writes, never
a roster row under any formatting convention, so excluding it needs none of that risk. The docstring now
records where that documented limitation stopped being cosmetic, and the question to ask next time —
*does the offending text have a writer that is knowably not the roster author?* — so a future case is
weighed against this carve-out instead of reopening the rejected option from scratch.

**Residual, unchanged and deliberately not chased:** a roster file that references a lens path in
ordinary prose still satisfies the test for that id. This repo does precisely that — Chris's lens is
linked from the routing prose — so its `01-01` would pass even without a table row. Harmless here, since
the real roster row exists, and the same accepted class as the prose false positives in #182.

**The error count goes up, not down: 21 → 22.** This fix *adds* a correct finding rather than removing
one, because the bug was concealing real work. Worth stating plainly so the next measurement is not read
as a regression.

The regression test was verified to **fail without the fix** before being trusted — both halves, the
missing row and the phantom orphan.
