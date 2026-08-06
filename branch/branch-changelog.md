## The impact-table strip takes the heading that introduced it

### What does this change do?

**Stripping the impact table left its section heading standing, so every outward-facing entry carried a
named question with nothing under it.** `Remove-EntryImpactTable` removed the rows and collapsed the blank
line, which was the whole job under the pre-#467 format: the declaration was then a bare `Tier: N` line
with nothing above it. Since the entry gained three named sections the table lives under
`### Who is this for`, and the entry format is explicit that the table **is** the answer rather than prose
beside it — so removing the table and keeping the heading produces a hole, not structure.

**Measured while cutting v3.6.0 with `-NoPush`, which is the only step where a human sees the assembled
artifact**: 17 empty sections in `plugins/specialists/RELEASE.md`, 17 in its per-plugin `CHANGELOG.md`, 16
in the highlights draft, 2 in each smaller plugin's card. The development notes were correct throughout —
they keep the table, so they keep its heading — which is why nothing upstream of the cut noticed. Those
are exactly the documents that travel to consumers in the plugin cache.

**A test asserted the broken behaviour, and how it got there is the more useful half of this.**
`release-lib.tests.ps1` held *"the section heading stays -- an outward document keeps its structure"*. It
arrived in [#476](https://github.com/DaveKJohn/claude-code-specialists/pull/476), the same PR that
introduced the named sections, and no document anywhere states that rule — the rationale existed only in
the assert message, written to describe what the code happened to do. This repo has met that shape before:
`Get-RosterIgnoredIds` was likewise introduced by the commit that built the check it kept quiet, and
justified in code as a decision nobody had made. **The consequence had also never been observed**, because
`v3.5.0` was cut hours *before* #476 landed; `v3.6.0` would have been the first release to ship it.

**The heading only goes when the section is genuinely empty, and that check is the point rather than
caution.** The convention says the table is the whole answer, but a strip that deletes a heading on the
strength of a convention deletes a reader's prose the first time somebody writes some. So the lines between
the heading and the next one must all be blank, the heading text comes from `Get-EntrySectionHeadings`
rather than a literal — a repo that translates its section headings gets this behaviour translated with
them — and both halves are fence-aware, so an entry quoting the heading (the entries documenting this
format do) keeps the quoted copy while the real one goes.

**Verified by falsification, not by passing.** With the new call disabled, two of the added asserts fail
and the rest still pass; restored, all 215 asserts in that suite and all 374 in `release-lib`'s pass. The
shared mirror under `plugins/specialists/scripts/lib/` was updated in the same commit.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 3 | a consumer who has adopted the entry format gets clean release cards and per-plugin CHANGELOGs from their next cut instead of one empty section per entry -- noticed the moment they open one |
| 1 | 3 | v3.6.0 goes out without the defect, and an assert that pinned undecided behaviour has been named as such rather than worked around |

### Type of change

Fix
