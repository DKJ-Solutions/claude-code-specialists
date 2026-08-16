## Branch `feat/compact-changelog-entry` changelog - '20260816-163324'

### What does the change on this branch bring to main?

#### Tier 0

The changelog entry goes from six `###` sections to two. Four of them stated something the document
already stated: `Branch ID` is now the timestamp in the entry's own heading, `Branch type` is the prefix
of the branch that heading names, `Significance` was a heading whose sub-sections already answer the
question above it, and `Branch title` never held a branch title -- it is the PR title, and it moved into
the `Pull Request` section beside the number and the merge date the fold writes there. The audience
tier's sub-heading reads `#### Higher than tier 0?` instead of naming a tier number, so the shipped
template stops telling a tier-1 consumer about tier 2.

Nothing was removed from the RECOGNISED set, and that is what makes it safe rather than merely small:
`Get-EntrySectionHeadings` still answers for all six keys, so `CHANGELOG.md`, every release document,
every consumer's tree and every branch in flight keep folding untouched. The evidence is that
`fold-changelog` (130 asserts), `release-lib` (388) and `pr-body` (112) passed without a line changed.

Two facts that used to be written into the file are resolved on read now, and each needed its own
repair to keep working: the change TYPE comes off the branch prefix in the heading -- guarded to a
`changelog` heading, because reading it off any branch heading made every step list parse as an entry --
and an unknown prefix falls back to `Get-EntryFallbackType` with the lib carrying `Chore` as its own
default, since a consumer without a `repo-config.ps1` would otherwise get no type at all.

**Score:** 3

#### Higher than tier 0?

A consumer writes this file on every branch, so a form that asks four fewer questions is felt on every
piece of work rather than once. They receive it through a plugin update: the scaffolder, the templates it
regenerates in their repo, and the `CONTRIBUTING-portable.md` and `fold-changelog` pages that describe
the shape all travel together, and their existing entries need no migration.

**Score:** 3

### Pull Request

the changelog entry shrinks to its heading, its significance and its PR link
