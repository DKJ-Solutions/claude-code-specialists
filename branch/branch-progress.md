## `fix/releases-reorg-residue` progress

### Steps

- [x] Repoint the four history rows (`3.2.0`–`3.5.0`) at their merged `audience/` documents
- [x] Check the other direction too: every version with an `audience/` document is linked to it, and the
      patch rows correctly still point at `development/`
- [x] Remove the dead `$consumerFacing`, and write down why the surviving `$notable` counts `>= 1`
- [x] Rebuild the shared-script mirror and run the `release-lib` suite
- [x] Fill in the changelog entry (both tiers, with scores)

### Where I left off

