## `feat/gate-evidence-not-a-flag` progress

### Steps

#### PLAN

- [x] Verify the locked topic against the repo before acting on it -- mechanism confirmed
      (`ship-pr.ps1:207` shells out to `open-pr.ps1`, which gates at `open-pr.ps1:661`), and all four
      named mechanisms exist.
- [x] Measure the re-run over its population rather than from the release notes' series. 293 merged
      PRs, bimodal at 14s / 263s, excess 249s on 28.3%. Confound (a second CI run on the same sha)
      ruled out at zero of 83.
- [x] Correct the size in the report before building on it: the notes' five-figure series mixes the
      merge leg with the gate re-run inside it.
- [x] Put the one decision that is not a specialist's to Dave -- what makes the skip safe -- and get
      an answer. Evidence-based skip chosen.

#### CREATE

- [x] `scripts/lib/gate-lib.ps1`: fingerprint (HEAD + content hash of every dirty/untracked file),
      read/test/save/clear, age bound, all failure paths refusing.
- [x] Wire it into `open-pr.ps1`: one fingerprint for both gates, each gate consulting and recording
      separately, neither recording under its escape valve.
- [x] Register the pair in `shared-scripts-lib.ps1` and generate the mirror.
- [~] Move `Invoke-TestSuiteGate` into the new lib as `native-capture-lib.ps1`'s own note invites.
      Dropped from this branch deliberately: the move puts `ci.yml` -- the one check that blocks every
      merge -- into the same diff that changes gate behaviour, and the constraint that note actually
      states (do not widen `native-capture-lib`) is already met by the new file. Clean follow-up.
- [~] Give the skip a `-Force`-style override. Dropped: the evidence *is* the content, so a matching
      fingerprint means a re-run provably cannot reach a different verdict. `Clear-GateEvidence` exists
      for anyone who wants everything proved again, and a new flag would be one more knob that gets
      set to skip a gate.

#### TEST

- [x] `scripts/tests/gate-lib.tests.ps1` -- 46 asserts over a real `git init` fixture per case, not a
      stub returning canned porcelain.
- [x] Pin the case the whole design turns on: edit, gate, edit again with a different byte and the
      same status letter, and assert the record no longer covers it.
- [x] Pin that the wiring is REACHED, not just correct -- the lesson `pr-issues-lib` cost, where a
      pure decision table proved the decision and never that it was reached.
- [x] Pin that `ci.yml` neither loads the lib nor consults a record.
- [x] Suite green: 46 pass, 0 fail.

### Where I left off

The mechanism is built, mirrored and pinned. What remains is the ordinary chain: local gates, PR,
CI, merge, fold.

Two things worth watching on this branch's own run, because it is the first one to exercise the
change end to end:

- **The ship should visibly skip.** `open-pr.ps1` records both gates, then `ship-pr.ps1` calls
  `open-pr.ps1` again and should print `already proved against this exact tree -- skipped` for both
  rather than spending another four minutes. That is the change demonstrating itself, and if it does
  not happen the fingerprint moved between the two runs -- worth reading before assuming the record
  is at fault.
- **Ship WITHOUT `-SkipLint -SkipTests`.** Reaching for the flag out of habit would skip the gate on
  the very run that is supposed to prove the flag is no longer needed.

Two measurements are deliberately left for after the merge, since neither can be taken before it: the
observed excess on the next release cut, and whether the Mode B share falls in the weekly figures. The
issue this closes for the release notes is the standing "the merge re-runs the tests the pull request
already proved" item, named in five consecutive notes.

