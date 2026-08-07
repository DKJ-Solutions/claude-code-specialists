## `feat/park-says-what-it-saved` changelog

### Branch title

A park says which half of the work it saved

### Branch ID

20260807-204139

### Branch type

feat

### What does the change on this branch bring to main?

A park commit now names its scope: `park: <branch> (all outstanding work)` against
`park: <branch> (the branch files only)`. Both parking entry points -- `park-branch.ps1` and
`new-branch.ps1 -Park` -- run one implementation, `Invoke-GitPark` in the new shared `park-lib.ps1`.

**They wrote the identical subject while committing different things.** Both said
`park: <branch> (work parked for later)`, but `-Park` commits only the two `branch/` files while
`park-branch` commits everything outstanding. So afterwards the log could not answer the single question a
park is asked later -- *which half of my work is on origin?* -- and the answer matters most exactly when
you are on the other machine and cannot look.

**The scope and the words are now ONE decision.** `-Scope` picks the pathspec that is committed and the
phrase that describes it, from one map, so a caller cannot commit one scope and announce another. That is
the same defect one level down, closed before it can happen rather than after.

**What was deliberately NOT done, and why, since both were on the table:**

- **Neither script was deleted.** The proposal was to drop `-Park` as "parking a branch with nothing in it
  yet", and the measurement refutes it: of **three** park commits in the whole history, **two** came from
  `-Park`. The two entry points are two *moments* -- at creation and mid-work -- and both are used. What
  was wrong was never that there are two, but that the record could not tell them apart.
- **`park-branch` did not gain a scope switch.** The issue's direction was "one thing with an option", and
  the shared implementation plus the naming commit already delivers what that was for. A switch on top
  would invent a use nobody has had: all three real parks were at their entry point's natural scope. This
  repo does not build the repair for a failure that has not happened.
- **The script was not renamed to `origin-save`.** Recorded in the issue as a suggestion rather than a
  decision, and it is consumer-visible -- a shared script with its own skill page, the same care that
  retiring `new-changelog-entry.ps1` needed. It is put to Dave rather than taken.

**One inaccuracy fell out of the work.** `branch/README.md` claimed both parks "commit **both** files",
which is true of `-Park` and false of `park-branch`. It survived because nothing made the difference
visible; the commit subject does now.

**And the suite could not see the defect it was closest to.** `park-branch.tests.ps1` checked the exit
code, the working tree, the commit contents, the push and the upstream -- but of the subject only that it
began `park: <branch>`, which both scopes satisfied. Both suites now assert the scope phrase, read from
`Get-GitParkScopes` rather than retyped, so rewording a scope stays a one-place change.

The lib is its own file rather than another function in `native-capture-lib.ps1`, where the test-suite
gate landed days earlier: that file's note asks the next person not to widen it again, and a park is not a
gate. The cost is one registry entry and one mirror -- nothing in it is repo-owned, so no contract row
follows.

### Significance

#### Tier 0

The log answers the question a park exists to answer. Two copies of four git steps became one, and the
copy that drifted did so in the half nothing was watching.

**Score:** 3

#### Tier 1

A parked branch is how work crosses machines, and a colleague reading that history now sees what was
actually saved rather than a sentence that fits either case.

**Score:** 2

#### Tier 2

Both scripts are plugin-carried, so a consumer's park commits start naming their scope and a new shared
lib arrives with them. Scored 2 rather than 3 because parking is occasional -- three times here in the
whole history -- so most consumers meet it the first time they park after the update, not the same day.

**Score:** 2

### Pull Request

