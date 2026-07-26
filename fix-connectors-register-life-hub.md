### Life-hub register: stale notes and four unregistered lenses · Fix · 2026-07-26

`scripts/sync/check-connectors.ps1` flagged four `[INFO]` signals: lenses 06-24, 06-25, 06-29, and
06-30 exist in the life-hub checkout (verified as owned by `specialists@davekjohns-workshop` via
`Get-PluginIds`) but were never added to
`claude-code-plugins/claude-specialists/connectors/life-hub.json`'s extension list. Registered them.

The `notes` field had also gone stale and was being read as current truth — it claimed the
life-hub session ran on "another machine" needing an update to a specific version ("v1.10.0"),
both wrong, and still carried an action item (registering 06-24) this change now performs.
Commit `fde6556` had already removed version bookkeeping from the register on purpose (the check
reads the installed version from the machine record instead), so a version number in `notes` didn't
just go stale, it contradicted the register's own design. Rewrote `notes` down to the one thing
that is still timeless: the lens-only model for the four personas (01-01, 03-02, 05-05, 05-06) —
no machine claims, no version numbers, no dangling to-do.