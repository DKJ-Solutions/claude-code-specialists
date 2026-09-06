## fix/1493-fold-on-merge-pat-push

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

#### Background

Issue #1493: the merge queue merges PRs without the session that ships them ever seeing it, so the fold
step (previously `ship-pr.ps1`'s own last step) never runs and every queue-merged PR landed unfolded.
`fold-on-merge.yml` (#1496) closed that by running the fold from a `push` to `main`, but that push needs
to bypass `main-ci-gate`'s `required_status_checks` and `merge_queue` rules. The plan was to add the
GitHub Actions app as a ruleset bypass actor -- discovered live, in conversation with Dave, that this is
not possible: that app (`github-actions`, integration_id 15368) is owned by `anthropics`, installed on
this org but not administered by it, so no private key is available to authenticate as it. `main-ci-gate`
already carries `OrganizationAdmin` with `bypass_mode: always`, so Dave created a fine-grained PAT
(`FOLD_PUSH_TOKEN`, scoped to this repo only, `Contents: Read and write` only) under his own org-owner
account instead, sidestepping the ruleset-bypass dead end entirely -- no ruleset change needed.

### CREATE

- [x] Wire `fold-on-merge.yml`'s checkout step to authenticate with `secrets.FOLD_PUSH_TOKEN` instead of
      the default `GITHUB_TOKEN`, so the fold step's later `git push` carries that identity.
- [x] Narrow the workflow's `permissions:` block from `contents: write` to `contents: read` -- the
      default `GITHUB_TOKEN` no longer pushes anything, it is only used for `gh pr list` (read-only).
- [x] Update the workflow's own header comment: it previously said the job was inert pending a
      repo-settings ruleset change; it now explains the PAT-based bypass and that the token needs
      rotating within the org's enforced 366-day maximum.

### TEST

- [x] Lint gate green (`check-plugin-integrity.ps1`) -- 0 errors.
- [x] Relevant suites green (`fold-changelog.tests.ps1`, `unfolded-entry-gate.tests.ps1`,
      `workflow-concurrency.tests.ps1`) -- none of them assert on `fold-on-merge.yml`'s auth mechanism,
      so this is a regression check rather than new coverage; no test exists for "which token
      authenticates the push" and none is practical to add without a live GitHub ruleset in CI.

### DEPLOY: fix/1493-fold-on-merge-pat-push

`fold-on-merge.yml` now pushes its fold commit authenticated as a fine-grained personal access token
(`FOLD_PUSH_TOKEN`) belonging to an org admin, instead of the default `GITHUB_TOKEN`. `main-ci-gate`
already bypasses `OrganizationAdmin`, so this identity clears the ruleset with no repo-settings change --
the originally planned route (adding the GitHub Actions app as a bypass actor) turned out to be
impossible, since that app is owned and administered by `anthropics`, not this org. Closes out the
remaining blocker in #1493; the workflow is no longer waiting on a permission nobody here can grant.

**Score:** 2

#### What makes this deploy extra special

The token requires manual rotation before it expires (org policy caps it at 366 days) -- if it lapses,
this job starts failing its push again with no code-level cause, which is worth a subscriber-facing
reader's awareness only in the sense that a maintenance rhythm now exists where none did. N/A for a
direct subscriber-facing effect: nothing about what a consumer of this repo's plugins sees changes.

**Score:** N/A

#### Pull Request

Push fold-on-merge.yml's commit with a fine-grained PAT from an org admin instead of the default GITHUB_TOKEN

