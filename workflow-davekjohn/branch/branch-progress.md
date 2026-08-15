## `fix/bypassed-helpers-and-stale-register` progress

### Steps

#### PLAN

- [x] Confirm the fence bug is reachable rather than theoretical: locate indented fences in the very
      documents checks 15 and 16 scan (`INSTALL.md:554`, `UNINSTALL.md:267`, `:468`)
- [x] Read the live consumer `settings.json` from the GitHub API before rewriting the register, rather
      than trusting the record it was supposed to describe

#### CREATE

- [x] `#706` — checks 15 and 16 call `Test-FenceDelimiterLine`; check 15's language-tag extraction
      strips leading whitespace too, since it reads the same line
- [x] `#704` — register the two plugin ids the consumer actually enables, and record in the note that
      this checkout is not on this machine, so the record is unverified rather than verified-and-quiet
- [~] `#707` — the duplicated `Get-JsonField`: deliberately not repaired. No live misbehaviour was
      found, so it is a risk that has not bitten, which this repo names and leaves; and both available
      repairs are disproportionate (dot-source 1,274 lines into a publishing script, or change the
      default across 18 call sites). Reasoning recorded on the issue

#### TEST

- [x] `check-plugin-integrity.ps1` green (0 errors) with both checks on the shared helper
- [x] `check-connectors.ps1` parses the rewritten register: djcylow-react no longer draws the
      "not a plugin this marketplace declares" INFO that life-hub still legitimately does
- [x] full test suite green

### Where I left off

