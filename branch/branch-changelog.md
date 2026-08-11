## `feat/one-hand-written-release-note` changelog

### Branch title

One hand-written release note, with a named section per reader

### Branch ID

20260811-082447

### Branch type

feat

### What does the change on this branch bring to main?

Two hand-written documents per release become one. `cut-release.ps1` drafts
`releases/notes/<dir>/<X.Y.Z>.md` with a named section per reader: *For consumers* (pre-filled with the
tier-2 entries), *What it is worth* and *What was still open at this release* (both empty — neither can be
generated). **A patch writes none of it** and is announced by the generated Release body alone.

**The duplication was real and it was measured before anything was merged.** At **all twelve** releases
since the internal tier existed, both documents were written, about the same changes. `v4.2.0`'s internal
note (962 words) held against the writing norm's test 2 — *does this describe our effort or their outcome*:

| | words | |
|---|---|---|
| could appear in a consumer-facing section | ~365 (38%) | and **did**, rewritten in a second register in the other document |
| could not | ~597 (62%) | including the 316-word *what it is worth*, which is not an outlier but the entire reason the organisational tier exists |

**So a blended document was refused and a sectioned one built.** A blend would have to drop the 62% or
break the norm; sections keep each register intact and write the shared 38% once. The heading *"what is
different now"* is **gone rather than moved** — it *was* the duplicated half, and the consumer section is it.

**What made this possible was the previous change, which is why the order mattered.** While the GitHub
Release body *was* the internal note, that note had to exist at every release or the page had none — the
"every release, patch included" rule was a coupling to the page, not a judgement about patches. With a
generated body the page needs no hand-written document at all, and the document model could be simplified
on its own terms.

**Three decisions that were made by weighing something rather than by preference.**

- **The cut drafts it, against a docstring that argued the opposite.** `new-internal-note.ps1` explains that
  it is a separate script so a skeleton is not committed inside the release tag. Weighed rather than
  overruled: the tag already held a 396-line unpublishable consumer draft, so "purely generated artefacts"
  was already half true. Two empty headings do not change that in kind, and it buys one artefact, one
  editing pass, and — the concrete win — an **overview row the cut points at the right document first
  time**. `Set-ReleaseInternalNoteLink` existed only because the note did not exist while the cut ran.
- **`new-internal-note.ps1` is kept, not deleted.** It ships to consumers, who receive a plugin update
  rather than choosing one, and deleting a shipped entry point is a breaking change for a flow that still
  works. Nothing in this repo's chain calls it. The eleven documents in `releases/consumer/` and the twelve
  in `releases/internal/` stay where they are: published records.
- **The seam keeps its name.** `Get-ReleaseConsumerBumps` was renamed from `Get-ReleaseHighlightsBumps`
  one day earlier; a third name for the same knob would be churn a consumer pays for. Its meaning barely
  moved — *which bumps get a stakeholder-facing document* — so it now answers *which bumps get the
  hand-written note*, with the same `minor`/`major` answer.

**Lint check 25 reads two trees now, and the rule follows the reader rather than the directory.** A consumer
reads the whole of the new file, organisation sections included, so a link into the per-PR record is exactly
as wrong there as it was before. `releases/consumer/` stays held as well: relaxing a rule over an archive
would let a repair to one of those eleven documents reintroduce what the check caught.

One bug found by the gate it was added to: the two-tree scan read `.Count` on a pipeline that yields a
scalar when only one tree exists — which is every repo until its first cut under this model. `@()` around
it, with the reason on the line.

### Significance

#### Tier 0

The release cycle loses a document, a script invocation and a second editing pass. Measured on the release
this came out of: about a third of the writing was the same material in two registers.

**Score:** 4

#### Tier 1

The organisation's half of a release is written in one place instead of being reconstructed beside a
consumer document, and a patch stops producing a document nobody asked for.

**Score:** 3

#### Tier 2

A consumer gets one document rather than two, and the section written for them is held to the writing norm
by a gate that now reads the file they actually receive. Nothing they have breaks: the old directories, the
old script and the seam name all stay.

**Score:** 3

### Pull Request

