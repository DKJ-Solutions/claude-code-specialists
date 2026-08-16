## `docs/entry-shape-repair` progress

### Steps

#### PLAN

- [x] Confirm the correct shape against the canonical template and the three sibling entries pending in
      `CHANGELOG.md` — both agree: `#### Tier 0` follows the question heading directly, no prose between

#### CREATE

- [x] Move the `docs/destination-reach` description inside its `#### Tier 0` section in `CHANGELOG.md`
- [x] Correct the two claims the entry shipped stale relative to the files it describes
- [~] `BRANCH-portable.md`'s drift (`Branch title`, `### Significance`) left for its own branch — portable
      payload, several distinct claims, and a contributor page is a scoped rewrite rather than a ride-along

#### TEST

- [x] Lint + test gates via `open-pr.ps1` — ticked at invocation, since the step-list gate runs first and
      a step naming the command that checks it can never be true beforehand

### Where I left off
