# `docs/ship-pr-reads-the-worktree` cycle · 20260820-181210

## PLAN

- [x] Verify the mechanism before writing it down, rather than repairing to the symptom: `ship-pr.ps1:291`
      reads the step list from the working tree, and its own comment states that as the design
- [x] Establish the direction that is dangerous. The refusal I hit was SAFE (CI green, branch pushed,
      re-runnable); the mirror case -- a tree on a finished branch letting an unfinished list through -- is
      the silent one, and it is what makes this worth a paragraph

## CREATE

- [x] The `ship-pr` skill page gains the section, with the measured instance and the one-line recognition
      test (`git rev-parse --abbrev-ref HEAD` against the PR's head ref)
- [x] The wider rule stated in the same place: these scripts assume one working tree per session, and
      `/lock` is a note for the next session rather than a claim on a checkout
- [~] No guard built. Refusing when HEAD and the PR's head ref differ is one comparison, but it changes
      the merge path, and one benign instance is not the evidence for that. Recorded as a proposal in the
      page instead

## TEST

- [x] `check-plugin-integrity.ps1`: 0 errors -- the page is shipped payload, so its links and anchors are
      the part a gate can actually prove

## DEPLOY

- [x] Branch check before the first edit

## Where I left off

The six inbound items from the xoxowildhearts adoption are closed. Two findings remain Dave's to decide:
the cumulative ladder that `Get-EntryImpactFindings` still enforces after the entry model retired it on
August 12, 2026, and whether the new `branch-entry` check joins the `main` ruleset.
