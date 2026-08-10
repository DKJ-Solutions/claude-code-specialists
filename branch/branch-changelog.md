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

