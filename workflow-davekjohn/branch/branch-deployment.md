## `docs/branch-portable-entry-shape` deployment

### What does the change on this branch deploy to main?

`BRANCH-portable.md` was half-migrated on the entry's sections, and half-migrated is worse than stale: it
named the retired shape and the current one on the same page, with nothing saying which was live. A reader
of line 61 learned their entry had "Significance sections", read line 71 and looked for a `Branch title`
section, then met `extra special` further down. The scaffolder writes two `###` sections and neither
retired name is one of them.

Four claims were repaired and a fifth found on the way — the page still said `new-branch` fills in "the
branch type", a section it stopped writing on August 16. The durable half is that the page now **cites the
seams** (`Get-EntryPrTitle`, `Get-EntryWrittenSectionKeys`, `Get-EntrySectionHeadings`,
`Get-EntrySectionRetiredNames`) instead of restating the literals, so the next format change does not
re-break it — the entry format moved three times in four days.

`new-branch.ps1` printed the same retired name at every branch creation (*"Significance sections written at
tier 0"*), directly contradicting the repaired page. Reworded in the same pass, mirror rebuilt.

**Score:** 3

#### What makes this change extra special

This page is **payload**: it reaches every consumer by plugin update rather than by anyone choosing it,
and it is instruction text — the expensive kind of wrong. It did not merely fail to help; it told a reader
to write a section no gate accepts and no parser reads. The same holds for the scaffolder line, which every
consumer sees on every branch they create.

The `[entry-shape]` lint check could not catch this and deliberately never will: it holds *numeric* claims
about section counts, not section **names**, because name-matching accuses two correct documents (the
retired entry sections are live PR-template headings). So the only defence for a consumer was a page that
told the truth.

**Score:** 4

### Pull Request

BRANCH-portable.md describes the entry the scaffolder actually writes
