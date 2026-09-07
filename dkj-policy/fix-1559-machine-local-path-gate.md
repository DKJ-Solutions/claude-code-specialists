## fix/1559-machine-local-path-gate

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

Issue #1559: a tracked file already modified in the working copy before a branch existed rides into a
PR on a `git add -A` and past every gate -- measured on PR #1557, where a locally-enabled plugin set
in `.claude/settings.json` reached the merge queue and had to be pulled back out by hand.

Verified against the tree before building:
- **Symptom stands.** The scaffold, step-list, impact and link gates read the branch's development
  document, never the diff's file set. The backing gate (`open-pr.ps1`) reads the diff but asks the
  opposite question -- work MISSING from the commit, not surplus in it.
- **Precedent.** #303 (v3.0.7) already documented this class -- `claude plugin install --scope
  project` writes `enabledPlugins` into the tracked `.claude/settings.json` -- at doc level. The
  sanctioned home for machine-local enablement is `.claude/settings.local.json` (gitignored).
- **Detection limit.** git records nothing about what was dirty when a branch was cut, so
  "already modified on the base" is not reconstructable after a `git add -A`. The buildable form is a
  named-path watch, not that heuristic.

Approach (Dave: follow the specialist's advice -> option A): a narrow, advisory named-path check.
- A new optional seam `Get-MachineLocalPaths` in `scripts/repo-config.ps1` -- repo-root-relative
  paths whose edits belong to a clone, not the tree. This repo returns `.claude/settings.json`.
  Probed like `Get-PrAssignee`, so it is not in the script contract; absent or empty -> silent.
- `Get-BranchMachineLocalFindings` in `scripts/lib/park-lib.ps1` -- which of those paths appear in
  the branch's committed diff against its merge base with the trunk. Three-dot, and the
  remote-tracking ref preferred (#1399), the same as `Get-GitParkBacking` beside it.
- `open-pr.ps1` turns a hit into a `Write-Warning`, said twice (once at the gate, once from each run
  end, because everything after is off-screen). **No refusal and no `-Force` valve** -- the issue
  asked for exactly that: a branch that legitimately changes the shared settings file must not need
  an escape valve, and this repo declines findings-list gates on their false-positive rate.

### CREATE

- [x] `scripts/repo-config.ps1`: add the optional `Get-MachineLocalPaths` seam, returning
      `@('.claude/settings.json')`, with the docstring explaining probe-not-contract and the
      trailing-`/` directory form.
- [x] `scripts/lib/park-lib.ps1`: add `Get-BranchMachineLocalFindings` -- merge-base diff,
      remote-tracking ref preferred, `core.quotePath` forced, degrades to `Known = $false` on an
      unreadable diff.
- [x] `scripts/release/open-pr.ps1`: probe the seam before the scaffold gate, warn on a hit, and
      re-emit the note from both run ends.
- [x] Regenerate the plugin mirrors (`scripts/sync/build-shared-scripts.ps1`) for `open-pr` and
      `park-lib`; `repo-config.ps1` is not mirrored.

### TEST

- [x] New suite `scripts/tests/machine-local-gate.tests.ps1` -- spec parsing, unreadable-diff
      degrade, a real fixture where `git add -A` sweeps `.claude/settings.json` into a branch commit,
      a trunk-side change to the same file that is NOT attributed to the branch, the #1399
      stale-local-trunk case, and the open-pr wiring (probed, warns, never exits, said twice, placed
      before the scaffold gate and the push).
- [x] `scripts/tests/repo-config.tests.ps1`: assert the seam watches the settings file and its
      entries are repo-root-relative.
- [x] Lint + all suites green (`open-pr.ps1 -GatesOnly`), exactly as CI runs them.
- [ ] Lint + tests green, then PR + merge + fold.

### DEPLOY: fix/1559-machine-local-path-gate

`open-pr.ps1` now warns -- twice, and never refuses -- when a branch's commits touch a path this repo
has marked machine-local (`Get-MachineLocalPaths`, `.claude/settings.json` here). A file a person
edited for their own clone and swept in with `git add -A` reached the merge queue on PR #1557 past
every other gate, because none of them reads the diff's file set. The new optional seam lets each
consumer name its own such paths; undefined, the check is silent.

**Score:** 2

#### What makes this deploy extra special

N/A -- a workflow-internal guardrail. It changes what `open-pr` prints for a repo developer running a
PR; a subscriber of any consuming service never sees it.

**Score:** N/A

#### Pull Request

warn when a branch commit touches a machine-local path such as .claude/settings.json
