## `docs/destination-reach` progress

### Steps

#### PLAN

- [x] Verify the locked subject against the tree: both halves live only in the folded
      `docs/chain-route-readable` entry (`7c200a8`), nowhere in `plugins/`
- [x] Decide the destination — Tessa's portable manual, beside the existing "portable is the default,
      the lens is the exception" rule; `CONTRIBUTING-portable.md` and `adopt-workflow-folder/SKILL.md`
      rejected for having the wrong reader

#### CREATE

- [x] Add the hard rule to `plugins/teams/team-alpha/manuals/06-16-manual.md`, both halves, timeless
      and repo-neutral, quoting no runnable command
- [x] Add the measured instance and the two rejected destinations to
      `.claude/specialists/lenses/06-16-extension.md`, under the existing citations section
- [~] No pointer added to `adopt-workflow-folder/SKILL.md` — its reader is a consumer scaffolding a
      folder, not a maintainer siting a repair, so the bytes would ship to every consumer for a reader
      who is not there

#### TEST

- [x] Edith on the diff: language, links, consistency — three findings, all applied: "two destinations
      look correct and are unreachable" was imprecise for the second half (a wrong plugin root resolves,
      it does not fail to arrive); "where no single document can own both" left *both* dangling; and the
      lens miscounted #731's rejected targets as three-weighed-two-rejected when three were rejected and
      only two of them on reach
- [x] Lint + test gates via `open-pr.ps1` — ticked at the moment of invoking it, since the step-list
      gate runs first and a step naming the command that checks it can never be true beforehand

### Where I left off

