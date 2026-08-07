## `feat/pr-title-is-derived` changelog

### Branch title

The PR title is derived: the type from the branch, the words from the entry

### Branch ID

20260807-185602

### Branch type

feat

### What does the change on this branch bring to main?

The PR title is no longer typed. `open-pr.ps1` composes it as `<branch type>: <the entry's title section>`
-- the type off the branch prefix, the words out of `branch/branch-changelog.md` -- so the sentence is
written **once**, at `new-branch -Title`. The entry's first section is renamed to match what it actually is:
`### Branch title`, not `Branch description`.

Two issues, one change, because they are the same defect from two sides:

- **[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506)** -- the same sentence was typed
  twice, once into the entry at creation and once into `open-pr -Title` at the end, with nothing holding
  the two together. One of them is what `CHANGELOG.md` and the release documents carry; the other is what
  the PR is called; and which one a reader met depended on where they were standing.
- **[#505](https://github.com/DaveKJohn/claude-code-specialists/issues/505)** -- Derek's manual has always
  said the PR title mirrors the branch type. Measured August 7, 2026: the last **five** merged PRs
  (#499-#503) all lacked it, while every commit and every merge line in the graph carried its type. Same
  shape as `chore/` and the `final` rule -- a rule that lives in a document, is never measured, and is
  therefore silently broken. Composing the title fixes it by construction rather than adding a third check
  on the second answer.

**`-Title` is accepted and ignored, not removed**, and warns once, naming the title the entry actually
gives. Every branch in flight -- here and in every consumer -- passes one right now, and consumers receive
these scripts through a plugin update rather than by choosing to; a removed parameter turns all of those
into "A parameter cannot be found" at the end of a finished branch. An **override** was the alternative and
Dave declined it in the issue: an override is a second source of the title, which is the thing being removed.

**A PR is never created nameless.** The emptiness gate already refuses an entry with no title, but `-Force`
waves that gate through, so the create path checks again and names the entry rather than letting `gh`
complain about a flag.

**And a pre-split entry still opens a PR.** Such an entry has no title section at all -- its title WAS the
heading -- so the words fall back to that heading with its administrative fields dropped, via
`Convert-EntryHeadingToTitle`, the same rule the highlights document already uses. The fallback keys on the
section being ABSENT rather than empty: an entry that has the section and left it blank is an author who
has not written the title yet, and falling back there would hide that behind a plausible-looking PR.

**Two readers were quietly wrong, and the rename is what exposed them.** Both asked a per-section question
of the flattened list of every retired heading -- sound only while every retired name happened to belong to
a section no other document carried:

- the significance stripper would have accepted an entry's empty **title** heading as the significance
  block's and deleted it;
- the entry-versus-step-list discriminator would have read the step lists of early August -- which carry
  `Branch description` -- as **entries** again, the exact confusion the two-file split was made to remove.

Both ask their own section now. Nothing is lost by the narrowing: an entry old enough to carry
`Type of change` carries two other retired entry-only headings as well.

**The lint needed the same repair one section to the left.** Its split-entry rule knew the retired names of
`What` but not of the opening section, so the moment that section was renamed all six pending entries were
reported as SPLIT -- two dozen false accusations is how a check gets switched off rather than heeded, which
this repo has now measured three times. A rename is not a one-line change while any reader knows only the
new name.

**One fixture was proving the legacy path against a legacy format that never existed.** It carried
`### Title - Feat - 2026-07-21`; that hyphen shape appears **zero** times across `releases/`, where every
entry uses middots. Harmless while nothing parsed the heading -- and the PR title now does, so the fixture
would have asserted the wrong title. Corrected to the shape the record actually uses.

### Significance

#### Tier 0

Two facts that had to agree by hand now agree by construction, and the one that was never checked -- the
type prefix -- cannot be omitted at all. The rename also cost two silent reader bugs their hiding place.

**Score:** 4

#### Tier 1

The PR list becomes readable by type at a glance, as the commit graph already was. Nobody has to remember a
convention that five consecutive PRs forgot.

**Score:** 3

#### Tier 2

`open-pr`, `ship-pr`, `new-branch` and the entry format are all plugin-carried, so a consumer's PR titles
start composing themselves and their entries gain a renamed first section -- read under both names, so
nothing they have in flight breaks. Their `-Title` calls keep working and say so.

**Score:** 3

### Pull Request

