## Development: `fix/claude-review-presdk-failure-silent-v1` · 20260902-195945

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

A claude-review failure that happens BEFORE the Claude SDK runs -- the 401 'app not installed' of #1245 is the measured case -- leaves execution_file empty, so the 'Why the review failed' step is skipped and no TITLED annotation is written. Get-AuthoredFailureNote selects only titled failures, by design, so ship-pr relays NOTHING and the operator meets a red tick with no reason. Add the complementary diagnostic step for the pre-SDK class.

### CREATE

- [x] `.github/workflows/claude-code-review.yml` — the **complementary** diagnostic step, gated on
      `steps.claude-review.outputs.execution_file == ''`, writing a titled `::error` annotation and a
      job-summary section. The comment block states what an empty output proves and what it therefore
      may not claim.
- [x] The same step escapes its headline (`${headline//%/%25}`) although every character of it is a
      literal — #1118's lesson, not belt-and-braces. See TEST for why the count is pinned rather than
      a `-ge`.
- [x] `.claude/specialists/lenses/05-15-extension.md` — the next entry in the #1103 → #1112 → #1116
      narrative, including #1245's own transferable sentence (*verify the capability, not the
      artefact*) and what is explicitly **not** in this repo's gift.
- [~] The app install itself — **dropped, and not droppable any other way**: installing the Claude Code
      GitHub App on the `DKJ-Solutions` organisation is an account-level action, and the session's `gh`
      holds `write` here rather than `admin`. Reported to Dave instead. This branch makes the failure
      legible; it cannot make it stop.
- [~] A consumer-facing page for the titled-annotation contract — **dropped as out of scope** and filed
      as [#1251](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1251). The relay ships to
      consumers while this workflow does not, and `annotation` appears in three shipped `.ps1` files and
      zero shipped `.md`. Which page it belongs on is the technical writer's call.

### TEST

- [x] **The symptom was verified before anything was repaired, and it still stood.** Run
      `33663986438` (17:55, September 2, 2026) — two hours after the transfer PR — same 401 on the
      app-token exchange. Step *Run Claude Code Review* `failure`, step *Why the review failed*
      **`skipped`**, and the job's only failure annotations were the runner's two **untitled** ones.
      That is the mechanism the repair addresses, read off the API rather than inferred.
- [x] **The step was executed, not just written.** Its shell body extracted and run with
      `GITHUB_STEP_SUMMARY` pointed at a file: the `::error title=claude-review -- the review never
      started::…` command renders on one line, and the summary section renders as intended. `bash -n`
      clean; every non-blank line under `run: |` at ≥ 10 spaces, so the block scalar is intact; step
      keys at the same indentation as the sibling step.
- [x] **22 new asserts in `scripts/tests/pr-issues.tests.ps1`**, and what they pin is the **coverage**,
      not the wording — a rewrite of either sentence passes, deleting the second step does not:
      - both halves of `failure()` are diagnosed, and **exactly once each**, so no class falls between
        them;
      - the step's `short` and `headline` are read **out of the workflow** rather than re-typed, so the
        asserts cannot drift from the file they describe;
      - end to end through `Get-AuthoredFailureNote` — the function `ship-pr` actually calls — on the
        real captured payload: the authored sentence comes back, and the runner's untitled 401 does
        **not**, which is the lib change #1112 ruled out;
      - the note is **356 characters against the relay's 500** and carries no reason to be cut from, so
        it must arrive whole and unmarked by the ellipsis;
      - the headline may not mention 429, 529, quota or a reset — that class arrives *with* a result
        message and belongs to the other step.
- [x] **Two pre-existing #1118 asserts went red, and that was correct.** The new step is a third
      `::error` emission site. Rather than exempt a literal-only site, it now escapes like the other
      two and the count moved 2 → 3 — the invariant is *every* site, because #1118 was the branch that
      needed no escape until somebody interpolated into it. The comment above the assert now says why
      the count is the property.
- [x] `pr-issues.tests.ps1`: **415/415**. `check-plugin-integrity.ps1`: **0 errors** (35 checks,
      including `[shared-script] 47` — the lib was not touched, so no plugin mirror drifted).

### DEPLOY: `fix/claude-review-presdk-failure-silent-v1`

`claude-review` no longer goes red in silence when it fails **before** the Claude SDK is reached. That
class — a bad credential, missing action inputs, or the GitHub App not being installed — leaves
`execution_file` empty, which skipped the **Why the review failed** step entirely, so the workflow wrote
no titled annotation and `ship-pr`'s relay had nothing to print. The operator got a red tick and a blank
reason line, indistinguishable from a workflow with nothing to say.

**The workflow now has the complementary gate**, and the tests pin that both halves of `failure()` are
covered so a class cannot fall between them again. The repair went into the workflow rather than into
`Get-AuthoredFailureNote`, for the reason #1112 settled: teaching the relay to read *untitled*
annotations would relay "Process completed with exit code 1" in every consuming repo. A workflow that
wants to be heard writes a title.

**What the new sentence may claim is the constraint, not its wording.** It states only what an empty
output proves — the SDK produced no result, so this is the setup and not the diff, and no
`api_error_status` exists to read. It does not name the cause, because the step cannot read it: the cause
is in the runner's untitled annotation and the step log. The app installation is cited in the job summary
as the *measured instance*, never as the diagnosis, which is #966's mistake with the sign flipped.

**The failure that produced this is still live and is not repairable here.** The Claude Code GitHub App
did not follow the transfer into `DKJ-Solutions`, so both `claude.yml` and `claude-code-review.yml` are
inert on a 401 — an account-level install, like the spend limit #1164 needed. The transferable lesson,
now in the system-administration lens beside its sibling #1244: **after a transfer, verify the
capability, not the artefact that represents it.** #1239's checklist confirmed the Actions secret
survived, and it had — while both workflows depending on it were dead anyway, one layer further out than
the check reached.

**Score:** 3

#### What makes this deploy extra special

N/A — nothing here reaches that reader. `.github/workflows/claude-code-review.yml` is this repo's own CI
and ships to nobody, and `pr-issues-lib.ps1` was deliberately not touched, so no plugin mirror moved.

The half a consumer *does* inherit is split out rather than folded in: `ship-pr` relays only a **titled**
annotation, and no shipped page says so — `annotation` appears in three shipped `.ps1` files and zero
shipped `.md`, so a consumer's own advisory check can go red with a blank reason and no way to learn that
`echo "::error title=X::Y"` is the whole price of admission. That is
[#1251](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1251).

**Score:** N/A

#### Pull Request

claude-review names a pre-SDK failure instead of going red in silence
