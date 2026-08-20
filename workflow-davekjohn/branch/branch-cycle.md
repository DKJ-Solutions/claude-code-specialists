# `docs/handover-spent-not-broken` cycle

## PLAN

- [x] Check what the `/handover` and `/lock` pages already say about a lock going stale
- [x] Decide which page owns the rule — the reading side, following the precedent in Chris's lens

## CREATE

- [x] Step 3 gains its second half: a spent lock is spent, not broken
- [x] The *deliberately does not do* bullet gains the matching clause

## TEST

- [x] `check-plugin-integrity.ps1` — 0 errors
- [~] No test suite: the change is prose in a skill page, and no gate reads its meaning. Dropped
      rather than faked — the mojibake, link and frontmatter checks already cover what is mechanical
      about this file.

## DEPLOY

## Where I left off

Nothing outstanding. The `/lock` page is deliberately untouched: one canonical source, and the reader
who needs this rule is reading `/handover`.
