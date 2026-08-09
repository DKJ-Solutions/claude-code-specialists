## `fix/pr-body-heading-levels` changelog

### Branch title

The PR body headings start at H1

### Branch ID

20260809-131332

### Branch type

fix

### What does the change on this branch bring to main?

A PR body is now a document in its own right rather than a fragment of one. The entry's levels are
shifted up by one at the single point where the copy is made:

| in the entry and `CHANGELOG.md` | in a PR body |
|---|---|
| `## ` + the branch name | *(the PR title, not part of the body)* |
| `### What does the change on this branch bring to main?` | `# What does the change on this branch bring to main?` |
| `### Significance` | `## Significance` |
| `#### Tier 0` | `### Tier 0` |

**Why the levels differed in the first place, so nobody "corrects" them back.** In `CHANGELOG.md` an
entry is one `##` block among many, so its sections are `###` and its tiers `####`. That is right
there and wrong in a PR, where the entry is the whole document and its title is printed above the body
by GitHub. Carrying the levels across unchanged produced a body that opened at H2 with sub-sub-headings
at H4 — the typography of an excerpt. `CHANGELOG.md` and the release documents are untouched.

**One thing this could not be done without, and it is not cosmetic.** `-RefreshBody` replaces the
description by scanning forward to the next heading **at its level or shallower**. Promote the
description to H1 and leave `## Resolved issues` where it was, and that block is no longer a sibling of
the description but a child of it — so the next refresh deletes it along with the text it replaces,
GitHub closes nothing at the merge, and [the #341–#343 failure](https://github.com/DaveKJohn/claude-code-specialists/pull/343)
walks back in through the door built to stop it. `New-ResolvesBlock` therefore takes a level, and
`Add-ResolvesBlock` **derives** it from the body it is appending to rather than making a caller
remember: this repo's template is H1, a consumer's is still H2, and a hand-written `-Body` is whatever
its author wrote. Reading the answer off the text is the only form that is right for all three.

**A second thing that would have failed silently.** `-RefreshBody` located its target with `^##\s+\S`
— two hashes exactly, from a time when every template started at H2. Against an H1 template that
pattern finds nothing and the feature degrades to its warning branch on every run, reported as *"the
description was left as it is"*, which reads like a decision rather than a miss. It matches any level
now, and the suite asserts that from the script's own source.

**Back-compat, as always in this corner:** the fallback list of headings a PR may already be open under
gains the H2 form of the current wording — live for a single day, which is long enough for open PRs to
carry it. A consumer's template is untouched, keeps its levels, and keeps getting an H2 resolves block.
Promotion is fence-aware and floored at H1: a heading quoted inside a fence is sample text, and an entry
explaining this format would otherwise have its own example rewritten to say something else.

### Significance

#### Tier 0

Third and last pass over the PR body in one day, and the one that makes it read as a document. What it
also closes is two silent failures that the level change would have introduced on its own: a
`-RefreshBody` that eats the closing keywords, and a `-RefreshBody` that quietly stops working at all.

**Score:** 3

#### Tier 1

A reviewer opens a PR and sees a title, a question, and the answer — with Significance and its tiers
nested underneath rather than hanging at the same visual depth as the prose around them.

**Score:** 2

#### Tier 2

Consumers keep their own template and their own levels; the derivation exists so that stays true
without anyone configuring it. What reaches them is the repair of the two failure modes above, which
would otherwise bite the first consumer to promote a heading in their own template.

**Score:** 2

### Pull Request

