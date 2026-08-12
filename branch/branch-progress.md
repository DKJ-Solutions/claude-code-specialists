## `feat/audience-tier-seam` progress

### Steps

- [x] Re-measure the tier usage PER ENTRY rather than in aggregate — 81 of 89 tier-1 sections were ladder tax, which reversed my own earlier argument against this change
- [x] `Get-ReleaseAudienceTier` in `repo-config.ps1`, answering 2 for this repo, with the measurement written above it
- [x] `Get-EntryAudienceTier` + `Get-EntryAskedTiers` in `entry-scaffold-lib.ps1` — one answer to "which tiers", read by the scaffolder, the routing question and the gate
- [x] Keep `Get-EntryTierMax` at 2 — the max says what is valid to READ, the audience says what is ASKED; four validators keep using the max
- [x] Absent seam = ask about all three, so the plugin update alone changes nothing in a consumer
- [x] Route the tier-0 question at the NEXT WRITTEN tier — it said "continue to Tier 1" above a file whose next section is Tier 2
- [x] Narrow the ladder gate to the asked tiers, and keep it TOLERANT of an extra answered tier
- [x] Contract record: `decide`, with the default described as "ask about all of them"
- [x] Sync both plugin mirrors by copying, not by retyping the edits
- [x] Regenerate `branch/templates/` via `new-branch` (idempotent) — now tier 0 + tier 2
- [x] Regenerate the config blueprint — 26 records, 13 decide
- [x] Update the three counting asserts in `script-contract.tests.ps1`, extending each one's written history
- [x] Tests: the unstated case, the stated case, out-of-model answers, what the scaffolder writes, where the question points, and the tolerance case
- [x] Docs describing THIS mechanism: the `new-branch` skill, `branch/README.md`, `CONTRIBUTING-portable.md`
- [x] Lint gate green
- [x] All suites green — all 31 in 350s (the docs still say 26; flagged for its own `docs/` branch, not repaired here)
- [x] Review pass on the diff: three stale claims repaired in `Format-EntrySignificanceSections` — a routing paragraph left duplicated verbatim when `$routes` moved below the `$ordered` it now depends on, plus two docstring claims (`for tier 0 and 1`, `tier 0 alone`) that the audience knob and the August 7 change had outrun
- [~] `CLAUDE.md`'s tier section, `releases/README.md`, the `cut-release` skill and Rendall's lens — deliberately chunk 3's, which owns the release-document half (`notes/` → `audience/`); this branch owns what an ENTRY is asked
- [~] Migrating the 6 pending entries to two tiers — declined: they are correct as written, the gate tolerates them, and rewriting somebody's finished reasoning to match a new form is churn with a chance of loss

### Where I left off

Chunk 2 of three. Mechanism, tests, the three mechanism-facing documents and both gates are done, and the
review pass is folded in. Chunk 3 is `releases/notes/` → `releases/audience/`, the documents that describe the release
side of the tier model, and closing #620 with the evidence — including the part where its proposal was right
and two of its stated reasons were not.

