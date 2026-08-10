# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `feat/nolan-owns-cost-not-only-tokens` changelog

### Branch title

Nolan owns cost in whichever resource the repo spends, wall-clock included

### Branch ID

20260810-225007

### Branch type

feat

### What does the change on this branch bring to main?

The performance engineer owned **token and context budget** and nothing else. He now owns **cost**, in
whichever resource a repo actually spends — that budget, and **wall-clock**: test suites, lint gates, CI,
and any script a branch cannot avoid. The agent def, the portable playbook and the routing all say so.

**Not one word of his craft changed, which is what made this a widening rather than a new specialist.**
*Measure, name the location and the current cost, propose the saving, hand the fix to whoever owns that
surface* is silent about which resource is being counted. So the alternative — a separate build/CI
specialist — was declined: it would have duplicated an entire craft in order to change the unit.

**The measurement behind it, taken on pickup rather than assumed.** Nolan is named **12 times** in this
repo's record and **all 12 are in `1.x` and `2.x`**, the last around August 2 — nothing across the twelve
releases of `3.x` and `4.x`. That is not a specialist who does little: his roster-description finding is
still cited in `CLAUDE.md` today (~750 tokens per session). It is a proven craft whose **one resource ran
out of surface** — his lens now records two separate *leave it alone* verdicts, both reached by measuring —
while a second resource went unowned. Meanwhile a release here takes about thirty minutes, seventeen of it
gate time, and nobody was responsible for that number.

**Three craft rules travel with the widening, because wall-clock fails in ways tokens do not.**

- **Count the invocations, not the run.** A gate that runs locally, again on the way out, and again in CI
  costs three times per unit of work, so halving it buys three times what one run suggests — and this repo
  is the worked example: the same 30 suites run three times per release-with-documents, deliberately,
  because the release commit meets no CI.
- **Separate what blocks a person from what does not.** Eight minutes of CI a human waits on is a
  different cost from eight minutes running behind them, and a proposal that shortens the second is worth
  close to nothing.
- **Name the fixed cost and the frequency separately.** Where a cost is fixed per event, halving how often
  the event happens is as real a lever as making it faster, and usually needs no code. Live here: 16
  releases in 10 days, each carrying that fixed ~17 minutes.

**And one hard rule, stated as a prohibition because it is the obvious wrong answer.** The fastest way to
shorten any gate is to stop running it, and that is a transfer of risk rather than a reduction in cost.
Nolan may put a coverage-for-time trade on the table with both sides quantified and labelled as such; he
may never present it as a saving. Several of this repo's gates exist *because* of a measured failure, so
that call is not his.

His new working partner is the test engineer: a slow suite is a cost finding and a testing decision at the
same time, and which asserts can be narrowed requires knowing what each one protects.

### Significance

#### Tier 0

The thirty minutes a release costs here now has an owner, and the baseline is written down instead of
re-measured every time somebody wonders.

**Score:** 3

#### Tier 1

A specialist who had produced nothing in twelve releases is working again, on the bill the organisation
actually pays.

**Score:** 3

#### Tier 2

A consumer with a real test suite spends far more wall-clock than this repo does, and until now no
specialist in the team owned that. The three counting rules are the transferable part.

**Score:** 4

### Pull Request

Plugins: team-alpha

