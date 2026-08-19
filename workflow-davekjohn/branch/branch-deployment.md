## `fix/retired-seam-scaffold` deployment

### What does the change on this branch deploy to main?

`specialists-init` stops scaffolding `Get-ChangelogHeading` into a fresh consumer's
`scripts/repo-config.ps1`. The seam was **retired** on August 5, 2026 with the flat changelog (#178) —
the contract registry holds no record for it and nothing reads it — but the bootstrap kept writing the
function, its backing variable, and a comment presenting it as live: *"Set it to whatever this repo uses;
the fold stops with a clear message if the heading is not found."* The fold no longer looks for a heading
at all.

**This repo's own two suites asserted both sides of that for fifteen days.** `repo-config.tests.ps1`
requires the source's config **not** to define it — *"a repo-config still answering these would hand values
to a mechanism that no longer reads them"* — while `bootstrap-drift.tests.ps1` required the scaffold to
supply it, under a comment calling it "Optional in the script contract". Optional is the stale half: it is
not optional, it is gone. That assert now reads the other way, on the whole block rather than the function,
and carries the reason so the next reader does not restore it.

**Two neighbours came along, both in the same class — a document that misinforms the reader who trusts it.**
`ship-pr.ps1`'s own header claimed the fold reads `Get-ChangelogHeading`; it does not, and has not since
that retirement. And three `.EXAMPLE`/doc lines in `ship-pr.ps1` and `open-pr.ps1` read
`-Resolves 331,332` **unquoted**, which cannot run: called directly, `331,332` is parsed as an array before
binding, and a script file with `[CmdletBinding()]` refuses an array for a `[string]` parameter. Reproduced
twice before being called a defect — once on the real script, once on a four-line probe — and the probe is
what makes it worth documenting: a **scriptblock** coerces the same argument to `'331 332'` and succeeds, so
testing the behaviour rather than the file hides it. The note now sits beside the parameter, because the
quotes are the price of the type choice rather than a style preference.

**Score:** 3

#### What makes this change extra special

A scaffolded file is written **once and never again**, which is what makes a wrong default expensive rather
than untidy: no later release can correct it. Every consumer bootstrapped with `workflow-davekjohn` since
August 5 carries a dead function with a comment that argues for filling it in — and one of them paid for it
in the way that is easiest to miss, by doing the work properly. `xoxowildhearts`, a Shopify theme repo with
no `CHANGELOG.md` at all, spent **nine lines of comment** reasoning about which of two false values was less
harmful, and then filed the reasoning as an inbound issue. Both of its options were wrong, and so was the
question: nothing reads the answer.

Existing consumers are not reached by this — their file is already written. `INSTALL.md` already tells them
the function may be deleted, which is the only route a write-once scaffold leaves.

**Score:** 3

### Pull Request

the bootstrap stops scaffolding a retired seam
