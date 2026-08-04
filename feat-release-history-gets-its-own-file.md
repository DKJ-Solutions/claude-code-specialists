### The release overview leaves the README and becomes the file the seam already points at · Feat · 2026-08-04

**Two changes to the same pair of files, done together because they are the same reorganisation seen from
two sides:** the release list gets its own page, and `CONTRIBUTING.md` stops describing a cycle that is
not its own.

#### The overview becomes `releases/HISTORY.md`

**`releases/README.md`: 228 → 131 lines. `releases/HISTORY.md`: 102 lines, all 72 versions.** The split
line is what each file answers. The README describes the **process** — what a release is, the three note
tiers, how one is cut, the guardrails. `HISTORY.md` is the **outcome** — every release ever cut, grouped
by major, newest first. Each now opens by naming the other, so neither reads as the whole story.

**The path became one answer instead of three.** `releases\README.md` was hardcoded twice in
`cut-release.ps1` — the guardrail that checks which major a new row lands in, and the inserter that
writes it — while [#452](https://github.com/DaveKJohn/claude-code-specialists/pull/452) had just added
`Get-ReleaseHistoryPath` for the changelog's pointer. Those are the same question: *where does this repo
keep its release history?* Both now read the seam, so moving the file again is one edit rather than three
that must agree. **The day they stopped agreeing, the changelog would point at one file while the row
landed in another** — silently, since both writes succeed.

**The lint gate caught all three broken anchors** (`#overview` twice, `#cutting-a-release` once) the
moment the sections moved apart, which is exactly the class of breakage a split like this produces and
nobody re-reads for.

**And a test was pinning the old path.** `release-lib.tests.ps1` asserted the live overview targets `3.x`
against a hardcoded `releases/README.md`. Left alone it would have gone on passing while looking at a file
that no longer holds the table — passing by examining nothing, the failure mode this very file caught
twice earlier today. It now reads the path from `Get-ReleaseHistoryPath` too.

#### `CONTRIBUTING.md` stops describing the release cycle

**Measured before and after: 2 literally shared lines → 0, and 1 identical heading → 0.** Both files
carried `## Cutting a release`, which is what made the pair *feel* duplicated far more than the two lines
justified — a reader meeting the same heading twice assumes two versions of the same text.

**Not merged, and the reasoning is worth keeping.** `CONTRIBUTING.md` is a naming convention with a fixed
place and audience: GitHub offers it to whoever opens an issue or PR, which is precisely the reader who
does not know this repo. A map README renders beside the artifacts it describes. And the two cycles differ
in every dimension that matters — everyone versus the release manager, every branch versus on request, and
an ordinary contribution versus one running under a **direct-on-`main` exception that must not read as
something the contribution page grants**. One file would put those two authorisation regimes side by side,
which is the one place not to blur them.

So the heading now says what the section is (`## Releases — a different cycle, described elsewhere`), the
duplicated definition is gone, and what remains is the single fact a contributor needs from there:
lockstep works because this repo holds one product.
