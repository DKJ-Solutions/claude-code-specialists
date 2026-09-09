## feat/1715-ci-certificate-skips-third-gate

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### What #1715 asked, and the shape chosen for it

The issue measured the same 84-85 suites running **three times** per pull request and deliberately
left the fix open: *"Whether `ship-pr` should skip the suites when the required check is already
green on the head commit, or gate that on something narrower, is the owner's call."*

The shape built here is the first of those two, with the narrowing put where it costs nothing: the
gate skips only when the trunk's **required** checks are green on the **exact** commit this run
would ship. That is not a new bar -- it is the certificate the merge is already gated on.

#### Why the existing evidence record could not answer it

`gate-lib.ps1` already skips a gate it has proved, keyed on a **local** fingerprint (HEAD plus every
dirty and untracked file). That misses the expensive case by construction: `ship-pr` calls `open-pr`,
and between the two the branch is routinely brought forward onto a moved trunk. HEAD is then a commit
no local run has seen, the fingerprint misses, and the full suite runs on a commit CI has just
certified. So the repair is a **second evidence source**, not a change to the first.

### CREATE

- [x] `Get-CiTestCertificate` in `scripts/lib/gate-lib.ps1` -- pure, judging two SHAs plus the
      `gh pr checks --required` payload the caller fetched, so every refusal is reachable in a suite
      without a network or a PR.
- [x] `Invoke-WorkflowGates` takes `-TestsProvedByCi <note>` and consults it **after** the local
      record and **before** the suites. A string and not a switch: the note is the whole value, since
      a skip nobody can read is a gate nobody can audit.
- [x] `scripts/release/open-pr.ps1` computes the certificate, but only where a PR already exists and
      the suites were going to run -- so the first `open-pr` of a branch and the `-GatesOnly` route
      are untouched.
- [x] Mirrored to `plugins/dkj-policy/scripts/` via `scripts/sync/build-shared-scripts.ps1`, so the
      consumer copy and the source cannot drift.
- [x] The `open-pr` skill page documents it, including what it refuses and why the lint half is not
      skipped this way.

### TEST

- [x] `scripts/tests/gate-lib.tests.ps1` case 18: the happy path in one line, and a case each for
      the two ways a false positive could arise -- a certificate issued for a different commit, and a
      green **subset** of the required checks. Plus the four empty/unparseable payloads, which are
      the ambiguous answer and must resolve toward running the gate.
- [x] Case 19 asserts the wiring rather than the decision: the parameter's type, its position between
      the local record and the suites, that `open-pr` asks for `--required`, and that the certificate
      branch writes **nothing** into the evidence record.
- [x] `gate-lib.tests.ps1` green on its own (144 pass, 0 fail) and all four touched files
      parse-checked -- source and mirror. The full gate is `open-pr`'s own run and is deliberately
      not pre-run here.
- [x] The `gh` payload shape verified against a real PR (#1716) rather than assumed:
      `[{"bucket":"pass","name":"lint-en-tests"}]`, fed back through the function for a real
      certified verdict.

### DEPLOY: feat/1715-ci-certificate-skips-third-gate

The local test gate stops re-proving what CI has already proved. `open-pr` now asks whether the
trunk's required checks are green on the exact commit it would ship, and where they are, the suites
do not run again -- naming the check and the commit that carried the skip. Measured on PR #1708, that
was a third run of 85 suites at ~30 minutes, started while `lint-en-tests pass` was already on the
screen.

The wall-clock is the cheaper half. A ~40-minute cycle loses races a shorter one wins: on that same
PR the trunk moved during the third run, the stale-CI gate refused correctly, the re-run went
`CONFLICTING`, and a two-file docs change took over two hours. Shortening the window is what stops
those gates from firing, and it needed no gate to be relaxed -- the certificate skipped for is the
one the merge is blocked on anyway.

Every ambiguity still runs the gate: no PR, a PR head that is not this HEAD, an unreadable answer,
zero required checks, or any required check not green. A repo with no required check therefore keeps
its full local gate, which is the correct answer rather than a gap.

**Score:** 4

#### What makes this deploy extra special

Every repo running this workflow gets the shorter cycle with the plugin update -- no configuration
and no new seam. A consumer whose trunk requires no status check is unaffected by construction, so
the change cannot quietly remove anyone's only gate.

**Score:** 4

#### Pull Request

The CI certificate satisfies the local test gate
