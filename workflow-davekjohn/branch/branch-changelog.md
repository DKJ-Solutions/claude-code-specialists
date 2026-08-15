## `feat/cut-release-driven-by-a-suite` changelog

### Branch title

The release script is driven end to end against a throwaway repo

### Branch ID

20260815-234006

### Branch type

feat

### What does the change on this branch bring to main?

**`cut-release.ps1` is now driven end to end by a suite, against a throwaway repo.** It is the
highest-blast-radius script here: it bumps every `plugin.json` in lockstep, empties `CHANGELOG.md` down
to its intro, writes the notes, rewrites the history table, commits **directly on the trunk** and tags.
Because it runs under the narrow exception to "never directly on `main`", no PR and no CI stand between
a defect and the tag — CI first sees that commit when it is already pushed and tagged. Its only
dedicated coverage was an allowlist drift guard plus asserts on its own source text.

`scripts/tests/cut-release-drive.tests.ps1` runs the real script in a child process with
`CLAUDE_PROJECT_DIR` pointed at a fresh `git init` fixture that has **no remote**, and every run passes
`-NoPush`. Seventeen asserts across three cases:

- **the happy path** — both fixture plugins land on the same patch version (lockstep is the property a
  consumer depends on, so it is asserted rather than assumed), the intro survives while the pending
  entry is gone, the development note appears at the grouped path *carrying the entry the changelog
  lost*, the history table gains its row, the tag exists and points at the commit the cut just made,
  and the tree is clean afterwards — which is how "everything written was committed" gets proven rather
  than hoped;
- **a bump the entries have not earned** — a tier-0-only changelog asked for a minor: refused, nothing
  written, no tag, so the gate demonstrably runs before the first write;
- **a new major with no section yet** — refused, tree untouched. That is the case `CLAUDE.md` documents
  as needing two hand edits on the trunk before a cut will run, and it now cannot quietly become a
  silent success.

**The fixture found its own bug first, which is the argument for this suite in miniature.** Its first
draft wrote the history table with a `| Release |` header and no `### The release list` heading. The cut
did not fail — it wrote no row and refused no major, silently. Exactly the shape a script that runs
unattended on the trunk produces when its input is a little off, and exactly what nothing here could see
before. The fixture now copies the real page's shape, and the reason is written beside it.

**The asymmetry that made this issue sharp is also gone.** `ship-pr.ps1` names its own test gap twice in
its docstring; `cut-release.ps1` named it zero times, so the absence read as coverage. It now carries a
`.NOTES` block stating both halves: what the driven suite proves, and what stays uncovered on purpose —
the push (a suite must not be able to reach a remote) and the hand-written documents, which are prose a
person writes.

Every git call in the new suite goes through the repo's own `Invoke-NativeCapture`. That is not
decoration: under `EAP=Stop`, `git add` writing its ordinary CRLF warning is promoted to a terminating
error, which is the pitfall that broke cutting `v1.12.0` (#107). It cost this suite one red run to
re-learn, and the reason is now recorded at the top of the file.

### Significance

#### Tier 0

The one script that can put a wrong version, a truncated changelog or a misplaced tag on the trunk with
nothing downstream to catch it now has a suite that drives it. Three refusal and success paths are
pinned, including the two that must leave the tree untouched.

**Score:** 4

#### Tier 2

`cut-release.ps1` ships, so a consumer cutting their own release gains the same proven behaviour and the
same honest coverage statement in its docstring. Scored 2: nothing they do changes, but the script they
run is now held to what it claims.

**Score:** 2

### Pull Request

