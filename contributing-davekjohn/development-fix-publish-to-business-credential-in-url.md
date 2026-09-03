## Development: `fix/publish-to-business-credential-in-url` · 20260903-152650

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

Issue #1313 reports that `scripts/release/ship-pr.ps1`'s fold-step `git fetch` -- and, by its own
sweep instruction, the same call in `worktree-lane.ps1` and `prune-merged.ps1` -- runs without
`-DiscardStderr` and echoes git's merged output on failure. Its stated reason: a failing fetch quotes
the remote URL, so on a clone whose HTTPS remote carries a credential, that credential reaches the
console and, under CI, a log. `new-branch.ps1` says exactly that at its own fetch, inline, which is
what the report leans on.

#### The reason was measured before it was repaired, and it did not survive

Per this repo's own rule -- *a reported finding's reason is verified before it is repaired, not just
its symptom* -- the reason was held against git rather than against the report. **git redacts the
credential itself.** Measured on `git 2.55.0.windows.5`, against a real failing fetch on a temp repo
whose remote carried `someuser:SUPERSECRETTOKEN@`:

| remote URL shape | git's failure line | token in the captured output |
|---|---|---|
| `https://user:token@github.com/o/r.git` | `fatal: Authentication failed for 'https://github.com/o/r.git/'` | no |
| `https://user:token@unresolvable.invalid/o/r.git` | `fatal: unable to access 'https://unresolvable.invalid/o/r.git/'` | no |
| `https://token@unresolvable.invalid/o/r.git` | same, userinfo gone | no |
| `https://unresolvable.invalid/o/r.git?access_token=token` | printed verbatim | **yes** |
| `https://unresolvable.invalid/token/o/r.git` | printed verbatim | **yes** |

git puts every such URL through `transport_anonymize_url`, which strips userinfo whole -- username
included. What it does not touch is a secret sitting elsewhere in the URL, and no remote of this
family is shaped that way.

**So the proposed repair was declined, and the reasoning is the trade it makes.** Dropping stderr at
those three call sites removes git's own diagnosis from three failure paths and buys nothing against
the shape the report names. One of the three is the worst place in the system to lose it:
`ship-pr.ps1`'s fold step runs when the PR is **already merged**, in the one gap nothing reports, and
git's reason is all a reader has. `prune-merged.ps1` is nearly as bad -- issue #1069 built that
warning *around* git's message as its fallback. A change that satisfies the report and is wrong is
worse than the defect, because it then carries a citation.

#### Where the report's reasoning does hold, and that half is repaired

Where a credential really does reach a log is where **we** compose the line rather than git.
`publish-to-business.ps1` takes `-TargetRepo` as either `owner/repo` or a URL verbatim -- and the
verbatim form is where an operator publishing without gh auth pastes
`https://<user>:<token>@github.com/o/r.git`. That value was then printed on **every** run (the
`Target :` banner), again on a clone failure (`Could not reach ...`), again on success, and embedded
in `Invoke-Git`'s throw message, whose first three lines the clone's own error handler prints. Our
interpolation of a value we were handed: git's redaction never gets a say. That is the standing half
of #1313, and it is fixed here.

### CREATE

- [x] Measured the reported hazard against git itself, in three credential shapes plus two
      non-userinfo ones -- the table above.
- [x] Declined `-DiscardStderr` at `ship-pr.ps1`'s fold-step fetch, `worktree-lane.ps1`'s and
      `prune-merged.ps1`'s. Those three files are untouched by this branch.
- [x] `scripts/release/publish-to-business.ps1`: added `Format-UrlForDisplay`, which masks a URL's
      userinfo to `***@`, and routed every print through a single `$urlShown` rather than masking at
      each `Write-Host` -- so a print added later cannot be the one that forgets. `Invoke-Git`'s throw
      now masks its **arguments** too, which is where the clone and the `remote add` carry the URL.
      Userinfo only, deliberately: that is the part a URL is guaranteed to carry a secret in, and
      guessing at which path segment is a secret produces a mask nobody can trust.
- [x] `scripts/task/new-branch.ps1`: corrected the inline comment the report leans on. The flag stays
      -- nothing there reads git's progress and the message is complete without it -- but the security
      reason is gone, replaced by the measurement and by a note that it must not become a precedent.
      That comment reading as a rule is what put three other call sites on the table.
- [x] `scripts/lib/native-capture-lib.ps1`: stated it at the seam every caller reads --
      `-DiscardStderr` is not a credential guard, the measurement, the declined repair, and why
      `Invoke-GitPark`'s push keeps stderr on purpose (#1143). *If you are about to print a URL, mask
      it; if you are about to hide git's output, ask what the reader is left with.*
- [x] Rebuilt the plugin mirrors (`build-shared-scripts.ps1`) -- `new-branch.ps1` and
      `native-capture-lib.ps1` travel; `publish-to-business.ps1` is root-only.

### TEST

- [x] `publish-to-business.tests.ps1` case 12: against a deliberately unreachable target, so the
      banner, the clone failure and the thrown command line are all exercised. Asserts the **token**
      is absent (not just that a mask is present -- a refactor that composes the line differently
      still has to keep the secret out), that the userinfo shows as `***@`, that the username went
      with it, and -- the other half -- that a URL **without** userinfo is printed untouched, so an
      ordinary run does not read as though something were hidden.
- [x] Proved the test catches the regression: with `publish-to-business.ps1` reverted to `HEAD`, the
      three credential asserts fail (`3 failed, 66 passed`); with the fix, `69/69`.
- [x] `check-plugin-integrity.ps1`: 0 errors, run directly.
- [x] The full suite set is left to `open-pr.ps1`'s gate and to CI, both of which block on any
      failure -- a second copy started ahead of them proves nothing they would not catch, and two
      concurrent suite runs share one console, which is its own measured hazard (#821).

### DEPLOY: `fix/publish-to-business-credential-in-url`

A credential pasted into `publish-to-business.ps1`'s `-TargetRepo` no longer reaches the console or a
CI log: the userinfo is masked at every print and in the thrown command line. The reported hazard in
`ship-pr.ps1`, `worktree-lane.ps1` and `prune-merged.ps1` was measured against git and declined --
git redacts userinfo itself (`transport_anonymize_url`), so dropping stderr there would have cost
git's own diagnosis, including at the fold step where the PR is already merged, and bought nothing.
The measurement is now stated at the seam in `native-capture-lib.ps1` and the overstated comment in
`new-branch.ps1` that the report leaned on is corrected, so the next reader neither re-files it nor
applies the guard on a reason that does not hold.

**Score:** 3

#### What makes this deploy extra special

It is the declined half that matters. The issue arrived with a plausible reason, a documented
in-repo precedent, and a one-line fix at three named call sites -- and the fix was wrong at all
three, while the one call site the report never mentioned was leaking for real. What separated them
was ten minutes of holding the reason against git instead of against the report. The repair therefore
changes what the tree *says* as much as what it does: a comment that read as a rule is now a
measurement, and the seam tells the next caller which question to ask.

**Score:** N/A

#### Pull Request

Mask a credential-laden -TargetRepo in publish-to-business's output
