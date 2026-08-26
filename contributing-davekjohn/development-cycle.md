## Development cycle: `fix/the-review-failure-names-its-reason-v1` · 20260826-141215

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### What #913 asked, and what the log actually says

The issue reports that `claude-review` failed on both attempts of PR #911 where it had passed on the three
PRs merged before it the same day, and it is explicit about which half of itself is unverified: it infers an
expired or rate-limited OAuth token from the empty `ANTHROPIC_API_KEY:` line, and closes by naming the check
a fix would have to run first.

- [x] Verify the symptom still stands. It does: run 32964843900 is the last `Claude Code Review` run in the
      repo, so nothing has re-run since and nothing has repaired it.
- [x] Verify the reported reason. **Half of it is refuted.** Attempt 1 reports `num_turns: 12` and
      `total_cost_usd: 1.03208985` over 69s, so the token authenticated and did real work -- an expired
      credential cannot spend a dollar across twelve turns. Attempt 2 (`num_turns: 1`, `total_cost_usd: 0`,
      470ms) is a different failure from the same day. A rate limit fits both and an expiry fits neither.
- [x] Verify the second candidate the numbers offer. Not the denials: the three runs that PASSED carry
      `permission_denials_count` of 6, 10 and 16, against the failure's 1.
- [x] Find the mechanism for the silence, rather than proposing one. `sanitizeSdkOutput`
      (`base-action/src/run-claude-sdk.ts` at the pinned SHA `e63208c`) emits seven fields of the result
      message and suppresses every other message type. `SDKResultSuccess` in the SDK typings carries two more
      that name a reason -- `result` and `api_error_status` -- and neither is in that seven.

**So the repair is not the credential and it is not a guess at one.** Nothing in a workflow file can fix an
upstream rate limit; what it can fix is that the next occurrence arrives unattributable. That is the defect
this branch closes, and the issue's own open question is answered by this PR's own review run.

#### This document's own guidance block was repaired by hand, and why that is not part of this change

`new-branch.ps1` wrote the four level markers in the blockquote above as bare `###` / `####` lines of their
own, and `check-branch-entry.ps1` refused the document for carrying branch content in the guidance region --
so this branch could not be pushed at all. The cause is that PowerShell's `,` binds tighter than `+`, which
makes `'a' + $H + 'b'` inside a comma-separated array literal an ARRAY concatenation: the guidance array holds
38 elements where the source lists 34. Filed as
[#915](https://github.com/DaveKJohn/claude-code-specialists/issues/915) with the mechanism and the
parenthesise-the-four-sites repair, because it blocks every branch here and in every consumer of the workflow
plugin and deserves the generator fix plus the assert that would have caught it -- not a fix smuggled into a
CI-diagnostics change. The four lines here were set to exactly what the generator intends to emit, so this
document is what a repaired scaffolder would have produced. The generator is untouched: the next branch
created reproduces it.

#### What was deliberately not built

Not `show_full_output: true`. It is the only switch upstream offers and it dumps every message including tool
results into a public log; its own description warns it may carry secrets. The point of reading the execution
file instead is that the disclosure is bounded to the fields that name the failure.

### CREATE

- [x] Add a failure-only diagnostic step to `.github/workflows/claude-code-review.yml` that reads the
      `execution_file` output and prints the result message's structured fields plus a truncated `result`.
- [x] Record in the step's comment why each mechanism it leans on exists -- the sanitiser's seven fields, the
      catch-block `setExecutionFileOutputIfPresent()` that keeps the output alive through the throw, and the
      array shape upstream reads the same way in `update-comment-link.ts`.
- [x] State the bound: `claude.yml` has the same blindness and is deliberately left alone.

### TEST

- [x] The shipped jq filter, extracted from the workflow file itself so the test runs what merges, against
      five cases: the real attempt-1 shape (429 named), no result message at all, the attempt-2 shape with
      `result`/`api_error_status`/`permission_denials` all absent, a 5,000-character `result` (printed
      length 2,000), and malformed JSON (exit 5 -- which is what `continue-on-error` is for).
- [x] The workflow parses as YAML, and the step's `steps.claude-review` reference resolves to the
      `id: claude-review` on the step above it.
- [x] Lint gate + all suites.

#### The one check that cannot be a step here

The issue closes by naming the test a fix would have to run first -- the check re-run on an unrelated PR -- and
this PR is that PR. It cannot be a step above DEPLOY, because the step gate counts them before the push that
creates the run. So it is written here instead: a green answers #913 in one direction, a red in the other, and
from this merge onward a red says which.

### DEPLOY: `fix/the-review-failure-names-its-reason-v1`

When `claude-review` goes red, the log now names the reason. A failure-only step in
`.github/workflows/claude-code-review.yml` reads the execution file the action leaves behind and prints the
result message's `subtype`, `is_error`, `api_error_status`, `stop_reason`, turn count, duration, cost and
denial count, plus its `result` string truncated to 2,000 characters. On PR #911 -- inbound
[#913](https://github.com/DaveKJohn/claude-code-specialists/issues/913) -- the check failed twice and said
nothing but `is_error:true`, which left a guess about the credential as the only available hypothesis.

**The guess was half wrong, and the numbers already in the log say so.** #913 inferred an expired or
rate-limited OAuth token from the empty `ANTHROPIC_API_KEY:` line. Attempt 1 reports `num_turns: 12` and
`total_cost_usd: 1.03208985` across 69 seconds, so the token authenticated and did real work; an expired
credential cannot spend a dollar over twelve turns. Attempt 2 reports `num_turns: 1` and `total_cost_usd: 0`
in 470ms, a different failure entirely. A rate limit is consistent with both and an expiry with neither --
which is as far as the log can be read, and exactly why the reason has to be printed rather than reconstructed.
The other candidate the numbers offer is refuted outright: the three runs that PASSED that day carry
`permission_denials_count` of 6, 10 and 16, against the failing run's 1.

**The silence had a located cause, not a mysterious one.** `sanitizeSdkOutput` in the action's
`base-action/src/run-claude-sdk.ts`, read at the pinned SHA `e63208c`, emits seven fields of the result message
and suppresses every other message type. The SDK's own `SDKResultSuccess` type carries two more that name a
reason -- `result` and `api_error_status`, the latter holding 429 for a rate limit and 529 for an overload --
and neither is among the seven. So nothing was missing upstream that could be asked for; what was missing was a
reader for the file it already writes.

**Three mechanisms were read rather than assumed, because a workflow that leans on the wrong one fails only
when it is needed.** `execution_file` survives the failure, because `src/entrypoints/run.ts` calls
`setExecutionFileOutputIfPresent()` from its catch block. The file is an array whose last element is the
result, which is how upstream reads it in `update-comment-link.ts`. And `show_full_output: true` was rejected
rather than overlooked: it is the only switch on offer, it dumps every message including tool results into a
public log, and its own description warns it may carry secrets. Reading the file keeps the disclosure to the
fields that name the failure -- which is also why the step runs on failure only, where `result` holds an error
instead of review prose about the diff.

`claude.yml` has the identical blindness and is deliberately left alone: it answers a human who typed
`@claude` and is already reading the thread when it breaks. This check runs unattended on every PR, which is
what makes its silence expensive.

**Score:** 2

#### What makes this deploy extra special

N/A -- `.github/workflows/claude-code-review.yml` is this repo's own CI. It is not plugin payload, it ships
in no release, and no consumer of the specialists plugins ever reads it. The mechanism generalises to any repo
running `claude-code-action`, but nothing here delivers it to one.

**Score:** N/A

#### Pull Request

The claude-review failure names its own reason

