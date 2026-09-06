## docs/1526-canonical-repo-owner-name

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

#### What #1526 asks for

The tree cites this repo under two owner names — `github.com/DaveKJohn/claude-code-specialists`
(133 `.md` files) and `github.com/DKJ-Solutions/claude-code-specialists` (28), 22 files carrying
both. Both resolve (GitHub transfer redirect since the September 2, 2026 org transfer), so nothing
is broken and the dead-link gate is right not to flag it — but there is no readable answer to
*which is canonical*, and new writing copies whichever example sits nearest.

#### Scope taken here

The issue's own "not measured / not claimed" section leaves the blanket rewrite and a lint check
to the owner, and protects the archived release history under `dkj-policy/releases/**`. So this
branch does step 1 only — **state the convention** — plus make the always-on constitution obey it.
The bulk sweep and a lint gate are surfaced back to Dave as a choice, not done here.

### CREATE

- [x] Add a `### Repo citation` section to `CLAUDE.md` (after `### Language`): `DKJ-Solutions`
      canonical for new writing, the redirect it rests on, existing `DaveKJohn/` citations
      corrected opportunistically not swept, `dkj-policy/releases/**` left as written.
- [x] Fix `CLAUDE.md`'s own two stray repo-URL citations (#1094, #1449) so the doc that states
      the rule follows it. The person-name attribution "Dave (DaveKJohn)" is left — it is an
      account name, not a repo URL.

### TEST

- [x] `check-plugin-integrity.ps1` + all suites green (dead-link scan covers the new links).
- [x] `grep` confirms `CLAUDE.md` carries no remaining `github.com/DaveKJohn/claude-code-specialists`.

### DEPLOY: docs/1526-canonical-repo-owner-name

`CLAUDE.md` now states which owner name to cite this repo under — `DKJ-Solutions/claude-code-specialists`
— and why the old one only works through a redirect the repo does not control. New writing has a
convention to copy instead of the nearest example. Existing `DaveKJohn/` citations are left to be
corrected as files are touched; the archived release history stays as written.

**Score:** 2

#### What makes this deploy extra special

N/A — internal documentation convention. No subscriber of any service notices a change in how this
repo's own docs cite its GitHub URL.

**Score:** N/A

#### Pull Request

State DKJ-Solutions as the canonical repo owner name for new writing

