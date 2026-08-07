## `feat/park-says-what-it-saved` progress

### Steps

- [x] `scripts/lib/park-lib.ps1`: one implementation, with the scope and the commit words as ONE decision
- [x] Both entry points call it -- `park-branch.ps1` and `new-branch.ps1 -Park`
- [x] Register it in `shared-scripts-lib.ps1` so it travels with the two scripts that need it
- [x] Tests: the scope/label pairing, and both scopes end to end against a real throwaway repo
- [x] The documents that describe the two: the `park` skill, Derek's lens, `branch/README.md`, `plugins/specialists/scripts/README.md`
- [x] Mirrors, lint, suites

### Where I left off

Lint 0 findings, all suites green.

**Three things worth carrying forward.**

A fixture-copied script needs every lib it dot-sources copied too. Adding `park-lib.ps1` broke BOTH park
suites at once with failures that looked unrelated to the change (the guardrail assert failed first), and
the parse check was clean -- because the file parsed fine and simply had no `Invoke-GitPark` to call. If a
suite that copies scripts into a throwaway repo starts failing wholesale, check the copy list before the
code.

`new-branch`'s `-Park` block still names its two paths explicitly rather than letting the lib decide.
That is deliberate: the pathspec discipline belongs to the caller who knows which files are its own.

**Open for Dave:** the rename to `origin-save` (#507's second half) and the three-way choice in #508.
Both are put to him rather than taken.

Next in the queue: #508 (needs Dave's decision first), #512, #456.
