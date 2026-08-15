## `docs/v4-10-0-release-note` progress

### Steps

#### PLAN

- [x] Read the cut's draft and establish which of the four tier-2 entries actually reach a consumer
- [x] Anchor the timing legs on real timestamps (clock start, release commit, push) rather than estimates

#### CREATE

- [x] Rewrite the consumer section against the seven writing tests
- [x] Write `What it is worth` -- the organisational half the draft cannot generate
- [x] Write `What was still open at this release` as a snapshot, past tense

#### TEST

- [x] Gates green via `open-pr.ps1` (lint + all suites)
- [~] No new automated test: the deliverable is a hand-written release document, and lint check 25 already holds the one rule with a measured basis (no links into `development/` or `internal/`)

### Where I left off

Document written and shipping. The end-to-end total follows in its own small edit once the publish
leg exists -- step 0a's second pass, and the last bullet of `What was still open` says so.
