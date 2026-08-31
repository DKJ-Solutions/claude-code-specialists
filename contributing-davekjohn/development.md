## Development: `fix/review-quota-headline-not-just-timescale-v1` · 20260831-142843

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

Issue #1164: `claude-review` red on three consecutive PRs (33384724875, 33387305049, 33390012681),
each `api_error_status: 429` with the result string "You've hit your individual spend limit -- ask
your admin to raise it at claude.ai/settings/usage". The issue reads this as an expired
`CLAUDE_CODE_OAUTH_TOKEN` and a recurrence of #966/#942 needing a rotation -- the exact misread
#913's diagnostic step exists to catch, and the annotation on all three runs already named the real
cause. This branch fixes the repo-side half: the 429 headline over-promised that the reason names a
timescale ("hours for a session cap, days for a weekly one"), which a spend limit -- lifted by an
admin, not a clock -- is not. The account-side half (raise the spend limit) is Dave's, like the
rotation #942 turned out not to need; reported on the issue.

### CREATE

- [x] `claude-code-review.yml`: reword the 429 `headline` so it points at the upstream reason for
      WHICH of three limits it is (session window / weekly cap / spend limit an admin lifts) and
      asserts none itself. Kept at exactly 296 chars so the #1116 arithmetic comments stay valid.
- [x] `claude-code-review.yml`: add the #1164 paragraph to the diagnostic comment block, in the
      #974/#1055/#1112 series; update the sampling note with the 121-char spend-limit reason.
- [x] `scripts/tests/pr-issues.tests.ps1`: bump `$longestMeasuredReason` 55 -> 121, update the two
      prose comments citing the sample and the headline-rewrite series.
- [x] `contributing-davekjohn/CONTRIBUTING.md`: the operator-facing counterpart -- the "WHICH limit"
      list gains the spend-limit case, and the #966 misdiagnosis paragraph gains #1164 as the latest
      recurrence (eight threads -> nine).

### TEST

- [x] `scripts/tests/pr-issues.tests.ps1` -- 340 asserts pass; the headline is read from the file at
      296 chars, room 203 >= 121.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors (mojibake, dead-link, entry-shape all green).
- [ ] Full `Invoke-TestSuiteGate` over `scripts/tests/` -- green.

### DEPLOY: `fix/review-quota-headline-not-just-timescale-v1`

The `claude-review` 429 headline no longer promises the failure reason names a timescale. A third
kind of 429 -- an individual spend limit an account admin has to raise, measured on three PRs on
August 31, 2026 (#1164) -- resets on no clock, so "wait hours" / "wait days" is the wrong read. The
headline now points at the upstream reason string for WHICH of the three limits it is (session
window, weekly cap, or spend limit) and asserts none itself; the diagnostic comment block, the
`pr-issues` test that pins the caps, and the operator-facing note in `CONTRIBUTING.md` are updated to
match. No behaviour change: the check still goes red on a 429, because the PR still got no review.

**Score:** 2 -- a red `claude-review` is read by whoever is shipping a PR; the headline they land on
now covers the spend-limit case instead of sending them to wait out a reset that will not come.

#### What makes this deploy extra special

Nothing. Comment/prose accuracy in a CI diagnostic plus its pinned test, no runtime change.

**Score:** N/A

#### Pull Request

The out-of-quota review headline stops promising the reason names a timescale

