## `docs/v4-12-0-release-note` progress

### Steps

#### PLAN

- [x] Read all 14 tier-2 entries in the cut's draft, not just their headings
- [x] Verify the publication target live rather than carrying the previous note's line forward
- [x] Check whether `v4.11.0`'s own correction needs a second one (it does not -- true when published,
      stale after, so the record is working)

#### CREATE

- [x] Rewrite the consumer section against the seven writing tests: action first, second person,
      urgency order, and the draft comment removed
- [x] Write *what it is worth* -- the organisation's section, which cannot be generated
- [x] Write *what was still open*, as a snapshot, with the five-release merge item removed because
      this release closes it
- [x] Record step 0a's first timing pass in the document and in this entry

#### TEST

- [x] Lint and test gates via `open-pr.ps1`
- [~] No new automated test: the deliverable is prose in a published record, and the gates already
      hold its links, headings and language layer

### Where I left off

Document written and the branch ready to ship. The second timing pass -- the end-to-end total -- cannot
be written until the Release is published, and follows in its own small edit as step 0a requires.
