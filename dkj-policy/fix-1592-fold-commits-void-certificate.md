## fix/1592-fold-commits-void-certificate

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

#### The reported reason did not hold, so the repair is not where #1592 proposed it

#1592 read `lint-en-tests finished in 2s` off the check table and concluded that ship-pr's wait on
the NON-required `claude-review` check is what made the certificate stale. Verified first, per the
repo's own rule that a finding's reason is checked before its symptom is repaired:

- That `2s` is the **aggregator job's** own elapsed. `lint-en-tests` in
  [`ci.yml`](../.github/workflows/ci.yml) is `needs: [lint, suites]` on ubuntu and compares two
  strings, so it cannot conclude before the windows legs it waits on. CI itself takes 5-7 minutes,
  which is what the certificate's window actually is. The report's own table already showed this --
  `wait 11m45s` minus `after last required check 5m57s` puts the required check at 5m48s.
- The non-required check governs **8 of the last 40** paired `pull_request` runs (20%, median excess
  0s), which **reconfirms** #831's own n=100 finding of 23% rather than overturning it. So the wait
  stays exactly where Dave left it, and #1592's options 2 and 3 lose their premise with it.
- Of the two refusals, **attempt 3 was already lost before its certificate was valid**: its first
  voiding commit landed at 08:33:02Z, the required check concluded at 08:37:06Z.

What both refusals actually turned on: **all three voiding commits were folds** -- 4ea4f31b,
437366a4 and 072bb6bd, each one `dkj-policy/CHANGELOG.md` plus the deletion of one branch document
and nothing else. Folds are 10 of the trunk's 19 first-parent commits in that window and 71 of 169
(42%) over the four days to it.

#### Why exempting the fold is not the path filter #1292 declined

#1292's verdict declines to ask which files an **arbitrary** gained commit touched, because it
would have to guess that commit's reach. A fold is not arbitrary: this workflow writes it, straight
onto the trunk, under an exception whose bound `CLAUDE.md` states as exactly two paths and which
`fold-changelog-entry.ps1` enforces with git rather than with care. It carries no script, no test,
no manifest and no agent def, so it cannot be the hazard #1292 was filed on -- a test block reaching
`main` that the shipping branch's CI never executed.

Ruleset options 1 and 2 are Dave's own act and were not reached for; neither shortens the window
anyway, so nothing here waits on them.

### CREATE

- [x] `Test-IsFoldOnlyCommit` in `scripts/lib/pr-issues-lib.ps1`: pure, reads a commit's own
      `--name-status` diff, and returns true only for the fold's shape -- the changelog written plus
      at least one branch document deleted, nothing else in the diff. Fails closed on every missing
      or unreadable input.
- [x] `Get-StaleCertificateVerdict` gained `-ExemptCommits`, reporting `ExemptCount`/`ExemptCommits`
      beside the unchanged verdict. Omitted, the answer is byte-for-byte the pre-#1592 one.
- [x] ship-pr step 3b classifies each gained commit (one local `git show`, only when the trunk has
      moved), reads both halves of the bound from the repo's own seams, and says what it discounted
      on the passing path and inside the refusal.
- [x] The measurement above recorded at the seam -- the function's own header and step 3b's block
      comment -- rather than only in this document.

### TEST

- [x] 53 new asserts in `scripts/tests/pr-issues.tests.ps1`: the fold's shape, every way of not
      being one (a script or test riding along, a rename, a copy, a nested path, a reserved page, a
      deleted changelog, a space-separated line), the fail-closed paths, the exemption arithmetic,
      and step 3b's wiring. Suite green at 732 asserts.
- [x] Classifier driven against the real commits: 4ea4f31b, 437366a4, 072bb6bd and 7a755c8b read as
      folds; the two PR merge commits beside them do not.
- [x] Full lint gate and all suites via `open-pr.ps1`.

### DEPLOY: fix/1592-fold-commits-void-certificate

`ship-pr`'s stale-certificate gate no longer refuses on a **fold** commit. A commit whose entire
diff is the changelog plus the removal of a branch document is written by this workflow itself,
under an exception bounded to those two paths, and carries no script, test, manifest or agent def --
so it cannot be the case the gate was built for: a test block reaching the trunk that the shipping
branch's CI never ran. The commit's own diff decides that, never its subject line, and every
unreadable input leaves the commit counted exactly as before.

It is why detect-and-rebase can converge on a busy trunk. Shipping PR #1571 took four attempts and
about an hour; the three commits that voided its two refused certificates were all folds, and both
refusals would have passed. Folds are 42% of this trunk's first-parent commits, so the rate at which
the trunk voids a certificate roughly halves -- against a window that is about as long as CI takes
(5-7 minutes) and cannot be made much shorter.

Nothing changed at the wait. #1592 attributed the window to the non-required `claude-review` check,
reading `lint-en-tests finished in 2s` off the check table; that 2s is the aggregator job's elapsed,
and measured over 40 paired runs the non-required check governs 20% of them at a median excess of 0s
-- reconfirming #831 rather than overturning it.

**Score:** 4

#### What makes this deploy extra special

N/A -- no subscriber of a service notices this. It is entirely internal to how a branch reaches the
trunk in this repo and in every consumer running the workflow.

**Score:** N/A

#### Pull Request

The staleness gate no longer refuses on fold commits

