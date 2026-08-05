### A significance score per entry, and the order follows it · Feat

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | a consumer's next entry file looks different and their next cut asks for scores -- noticed the same day, without anything breaking: entries written before this still fold |
| 1 | 4 | the release documents now order themselves by consequence, so the most consequential change leads instead of sitting third under whichever heading its branch prefix produced |

Closes [#467](https://github.com/DaveKJohn/claude-code-specialists/issues/467).

The tier model answers how far a change **reaches**, and therefore which document an entry appears in.
This adds the second axis: how much it **weighs** for that document's reader, and therefore **where in
it** the entry sits. Both are now declared in one **impact table**, which replaces the `Tier: N` line:

```text
| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | consumers must re-add the marketplace under its new name; installs break without it |
| 1 | 4 | the routine version bump stops needing a developer |
```

**The tier is the row, and that is what the shape buys.** The ladder is cumulative, so a change consumers
notice is also a change colleagues get something out of — as rows that is impossible to claim halfway. The
rows an entry has *are* the documents it appears in, and each row is that document's reader answering their
own question. The score cells are scaffolded **empty**, deliberately unlike the old `Tier: 0` default: 0
was a harmless final answer, while any scaffolded score would be a guess at a **ranking** — the exact
failure the retired highlights marker was measured on.

**1 to 5 against a written rubric** (`Get-EntrySignificanceRubric`, overridable per repo), in the shape
severity levels and ITIL impact levels use: 5 is *the reader must act*, 1 is *nothing changes for them
today*. That is what makes the number a measurement rather than a mood, and it is why the score is
comparable across releases. The **`Why` is required** and is the lasting half — the rubric says which band,
the `Why` says why *this* change is in it.

**The fold is the only moment `CHANGELOG.md` can be ordered**, because the cut empties the tier sections:
whatever order the fold leaves behind is what the release documents inherit, since they read the section in
document order and sort nothing. That makes the ordering reproducible across two moments days apart with
nothing re-estimated. Insert-only, never a re-sort — this commit lands directly on `main`, so a bug must be
able to misplace at most the one entry being folded rather than scramble a section it did not write.

**Where each score is read.** The highlights re-read the **tier-2** row (their reader is the consumer); the
internal note reads the **tier-1** row. **Tier 0 is never ranked** — the development note is the record:
complete and chronological. The table **survives into the record**, which is the last place each ranking's
justification lives, and is **stripped from everything that travels outward** (highlights, per-plugin
`CHANGELOG.md`, `RELEASE.md`), because a self-assigned number printed at a consumer is a marketing claim.

`cut-release.ps1` refuses a release whose tier-1-or-higher entries have not scored themselves, with
`-SkipSignificanceGate` as the escape valve — separate from `-SkipTierGate`, because one overrules whether
the release should exist and the other how its contents are ordered. `open-pr.ps1` refuses a *malformed*
table while the branch is still the only thing affected, but only **reports** a missing score: that is a
judgement about a finished change, and an author who has not settled it should not be blocked from merging.

**`Tier: N` is still read, and always will be** — "recognise both, write one". Every entry already in
`CHANGELOG.md` and in every consumer's tree predates the table, and a parser that only knew the new shape
would read all of them as tier 0: silent, correct-looking, and wrong in the direction that empties a
release. The whole mechanism switches itself **off** where a repo declares no tier split, and can be
switched off explicitly via `Get-EntrySignificanceEnabled`.

**Two bugs worth recording, both caught while building this and both now asserted.** An
`[ordered]@{ 5 = '...' }` indexer takes a **positional** index for an integer, so `$rubric[5]` asked for the
sixth element of a five-element map — the exact trap `Resolve-ChangelogTierSections` already warns about in
the same file, walked into one screen below the warning; on a longer map it would have silently returned a
neighbouring band's text instead of throwing. And `Sort-Object` is **not stable** in PowerShell 5.1, so
ordering on the score alone would let equal-scoring entries come out differently from one run to the next —
a regenerated release document differing from the published one with nothing having changed. The arrival
index is now the tie-break.

**The name was `Happiness` for one afternoon.** Dave rejected it as unprofessional, and he was right about
more than the word: *happiness* names an emotion in the reader, which an entry's author is in no position to
assert, while the weight of a change for an audience is something they can judge. Recorded alongside it
because it is the first thing anyone reaches for: **RICE and WSJF do not apply here.** They price work
*before* it is done, with effort in the denominator — they answer "what do we build next". Everything scored
here is already merged, so effort is spent and irrelevant.
