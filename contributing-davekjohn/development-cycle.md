## Development cycle: `fix/seam-isolation-legacy-root-v1` · 20260827-114540

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

`Assert-WorkflowIsolatedSeamPath` refuses a deliberate seam override (issue
[#956](https://github.com/DaveKJohn/claude-code-specialists/issues/956)), hard-blocking the fold and the
cut in consumers whose `CHANGELOG.md` is at the repo root. Recognise each seam's own pre-isolation root
answer alongside the workflow folder, so a typo is still refused.

#### The report was verified before it was routed, and one part of it did not survive

The symptom stands: `scripts/lib/seam-lib.ps1` refuses any consumer seam resolving outside the folder,
with no opt-out, and `fold-changelog-entry.ps1:333` calls it — so the fold fails *after* the merge has
landed. The reason stands too.

**The first repair it proposed does not.** #956's shape 2 offered warning instead of refusing "where the
resolved path exists and is non-empty", on the grounds that a typo'd `README.md` and a real 24-entry
`CHANGELOG.md` are distinguishable by looking at the target. By that test they are not: `README.md`
exists and is non-empty in every repo, so the one case the guard's own docstring names as its reason
would have passed with a warning while the cut went on to truncate it. Building shape 2 would have
satisfied the report and removed the guard.

Shape 3 (exempt `Get-ChangelogPath`) leaves the same hole for that one seam and covers only one of the
five the assert guards. Shape 1 (a new seam to declare the exemption) keeps the teeth but leaves every
affected consumer blocked until they adopt a new seam — for a default that moved under them rather than
by their choice.

#### So the shape built here is a fourth one, and the argument for it is already in the file

The guard learns each seam's **pre-isolation answer** — what that seam pointed at before #885/#914 moved
it — and accepts that alongside the folder, per seam. This is the reasoning the same function already
gives for exempting `Get-ReleaseNoteRoot`: *"the one seam whose whole point is to keep meaning what it
meant yesterday."* That is true of every seam here for a repo that was folding into its root before the
folder existed. Written as a per-seam lookup rather than a second blanket exemption, a typo'd
`README.md` is still refused for all five — which an exemption would not do.

It also needs nothing from the consumer, which shapes 1 and 3 both do, and it mirrors the tolerance this
same function already carries for the folder's own rename (#886): recognise the old answer, write the new
one.

### CREATE

- [x] `Get-PreIsolationSeamPath` in `scripts/lib/seam-lib.ps1`: the per-seam lookup of what each isolated
      seam pointed at before it isolated — `CHANGELOG.md`, `releases/README.md`,
      `releases/development` + `releases/changelog`, `releases/github`, `releases/internal`. Keyed on the
      past rather than on the current computed default, which will move again.
- [x] `Assert-WorkflowIsolatedSeamPath` accepts that answer as well as the folder, **exact match only** —
      every call site passes the resolved seam value itself, so a prefix match would additionally wave
      through paths below a legacy file, which no caller produces and a typo can.
- [x] The refusal message names the one answer that would have been accepted, so a reader meeting it is
      not left guessing which of the two forms the guard wanted.
- [x] Both docstrings record why shape 2 was declined and why the legacy match is silent — a recognised
      layout is not a finding, and this runs at every fold and every cut.
- [x] Mirrored into the plugin payload via `scripts/sync/build-shared-scripts.ps1`.
- [~] No new seam and no repo-config entry: dropped on purpose. `Get-PreIsolationSeamPath` is a lookup of
      history, not a question a repo answers, so it is not part of the script contract — and
      `check-script-contract.ps1` confirms it wants nothing added.

### TEST

- [x] `scripts/tests/seam-lib.tests.ps1`: **37 asserts, all passing** (was 25). The pre-isolation answer
      is asserted for each of the five seams individually rather than by one sample — the tolerance is a
      per-seam lookup, so a missing entry breaks exactly one seam in exactly one consumer, at that
      consumer's next fold, with the merge already landed.
- [x] The per-seam bound is asserted from the refusing side too: one seam's legacy answer handed to
      another is still refused. Without it, collapsing the lookup into a shared allow-list would read as
      a simplification and pass every other assert in the file.
- [x] `Get-PreIsolationSeamPath` is asserted to answer **nothing** for `Get-ReleaseNoteRoot`. That seam is
      exempt from the assert entirely, so completing the table "for symmetry" would record an exempt seam
      as guarded.
- [x] Two existing fixtures had to move off `CHANGELOG.md`, and the reason is written into the suite: it
      is now a recognised layout, so both the source-exemption assert and the refusal assert use
      `README.md` — the path the guard's own docstring names as the case it exists for. The teeth are now
      asserted on the example instead of on a path that had become legal.
- [x] `check-plugin-integrity.ps1`: **0 errors** (all 28 checks, `[script-ascii]` over 160 `.ps1` files
      included). `check-script-contract.ps1`: 0 errors, 10 pre-existing info signals.
- [~] `internal-note.tests.ps1` fails one assert ("and the run warns about it out loud") and it is **not
      this branch**: it is
      [#959](https://github.com/DaveKJohn/claude-code-specialists/issues/959), console wrapping. Not taken
      on trust from that issue, because `new-internal-note.ps1` does call the changed assert — measured in
      a detached worktree at `origin/main`, where the same single assert fails identically.

### DEPLOY: `fix/seam-isolation-legacy-root-v1`

`Assert-WorkflowIsolatedSeamPath` could not tell a typo from a layout, and treated both as a typo. It
refuses with `exit 1` and had no opt-out, so a consumer that had been folding into a root `CHANGELOG.md`
since before the workflow folder existed was hard-blocked at the fold — after the merge had already
landed. It now accepts two answers instead of one: the folder, and the seam's **own** pre-isolation
target, looked up per seam by `Get-PreIsolationSeamPath`.

Per seam is the load-bearing half. `CHANGELOG.md` is a legal answer for `Get-ChangelogPath` and stays
refused for `Get-ReleaseGithubNotesRoot`, and `README.md` — the case the guard exists for, and the one its
own docstring names — is still refused for all five.

For this repo the reach is nil, and that is worth stating plainly rather than dressing up: a source repo
(`marketplace.json` present) is exempt from this assert outright and always was, so nothing here behaves
differently. What lands here is a lib, a suite that grew from 25 asserts to 37, and the record of why the
shape #956 proposed first was declined.

**Score:** 1

#### What makes this deploy extra special

**A blocker that is gone, and the reader has to act to collect it.** Two consumers answer this seam at
their repo root, independently: `smartwatchbanden` (14 pending entries, set in its own 4.20.0 adoption
commit) and `xoxowildhearts` (24). For them the fold and the cut were refused outright, and the
work-arounds were real ones — `xoxowildhearts` folded by hand under its documented fold exception, and
moved its `CHANGELOG.md` into the workflow folder purely to get past this guard. Both can be dropped
now, and the moved file can move back.

They notice this the moment they merge anything, without being told, because the failure they were
meeting was total. The one thing they have to do is stop working around it.

It reaches every other consumer as nothing at all: a repo already inside the folder passes the assert
exactly as before, and a repo with a genuine typo is refused exactly as before, now with a message that
names the answer it wanted.

**Score:** 5

#### Pull Request

A consumer's pre-isolation root answer stays a valid seam target

