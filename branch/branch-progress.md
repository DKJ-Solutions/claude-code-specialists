# Branch progress

**Branch:** `fix/entry-links-resolve-from-root`

## Steps

- [x] Rebase the entry's link resolution to the repo root, beside the existing persona-template case
- [x] Leave the step list on the ordinary nested convention, and say why
- [x] Regression test asserting BOTH halves -- the valid link passes and a dead one is still caught
- [x] Write the entry
- [x] Take `main` in and re-run the gates on the merged tree
- [x] PR

## Where I left off

Done. Next up, on their own branch: the step-list gate (`open-pr` and `ship-pr` refuse while a `- [ ]`
is open, `- [~]` counts as deliberately dropped) together with `branch/README.md`, which Dave asked
for -- the two belong on one branch because the README states the rules the gate enforces.
