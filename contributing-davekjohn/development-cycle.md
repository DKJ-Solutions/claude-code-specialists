## Development cycle: `fix/review-quota-names-itself-v1` · 20260827-111830

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

#### What issue #966 reports, and where its reason is wrong

#966 measured that `claude-review` fails with `is_error: true`, one turn, zero cost, and inferred a
credential problem -- an expired or revoked `CLAUDE_CODE_OAUTH_TOKEN` -- while saying plainly that it
could not confirm that. It could not, and it is not the reason. Read out of the very run the issue
links ([33056222345](https://github.com/DaveKJohn/claude-code-specialists/actions/runs/33056222345)):

```
api_error_status: 429
result:           You've hit your session limit - resets 11:20am (UTC)
```

The same on the other three failing runs, which is what makes it a class rather than an incident:

| run | turns | cost | `api_error_status` | `result` |
|---|---|---|---|---|
| 33056222345 (Aug 27, 08:56) | 1 | 0 | 429 | resets 11:20am (UTC) |
| 33054812488 (Aug 27, 08:37) | 2 | 0.1984566 | 429 | resets 11:20am (UTC) |
| 32990599729 (Aug 26, 16:49) | 1 | 0 | 429 | resets 5:20pm (UTC) |
| 32990367604 (Aug 26, 16:47) | 1 | 0 | 429 | resets 5:20pm (UTC) |

So the token authenticates and the account behind it is out of session quota. **Nothing needs
rotating**, and the issue's premise for filing rather than fixing -- "rotating a repo secret needs
Dave, and nothing in a session can do it" -- does not apply.

Two corrections to the measurement while it is on the table. The issue dates the break to "somewhere
between 20:30 yesterday and 08:36 today". Two runs at 16:47 and 16:49 yesterday had already failed with
the identical 429, so there is no start time to find: this is recurring quota exhaustion, and today is
its **second** window. And the 08:37 run spent `0.1984566` over two turns with one denial -- it had
begun reviewing and was cut off mid-run, so the limit hits both before the first turn and during.

#### The actual defect: #913 made the reason available, not legible

The claim that "the action prints no underlying message" was true when #913 was filed and is not true
now: the **"Why the review failed"** step that #913 produced printed both the 429 and the human
sentence into the log of every one of those runs. The answer was already there.

What a reader sees first, though, is the action's own `##[error]Claude result reported subtype success
with is_error:true` -- and a careful reader (Dave, in #966) read that run and concluded credentials.
That is the measurable defect and the only thing here worth changing: the reason lives in the body of
a second step's log, and the loud line at the top of the page says nothing.

#### What this branch does NOT do, deliberately

**It keeps the check red.** A 429 means this PR got no review, and #966's own stated harm is that PRs
merge without the review pass **silently**. Turning the failure green would deepen exactly that. Red
is the correct signal; what is wrong is that red is unreadable.

**It does not touch quota consumption.** Whether the review earns its share of a shared session
window -- skipping docs-only PRs, a cheaper model, a separate account -- is a decision about what the
dependency is worth rather than a defect, and it is Dave's.

### CREATE

- [x] Surface the reason where a reader lands: an `::error title=...::` annotation and a
      `$GITHUB_STEP_SUMMARY` block, named per `api_error_status` (429 quota, 529 overload, anything
      else generic), appended to the existing diagnostic step so the log dump still runs first
- [x] Record the structural fact nobody would guess: the OAuth token is a subscription credential
      whose session window is shared with interactive use, so this workflow starves on a busy morning
- [x] Hold the safety bound the existing step already reasons about -- the annotation carries no text
      the log did not already carry, first line only and length-capped

### TEST

- [x] `check-plugin-integrity.ps1` + all suites green (the gate `open-pr.ps1` runs)
- [x] The jq expressions exercised against the real execution-log shape from a failing run, including
      the no-result-message path

#### What the fixtures caught, which is why they exist

Six execution-log fixtures were run against the exact body the workflow ships -- extracted back out of
the parsed YAML, not out of the draft, so the tested artefact is the shipped one. They found three
defects in the first version, all of them in the paths a real failure is least likely to take:

1. **jq's `split` on an empty string returns `[]`, not `[""]`.** So `split("\n")[0]` was null on a
   result message carrying no `result` field, and `-r` printed the literal word `null` -- the
   annotation read "... named no API status. null" and the summary's fallback text never fired,
   because the variable was not empty, it held four characters.
2. **`%` reaches the runner's percent-decoder.** An unescaped `%0A` inside `result` would have become
   a newline in the rendered annotation. It cannot forge a second workflow command -- one only counts
   at the start of a line and the message is capped to one -- but a diagnostic that renders wrong is
   this step's own failure mode.
3. **A `|` in `result` broke the summary table.** The reason is free text and was going into a table
   cell; it is a blockquote now, which needs no escaping at all.

The remaining fixtures cover two of the four real 429 runs (including the one that spent `0.1984566`
over two turns before being cut off), a 529, a missing result message, and an unknown status with
quotes, a comma and a `::` in the reason. All six exit clean and produce exactly one annotation.

#### Why the fix could not be demonstrated on its own PR, and what that turned up

The intention was to let this branch's own PR prove the annotation, since the quota window was still
open when it went up. It did not, and the reason is worth more than the demonstration: a pull request
that MODIFIES this workflow gets no review at all. The action validates the file against the copy on
the default branch, logs `Skipping action due to workflow validation`, and exits SUCCESSFULLY -- green
check, nine seconds, no review. So the diagnostics never fired, because they only run on failure.

That is correct behaviour and the same guarantee the `pull_request` trigger buys, one level up: a PR
must not review itself under rules it has just rewritten. But it was written down nowhere, and it is
this branch's own subject wearing the opposite colour -- a check that says nothing while looking like
it said yes. It is recorded at the top of the workflow now, beside the fork note it belongs with.

### DEPLOY: `fix/review-quota-names-itself-v1`

A red `claude-review` now says why it is red where a reader actually lands -- in the run's annotation
list and on its summary page -- instead of only in the body of a diagnostic step's log. #913 put the
reason in that log; this puts it in front of the person reading the PR.

The reason it needed doing is that the log was not enough, measured rather than supposed. #966 was
filed against a run whose log already read `api_error_status: 429` with
`result: You've hit your session limit`, and concluded the cause was an expired OAuth token and the
repair a rotated secret. Neither is true: the token authenticates, the account behind it is out of
session quota, and there is nothing to rotate. The line a reader meets first was the action's own
`Claude result reported subtype success with is_error:true`, which names nothing at all.

Two things this deliberately does not do. **The check stays red on a 429** -- that means the PR got no
review, which is exactly what #966 wanted not to be silent, and a green check would hide it better
than an unreadable red one. **Quota consumption is untouched**: `CLAUDE_CODE_OAUTH_TOKEN` is a
subscription credential, so the session window it draws on is the same one interactive use draws on,
and a morning of heavy local work starves the review of every PR opened in that window. Whether the
review earns its share of that window is a decision about what the dependency is worth, not a defect,
and the workflow now states the mechanism so the next reader does not have to rediscover it.

For somebody maintaining this repo the gain is one specific hour back: the next time this goes red,
the summary page says `out of quota -- the review did not run` and nobody re-derives the credential
hypothesis. It is a 3 rather than higher because it changes no gate, blocks no merge, and is noticed
only on a failing run -- but this has now failed on four runs across two days, so that is not rare.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches that reader. `.github/workflows/` is this repo's own CI and ships in no plugin, so a
consumer sees none of it -- not the workflow, not the diagnostic, not the annotation.

**Score:** N/A

#### Pull Request

The 429 review failure names its own reason where a reader sees it
