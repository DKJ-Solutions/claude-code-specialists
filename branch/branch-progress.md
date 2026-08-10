## `docs/a-report-proposes-a-mechanism-too` progress

### Steps

- [x] Add the third check to Chris's portable body: a proposal names mechanisms too, and they are verified before being built on
- [x] Record the measured instance (#566) in his repo lens, beside the two existing failure patterns
- [x] Fill in the changelog entry, all three Significance sections
- [~] Nothing to test — the change is persona and lens prose; check 7 does not reach it, since the edit sits outside the shared block that starts one section lower

### Where I left off

Done; ready for the PR.

The rule went into the portable body rather than the lens, per the standing split: a decision about how we
work belongs with the plugin, and the lens carries the measured instance. Verified before editing that the
paragraph sits **outside** `<!-- BEGIN shared:repo-way-of-working -->`, so no shared-block regeneration is
involved.
