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

The shape built here is the first of those two, and the narrowing turned out to be load-bearing
rather than optional: the gate skips only when **one named check**, declared by the repo itself, is
green on the **exact** commit this run would ship. That is not a new bar -- it is the certificate the
merge is already gated on.

#### The first draft was wrong, and two reviews found it from opposite sides

It trusted every record `gh pr checks --required` returned. Both readings of that are defects:

- **Any required check would do.** A consumer whose trunk requires a CLA bot, a PR-title linter or a
  theme-check would have its local test gate skipped the moment that check went green, with the
  suites never having run anywhere for that commit.
- **A green subset certified.** Where a trunk requires two contexts, the unrelated one registers and
  goes green first while the test check has not registered at all -- so the payload is non-empty,
  holds no failure, and certifies. That is the registration race `Get-RequiredCheckContexts` already
  documents, in its **partial** shape rather than its empty one, which is the shape a `Count -eq 0`
  guard cannot see.

Both close with the same repair, which is why the seam is here rather than in a follow-up: the repo
names the check, and a check that has not registered cannot be found.

#### Why the existing evidence record could not answer it

`gate-lib.ps1` already skips a gate it has proved, keyed on a **local** fingerprint (HEAD plus every
dirty and untracked file). That misses the expensive case by construction: `ship-pr` calls `open-pr`,
and between the two the branch is routinely brought forward onto a moved trunk. HEAD is then a commit
no local run has seen, the fingerprint misses, and the full suite runs on a commit CI has just
certified. So the repair is a **second evidence source**, not a change to the first.

### CREATE

- [x] `Get-CiTestCheckName` in `scripts/repo-config.ps1` -- the seam naming the check whose green
      proves this repo's suites (`lint-en-tests`), registered in the contract as **optional** with
      "no certificate, the gate runs" as its default, so the change arrives inert in a consumer.
- [x] `Get-CiTestCertificate` in `scripts/lib/gate-lib.ps1` -- pure, judging two SHAs plus the
      `gh pr checks --required` payload the caller fetched against that named check, so every refusal
      is reachable in a suite without a network or a PR.
- [x] Check names sanitised through `Get-DisplayRef` before they are printed **and** before they are
      compared -- the existing single source for externally-authored text reaching a terminal.
      `gate-lib` loads `ref-print-lib` itself, following `remote-ahead-lib` and `entry-scaffold-lib`
      rather than widening its caller contract.
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

- [x] `scripts/tests/gate-lib.tests.ps1` case 18: the happy path in one line, and a case for every
      way a false positive could arise -- a certificate issued for a different commit, no declared
      name, the named check **absent** from a non-empty payload (the race above), the named check
      present but pending, a red named check, and the four empty/unparseable payloads.
- [x] A hostile check name (ANSI escape plus a zero-width character) asserted to leave no control or
      format character in the printed note.
- [x] Case 19 asserts the wiring rather than the decision: the parameter's type, its position between
      the local record and the suites, that `open-pr` reads the seam defensively via `Get-Command`,
      that it asks for `--required`, that all three sanitiser call sites are present, and that the
      certificate branch writes **nothing** into the evidence record.
- [x] `gate-lib.tests.ps1` green on its own (153 pass, 0 fail); `check-script-contract.ps1` reports
      0 errors with the new seam answered; the config blueprint regenerated (37 records). The full
      gate is `open-pr`'s own run and is deliberately not pre-run here.
- [x] Verified against a real PR (#1716) rather than assumed -- the payload shape
      (`[{"bucket":"pass","name":"lint-en-tests"}]`), a real certified verdict, and both dangerous
      negatives: a mismatched head, and a seam naming a check the trunk does not require.

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

The skip is granted on **one named check**, declared by the repo in `Get-CiTestCheckName`, and never
on "whatever the trunk happens to require" -- which is what keeps it from standing a gate down on a
CLA bot's green, or on a neighbour check that went green while the test check had not registered.
Every ambiguity runs the gate: no declared name, no PR, a PR head that is not this HEAD, an
unreadable answer, an empty required set, the named check missing from it, or that check not green.

**Score:** 4

#### What makes this deploy extra special

The shorter cycle is opt-in, and it arrives switched off. A consumer gets today's behaviour until it
names the check that proves its own suites -- one line in `scripts/repo-config.ps1`, offered by the
adopt blueprint like every other seam -- so a plugin update cannot quietly stand down a gate in a
repo nobody has looked at. The reason it is a declaration rather than an inference: which of a
repo's checks actually runs its tests is a fact about that repo's CI that no script can read from the
tree, and guessing it wrong is silent in the one direction that matters.

**Score:** 4

#### Pull Request

The CI certificate satisfies the local test gate
