# `fix/sync-floor-anchors-on-the-subject` cycle · 20260821-175354

## PLAN

- [x] Verify inbound #819 all four ways before scoping it, per the intake rule. **Symptom:** stands --
      `Get-SyncReferencePoint` still greps the whole message. **Reason:** stands -- `--grep` is
      line-oriented and `--no-merges` removes only merge commits. **Named mechanisms:** both real,
      `Invoke-SyncGitQuiet` and `Get-SyncDefaultReferencePattern` exist under exactly those names.
      **Count:** re-measured independently rather than inherited.
- [x] Reproduce it on a SECOND history instead of trusting the consumer's shas, which this checkout
      cannot resolve. This repo has zero sync subjects and the lookup still answered
      `5f3a40cb fix: ...` -- six false positives in 2,012 commits. Starker than the reported instance,
      so that is the one the docstring keeps.
- [x] Settle the prefilter question before writing, because it is the only real design choice here.

## CREATE

- [x] `Get-SyncReferencePoint`: the pattern is applied to the SUBJECT field (`%H%x09%s`, split on tab)
      and `--grep` is gone entirely. `--no-merges` stays for legibility -- a merge's own subject is
      `merge:`, so the anchoring already excludes it.
- [x] `--grep` was NOT kept as a prefilter, though it is a strict superset and would have been correct.
      It would make correctness depend on git's POSIX BRE and .NET's engine agreeing about a pattern a
      CONSUMER supplies through the seam, failing as a silently-too-recent floor. Measured the cost of
      dropping it at 2,012 commits: 94 ms against 48 ms. The reasoning is in the docstring, not just here.
- [x] Both `sync-rules.ps1` docstrings repaired. The old one claimed `--no-merges` "separates a subject
      from a body line", which is the sentence that stopped anyone looking again -- it is now stated as
      necessary-and-not-sufficient, with both measurements.
- [x] The two other places that stated the retired conclusion as fact: `sync-main.ps1`'s header note and
      the consumer-facing `sync-main` skill page. Found by grepping `--no-merges` across the tree rather
      than by memory; `CHANGELOG.md` and `releases/` deliberately left alone, being published records.
- [x] Mirrors rebuilt with `build-shared-scripts.ps1` -- `sync-rules.ps1` and `sync-main.ps1` are held
      byte-identical to their team-shopify copies.

## TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: 46 -> 51 asserts. The new `ref/chatty` fixture is the case
      that had no coverage at all -- one parent, subject `fix:`, body line opening with `sync`.
- [x] Its regression half passes `--no-merges` EXPLICITLY and asserts the old shape still picks the body
      line, so "necessary and not sufficient" is pinned by a failing-without-the-fix assert rather than
      asserted in prose.
- [x] `ref/merged` relabelled rather than deleted: it still passes, but no longer for the reason its
      label gave. Same treatment the previous branch gave the `## For consumers` asserts.
- [x] The seam is re-asserted on the new axis -- a narrowed pattern that no SUBJECT matches must answer
      `$null`, not fall back to the body line.
- [x] `sync-rules.tests.ps1` green: 51/51. Lint gate 0 errors, script contract 0 errors, branch-entry gate
      green at tier 0: 3, tier 2: 5. Mirrors in sync.
- [x] The FULL gate, not a hand-rolled loop: `Invoke-TestSuiteGate` over all 49 suites, **49/49 in 177s**.
      Run twice, the second time keeping the whole log, because the first run's output was `tail`-truncated
      and I had drawn a conclusion from the visible part.

## DEPLOY

- [x] PR, CI, merge, fold. Default route -- no visible result, nothing irreversible, so it does not wait.
      `-Resolves 819`. The first `ship-pr` run was refused by the step-list gate for this very line, which
      is the gate working: a branch reaches a PR when its own plan is finished, and nothing was pushed.

## Where I left off

**A side finding, filed as [#821](https://github.com/DaveKJohn/claude-code-specialists/issues/821) and
deliberately not repaired here** -- and the way I got it wrong first is the part worth keeping.
`sync-main.tests.ps1`'s `quotepath` assert fails when the suite is run **on its own** (n=3, deterministic;
also with the gate's exact `Start-Process` arguments) and **passes under the gate** and in CI. Proven not
mine by stashing the whole branch and re-running.

I filed it as *"fails locally, passes in CI, and the local gate blocks on it"*. Both halves were wrong:
platform is not the axis (CI is `windows-latest` too), and **the gate does not block -- it is 49/49**. I
had read a `tail`-truncated log and taken the visible part for the whole. Running the real gate and
keeping all 4,066 lines is what corrected it, and #821 was rewritten with the correction stated rather
than edited away. The mechanism is still **not established**, so no fix is proposed: the obvious
`-c core.quotepath=false` would be built on an explanation that does not hold.

Still open beyond this branch: **#815** (nothing deletes a merged branch; the seven merged local branches
this session found were cleaned up by hand, which is the symptom rather than the fix), **#817** (the stale
`Write` on the two branch files), **#810** (the audience heading and the rubric docstring, partly answered
by #820). And the release delivering #801 + #807 + this to the two Shopify consumers is still waiting on
Dave's word -- it is now the third sync repair queued behind that decision, and the consumer is running
the incomplete version until it goes out.
