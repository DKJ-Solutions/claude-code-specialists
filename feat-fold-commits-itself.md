### The fold can commit itself, within the scope the exception allows · Feat · 2026-08-02

`fold-changelog-entry.ps1` folded the entry and removed it, and then stopped — the commit around it was
typed by hand every time, four times in the session that prompted this. That is the house's own
"noticed once, automated the second time" trigger, and it is also the step where a mistake is least
visible: the fold itself is proved by the lint gate, while the commit is retyped from memory.

`-Commit` now makes that commit and `-Push` (which implies it) pushes. **Both are opt-in and the default
is unchanged**, deliberately: this commit lands directly on `main` under one of the two named exceptions
to "never commit directly", so it has to be asked for — the same reasoning that makes `teardown.ps1`
require `-Apply`.

**The scope limit is now enforced by git rather than intended by the operator.** The commit names
`CHANGELOG.md` and the folded entry files as its pathspec, so anything else modified — or already
staged, which a plain `git commit` would sweep in — cannot land in it. That property is exactly what the
direct-on-`main` exception was granted for, and it is covered by a test that stages an unrelated file
before the fold runs and asserts it stays out.

`-Push` is separate from `-Commit` for a reason of the same family: a fold commit sitting unpushed on
`main` looks folded locally and unfolded to everybody else, which is the silent half-state this repo
keeps rediscovering the expensive way.

**One bug found by the tests before it reached anyone.** Naming an untracked path makes `git commit`
fail on the pathspec — and by then the fold has already deleted the entry file, so the run would end
with the changelog updated, the entry gone, and nothing committed. The normal flow never reaches it,
because the entry arrives on `main` with the merge and is therefore tracked; it would have waited for
the first person to fold an entry they had never committed. The commit now takes its entry paths from
the git index and says out loud which files it left out.
