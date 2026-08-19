# `fix/retired-seam-scaffold` cycle · 20260820-005320

## PLAN

- [x] Verify inbound #763's claim that the contract marks `Get-ChangelogHeading` required -- it does not
- [x] Find what the consumer actually hit, since the reported reason is not it

## CREATE

- [x] `bootstrap.ps1`: the whole block goes -- comment, variable and function
- [x] `ship-pr.ps1`'s header stops naming the retired seam as one the fold reads
- [x] The three unquoted `-Resolves 331,332` examples, plus a note on why the quotes are load-bearing
- [x] Mirror rebuilt (`open-pr.ps1`, `ship-pr.ps1`)
- [~] A seam that can say "not applicable" -- not built: the function is retired, so the repair is to stop
      writing it, not to give it a vocabulary
- [~] Reaching consumers who already have the dead function -- impossible by design (write-once scaffold);
      `INSTALL.md` already tells them they may delete it

## TEST

- [x] `bootstrap-drift.tests.ps1`: the assert flipped to absence, on the block rather than the function
- [x] That suite green -- 126 asserts, including the pre-existing core-only case that already required
      absence, so the two halves of the file now agree
- [x] `check-plugin-integrity.ps1` green
- [x] All test suites green
- [x] The `-Resolves` failure reproduced twice before being called a defect: on the real script, and on a
      four-line probe that also shows a scriptblock behaving differently

## DEPLOY

## Where I left off

Done. #763's second half was closed earlier tonight with evidence (the folder `[ERROR]` comes from a hook
that ships only with `workflow-davekjohn`, and `workflow-default` is the "no workflow chosen" slot the
reporter had already switched to). This closes the first half, so the issue goes with it.

The transferable part is not the seam: it is that **two suites in this repo asserted opposite things about
one string for fifteen days**, and neither was red, because they test different fixtures. A retirement is
not finished when the source stops using something -- it is finished when the thing that WRITES it for
somebody else stops too.
