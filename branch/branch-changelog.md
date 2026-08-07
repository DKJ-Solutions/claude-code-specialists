## `feat/one-source-for-the-entry-shape` changelog

### Branch title

A document that says how many sections an entry has is held to the scaffolder

### Branch ID

20260807-211915

### Branch type

feat

### What does the change on this branch bring to main?

The lint gains **check 20**: any document claiming a number of `###` sections for a changelog entry is
held against the count `Get-EntrySectionHeadings` actually writes. And the document that measurement
caught is repaired -- `05-06-extension.md` still described the pre-dossier shape, "just the title" and
three sections, a day after the format moved to a branch heading and six.

**Dave chose a check over a clear-out.** [#508](https://github.com/DaveKJohn/claude-code-specialists/issues/508)
measured the entry format described in about ten hand-maintained places against two that cannot drift, with
two of the ten stale during a sweep that was looking for exactly that. Deleting the shape from every
document and pointing at `branch/templates/` was the alternative; it costs every reader on every read,
while a check costs nothing per read.

**The rule was chosen by measurement, and the first three candidates were rejected by it.** This is the
part worth keeping, because the obvious rule is the wrong one:

| candidate | findings on the real tree | verdict |
|---|---|---|
| two or more section NAMES together, one retired | 6 | **all six false** |
| the same, minus units marked as history | 3 | 2 false |
| fenced skeleton blocks only | 0 | clean, but covers one of three known drifts |
| **a claimed section COUNT vs the scaffolder's** | **4 (3 correct, 1 stale)** | **clean, and covers every known drift** |

Name-matching fails on a collision nobody would predict: **`What does this change do?` and `Type of change`
are retired entry sections *and* live headings of `.github/pull_request_template.md`.** So a name-matcher
accuses two correct documents of being stale for describing the PR body accurately, and would be born red
behind an exemption list -- the shape this repo already paid for with `Get-RosterIgnoredIds`. A count has
none of that: it is a fact the scaffolder owns, stated in a form that cannot mean anything else, and both
recorded drifts made exactly that claim.

**The level marker is what keeps the haystack honest.** Without requiring the `###` between the number and
the word, the pattern matches ordinary prose -- "one section apart", "two sections went in the same
movement" -- which measured **18** disagreements of which 17 were noise. With it: four claims in the whole
tree, small enough to read by hand, and it was read by hand before the rule was written.

**Two defects surfaced while wiring it, each caught by something rather than reasoned about:**

- The exclusion of the branch working files did nothing, because `Get-BranchFilePaths` returns forward
  slashes while the scanned path uses backslashes. The check reported the step list of the very branch
  adding it, for **quoting** a stale count while explaining it.
- Two of the three new asserts failed against a check that was behaving correctly: they matched
  `[entry-shape].*README.md`, which also matches the **coverage line**, where the check names
  `branch/README.md` while explaining what it does not exclude. An assert that can match the check's own
  prose is testing the note, not the rule.

**Also recorded here, so neither returns as an open question:** the `origin-save` rename proposed alongside
[#507](https://github.com/DaveKJohn/claude-code-specialists/issues/507) was **declined** -- the confusion it
was meant to cure was which half of the work got saved, and that is what the naming commit fixed; a rename
would have cost a consumer-visible transition for clarity already delivered.

### Significance

#### Tier 0

The one format this repo changes most often now has a gate on the one thing documents say about it that is
checkable, and the document that was already wrong is right again.

**Score:** 3

#### Tier 1

A colleague reading the release manager's own lens was being told the changelog entry has three sections
and two names that no longer exist. That page is where somebody goes to learn the format.

**Score:** 2

#### Tier 2

The lint itself is repo-owned -- a consumer runs their own via `Get-LintScript` -- so the check does not
travel. What does is one paragraph in the plugin-carried `park` skill recording that the rename was
settled. It prevents a consumer proposing the same rename and being told, months later, that it was
already weighed.

**Score:** 1

### Pull Request

