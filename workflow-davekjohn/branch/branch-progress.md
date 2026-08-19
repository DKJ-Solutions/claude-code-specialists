## `docs/v4-14-0-timing-total` progress

### Steps

#### PLAN

- [x] Read every leg from a timestamp rather than a stopwatch: the release commit, the note commits, the PR's
      `createdAt`/`mergedAt`, the fold commit, and the Release's `publishedAt`.

#### CREATE

- [x] Replace the head-only timing paragraph with the total and the seven legs.
- [x] State the head-as-share figure against the three previous releases that recorded one, with each source
      named, and say plainly that four readings are not a distribution.
- [x] Name where the extra six minutes went -- all tail, two legs plus one refused command.
- [x] Rewrite the first open bullet from a promise into a statement, keeping the reason the attachment is not
      replaced.

#### TEST

- [x] Lint gate (`check-plugin-integrity.ps1`), then the full gates via the ship chain.

### Where I left off

Nothing outstanding. After this merges, the release is closed out: the only remaining item on the checklist is
the cache-refresh line in the closing report, and publishing to the organisation, which is a separate decision
nobody has asked for.
