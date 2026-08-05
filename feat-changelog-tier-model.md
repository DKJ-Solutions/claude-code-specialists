### The changelog gets three tiers, and a release must earn its bump · Feat · 2026-08-05

Tier: 2

**Every change now declares how far it reaches, and that one number decides two things it used to decide
neither of.** An entry carries a `Tier:` line while it is on its branch — `0` = only this repo's own
developers notice, `1` = a colleague on the project gets something out of it, `2` = a consumer notices. The
fold files it under the matching section of `CHANGELOG.md`, which now has three instead of one, and then
**removes the line**: from that point the section states the tier, so the fact lives in exactly one place
rather than two that can disagree.

**The old numbering was one off from what it described.** The three release documents were Tier 1/2/3 while
the entries they were built from had no tier at all. They are now 0/1/2 and the number means the same thing
in both places: `development` is tier 0, `internal` is tier 1, `highlights` is tier 2. The ladder is
**cumulative**, so a tier-2 entry is in the highlights *and* in the internal note; the development note
carries everything, tier 0 included, because it is the record rather than a summary of one.

**A release now has to earn its bump, checked before anything is written.** `Test-ReleaseBumpEarned`
(release-lib) answers three questions the version number was always supposed to answer while nothing
checked:

- **any release** needs at least one **tier-1** entry — a release made entirely of repo-internal work has
  nobody to announce it to, and cutting one spends a version, a tag and three documents on that;
- a **minor** needs a **tier-2** entry. "A minor is cut when a consumer actually notices something" was
  already the written rule; the entries now prove it, which also means the highlights document always has a
  reader by construction;
- a **major** needs **10 minors** in the current major line, on top of that minimum — a major is a *recap*,
  which is what both of this repo's majors already were (`v2.0.0` consolidated v1.0–v1.18, `v3.0.0`
  consolidated v2.2.0–v2.16.0). A pending tier-2 entry is deliberately *not* required: the accumulation is
  what earns it. The count is read off the current version's minor component, so it cannot disagree with
  itself.

`-SkipTierGate` overrules it, deliberately a separate flag from `-SkipLint`: that skips a tool, this
overrules a judgement about content.

**The "remove before publishing" marker is retired, and this is the change it was waiting for.** The
highlights document used to render every category, put `Feat`/`Fix` above that marker and leave the release
manager to cut the rest — explicitly a *proposal*, because the branch prefix does not predict impact. This
repo had the measurement: held against v3.2.0's 19 pending entries, the most consequential change for a
consumer (renaming the marketplace, which breaks every existing install) arrived on a `chore/` branch and
landed *below* the marker. The tier asks the entry's author instead, at the moment they know. Gone with it:
`Get-ReleaseHighlightsStakeholderTypes`, `Get-ReleaseHighlightsWording`, and
`Format-CategorizedEntries -OnlyTypes` — which had exactly one caller and would otherwise have stayed a
tested feature with nothing calling it.

**Nothing changes for a consumer that has not adopted the model, and that is a property of the design rather
than a compatibility layer.** A repo with no tier split declares **one** section, which is this same code
path with one tier: `Split-Changelog` parses N sections, `Build-ReleaseNotes` renders the flat document when
given no tier groups, and the bump gate reports itself **inactive** rather than refusing everything. The
opposite reading would have made a shared script refuse every release such a repo ever cuts.

**Three defects were measured during the work rather than reasoned about, and all three are now asserts.**

- **`[ordered]@{ 2 = '...' }` has an indexer that takes a positional index as well as a key**, so `$map[2]`
  returned the *third* value. In a map ordered 2, 1, 0 that handed every tier its neighbour's heading and
  filed entries under the wrong section without erroring. Found on the first run of the resolver — one
  screen below the comment warning about it. The resolver now uses `GetEnumerator()`, so no caller can
  reach for the indexer.
- **The tier loop reused `$block`**, the variable holding the release reference, so `**vX.Y.Z** … See
  [notes]` silently vanished from the changelog and a tier section appeared twice in its place. Well-formed
  markdown either way. Same class as the `$RepoRoot`/`$repoRoot` collision this repo already documents.
- **A contract record spelled the info marker in its own `Returns` text**, so one finding printed that
  marker twice and five findings counted as six. With the error marker it would have raised a blocking
  SessionStart signal for a repo with nothing wrong — the hook decides by counting them. There is now an
  assert that no record's text spells one.

**Two things are fence-aware because the entry documenting this mechanism quotes it — this one does.**
`Resolve-EntryTier` takes the first declaration *outside* a fence, and `Remove-EntryTierLine` removes
exactly what was read rather than the first regex match, so a quoted example survives the fold:

```text
Tier: 0
```

**Where the format lives, and why there.** The `Tier:` line, its validation, and the changelog section map
all sit in `entry-scaffold-lib.ps1` — the lib that already existed because the writer and the scaffold gate
must not disagree about a string. Three scripts now read this one format (the writer, `open-pr`'s new tier
gate, the fold), and the fold can only reach that lib rather than `release-lib`, so putting the section map
anywhere else would have meant two definitions of one fact.

**Test coverage, per suite:** release-lib 316 asserts (was 252), entry-scaffold 72 (was 31), fold-changelog
69 (was 45), internal-note 70 (was 54), cut-release-guardrail 24 (was 11), script-contract 259. Three
fixtures had to start copying `entry-scaffold-lib.ps1`, which is how a suite says a lib gained a sibling.

**The six pending entries were classified by hand and the classification is Dave's to correct** — #465 and
#458 as tier 2 (a new capability on shared scripts consumers run), #463 and #459 as tier 1, #457 and #455 as
tier 0 (release artefacts of an already-cut version). The migration ran as a script rather than by hand and
all six entry bodies were verified byte-identical afterwards, because re-typing section boundaries around
400 lines of prose is how one of them quietly changes.
