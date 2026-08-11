## `fix/the-ci-leg-is-a-distribution` progress

### Steps

- [x] Count every successful `ci.yml` run, split by event, rather than take a second sample
- [x] Replace the CI leg in the wall-clock table with the distribution
- [x] Replace the point value in open number 3, and say why one run was the wrong shape
- [x] Recompute every derived figure: per-bump cost, the window, the scenario table, the ceiling
- [x] Record that the conclusions did not move, since that is the load-bearing result
- [~] Leave the local suite legs as measured — n=1 and n=2 cannot honestly become a distribution
- [x] Write the changelog entry

### Where I left off

The lens carries the distribution and every derived figure is recomputed. Still open, deliberately and
not on this branch: whether the portable half of the lesson belongs in Nolan's shipped manual, which is
a consumer-facing change and Dave's call.
