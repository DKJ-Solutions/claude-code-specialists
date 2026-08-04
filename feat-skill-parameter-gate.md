### A shared script's parameters must appear in the skill that documents it · Feat · 2026-08-04

**Check 18 closes a class that was found by accident and then measured.** A consumer has exactly two
things: the plugin mirror of a script, and the skill that describes it. So a parameter the skill never names
does not exist for them — escape valves included. The accidental find was `fold-changelog`, which told every
consumer to commit the fold **by hand** for two days after the script gained `-Commit`/`-Push`, because that
improvement had been written into this repo's lens. One regex over the other four shared entry points found
three more.

**The gate then found a fourth that the regex had missed, which is the argument for how it reads them.**
Parameters come from the **PowerShell parser**, not a pattern match: the regex used for the initial
measurement skipped `[Parameter(Mandatory = $true)][string]$Bump` and reported three gaps where there were
four. `-Bump` is how you say what kind of release you are cutting. A gate built on that regex would have
shipped with exactly the blind spot it exists to close.

**Four repairs, and the largest was a clarity defect rather than a missing flag.** `cut-release`'s
`-Bump`, `-NoPush` and `-SkipLint` were absent because the skill never documented *cutting* at all — it
opened at "tag the release commit and push the tag", which is what the script prints when you pass
`-NoPush`. So the page silently documented only the `-NoPush` path without saying that was what it was,
while the script commits, tags **and** pushes by itself. It now starts with the invocation, states both
escape valves and why `-NoPush` matters (it is the only moment a human sees the assembled artifact before it
is public), and keeps the manual push as what it always was: the `-NoPush` follow-up.
`new-internal-note`'s `-RepoRoot` and `-Force` were the fourth.

**Two design decisions, both taken from what the registry already does.** The skill mapping and the
per-parameter exemptions are declared **in the registry beside the registration** — the reasoning `LibOnly`
already carries, that a second hand-written list is one a newly shared script falls out of silently. And an
entry point may declare `Skill = ''`, which is a *declaration* rather than an omission: the check reports
those in its coverage line by name instead of failing over them, because writing a missing skill is separate
work and blocking every unrelated PR until someone does it would get the gate bypassed.

**That coverage line is where this change surfaces a bigger gap than the one it fixes.** Four mirrored
scripts document nothing: `check-script-contract` legitimately (it runs from a hook; there is no procedure
to write down), but **`ship-pr`, `fix-mojibake` and `verify-resolved-issues` are real gaps**. `ship-pr` is
the sequence the registry itself calls safety-critical — it merges to `main` and then commits directly to
`main` — and the `cut-release` skill already sends the reader to "the normal `new-branch` → `ship-pr`
route", which is a route no page describes. `fix-mojibake` was mirrored precisely because three repos had
each written their own copy, i.e. three people needed it and none had a page. Named in the registry and in
the coverage output so the gap is visible rather than absent.

**Tests: 140 asserts in the integrity suite (up 6) and 183 in the shared-scripts suite.** Both directions
of the check, the coverage count as evidence that a parameter was really examined, and two guards that came
out of getting it wrong: a registered script **absent from the tree** must be skipped rather than reported
as a missing skill (check 8 owns that finding, and the first version of check 18 fired on every scenario in
the suite because of it), and the "declares no skill" case must be asserted against a script that **exists**
— asserting it on `ship-pr` failed, since the fixture has no `ship-pr.ps1` and the skip fires first. The
registry side asserts that every non-lib entry *declares* a Skill, that a lib declares none, that every
named skill exists, and that an exemption names a parameter the script actually has.

**A correction to yesterday's own record, made in `CHANGELOG.md` rather than left standing.** The `v3.3.0`
entry claimed the release push's ruleset bypass "was not written down anywhere before now". It was:
Sylvester's lens has carried the `main-ci-gate` ruleset, its bypass list, which account holds which right,
and the caveat that the Write bypass is only safe without external collaborators, since July 15, 2026. The
rule this repo already has for it — check whether the docs answer it before reporting a finding as new —
applied and was not followed.