[PR #588](https://github.com/DaveKJohn/claude-code-specialists/pull/588) · merged 2026-08-10

---

## `docs/v4-2-0-release-documents` changelog

### Branch title

The v4.2.0 release documents

### Branch ID

20260810-212615

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the minor tagged earlier today: the
**consumer document** and the **internal summary**. They arrive via a branch and a PR because the release
commit is already tagged, and neither is one of the two changes allowed to land directly on the trunk.

**This is the first cut whose consumer document went through the renamed seam, and that is worth recording
because the failure it could have had is silent.** An unrecognised seam falls back to `@()` — the tier
switched off — so a rename that had gone wrong anywhere would have produced a minor with no document for the
reader it was cut for, and reported success. `-NoPush` was used for exactly this: the cut was inspected on
disk before anything was public, and `releases/consumer/4.x/4.2.0.md` was there.

**397 generated lines became about 110, and this is the first release where the seven tests existed before
the document rather than being derived from it.** The draft is the tier-2 entries verbatim, and all seven of
this release's entries are tier 2, so the draft was the entire changelog in the words its authors wrote for
someone reviewing a diff.

**The ordering is the editorial decision worth arguing about.** Test 3 asks for urgency, and the two
checkable items are not equally urgent: the unreachable-seam check leads because it is the only one with an
action attached and it identifies its own audience — any repo whose branch types are not the canonical four
— while its symptom was *silent* under 4.0.0 and *loud* under 4.1.0, so a reader may have met the second
half without ever learning the first. The missing skill is second: the symptom is starker (pure absence,
nothing logged anywhere) but there is nothing for them to repair beyond updating.

**The rename got its own section instead of a line under "what is new", and that follows from test 4.**
"Say `no action needed` explicitly, or say exactly what the action is" is answerable here in two parts that
pull in opposite directions: the old seam name keeps working, *and* a consumer's own directory is not renamed
for them by anything. A half-done rename is undetectable, because either name alone satisfies the reader. That
is a paragraph, not a bullet.

**Test 2 cost the draft its best material, correctly.** The entries carry the measurements this release was
argued from — 0 findings over 22 records, 124 findings of which none were true, three candidate rules over
eleven documents — and almost all of it describes our effort rather than the reader's outcome. What survived
is the one measurement that tells them something about *their* risk: that only one of the seven tests could
be automated here, and that they should run the seven over their own documents rather than adopt our answer.

**The internal note names the single action this release requires, which the tier normally cannot.** Tier 1
deliberately carries no file names, no commands and no code — so on a release that asks the reader to do
something, the instruction lives in the attached consumer document and the body has to say so rather than
leave it to be found. Its "what was still open" section is written as a snapshot, including the check that
was measured and declined a second time at this release, with its count, so the next person spends a minute
on it instead of an afternoon.

### Significance

#### Tier 0

The record is complete: both documents exist, and the overview row's Version cell points at the internal
note rather than at the development notes.

**Score:** 2

#### Tier 1

The internal note is the published Release body, so this branch is how the release is communicated at all.
Without it the page would be the development notes.

**Score:** 3

#### Tier 2

This is the only page that tells a consumer about the two checks, one of which has a real cost and an
identifiable audience. Unwritten, that check sits in 397 lines of entries written for somebody else — so the
document is the difference between finding it and not.

**Score:** 4

### Pull Request

[PR #586](https://github.com/DaveKJohn/claude-code-specialists/pull/586) · merged 2026-08-10

---

## `fix/the-consumer-draft-strips-its-branch-metadata` changelog

### Branch title

The consumer draft no longer ships the branch administration it means to strip

### Branch ID

20260810-221304

### Branch type

fix

### What does the change on this branch bring to main?

The generated consumer draft carried four sections per entry that are administration for its reader:
`Branch title`, `Branch ID`, `Branch type` and `Pull Request`, plus the `Plugins:` line. Measured on the
`v4.2.0` draft: **125 of 396 rendered lines, 32%** — and `Branch title` printed **directly beneath the
heading it had just become**, seven times, in the one document written for someone paying for the product.

**The intent was never in doubt, which is what makes this a defect rather than a change of mind.**
`Convert-EntryHeadingToTitle`'s own header says this document's reader *"has no PR numbers"*, and the draft
shipped seven. Rendall's lens states the metadata *"is stripped"*.

**The reason, verified before the repair rather than inferred from the symptom — and it is not a missing
stripper.** The stripping works and always has: it operates on the **heading**, which is where the PR
number, type and date lived until August 6, 2026. The branch dossier then moved that metadata into named
`###` sections and nothing followed it down. So the heading rewrite kept succeeding while the same facts
arrived one line lower. The duplicated `Branch title` is the proof: it can only appear under a correct
readable heading if the rewrite ran *and* the section survived.

`Remove-EntryAdminSections` drops the four, `Remove-EntryPluginsLine` drops the line, both behind a new
`-StripAdminSections` on `Format-RankedEntries` that only `Build-ConsumerNotes` passes. Re-rendered from the
real pending entries: **396 lines to 271, no leftovers, and the headings still the readable titles.**

**Three details that are the actual engineering, each one a thing that would have gone wrong quietly.**

- **The strip runs strictly after the heading rewrite**, because that rewrite *reads* the `Branch title`
  section this pass deletes. Reversed, every change in the document would be listed as
  `` `fix/x` changelog `` — a branch slug, published. That is the third instance of the read-before-strip
  trap `-RankByTier` and `-StripSignificance` each document one case of, so an assert now pins the **order**
  rather than only the removal.
- **Retired section names are removed too**, and a miss matters more in a remover than in a reader: a reader
  that misses `Type of change` returns nothing and its caller notices, while a remover leaves the section
  standing in the document that travels outward. `CHANGELOG.md` and every consumer's tree hold both names
  right now.
- **The record keeps every one of them, and that asymmetry is asserted rather than assumed.** Once the cut
  empties `CHANGELOG.md`, the development notes are the last place an entry's administration and its ranking
  justification live. A strip that reached them would delete the audit trail instead of sparing a reader.

`Remove-EntryPluginsLine` gets a production caller back. It had none for two days — the per-plugin
CHANGELOG it was written for was retired on August 8 and the function was deliberately kept because the line
it strips still existed. Right conclusion, wrong reason: what wanted it was not the line surviving but a
reader who should not see it, and that reader was already being handed it.

Found while measuring why a release takes about thirty minutes. The document work is the hand-written half,
and a third of what a person had to read before writing was administration nobody meant to publish.

### Significance

#### Tier 0

The draft edited at every release is a third shorter, and the noise removed is exactly the kind that has to
be read before it can be skipped.

**Score:** 3

#### Tier 1

A cheaper release cycle, but only by minutes and only for whoever writes the documents.

**Score:** 2

#### Tier 2

The release document written for consumers stops carrying branch ids, prefixes and PR links — 32% of it was
this repo's own administration.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #587](https://github.com/DaveKJohn/claude-code-specialists/pull/587) · merged 2026-08-10

---

