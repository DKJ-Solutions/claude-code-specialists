# `docs/release-notes-on-main` cycle · 20260823-101613

## PLAN

- [x] Measure the reach: every place that states the direct-on-`main` exception count or the route
      the hand-written release documents take (11 files, `releases/` and `CHANGELOG.md` excluded as
      history)

## CREATE

- [x] `cut-release/SKILL.md`: step 4 becomes a direct commit on `main` with its bound written out;
      step 2's route line and step 0a's second pass follow it
- [x] `cut-release.ps1`: the header comment, the step-4 docstring and the closing `Write-Host` line
- [x] Mirror `cut-release.ps1` into `plugins/workflows/workflow-davekjohn/scripts/release/`
      (held byte-identical)
- [x] Root `CLAUDE.md`: two exceptions become three, the new one bounded; the constitution's summary
      line and the closing-steps sentence follow
- [x] `workflow-davekjohn/CLAUDE.md`: retitle the section, and rewrite "Who writes what, around a
      cut" as the third exception
- [x] `workflow-davekjohn/CONTRIBUTING.md`, root `README.md`: the count
- [x] `RELEASES-portable.md`: "Where the hand-written note lands", plus the two count/one-motion
      mentions
- [x] Rendall's lens `05-06-extension.md`: the route paragraph, the count, and the split summary
- [x] `.claude/handover.md` and the lint comment in `check-plugin-integrity.ps1`

## TEST

- [x] `check-plugin-integrity.ps1` green
- [ ] All suites in `scripts/tests/` green

## DEPLOY

- [ ] Open the PR, wait for `lint-en-tests`, merge, fold

## Where I left off

The historical statements are deliberately left standing where they are records rather than rules:
`RELEASES-portable.md`'s "the body used to be a hand-written document merged via its own branch + PR"
and PR #432 as the worked instance of the old route. The v4.4.0 timing measurement keeps its figure
and gains a sentence saying it was taken under the PR route, so the tail should be re-measured rather
than reasoned about.

Two things the change deliberately does not touch, both named in the docs so nobody repairs them by
accident: the tag still holds the *draft* (the cut commits and tags in one motion, so the written
version lands in the following commit either way), and the gates still run — being off a branch skips
`open-pr`, not the lint and the suites.
