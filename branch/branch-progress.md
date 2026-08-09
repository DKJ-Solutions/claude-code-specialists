## `fix/enabled-vs-installed-verdict` progress

### Steps

- [x] Verify the reason before building: confirm the `[INFO]` at check 4 is what stays silent, and that
      `check-roster-sync`'s marker of the same name is unreachable at session start by design
- [x] `check-connectors.ps1`: emit a non-counting `[NOT-INSTALLED-HERE]` marker when the plugin is
      enabled, has no record, and the checkout is the session's repo (`Test-IsSessionRepo`)
- [x] `connector-sessioncheck.ps1`: add the marker to `$notices`, give it its own verdict branch ahead
      of the two register notices, and update the docstring's "two exceptions" to three
- [x] Tests: `check-connectors` fires the marker for the session repo and not for another consumer;
      hook tests for the marker alone, with a real `[ERROR]`, with a register notice, and absent
- [x] `connectors/README.md`: the third named exception to the `[INFO]` silence, with the measured
      instance
- [x] Gates: lint + all suites green
- [~] No change to `check-roster-sync.ps1` — its blind spot is structural (a session start writes the
      record before any hook can look) and is already documented there; covering it from the source
      side is what this branch does instead

### Where I left off

Done; gates green.
