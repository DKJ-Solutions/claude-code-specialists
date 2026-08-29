## Development: `fix/ship-pr-on-an-already-merged-branch-v1` · 20260829-143114

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Two reports about one route: re-running `ship-pr` on a branch that has already shipped.
[#1077](https://github.com/DaveKJohn/claude-code-specialists/issues/1077) is the way in --
`open-pr` looks only for an OPEN PR, so a merged branch takes the create path and fails with a
message naming `gh` authentication, which was demonstrably fine.
[#1082](https://github.com/DaveKJohn/claude-code-specialists/issues/1082) is what the route
produced at the other end: two entries for one branch in `CHANGELOG.md`, both folded, both
reported as a success. First line of defence and second, fixed together because a second line
that is never reached cannot be measured.

Both symptoms verified against the tree before any repair: `open-pr.ps1:418` still carries
`--state open`, `:1371` still replaces gh's own message with the login guess, and the fold has
no read of what the changelog already holds.

### CREATE

- [x] `open-pr.ps1`: when the open lookup is empty, ask for a MERGED PR on the same
      (head, base) pair and stop cleanly with its number instead of taking the create path.
- [x] `open-pr.ps1`: the create failure reports gh's own reason; the `is gh logged in?` hint
      becomes a suffix rather than the whole message.
- [x] `ship-pr.ps1`: step 2 recognises the same state, so a merged branch ends the run as
      "nothing to ship" rather than as an error.
- [x] `fold-changelog-entry.ps1`: refuse a second entry for a branch the changelog already
      carries, naming the PR of the one already there, with `-Force` as the escape valve.
- [x] The pure halves live in the libs that own them, so a suite can assert them: the changelog
      read in `entry-scaffold-lib.ps1`, the failure-reason read in `pr-issues-lib.ps1`.
- [x] Mirror the changed scripts into the plugin (`build-shared-scripts.ps1`).

### TEST

- [x] Unit tests for both new pure functions, including the shapes that must NOT match.
- [x] The full local gate green: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: `fix/ship-pr-on-an-already-merged-branch-v1`

Re-running `ship-pr` on a branch that had already shipped used to end in a PowerShell error naming
`gh` authentication -- on a branch that was completely finished, in a run where `gh` had just listed
PRs, pushed and read the issue list. `open-pr` asked only for an *open* PR, so a merged branch fell
through to `gh pr create`, and the script then replaced GitHub's own answer with the fixed guess
`(is gh logged in?)`. Both halves are repaired: an already-merged PR is now its own outcome, reported
with its number and url and exiting 0 before the gates, the push and the create; and where a create
does still fail, the message carries gh's own reason, with the login hint kept only for a `gh` that
printed nothing at all. `ship-pr` reads the same state for itself in its step 2, because both scripts
are runnable on their own.

The route those two closed had a second end, and it is now guarded too: the fold would write a
**second** entry for a branch the changelog already carried, and report both runs as a success --
measured in a consumer as two entries, same branch, same text, two PR numbers. Nothing downstream
refused them either, so the cut counted the duplicate twice in its tier breakdown and printed it
twice in the published note. `fold-changelog-entry.ps1` now refuses, naming the PR of the entry
already there, leaving the entry file on disk and ending the run non-zero; `-Force` folds anyway.
Refusing is safe *here* for a reason that does not generalise, and the code says so: an entry refused
for a missing score leaves merged work with no record, while a duplicate refused leaves the record
already standing.

The branch name is the key and the merge stamp is not -- the fold writes that stamp at fold time, so
the duplicate carried a different one, which is exactly why nothing matched. The reads behind both
gates are pure functions in the libs that own the format (`Get-FoldedEntryForBranch`,
`Get-PrCreateFailureReason`), so a suite asserts them without a remote; the fold's refusal is
asserted end to end on the real script.

Closes [#1077](https://github.com/DaveKJohn/claude-code-specialists/issues/1077) and
[#1082](https://github.com/DaveKJohn/claude-code-specialists/issues/1082).

**Score:** 3

#### What makes this deploy extra special

A consumer meets this on the day they re-run `ship-pr` -- after an interrupted wait, from a second
session, or out of habit on a branch whose local copy survived the merge. Until now that produced a
message pointing at their `gh` login, their token and their network for a run whose only news was
good; now it says the work has landed. The duplicate guard is the quieter half and the more
expensive one: a doubled changelog entry is only repairable by hand, after the branch is gone, in a
release note that has already been published.

**Score:** 3

#### Pull Request

ship-pr on an already-merged branch says so, and the fold refuses a second entry for one branch
