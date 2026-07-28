### Record the measured smartwatchbanden gap in its register note · Chore · 2026-07-28

Preparation for the smartwatchbanden catch-up: its checkout is on the workshop machine, so the
v2.10.0 checks could be run against that tree directly. The result replaces the note's single
Bianca observation with the full, measured picture rather than an estimate.

**What was measured**, in two parts:

- **Script contract** — `scripts/repo-config.ps1` is missing `Get-RosterPath` and
  `Get-RosterIgnoredIds` (both required), plus the optional `Get-ChangelogHeading` and
  `Get-LiveStage`. `scripts/lib/branch-info.ps1` is complete. **This is the exact fingerprint that
  misled inbound #203**: the 2026-07-27 alarm about those two missing roster functions was true, about
  *this* repo, and it was reported into a life-hub session. Seeing it here closes that loop
  empirically — the check was right, about the wrong repo, which is precisely what #203 fixed.
- **Roster/lenses** — five specialists have neither a roster row nor a lens: 03-02 (Bianca, persona),
  06-24 (Ravi), 06-25 (Nolan), 06-29 (Marlowe), 06-30 (Auden). Everything else is clean: no orphans,
  no off-path lenses, no stale lens headers.

**The `extensions` arrays are deliberately left untouched.** They list 14 + 3, which is exactly what
that repo actually has — verified file by file against the canonical path (no legacy path in use). This
register records what a consumer *has*, not what it should have, so pre-filling the five missing ids
would make the check report them as `registered extension(s) missing` in the consumer. The inventory
gets updated after lenses actually land there, per the register's own "the registry data should follow
reality" rule.

**One ordering constraint recorded with it, because the intuitive order is wrong.** The script contract
has to be fixed *before* deciding per specialist: `Get-RosterIgnoredIds` is the mechanism for recording
a deliberate non-adoption, so while it is absent, "skip this one" is not an implementable outcome and
adopting all five is the only route that works. A session that takes the decisions first would either
stall or quietly adopt specialists nobody asked for.

Whether each of the five is adopted or deliberately skipped stays Dave's call per specialist — that
decision is not pre-empted here, only the data it needs.
