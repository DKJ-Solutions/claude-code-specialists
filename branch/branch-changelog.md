## `fix/pr-body-starts-at-the-answer` changelog

### Branch title

The PR body starts at what the change brings

### Branch ID

20260809-122742

### Branch type

fix

### What does the change on this branch bring to main?

A PR body now opens with the sentence that describes the change. Yesterday's cut removed the form
around the entry; this removes the entry's own front matter, which the page around the body was
already saying.

**What a reviewer met before the first substantive line**, measured on
[PR #540](https://github.com/DaveKJohn/claude-code-specialists/pull/540):

| line | why it added nothing |
|---|---|
| the **Branch title** | it **is** the PR title — `open-pr` composes `fix: <this>` from the same section and GitHub prints it above the body |
| `### Branch ID` | a creation timestamp; there is nothing a reviewer can do with it |
| `### Branch type` | the PR's **label**, and the prefix of the title one line up |

And at the bottom, an empty `### Pull Request`: the **fold** fills that section, from the merge — so in
a PR body it is a heading with nothing under it, every time, by construction.

The template's heading is therefore the entry's own question, which is what it should have been
yesterday. The reason it was not is that the wrapper sat *above* the whole dossier, so using the
question there would have printed it twice, four lines apart. Dropping the front matter is what makes
the obvious heading correct:

```markdown
## What does the change on this branch bring to main?
<!-- Filled from branch/branch-changelog.md. Opening a PR by hand? Paste that file's body here. -->
```

**`### Significance` stays, and that is a judgement rather than an oversight.** It is not front matter:
it is the author saying how far the change reaches and what it is worth to each audience, which is the
thing a reviewer is deciding about.

**`CHANGELOG.md` is untouched.** The fold still receives the dossier verbatim — branch line, ID, type
and all — which is what was chosen on August 6, 2026 and what the release documents inherit. The two
readers now differ because their readers do: a record wants provenance, a review wants the argument.

**The back-compat half is one line and it is the whole story.** `Get-PrDescription` returns `''` when
the entry has no `What does the change...` section, and `open-pr` then falls back to
`Get-EntryDescription` — today's behaviour, verbatim. A pre-dossier entry kept its description straight
under the heading, and every consumer with a branch in flight has one; they receive this script through
a plugin update rather than by choosing to. The retired section name is read too, for the same reason,
and `-RefreshBody` gained `## Changelog entry` in its fallback list so the PRs opened under yesterday's
heading stay refreshable.

**Fence-aware, and not hypothetically:** this entry quotes those headings inside a fence. A reader that
cut at the first `### Pull Request` it saw would end the description mid-entry and return something
plausible rather than failing — the worst shape, and the one this format's other readers were already
built against.

### Significance

#### Tier 0

Every PR opened here starts at the argument instead of at three restatements and a timestamp. Small per
PR, and it lands on every single one — the same reasoning as yesterday's cut, applied to what that cut
left standing.

**Score:** 3

#### Tier 1

A reviewer's first screen is now the change rather than provenance. What it prevents is the habit that
follows from a body with a preamble: scrolling past the top of it by default, which is how the
Significance sections would have stopped being read.

**Score:** 2

#### Tier 2

Consumers get the trimming through a plugin update, and their pre-dossier entries are explicitly
unaffected — the fallback keeps those PRs exactly as they were. What is worth naming is the failure it
prevents for them: a consumer who adopts the dossier form does not have to discover for themselves that
the PR body repeats its first three fields.

**Score:** 1

### Pull Request

