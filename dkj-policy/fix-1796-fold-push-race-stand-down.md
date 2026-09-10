## fix/1796-fold-push-race-stand-down

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### What #1796 asked for, and what happened to its one assumption

The report names the repair sites correctly and predicts the code (`3`), assuming #1792's repair had
already introduced it -- *"1 before #1792"*. At pickup it had not: #1792 was open, its branch carried
the scaffold and nothing else. So the code was written here as this repair's own precondition.

**Then #1792 merged (PR #1797) while this branch sat in CI, and had written the same code, in the same
place, on the same measurement.** Two sessions found the two sides of one race within hours and both
reached for `3` independently. The staleness guard caught the collision at the merge and refused --
which is the guard doing exactly its job.

Resolved in #1792's favour on the shared file: `scripts/release/fold-changelog-entry.ps1` is theirs
wholesale, since it landed first and the semantics were identical. What remains here is the half they
did not touch -- the **runner's** side of the race.

#### The two readers answer the same code differently, and that is the point

`ship-pr.ps1` stands down and then **tells the operator about the redundant commit** (#1792's step 5c),
because it is sitting on a trunk somebody has to live with. `fold-on-merge.yml` stands down and says
nothing further, because its workspace is thrown away when the run ends. One code, two callers, two
correct answers -- the difference is whose trunk it is.

### CREATE

- [x] `fold-changelog-entry.ps1`: the redundant-fold verdict exits `3`, and the docstring states both
      codes and what separates them -- what was written by the time each one fires
- [x] `.github/workflows/fold-on-merge.yml`: stand down on `3`; the header's three-cause triage now
      tells a ruleset `GH013` apart from a non-fast-forward, and the race section names both halves
- [x] `scripts/task/adopt-merge-queue.ps1`: the same arm and the same header reasoning in the emitted
      template
- [x] `plugins/dkj-policy/skills/adopt-dkj-policy/SKILL.md`: the one stood-down refusal becomes two,
      written as the two halves of one race
- [x] Plugin mirrors regenerated via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `fold-changelog.tests.ps1`: the existing `raced fold` case pins `3` instead of `1`, and `exit 3`
      is asserted to come from exactly one place -- the property exit `2` is already held to
- [x] The `diverged` case pins `1`, and is the half that keeps this from becoming "ignore a failed push"
- [x] And the READER of the codes is asserted for the first time -- this repo's own
      `fold-on-merge.yml`, which nothing checked, beside the template its own suite already covers
- [x] `adopt-merge-queue.tests.ps1`: the emitted template stands down on `3`, and on exactly two codes
- [x] Both suites green (261 pass / 0 fail; 71 pass / 0 fail), then the full lint + test gate

### DEPLOY: fix/1796-fold-push-race-stand-down

`fold-on-merge.yml` no longer goes red when it loses the fold race at the **push**. That race has two
halves: the other fold landing before the job's pre-pass reads the trunk (exit `2`, stood down since
#1586), and it landing in the ~1s between that read and the job's own push -- which no check at the top
of a run can close, because the window opens after it. The second half folded, committed, and came back
a non-fast-forward, and the job went red on a trunk that was already correct.

`fold-changelog-entry.ps1` signals that case with exit code `3` -- introduced by #1792 hours earlier for
the session's side of the same race, and earned by a measurement rather than by the push having failed:
every entry the run folded is already upstream, present with an identical body. The runner stands down
on it, and the redundant commit it leaves behind dies with the ephemeral workspace. A push refused for
any other reason -- a ruleset `GH013`, a credential, or a non-fast-forward where one entry is upstream
and another is genuinely new -- is still exit `1` and still red, which is what keeps this from becoming
a blanket "ignore a failed push".

So one code now has two readers that answer it differently, on purpose: `ship-pr.ps1` stands down and
then reports the redundant commit, because it sits on a trunk somebody has to live with; this runner
stands down and says nothing more, because its workspace is discarded. The suite that owns the code
pins both readers -- the workflow's half was asserted nowhere until now, only the template it ships.

The header's three-cause triage could not tell a ruleset rejection from a non-fast-forward -- the
report's own point -- so cause 3 now names the difference in the reader's terms: `GH013` names a rule
and a ruleset, a non-fast-forward names a ref and tells you to fetch first.

**Score:** 3

#### What makes this deploy extra special

A consumer running the placed fold runner gets the same stand-down through `adopt-merge-queue.ps1`'s
template, and the `adopt-dkj-policy` skill now documents two stood-down refusals as the two halves of
one race rather than one. Nothing for them to do: an adopted runner picks it up with the plugin update,
and a red run they would otherwise have read as a ruleset problem stops happening.

**Score:** 2

#### Pull Request

The fold-on-merge runner stands down when it loses the fold race at the push

