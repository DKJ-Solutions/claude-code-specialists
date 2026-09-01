## Development: `fix/asana-mirror-update-not-resolve-v1` · 20260901-215802

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

Dave, 2026-09-01: automation must never complete a mirrored Asana task -- the colleague who filed it resolves it, after testing. Remove every completion path; post a comment on close and on reopen; the sweep back-fills one update per already-closed issue, idempotently.

### CREATE

- [x] Every completion path removed from the asana-mirror template: `New-AsanaCompleteRequest` and
  `Set-AsanaTaskCompleted` are gone, and the script issues no `PUT` at all. The only write it can
  build is a comment.
- [x] `New-MirrorComment` (pure) writes the two updates -- ready to test on close, hold off on reopen
  -- each carrying the issue URL, and neither claiming the ticket is done.
- [x] `Get-MirrorCommentMarker` is the close update's own opening sentence and doubles as the
  de-duplication key. It names the issue, so two issues mirrored onto one task cannot mask each other.
- [x] De-duplication applies to the sweeps only, via `Test-MirrorUpdatePosted`. An event always
  comments: a close after a reopen is news again. A task a person has already ticked off is left
  alone by both sweeps, and an unreadable task answers "already told" so nothing is posted blindly.
- [x] `Update-MirroredTask` is the one shared step both sweeps go through, so the three refusals are
  stated once.
- [x] The two docs and the skill: `WORKFLOW-portable.md` step 4 rewritten, the plugin README's
  paragraph, and `report-issue`'s frontmatter and step 4, which both promised the CI would complete
  the task.
- [x] **The close update names the pull request that closed the issue** -- number, title and URL --
  read from GitHub's `closedByPullRequestsReferences`, the GraphQL field built for that question,
  rather than reconstructed from the timeline. An issue closed by hand says so; an issue GitHub
  cannot be asked about still gets its update with no pull request named.
- [x] A close **as not planned** gets the opposite update: nothing was built, so there is nothing to
  test. Saying "ready to test" there would be worse than saying nothing.
- [x] `templates/asana-mirror.yml`: `GH_TOKEN` added to the close/reopen step and `pull-requests: read`
  to the permissions, which is what the new query needs.

### TEST

- [x] `scripts/tests/bwj-codex.tests.ps1`: 67 asserts green. Four of the new ones assert an ABSENCE --
  no completion helper is defined, no `completed=` payload is built, no `PUT` is issued -- because the
  guarantee here is a missing code path and no call can demonstrate one.
- [x] The update texts are asserted on what a colleague reads: that the close update never says
  "resolved", "completed" or "done"; that it names the closing pull request by number, title and URL;
  that two closing PRs read in the plural; that an issue with none says "closed by hand" and links
  none; and that a not-planned close never asks anybody to test something that was never built.
- [x] `Get-IssueClosure` run against the live tracker (`BWJ-ecommerce/smartwatchbanden#446`): it
  returns `stateReason=completed` and PR #447, and the rendered comment carries all three fields.

### DEPLOY: `fix/asana-mirror-update-not-resolve-v1`

The Asana mirror posts an update instead of ticking the ticket off, and it no longer holds a code
path that could tick one off. Closing a GitHub issue says the work is **built**; it does not say the
colleague who asked for it has seen it work. Those are two claims by two people, and a tracker that
lets one stand in for the other can no longer tell you which of its closed tickets anybody actually
looked at. So `closed` now writes "built and ready to test, this ticket stays open on purpose", and
`reopened` writes its counterpart; `New-AsanaCompleteRequest` and `Set-AsanaTaskCompleted` are gone.

Measured, and the reason this lands the day the mirror learned to read imported tickets: that sweep
completed **six** Asana tasks it should only have commented on -- five belonging to colleagues who
were never asked whether the work was any good. Four of the ten new asserts test an absence for
exactly that reason.

**The update also names where the change was made** (Dave, same day): the pull request that closed
the issue, by number, title and URL -- the way GitHub itself puts it, *"closed this as completed in
#434"*. It is the first thing somebody about to test wants, and the ticket is the only place they
are looking. An issue closed by hand says so instead; an invented reference would be worse than a
missing one. A close **as not planned** gets the opposite update, because asking somebody to test
something that was never built is worse than saying nothing.

De-duplication is the close update's own first sentence, which names the issue. The sweeps look for
it and stay quiet; an event never does, because a close after a reopen is news again.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's subscribers are the consumers of the plugins, and nothing about installing or
running them changes. The repair is inside a CI template a BWJ store repo copies.

**Score:** N/A

#### Pull Request

the Asana mirror posts an update on the ticket instead of resolving it

