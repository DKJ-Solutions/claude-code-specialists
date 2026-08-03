### The highlights tier moves to the shared cut · Feat · 2026-08-03

**Phase 2 of [#417](https://github.com/DaveKJohn/claude-code-specialists/issues/417)**, and the half
phase 1 deliberately left out. Phase 1 shared `cut-release.ps1` with five seam knobs; knob 2 — the
highlights tier — was named in the issue but is a feature to port rather than a switch to flip, so it
waited. It is here now: a consumer generates its stakeholder document from the shared script instead
of from its own fork, which closes the divergence the issue was opened about.

**What the tier is.** A second rendering of the same release, written for **non-developers** (Dave's
rule, July 13, 2026): `releases/highlights/<dir>/<X.Y.Z>.md` plus a self-contained, print-ready
`.html` of it (open → Ctrl+P → PDF). The stakeholder categories come first; everything else lands
under an explicit "remove before publishing" marker. **The tool marks the cut, it does not make it** —
what a stakeholder should read is an editorial judgement, and a generator that silently dropped the
developer half would make that judgement for the release manager while hiding that there was anything
to decide.

**Knob 2 needed three functions, not one.** "The highlights tier" turned out to be three independent
questions, and folding them into one config object would have left the script contract a single record
whose `Returns` line could not name an actionable default for any of them:

| function | question | fallback |
|---|---|---|
| `Get-ReleaseHighlightsBumps` | whether, and for which bump types | `@()` — tier off |
| `Get-ReleaseHighlightsStakeholderTypes` | which branch types a non-developer is the audience for | `@()` — no split |
| `Get-ReleaseHighlightsWording` | the marker text + the `<html lang>` attribute | the English defaults |

All three are OPTIONAL, taking the contract from nineteen records to twenty-two. The developer half is
**derived** as "every category not named stakeholder-facing", not configured: a branch type added later
is then reviewed by default rather than published by default.

**All three are empty in this repo, and that one is a statement about the product rather than a
preference.** This repo's release audience *is* developers — a consumer reads `RELEASE.md` and the
per-plugin `CHANGELOG.md` to decide whether to update a plugin. There is no non-developer stakeholder
for a marketplace of subagent definitions, so the generated document would have no reader and the
release manager would be asked to delete a "developer-only" block that was in fact the entire release.
They stay declared anyway, because a consumer reading `repo-config.ps1` as the model needs to see the
switch and why it is off — the same argument that put `Get-ReleaseLiveMarker` there with an empty
string.

**The bug worth recording, because the tests now guard it from both directions.** The first
implementation stripped each entry's heading metadata *before* handing the entries to
`Format-CategorizedEntries` — which reads the branch type **off that same heading**. Nothing threw:
every entry fell into the `Other` catch-all, the stakeholder half came out empty, and the whole release
ended up under the "remove before publishing" marker. A generated document asserting that the entire
release is internal is exactly the kind of wrong that gets published. So the reduction happens *inside*
the renderer (`-BareTitles`), after the type has been read, and a regression test asserts both the
correct path and the collapse the wrong one produces.

**Verified byte-identical, the same bar phase 1 set.** A probe built the release notes, the
`CHANGELOG.md` rewrite and a `RELEASE.md` card from this repo's real nineteen pending entries against
`release-lib.ps1` as it stands on `main` and against this branch: identical, character for character,
all three. The tier being off means the new code path is never entered here.

**One deliberate difference from the source this was ported from.** There, both halves render their
categories at `##`, which puts the developer categories at the same level as the marker heading meant
to contain them — so the block reads as ended rather than nested, and an HTML render shows it that way.
Here the marker sits at `##` and its categories one level under it. The consumer's generated highlights
therefore gain a level of nesting they did not have; nothing else about them changes.

**Two stale claims fixed on the way, both left behind by phase 1 and both load-bearing for a reader.**
`check-script-contract.ps1`'s own docstring still said `cut-release.ps1` was "genuinely workshop-only…
not mirrored and not part of the consumer contract" — directly above the eight cut-release records in
that same file. And the `cut-release` skill still said "no script mirrored, deliberately", and told the
release manager to move the `<- LIVE` marker by hand, which
`Convert-ChangelogForRelease` has done automatically since phase 1. Corrected rather than left
standing: a reader who takes either at face value concludes the records are a mistake, or repeats work a
script already did. What was true in the original reasoning survives and is stated — the lockstep bump
*is* marketplace-specific; it just needed one seam function rather than a forked script.

**Tests: 219 asserts in `release-lib.tests.ps1`** (up 33 — the two renderers, the heading reduction with
its five degenerate-input guards, the stakeholder/developer split, the ordering regression, and the
HTML page's self-containment), the contract check's deliberate drift counts moved **19 → 22**,
`cut-release-guardrail.tests.ps1` gained the "every planned file is checked before the first write"
guard, and `repo-config.tests.ps1` asserts the tier is **off** here — so switching it on becomes a
decision rather than a release that quietly grows two files.

**Two limitations left in place on purpose, both asserted so they stay known rather than becoming
surprises.** The HTML renderer handles headings, rules, paragraphs, `**bold**` and `` `code` `` — link
markdown passes through literally, exactly as in the source. Widening it would change what the
consumer's existing highlights pages look like, which is a separate decision from moving the tier.
Escaping runs before any markup pass, so contributor-authored changelog prose cannot inject a tag into
the page.
