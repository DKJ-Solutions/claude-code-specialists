## `fix/an-unmigrated-consumer-is-not-a-defect` progress

### Steps

- [x] `Get-PluginDir` in `check-connectors.ps1` returns a STATUS rather than a bare `$null`:
      `malformed` (a register defect), `retired` (the consumer has not migrated), `no-source` (a defect
      in this checkout). Three ways to miss, and only two of them are faults
- [x] The caller branches on it: `retired` is an `[INFO]` that says what the state IS and why the
      register is right to still name the old id; the other two keep their `[ERROR]`
- [x] `connectors/README.md`: the doctrine paragraph records that it and the check disagreed, and that
      the check was the one that was wrong
- [x] `scripts/tests/connectors.tests.ps1`: the retired-id scenario, plus an assertion that a genuinely
      malformed id still exits 1 -- separating the reasons is only worth something if the real faults
      keep their verdict
- [x] Verified in reverse: with `retired` collapsed back into `malformed`, five named asserts fail
- [x] Gates green: lint 0 errors, all 30 suites, and `check-connectors` at 0 errors / 4 info

### Where I left off

Found while verifying an unrelated request -- Dave asked for the plugins on this machine to be updated
to `v3.10.0`, and the connector check that ran afterwards was red on four lines that were correct.

**The defect was mine, and it took three of my own branches to assemble.** Branch 1 made the check ask
the marketplace instead of joining a path. Branch 2 removed the old names from that marketplace. Branch
6 then wrote into `connectors/README.md` that the register deliberately keeps a consumer on their old
ids until they migrate -- a doctrine the check had, by then, been contradicting for two branches.

Each step was right on its own and each was reviewed. What no review caught is the interaction, and the
reason is worth keeping: **a document describing a mechanism is not evidence about that mechanism.**
Branch 6's paragraph was written from the design, published, and passed every gate -- while the thing
it described was reporting the opposite. Nothing measured the two against each other until the check
happened to be run for an entirely different reason.
