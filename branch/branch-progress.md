## `docs/migrating-to-teams-and-workflows` progress

### Steps

- [x] The migration section in `plugins/INSTALL.md`: the command sequence, marketplace refresh first
- [x] It LEADS with the workflow choice rather than closing on it -- measured against `connectors/`,
      all three registered consumers enable no workflow at all, so a mechanical id swap leaves them
      with the teams and silently no workflow
- [x] The pre-seam lens caveat, stated as unrepaired: the plugin name is the second segment of
      `.claude/plugins/claude-specialists/<plugin>/`. Verified on this machine that no such directory
      exists, which is what makes "named, not repaired" a measurement rather than an assumption
- [x] What does NOT change, so nobody goes looking: skill names, the marketplace name, the lens family
      segment, the seam, and the content of their own lenses
- [x] `plugins/UNINSTALL.md`: verified rather than assumed -- branch 2 did sweep it, so no change
- [x] `connectors/README.md`: why a consumer keeps their OLD ids in the register until they migrate
- [x] Gates green: lint 0 errors, all 30 suites
- [x] Changelog entry: body + a score per tier

### Where I left off

Branch 6 of 6, complete and green. The restructure is done.

**Left for Dave after this lands.** The release. `3.x` has ten minors, so a `4.0.0` clears the tier
gate, and the rename is a tier-2 score-5 change -- consumers must act. That decision is his and was
deliberately left open at the start of this work; the chain was built so it CAN be cut whenever he
wants, not so that it has to be.

**A standing note for whoever picks the register up next:** life-hub, smartwatchbanden and
djcylow-react are all still on the old ids. That is correct and deliberate until each of them actually
migrates -- it is not drift, and `connectors/README.md` now says so.
