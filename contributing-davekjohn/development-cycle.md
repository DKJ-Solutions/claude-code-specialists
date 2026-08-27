## Development cycle: `fix/readoption-warns-for-the-two-note-roots-v1` · 20260827-201833

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

adopt-workflow-folder.ps1 warns explicitly for Get-ReleaseHistoryPath and Get-ChangelogPath, the two sibling seams #885 isolated, but says nothing about the changelog- and github-note roots #914 relocated on August 26. Give those two the same warning, conditional on a legacy tree still sitting at the repo root.

### CREATE

- [x] `scripts/task/adopt-workflow-folder.ps1`: both roots are resolved and named unconditionally, and
      a yellow re-adoption block fires only where a pre-#914 tree is genuinely still at the repo root.
- [x] The legacy paths come from `Get-PreIsolationSeamPath` rather than a second list, so a name added
      to the cut's own tolerance is warned about here without this block learning it separately. That
      is also why `releases/changelog` at the root is covered as well as `releases/development`.
- [x] It counts the `.md` files it found and prints the number. djcylow-react's case was legible
      because of "39 + 2", not because a path was named.
- [x] Two answers offered, not one: `git mv` onto the isolated path, or define the seam to keep
      pointing at the root tree -- and it says the cut accepts that root answer for these two seams
      specifically (#956), so repointing is not a fight with the isolation guard.
- [x] `Get-ReleaseInternalNotesRoot` deliberately left out, with the reason in the code: for a consumer
      it has resolved inside the folder since #885, so it never had a root answer to split away from.
- [x] Resolved but **not** asserted. The cut already runs `Assert-WorkflowIsolatedSeamPath` over both;
      a second refusal here would let an informational adoption run exit 1 on a seam the reader has
      not been told about yet.
- [x] Plugin mirror held byte-identical; the file is pure ASCII.
- [x] `scripts/tests/adopt-workflow-folder.tests.ps1`: section 5, both directions.

#### The suite's capture was made wrap-proof first

`Invoke-Adopt` joined the child's records with newlines, so a phrase sitting mid-line was exposed to
the console wrap -- the exact class that turned `seam-lib` and `internal-note` red under #982 and #959
earlier today. Adding phrase asserts to it would have inherited that defect on the day it was repaired
elsewhere. It now returns `Flat` beside `Out`, and only the new asserts read `Flat`; the per-line
`[create]`/`[exists]` asserts keep reading `Out`, which is what they need.

### TEST

Driven against two throwaway consumer fixtures, because a warning has two correct behaviours and only
one of them is the interesting one:

| fixture | resolved roots named | warning |
|---|---|---|
| `releases/development/2.x` (3 files) + `releases/github/2.x` (1 file) at the root | yes | fires, names both trees with their counts, offers both answers |
| nothing at the root | yes | **silent** |

- [x] `adopt-workflow-folder.tests.ps1`: `OK: all 32 asserts passed.`
- [x] Exit 0 in both cases -- this is a warning and never a refusal.
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite.

#### What the verification changed about the issue, and it is worth recording

The issue's exhibit has moved on. It was filed because `djcylow-react` carried 39 files under
`releases/development/` and 2 under `releases/github/` at its repo root. Measured against their live
tree today: both root trees are **gone**, and `contributing-davekjohn/releases/changelog/2.x` holds 40
files while `.../github/2.x` holds its own. They found it themselves and repaired it with `git mv`
(their PR #158) -- and their `scripts/repo-config.ps1` now carries a long note saying, in as many
words, that nothing in the plugin migrated the files and nothing warned that it had to, citing #955.

So the symptom the issue reported is resolved at the consumer it was measured in, and the **gap is
untouched**: grepping this repo's `adopt-workflow-folder.ps1` for either seam name still returned
nothing. A consumer repairing a defect by hand is not the defect being fixed. If anything the exhibit
got stronger: the note they had to write is the note this block now prints.

One correction to the report while it is being answered. It names three seams --
`Get-ReleaseChangelogNotesRoot`, `Get-ReleaseDevelopmentNotesRoot`, `Get-ReleaseGithubNotesRoot` -- and
all three exist, but they are **two** roots: the middle one is the retired alias of the first, which
`cut-release.ps1` still reads for exactly the migration reason this branch is about. Scoping the
warning to three would have invented a third tree.

### DEPLOY: `fix/readoption-warns-for-the-two-note-roots-v1`

Re-adopting the workflow folder now tells you about the two generated note roots that moved, which was
the one relocation in that family with no warning behind it. `adopt-workflow-folder.ps1` has printed an
explicit re-adoption note for `Get-ReleaseHistoryPath` and for the root `CHANGELOG.md` since #885
isolated them -- "your next cut starts a NEW list here", "any entry pending there right now will NOT be
picked up". [#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914) did the same thing
to `Get-ReleaseChangelogNotesRoot` and `Get-ReleaseGithubNotesRoot` on August 26 and nothing followed
it: the scaffold text was updated, the migration-warning block was not, and `cut-release.ps1` only
asserts the resolved paths. So an existing consumer's next cut would open two fresh trees inside the
folder and leave the real history at the repo root, silently.

The block now resolves both seams and names their answers on every run, and warns only where a
pre-#914 tree is actually still sitting at the root -- with the file count, because the scale is what
makes it legible, and with both honest ways out rather than a preference. The legacy paths are asked of
`Get-PreIsolationSeamPath`, the same lookup the cut's own tolerance uses, so the two halves of one
mechanism cannot drift apart again -- which is the shape of defect this family keeps producing.

Filed as inbound [#955](https://github.com/DaveKJohn/claude-code-specialists/issues/955). Its exhibit
had already been repaired by hand at the consumer by the time it was picked up; the gap it reported had
not, and the TEST section above records both.

For this repo the durable half is that the warning is derived rather than restated: the next seam to
isolate gets its warning by being added to one lookup, not by somebody remembering this block exists.
That is exactly what #914 did not get.

**Score:** 3

#### What makes this deploy extra special

If you still keep `releases/development/` or `releases/github/` at your repo root, re-running
`adopt-workflow-folder` now says so -- which tree it found, how many notes are in it, and that your
next cut writes somewhere else and leaves it behind. Between 4.20.0 and this version nothing told you:
one consumer only caught it by going looking. Two ways out, both fine: `git mv` the tree onto the path
the run prints, or define the seam in `scripts/repo-config.ps1` to keep pointing at your root tree.
Nothing is moved for you and nothing is refused.

**Score:** 4

#### Pull Request

Re-adoption warns about the two generated note roots #914 moved

