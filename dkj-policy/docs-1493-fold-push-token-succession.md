## docs/1493-fold-push-token-succession

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

Follow-up from #1493/PR #1507 (fold-on-merge.yml now pushes as `FOLD_PUSH_TOKEN`, a fine-grained PAT
from an org owner, since the GitHub Actions app can't be a ruleset bypass actor here). Sebastian's
security review of that PR flagged that nothing durable records what happens if the token expires
(366-day org cap) or its owner becomes unreachable before then -- currently tribal knowledge held by
Dave alone. This branch writes that down.

### CREATE

- [x] Routed to Tessa: wrote the succession note into
      `.claude/specialists/lenses/05-15-extension.md`, under "What Sylvester owns here" -- judged to
      fit there rather than `dkj-policy/CONTRIBUTING.md`, since the ruleset/bypass-actor mechanics this
      note extends are already documented in that same lens rather than in the repo-agnostic
      contributing page.
- [x] Verified independently (not just trusted): the three named org owners (DaveKJohn, davekokbwj,
      maikel-bwj) checked live against `gh api orgs/DKJ-Solutions/memberships/<user>` -- all `admin`,
      matching the note's claim.

### TEST

- [x] Lint gate green (`check-plugin-integrity.ps1`) -- 0 errors, before and after the copy-edit fixes.
- [x] Routed to Edith for copy-edit: four minor wording nits found (an awkward stranded clause, an
      unclear pronoun referent, a cosmetic list-style mismatch against the role table cited elsewhere in
      the same file, and a slight over-narrowing of what #1499 actually measured), no factual or
      structural defects. All four applied directly.

### DEPLOY: docs/1493-fold-push-token-succession

`FOLD_PUSH_TOKEN`'s succession is now written down in Sylvester's system-administration lens: what it
is, why the GitHub Actions app couldn't be used instead, its 366-day expiry and what a lapse looks like
in a run log, and the manual renewal procedure (which org owner runs which command). Closes the
"tribal knowledge held by one person" gap Sebastian flagged reviewing PR #1507 -- no code changed.

**Score:** 1

#### What makes this deploy extra special

N/A -- purely internal governance documentation about a CI credential; no subscriber-facing effect.

**Score:** N/A

#### Pull Request

Write down FOLD_PUSH_TOKEN succession -- what happens if its owner becomes unreachable before the 366-day expiry

