## `fix/the-fold-refuses-a-pre-flat-changelog` changelog

### Branch title

The fold refuses a pre-flat CHANGELOG.md instead of writing outside its sections

### Branch ID

20260810-090435

### Branch type

fix

### What does the change on this branch bring to main?

`fold-changelog-entry.ps1` refuses a `CHANGELOG.md` that still carries the pre-flat shape, instead of
writing an entry above the first section heading and reporting success. `cut-release.ps1` has refused over
that identical assumption — every `##` below the intro is one change — since August 5, 2026; the fold made
the same assumption and never checked it. Measured in a consumer on 2026-08-09, the day after they adopted
the entry convention (inbound
[#561](https://github.com/DaveKJohn/claude-code-specialists/issues/561)):

```text
Folded and reset: branch/branch-changelog.md (tier 1, significance 3 -- placed above 2 existing entries)
CHANGELOG.md updated.
```

Exit 0, no warning. Their "2 existing entries" were two **section headings** (`## Pull Requests` and
`## Releases`), which sit at exactly the level an entry now occupies — so the insert landed above the first
of them, outside the section they keep their entries in. The document stays well-formed, so the only way to
see it is to open the file afterwards, which is precisely what nobody does after a green fold.

**The refusal text is shared rather than written a second time.** `Get-PreFlatChangelogRefusal` in
`entry-scaffold-lib.ps1` owns the diagnosis, the list of offending blocks and the migration advice; the cut
and the fold each pass in the one clause that genuinely differs — what *that* script is about to do to a
block it cannot read (the cut empties the file, the fold writes into it). Two copies of the diagnosis is
how the two scripts came apart in the first place.

**It refuses in the pre-pass, before the first write, and it has no `-Force`.** A fold-all run writes one
entry at a time, so finding this on the third file would leave the first two folded into the wrong place with
their sources already deleted. And no valve: every other refusal in this workflow that overrules a
*judgement about content* has one, while this overrules a *fact about the document* — there is no state in
which writing into the wrong section is what the caller wanted, and the cut has no valve for it either.

**The cost is named rather than glossed.** The fold runs after a merge, so a refusal leaves an unfolded entry
on the trunk — the silent half-state this repo has measured, and the reason a missing significance score is
warned about here instead of refused. The difference is that a missing score still produces a *correct*
write, while this cannot. So the message names the file still waiting and both ways out of it, which is what
turns a half-state into a next step.

**Two entry-boundary readers moved down a layer to make it possible**, and that was the enabling change
rather than a tidy-up beside it. `Get-EntryHeadingPattern` and `Split-EntryBlocks` now live in
`entry-scaffold-lib.ps1`, following `Get-FencedLineFlags` and for exactly the reason that move recorded: the
dependency can only run one way — the fold and that lib's own suite load it standalone, while nothing loads
`release-lib` without it. The fold's own header rejects, by name, pulling three thousand lines of release
machinery into a script that runs immediately after a merge and directly on the trunk. Leaving the splitter
up in `release-lib` would have meant either that, or a second boundary rule written beside the first and free
to disagree with it about where the intro ends. No call site changed in either lib.

### Significance

#### Tier 0

Nothing here observes it: this repo's `CHANGELOG.md` has been flat since August 5, 2026, so the refusal
cannot fire. What it does buy locally is one refusal text instead of two, and one splitter instead of two —
the drift shape this repo has now paid for four times.

**Score:** 2

#### Tier 1

A consumer's misplaced entry becomes this project's problem the moment they report it, and this one was
reported the day after their migration. The guardrail also settles a question that came up twice in one
week: two shared scripts making the same assumption owe their consumer the same refusal.

**Score:** 3

#### Tier 2

This is the consumer-facing half. A repo that has not migrated its changelog now gets a refusal naming every
block it cannot read and how to migrate, at the moment it would have gone wrong — instead of a green fold and
an entry in the wrong section, discoverable only by reading the file. They receive these scripts through a
plugin update rather than by choosing to, which is what makes a silent wrong write the wrong default.

**Score:** 4

### Pull Request
