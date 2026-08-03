### Block a PR whose changelog entry still carries its scaffold wording · Feat · 2026-08-03

**A third gate in `open-pr.ps1`, and it was found by the highlights tier rather than by a review.**
Rendering v3.2.0 for a non-developer audience surfaced that three of its twenty-one entries (#424,
#425, #426) still carried the scaffold heading `new-branch` had written, with a status appended behind
it:

```text
**To do / where I left off:** phase 1 done -- lint gate green, all 23 suites green.
```

A progress note. Correct on the branch, wrong the moment it is published — and it had already reached
the release notes *and* the per-plugin `CHANGELOG.md` files that travel to consumers in the plugin
cache.

**Why a gate rather than a habit.** The window closes at the merge, and it closes **invisibly**: the
fold moves the entry into `CHANGELOG.md`, the next release moves it on into `releases/` and empties the
Pull-Requests section. By the time anyone would review it, the place they would look is the one place it
no longer is. Measured across all 70 archived release notes: one older instance, then three in a single
day — a rate, not a one-off.

**The wording became a single shared source first, because otherwise the guard could drift.**
`new-changelog-entry.ps1` hardcoded the three strings; the gate needs the same three. A copy in each
would let the gate silently miss whatever the writer changed — a drift guard that drifts, which is worse
than no guard because it reports success. So they moved to
[`entry-scaffold-lib.ps1`](scripts/lib/entry-scaffold-lib.ps1), a shared lib both scripts dot-source,
registered in the mirror. `Get-EntryFallbackType` deliberately stayed behind: a changelog *type* is not
scaffold prose, so `Chore` is a legitimate final value and can never be evidence of an unedited entry.

**Two deliberate design choices, both measured rather than assumed:**

- **Substring, not whole-line.** The shape that actually shipped kept the heading and appended to it, so
  a whole-line match would have passed all three real cases.
- **Fenced code excluded.** This repo's own docs quote that wording while explaining the mechanism —
  this very entry does, above — and a guard that cannot tell a quote from the real thing gets switched
  off. An unclosed fence hides the tail, which is the safe direction: a missed finding, never a false
  accusation against prose somebody did write.

`-Force` is the escape valve, deliberately separate from `-SkipLint`/`-SkipTests`: those skip a tool,
this overrules a judgement about content, and conflating them would let a routine "skip the slow suites"
also wave prose through. `ship-pr.ps1` passes it along.

**The contract check learned about indirection.** Three `Get-Entry*` records are now read by two scripts
through a lib, so neither names them directly. Rather than weaken the "really references this, not a
stale entry" assertion, records gained a `ViaLib` field and the check now proves **both** halves: the
script really dot-sources that lib, and the lib really names the function. That is stricter than what it
replaced — the old text match was satisfiable by a mention in a docstring, which is exactly how this
would have passed unnoticed.

**A pre-existing flaky test found and fixed on the way, and it is the more interesting find.**
`shared-scripts.tests.ps1`'s resolves-gate assert failed four runs in a row when the suite's output was
redirected to a file and passed four runs in a row when it went to the terminal — same commit, with
`open-pr.ps1` behaving identically both times (verified by stashing my change: it failed against `main`'s
version too). The cause is the documented one: `Write-Error` wraps at the child's own console width, and
this scenario normalized whitespace by *collapsing* it, which only survives a wrap landing on a space. A
mid-word wrap yields `resol` + `ves gate`. #415 fixed exactly this in the branch suites; this scenario
kept the weaker form. **Green in the setup a human watches, red in the one CI uses** — the worst
direction for a gate to fail in. Now stripped rather than collapsed, verified on both paths.

**Tests: a new suite, `entry-scaffold.tests.ps1`, 31 asserts.** The one it exists for is the round trip:
the real `new-changelog-entry.ps1` writes an entry in a throwaway repo and the real matcher is handed its
output. "The writer and the guard cannot disagree" is a claim about code; that assert measures it. Plus
the seam probe (an empty override is *ignored* — a blank marker is a substring of everything and would
refuse every PR in the repo), the exact v3.2.0 shape, and the fence handling in both directions.
