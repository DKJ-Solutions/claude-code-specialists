# `feat/branch-entry-gate` cycle · 20260820-170655

## PLAN

- [x] Verify #789 at HEAD: all five functions it names exist at the line numbers it gives, no `.yml` ships
      in any plugin, and `ci.yml` gates nothing about the entry
- [x] Read both hand-written gates rather than designing from the report. Both consumers have a local
      checkout, so each `pr-guardrails.yml` is readable
- [x] **The recount that changed the design:** both gates refuse a merge over a missing score. That is a
      refusal `open-pr.ps1:643` deliberately does NOT make -- Dave moved it to the cut on August 5, 2026 --
      and one gate justifies it with "tier 0 can never legitimately stay empty" while
      `entry-scaffold-lib.ps1:1860` reads TIER 0 OWES NOTHING
- [x] Establish that `Get-EntryScaffoldFindings` already answers the case the report calls the interesting
      one (a scaffolded entry passes a heading test), so no score test is needed at all
- [x] Check the platform question before choosing a shape: the scripts target Windows PowerShell 5.1, and
      `ci.yml` already runs `windows-latest` for that stated reason
- [x] Check the source-repo guard's own conditions rather than assuming: its second condition is that the
      repo being operated on publishes plugins, so it cannot fire in a consumer's CI
- [x] Establish that `branch-info.ps1` does NOT travel with the plugin -- it is repo-owned -- so the gate
      reads it guarded, from the repo being judged, with an inline fallback for the one field it wants

## CREATE

- [x] `scripts/lint/check-branch-entry.ps1`: the gate, calling the two functions `open-pr` calls and
      adding no rule of its own; the significance is reported, never refused
- [x] Registered as a mirrored pair with **no** `Skill` field: nothing types this command, a workflow runs
      it. Check 18 correctly reports it as not covered, exactly as for `check-script-contract`
- [x] `Get-EntryGateExemptPrefixes` registered in the script contract (default `sync`) and the blueprint
      regenerated -- 31 records, the new one reported as left at the fallback here, which is honest
- [x] `.github/workflows/branch-entry.yml` in THIS repo, `pull_request` only. The source stops being the
      repo whose convention nothing enforces in CI, and the shipped YAML is exercised rather than assumed
- [x] `adopt-workflow-folder` places the consumer's copy -- the one file it writes outside its own folder,
      on the precedent `adopt-shopify-floor` set
- [x] Docs: the skill page (the gate, the seam, the pinned ref, and that making it required is the repo's),
      `CONTRIBUTING-portable.md` (the four local gates are all escapable), and the two gate COUNTS my own
      change falsified -- `workflow-davekjohn/CLAUDE.md` and the root `CLAUDE.md`
- [~] The `preview-answered` job is not ported. It reads a Preview section of a PR template, and no PR
      template this marketplace ships has one -- it is that consumer's own merge rule, not the convention
- [~] The check is NOT added to the `main` ruleset. Making a check required is a repo-settings change and
      therefore Dave's; this file makes it run and report

## TEST

- [x] `branch-entry-gate.tests.ps1`: 15 asserts, 0 fail. The entry states come from the REAL formatters
      (`Format-EntryBlock`, `Format-BranchChangelogReset`) rather than from literals, so the suite cannot
      become a third definition of the format
- [x] The load-bearing case is one that PASSES: an unsettled significance exits 0 and names the cut. A
      suite of refusals only would let the consumers' drift straight back in
- [x] Two counter-intuitive states pinned while measuring them: an EMPTY score reads as tier 0 and owes
      nothing (passes silently), while a tier with no REASON is an unwritten field and is refused by the
      scaffold gate
- [x] Smoke-tested against three real states in this repo, including this branch before its entry was
      written -- which the gate correctly refused
- [x] `check-plugin-integrity.ps1`: 0 errors -- 36 shared-script pairs, 135 parsed files, 286 links
- [x] `check-script-contract.ps1`: 0 errors, 5 info signals (was 4 -- the new seam)
- [~] A finding recorded rather than repaired, because it is a different subject: `Get-EntryImpactFindings`
      still demands a Tier 1 section when tier 2 is scored, with the message "The ladder is cumulative" --
      a rule the entry model retired on August 12, 2026 (81 of 89 tier-1 sections existed only because a
      tier-2 sat above them). Reproduce with one impact row at tier 2 scored and no tier 1. It changes a
      release-gate behaviour, so it does not ride along on a CI-gate branch

## DEPLOY

- [x] Full suite before the PR, since this branch adds a suite and a workflow that runs on its own PR

## Where I left off

The last of the six inbound items from the xoxowildhearts adoption. After the merge and the fold: close
#789 with the evidence -- the score recount is the part worth reading, since it inverts what the report
asked for. Two findings are then Dave's to decide on: the retired cumulative ladder still enforced by
`Get-EntryImpactFindings`, and whether this check joins the `main` ruleset.
