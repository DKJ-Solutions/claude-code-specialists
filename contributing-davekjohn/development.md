## Development: `fix/the-status-in-the-annotation-gets-the-same-care-as-the-reason-v1` · 20260829-225800

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

Issue #1118, found by Sebastian during the security review of PR #1119 and filed rather than fixed
there. The repair must not need an assertion about upstream's `api_error_status`: keep the status out
of the annotation TITLE (a literal short form, like the other three case branches), and give it the
single-line + percent-escape treatment `reason` already gets before it reaches the message body.

#### The question the issue left open, and why it does not need answering

#1118 says to establish first whether `api_error_status` can carry anything but a status-shaped value,
because its candidate 2 -- leave the asymmetry, record why it is safe -- is only honest if it can be
shown. It cannot: it is upstream's field, this repo has never observed anything but a 429 in it, and
observing 45 of one value is not a domain. #1112 is the standing reminder of what claiming otherwise
costs here. So the branch takes candidate 1 in a shape that needs no claim at all, and the question
dissolves rather than being answered.

#### Not in scope

PR #1119 is open on the same file. Its diff is a comment block ABOVE the `status=` line this branch
edits, so the two merge cleanly; nothing here touches the two caps that PR is about.

### CREATE

- [x] `claude-code-review.yml`: single-line and cap `status` where it is read, using the same jq idiom
      (`split("\n") | (.[0] // "")`) that the `reason` line beside it already proves
- [x] the `*)` branch's `short` becomes a literal, so no case branch puts a variable in the annotation
      title -- which is what enforces the rule the comment above that block already states
- [x] both emit sites escape `%` in `headline`, now that it is the variable carrying the status
- [x] `pr-issues.tests.ps1`: bind #1119's reason-cap assert to `.result` rather than to the slice
      SHAPE, and give the status cap an assert of its own -- see TEST for why this became necessary

### TEST

- [x] three asserts in `scripts/tests/pr-issues.tests.ps1`, one per axis, read off the workflow text --
      the idiom `cut-release-guardrail.tests.ps1` already uses for `ci.yml`, and for its stated reason:
      a workflow is the one caller no suite gets to run
- [x] proved they bite rather than decorate: stashing the workflow change turns exactly those three
      red (3 failed, 325 passed) and restoring it returns 328 green
- [x] the four case branches exercised in bash against a hostile status -- newline, `%0A`, comma and
      `::` -- confirming the title stays clean and the forged command lands mid-line, where it cannot
      count. The jq half inherits the `reason` line's own measurement (jq is not installed locally)
- [x] merged `origin/main` after #1119 landed mid-branch, resolved the single conflict in the workflow
      by keeping both comment blocks, and re-ran the suite: 340 asserts green
- [x] found and repaired a collision the merge exposed -- #1119's reason-cap assert matched on the
      slice shape `(.[0] // "") | .[0:(\d+)]`, and this branch's status slice sits EARLIER in the
      file, so `Match` returned 32 and the assert went red against a cap nobody had touched

### DEPLOY: `fix/the-status-in-the-annotation-gets-the-same-care-as-the-reason-v1`

The annotation a failed `claude-review` leaves behind can no longer be garbled or forged by a field
this repo does not own.

That step reads upstream's `api_error_status` and puts it on a workflow-command line, where three
variables meet and only `reason` was escaped. `status` reached the same line twice: through the `*)`
headline, and through `short`, which lands in the annotation TITLE -- the one place a comma or a `::`
is command syntax. The comment above the case block already stated that rule, and the only branch
interpolating a variable there was the only one that could not honour it.

Closed on all three axes -- newline, percent, title -- without asserting anything about upstream. The
status is single-lined and capped where it is read, the fourth `short` is a literal like its three
siblings, and `headline` is percent-escaped at both emit sites. The alternative #1118 offered was to
leave the asymmetry and record why it is safe, which requires claiming `api_error_status` is
status-shaped by construction; that is a claim about somebody else's field, and #1112 is what such
claims have already cost here. Three asserts pin the shape, and each was shown to fail against the
code as it stood.

It also repairs a neighbouring assert that this change turned red. #1119 pinned the reason's
300-character cap by matching the SHAPE of its jq slice, above a comment predicting that a second
slice added elsewhere "would go unread here rather than caught". A second slice arrived one line
above it, and the outcome was worse than unread: being earlier in the file it won the match, so the
assert reported 32 against a cap nobody had touched. It now binds to `.result`, the status cap has an
assert of its own, and the two can move independently.

Nothing has broken yet, which is the point: all 45 titled failure annotations this workflow left on
August 27-29, 2026 came from the `429` branch, whose headline is a literal, so the `*)` branch has not
been observed running. The failure it prevents is a diagnostic that renders wrong -- or emits a second,
forged workflow command -- in the one step whose whole job is explaining why a run went red.

**Score:** 1

#### What makes this deploy extra special

`.github/workflows/claude-code-review.yml` is this repo's own CI and travels in no plugin, so no
consumer installs it and no subscriber of the service can observe the change.

**Score:** N/A

#### Pull Request

The annotation's status gets the same care as its reason
