## Development: `docs/hook-delivery-is-verified-at-the-receiver-v1` · 20260828-135437

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

Record the two lessons from issue #1022 in Sylvester's portable manual, beside the existing pipe-test rule.

### CREATE

- [x] Sylvester's portable manual: two rules beside the existing pipe-test rule -- a hook is verified
      at the receiving end, and harness config lives in two trees.
- [~] No lens edit. Neither lesson is repo-specific, so the portable half is the whole of it
      (portable-first; the lens is the exception that needs a reason).

### TEST

- [x] `check-plugin-integrity.ps1` + all suites green locally.

### DEPLOY: `docs/hook-delivery-is-verified-at-the-receiver-v1`

Sylvester's manual now says how a hook is proven to work: the exit code says it RAN, only the receiver
says it ARRIVED. The measured case behind it is Claude Code's own `Notification` event, which produces a
desktop notification by default only in Ghostty, Kitty and iTerm2 -- so in any other terminal a
perfectly correct hook fires into nothing, and no exit code anywhere can say so. The second rule is
where to look before concluding nothing is configured: `~/.claude/settings.json` and `~/.claude/hooks/`
are machine-wide and outside every repo, so a grep of the project tree answers "no hook configured"
with complete confidence while that hook runs on every turn.

**Score:** 2

#### What makes this deploy extra special

The manual is plugin payload, so both rules reach every consuming repo at the next release. It changes
no script and no gate -- a consumer notices it the next time they debug a hook that appears to do
nothing, which is exactly the moment it is worth having.

**Score:** 2

#### Pull Request

Sylvester verifies a hook at the receiving end, and looks in the user-level config too
