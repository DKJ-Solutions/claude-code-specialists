### A round's baseline table is measured, not typed · Feat · 2026-08-02

Test round v12's [#371](https://github.com/DaveKJohn/davekjohns-workshop/issues/371), and the last
open finding of that round. Its baseline table said the fixture README had **23** lines where the file
has **22** — in the papers of the round that was verifying #360, the repair about a figure naming its
convention. Both numbers are defensible: 22 is the count of line terminators, 23 is the number of line
positions an editor gutter shows. What the table lacked was the column that says which one is meant,
and its `hoe gemeten` cell — the documented remedy for exactly this — read `alle regels`, which names
nothing.

**Why this is a script and not a fourth doc fix.** The round's own closing note asked for it: the
papers live in `DaveKJohn/specialists-adoptietest`, outside the reach of check 15 and check 16, so
there the habit had to do the work — and it did not. `scripts/tests/round-baseline.measure.ps1`
computes every figure from a checkout and prints the markdown block, so the number cannot be a typo
and the convention cannot go unnamed. **It prints both line conventions as separate rows**, each with
its rule, which is the actual fix: a consumer who measures the other one is no longer left deciding
whether they mis-cloned.

**It reproduces v12's table exactly** — 1105 bytes blob, 1127 on disk, 22 terminators, 23 positions,
15 per `Measure-Object -Line`, 3 commits, `f56a9e6` — which is independent confirmation that the
reporter of #371 was right about the one row and that the other five were sound. The size delta is no
longer a claim in prose either: the row states that the 22-byte difference is exactly the 22 CRLF
conversions, which is the reasoning the reporter used to prove the line count.

**A hole it found in itself, on its first run.** The blob rows come from the ref and the disk rows from
the working tree. The smoke test measured `main` in a checkout standing on another branch, and the
table was right only because that branch happened not to touch the file. Right by luck is the class
this whole issue is about, so the script now refuses — hard error, no table — when the file on disk
differs from the ref, and the guard compares *normalized* content on purpose: a byte comparison would
reject every Windows checkout, which is the only kind this family runs. Both directions are asserted.

**Pinned by 47 asserts in `scripts/tests/round-baseline.tests.ps1`**, which drives the real script over
the `powershell -File` hop rather than dot-running it. Three of them are the reason the suite exists:
a file *without* a closing terminator must report the same number twice (a naive `terminators + 1`
passes the 22/23 case and lies here), no row may carry an empty or one-word `how measured` cell — the
defect itself, failing in CI instead of in someone's papers — and a CRLF working tree must not trip the
mismatch guard. The CRLF fixtures drive `core.autocrlf` per repo, so the suite gives the same verdict
on a CRLF and an LF checkout.

**Two things learned while building it, both now comments in the code.** `-Path` is a comma-separated
`[string]` rather than a `[string[]]`, because `powershell -File` cannot bind an array parameter and
`-Path a,b` would arrive as the single filename `a,b` — the same trap `pr-issues-lib`'s `-Resolves`
was reshaped for. And the first shallow-clone fixture was refused by the script: setting
`core.autocrlf` *after* a checkout leaves the working tree inconsistent with the config, so git reads
the file as modified. The fixture was wrong, not the guard.

The suffix follows `fresh-consumer.measure.ps1`: a `.measure.ps1` asserts nothing and stays out of
CI's `*.tests.ps1` glob, because on a fresh clone whatever it finds *is* the baseline. Its correctness
is what CI checks.
