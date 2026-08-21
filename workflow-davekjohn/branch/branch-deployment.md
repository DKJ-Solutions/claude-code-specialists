## `feat/branch-files-say-reread-me` deployment

### What does the change on this branch deploy to main?

The two scripts that rewrite `workflow-davekjohn/branch/`'s pair now **say so where they print those
paths**, and `BRANCH-portable.md` states it for the session that did not run them. Reported by Dave as
something he sees often, filed as
[#817](https://github.com/DaveKJohn/claude-code-specialists/issues/817).

**The symptom.** A `Write` to `branch-deployment.md` or `branch-cycle.md` fails, recovers on a re-read, and
shows in the terminal as `Error writing file`. Underneath it is the editor's staleness guard -- *"file has
been modified since read"*. Nothing is lost and nothing is broken: one read re-syncs it and the next write
succeeds. What it costs is a round trip and, worse, a line that reads as a broken tool to whoever is
watching.

**Why these two files and no others.** They are the only ones in a repo that a script and a session write
**alternately**, twice per branch cycle: `new-branch.ps1` creates them, the session writes the entry and
the step list, `fold-changelog-entry.ps1` resets both after the merge. Every one of those script writes
invalidates what the session had tracked. Measured over three full cycles in one session: **2** refused
writes, **3** stale notices, **0** cases of anything clobbered -- and the refusal lands on the *first*
write after a script touched the file, so it is the second and later branches of a sitting rather than the
first. `open-pr.ps1` is **not** a third event, checked rather than assumed: its two `WriteAllText` calls
write the PR body to a temp file.

**What is deliberately not changed, said first.** The refusal is the harness's, and it is correct -- it is
what stops a session overwriting an out-of-band change it never saw. Nothing in this tree, no seam and no
hook can alter when it fires, and a repo-side "fix" that suppressed it would be removing a working safety
check to tidy a log line. So the subject is **legibility, not correctness**, which is the report's own
framing.

Both halves of it shipped, because they reach different readers:

- **`Get-BranchFilesRereadNote`** in `scripts/lib/entry-scaffold-lib.ps1` -- one source for one sentence
  printed by two scripts. `new-branch.ps1` prints it after writing the pair and **only** then: a rerun that
  kept both files changed nothing anybody was tracking, and advice about a staleness that did not happen
  trains a reader to ignore the line on the run where it is true. `fold-changelog-entry.ps1` prints it after
  the reset, gated on the branch entry having actually been folded so a legacy root entry -- removed, never
  reset -- gets no advice about a file it never had.
- **`BRANCH-portable.md`** gains the section, next to the reset state it already describes. The mechanism
  was documented there; its consequence for whoever edits those files next was not.
  `workflow-davekjohn/CLAUDE.md` points at it from the local layer.

Both suites cover it in both directions -- printed on the run that rewrites, absent on the run that does
not -- asserted through the shared function so a rewording cannot drift the test, plus one phrase assert so
the line still has to mean re-reading.

**Score:** 2

#### What makes this change extra special

Every consumer hits this twice per branch, in every repo, on work that is otherwise going right -- and until
now it presented as a failing editor with no explanation anywhere in the tree. A consumer has no
`scripts/lint/`, no issue tracker pointed here, and no way to tell a harness guard from a broken script, so
the sentence is the whole of what they get. It also closes the reading that costs the most: that this is
something the workflow should suppress.

**Score:** 3

### Pull Request

The two branch files say, where they are rewritten, that a session must re-read them
