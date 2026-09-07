## fix/1562-origin-remote-redirect

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

#1562: this checkout's `origin` still spelled `DaveKJohn/claude-code-specialists.git`, so every
`v4.32.0` push landed only via GitHub's transfer redirect. The tree cannot see or fix a remote URL
(per-checkout config), so the repair is a note in the repo-citation section of `CLAUDE.md` telling a
pre-transfer checkout to repoint. Repointing this checkout's own remote is a separate, untracked
`git remote set-url` for Dave to run.

### CREATE

- [x] Add a paragraph to the "Repo citation — one owner name" section of `CLAUDE.md`: a checkout's
      `origin` remote is the same citation the tree cannot reach, `v4.32.0` pushed against the old
      URL and landed on the redirect (#1562), and the one-command fix is
      `git remote set-url origin https://github.com/DKJ-Solutions/claude-code-specialists.git`.

### TEST

- [x] `check-plugin-integrity.ps1` — dead-link scan and manifest/frontmatter checks green over the
      `CLAUDE.md` edit.

### DEPLOY: fix/1562-origin-remote-redirect

The repo-citation section of `CLAUDE.md` now covers the layer it could not reach: a checkout's own
`origin` remote. A checkout cloned before the September 2, 2026 transfer still pushes to
`DaveKJohn/claude-code-specialists.git` and succeeds only because GitHub answers `remote: This
repository moved` — every push of the `v4.32.0` cut did exactly that. The note names the
one-command repoint (`git remote set-url origin
https://github.com/DKJ-Solutions/claude-code-specialists.git`) and ties the fragility to the same
condition the prose rule already carries: the redirect holds only while nothing is created at the
old path.

**Score:** 1

The failure this prevents has not happened: pushes from un-repointed checkouts still work today. It
bites the day anything is created at `DaveKJohn/claude-code-specialists` — every such checkout's
pushes then fail with no redirect to catch them, and nothing in the tree points at the cause.

#### What makes this deploy extra special

N/A — an internal documentation note. A subscriber of the service never sees a repo remote URL.

**Score:** N/A

#### Pull Request

Note the origin remote fix for checkouts still on DaveKJohn/

