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

