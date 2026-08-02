### The mojibake gate peels by the inverse operation, not by a table of known sequences · Fix · 2026-08-02

Found while measuring the surface for a different gate: `check-plugin-integrity.ps1` reported
`[mojibake] ... No findings` over files that held **517 doubly-encoded runs** — 315 em dashes, 43
arrows, 10 ellipses, 4 en dashes. Three of the four damaged files sat inside the check's own stated
scope, and the damage had ridden into `v3.1.0`: the root `CHANGELOG.md`, the specialists
`CHANGELOG.md`, its **consumer-facing** `RELEASE.md` card, and the 3.1.0 release notes.

**Why the gate could not see it.** `fix-mojibake.ps1` worked off a hand-written table of known
sequences, and the gate is deliberately nothing more than that tool run as a child process — one source
for "what does damage look like". The table carries the single-layer form of these four characters and
exactly one outer-layer peel rule, added when double encoding first bit. Damage double-encoded in any
*other* character matches no rule at all, so the fixpoint loop exits on its first pass with nothing
found. Shared source, shared blindness: the property that keeps repair and detection in step also kept
them wrong together.

**The repair is the method, not four more rows.** Mojibake is one specific operation — UTF-8 bytes
decoded as Windows-1252 — so its inverse is equally specific. Each run of non-ASCII text is now
re-encoded to Windows-1252 and decoded as UTF-8, repeatedly, for as long as the result gets shorter.
That repairs any character rather than the seventeen somebody wrote down. Both encoders are **strict**:
with the default fallbacks an unrepresentable character silently becomes `?` and invalid bytes become
`U+FFFD`, which would turn a repair tool into a corruption tool; strict, the round trip simply fails on
text that was never mojibake, and failure means leave it alone. Verified before adoption rather than
assumed — a correct em dash, arrow, middot, e-acute, a two-character run of u-diaeresis and an emoji all
survive untouched, while the eight-character double-encoded em dash peels to three characters and then
to `—`. The table stays as a net under the round trip for runs it cannot reach.

**Two reporting repairs alongside it.** The archived notes under `releases/` were outside the tool's
path list and held the largest single concentration of damage (474 sequences in `3.1.0.md`); they are in
scope now, because "history is not rewritten" protects what a note *said*, not a mis-decode nobody wrote.
And the coverage line said `checked 1` — the number of tool invocations, which is true of every possible
scope and therefore evidence of none. It now reports the file count the tool states (186) and names
`releases/` in its scope.

All 517 sequences repaired, confirmed by a detector written independently of the tool rather than by the
tool's own verdict.
