## `feat/audience-archive-merge` progress

### Steps

- [x] Merge the 12 `consumer/` + `internal/` pairs into `releases/audience/<X>.x/<X.Y.Z>.md` — faithful
      structural merge (Dave, 2026-08-12): all substantive prose verbatim, `## What is different now`
      dropped as the sanctioned duplicate, consumer headings demoted one level, consumer lead becomes the
      document lead, a now-false "the other document carries it" clause dropped (4 of the 12 had one)
- [x] Delete the 24 originals under `releases/consumer/` and `releases/internal/` — `releases/` now holds
      `audience/` 15, `development/` 85, `github/` 3
- [x] Repoint the 8 Version-cell links in `releases/README.md` that named `internal/`. The 4 rows at
      3.2.0–3.5.0 point at `development/` and were left alone — pre-existing, out of scope, reported to Dave
- [x] `releases/README.md`: the "frozen archives" claim at 149 replaced with the merge and its reasoning.
      The tier table needed nothing — it already named `audience/<dir>`
- [x] `CLAUDE.md`: the "frozen archives" claim and the "eleven documents in releases/consumer/" line, the
      second replaced with the do-not-repoint warning for `new-internal-note.ps1`
- [x] Rendall's lens `05-06-extension.md` — both roots re-headed as what they became, bodies kept as history
- [x] Nolan's lens `06-25-extension.md:309` — measurement's substance kept, source directories noted as merged
- [x] Lint check 25: the comment now states why `releases\consumer` is still read (a consumer still has one)
      and why `releases\internal` is deliberately absent; both `-Note` strings updated. Root list unchanged
      by design — absent roots are filtered out, so nothing had to move
- [x] `releases/development/` mentions: one dead link repointed in `4.x/4.0.0.md`; prose left alone
- [x] Check 25's tests: added assert 64b pinning that an internal note is NOT scanned
- [x] Write `branch/branch-changelog.md` — body, tier 0 = 3, tier 2 = 3
- [ ] Gates: `check-plugin-integrity.ps1` green (0 errors, `[consumer-tier] checked 15`, `[link-scan] 234`).
      Suites running; `check-script-contract.ps1` + `check-roster-sync.ps1` still to run

### Where I left off

Everything written. Waiting on the full suite run, then the two sync checks, then `open-pr`.

**Do NOT touch** (verified this session): `new-internal-note.ps1:166`, `release-lib.ps1`'s shared
`releases/notes` default, `Get-ReleaseNoteRoot`'s fallback, `script-contract-lib.ps1:371`,
`config-blueprint.json`. Those are a consumer's two-document flow, not this repo's archive — repointing them
is the one failure here that would be silent.

`CHANGELOG.md:47`'s "frozen archives" line is a folded record and stays as written. So does
`releases/audience/4.x/4.3.0.md:107`, which promises these archives would never be migrated — the reversal is
recorded in this branch's entry, not by editing the record.
