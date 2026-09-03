## Development: `fix/fixture-git-inherits-gpgsign-v1` · 20260903-113511

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

#1287: a test fixture that sets a local git identity but not `commit.gpgsign` inherits the
machine's global signing config. On a machine with `commit.gpgsign=true` and a locked signing
agent, every fixture commit fails -- and because the helpers run under `EAP=Continue` piped to
`Out-Null`, it fails silently: the fixture never sets up, and the failing assert names the script
under test instead of the fixture. CI is unaffected (no signing config there), so the suites are
green in CI and red on the machine where someone would act on the result. `native-capture` and
`source-repo-guard` already guard against exactly this; the rest do not.

### CREATE

- [x] Pin `commit.gpgsign false` in every test fixture that sets a git identity and commits,
      matching the existing `core.autocrlf` guard: `entry-scaffold`, `find-specialist-mentions`,
      `fold-changelog`, `new-branch` (3 sites), `park-branch`, `park-cycle`, `shared-scripts`,
      `sync-main`, `sync-rules`, plus the two `Invoke-FixtureGit` copies (`gate-lib`,
      `prune-merged`) and four more the issue's `grep` missed because they pass `config` as array
      elements or `-c` flags (`cut-release-drive`, `publish-to-business`, `round-baseline`,
      `worktree-lane`).
- [~] One shared fixture-git helper -- dropped: the repo already handles this class inline per
      file (the two existing gpgsign guards and every `core.autocrlf` guard are inline with a
      comment), and the test lens deliberately keeps each suite's fixture self-contained. A
      cross-suite helper is a larger refactor out of proportion to the bug and is not this fix.

### TEST

- [x] Reproduced #1287 with a throwaway `GIT_CONFIG_GLOBAL` forcing `commit.gpgsign=true` and a
      broken signer: fixture baseline commit fails (0 commits) without the guard, succeeds with it.
- [x] Ran all 15 touched suites -- every one green.

### DEPLOY: `fix/fixture-git-inherits-gpgsign-v1`

A locked commit-signing agent no longer fails test suites for a reason unrelated to their subject:
every git fixture that commits now pins `commit.gpgsign=false` locally, the way it already pins
`core.autocrlf`, so a fixture's throwaway commits never depend on the developer's signing setup.

**Score:** 2

#### What makes this deploy extra special

N/A -- test-fixture hygiene; no subscriber of any consuming service notices this.

**Score:** N/A

#### Pull Request

Fixture git repos pin commit.gpgsign=false so a locked signing agent no longer fails unrelated suites

