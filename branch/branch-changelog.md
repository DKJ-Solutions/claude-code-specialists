## `fix/release-row-note-root` changelog

### Branch title

The release overview row reads the note-root seam instead of a hardcoded notes/

### Branch ID

20260812-232307

### Branch type

fix

### What does the change on this branch bring to main?

`cut-release.ps1` writes one row into the release overview per cut, and its Version cell is the only inbound
link the hand-written release note has. That cell was built from a hardcoded `notes/`, so on the day
`Get-ReleaseNoteRoot` became `releases/audience` the cut began pointing every new row at a file it had just
written somewhere else. It now derives the cell from the seam.

**Caught at the `v4.6.0` cut itself** (August 12, 2026), by running with `-NoPush` and reading the row before
anything was pushed. That cut was undone locally — tag deleted, commit reset, sixteen entries restored — and
is being re-cut on top of this fix, so no tag ever carries the dead link.

**Nothing errored, and nothing was going to.** The row named a plausible path in a table of seventy-odd
identical-looking rows, and every neighbour was correct because
[#632](https://github.com/DaveKJohn/claude-code-specialists/pull/632) had repointed them by hand a day
earlier — so the single row a script wrote was the only wrong one, in the document a reader uses to find any
release note at all.

**The existing guard was written for exactly this defect and could not see it.** Two asserts in
`cut-release-guardrail.tests.ps1` already required the note root to come from the seam and allowed the
literal to appear exactly once, as the seam's own `-Default`. Both passed: they match the fully-qualified
`releases/notes`, and the escape was the bare `notes/`. That is this repo's recurring failure — a matcher
that reads as thorough and misses the instance — so the new asserts pin the Version-cell line itself, on the
absence of the short form *and* on the derivation, and were confirmed red against the reintroduced bug rather
than assumed to work.

The `releases/` prefix strip keeps the assumption the `development/` half has always made, and the comment
names the untested case (a root outside that directory would need a `../`) instead of pre-emptively building
for it.

### Significance

#### Tier 0

The overview row is how a developer here reaches a release note at all, and every cut from now on would have
written a dead one — silently, inside a commit that lands on the trunk under a direct-commit exception.

**Score:** 3

#### Tier 2

`cut-release.ps1` ships in `workflow-davekjohn`, and the consumer this hits is the exact one
[#616](https://github.com/DaveKJohn/claude-code-specialists/issues/616) added `Get-ReleaseNoteRoot` for: a
repo whose notes live outside `releases/notes/`. Answering that new knob correctly is what triggered the
broken row, so the seam arrived with a defect aimed at its only intended user, and it fails without a message.

**Score:** 3

### Pull Request

