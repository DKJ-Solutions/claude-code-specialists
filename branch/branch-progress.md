## `docs/ship-pr-is-the-whole-chain` progress

### Steps

- [x] Adopt the lens's merge-subject format in `ship-pr`, not the one invented today
- [x] Correct that format everywhere it was written (script header, mirror, `ship-pr` skill)
- [x] Rewrite the lens's "Merging to main" so it names `ship-pr` first and the by-hand route as fallback
- [x] Say at the `open-pr` step when to use it alone and when not to
- [x] Verify by running `ship-pr` ALONE for this branch -- the measurement is the proof

### Where I left off

Lint clean.

**Both of these were my own defects, found by Dave asking a plain question** ("is 13 minutes normal?"):

1. `ship-pr` is the whole chain -- `open-pr` -> wait for CI -> merge -> fold. Running `open-pr` first and
   then `ship-pr` puts the gate through twice. Seven PRs on August 7 x ~13 min = **~91 minutes** thrown
   away. Not a design flaw; my driving of it. What IS a real gap is that the lens documented the
   expensive route: its merge section showed a bare `gh pr merge` and never named `ship-pr`.
2. `ship-pr` shipped `merge: PR #NN <branch>` this afternoon while the lens has prescribed
   `merge: <branch> (#NN)` since `ba7081e`. Two formats for one line -- the exact defect the same day's
   work removed elsewhere, introduced by it. The older one wins: it matches the fold commit beside it,
   field for field.

**This branch is its own test.** Running `ship-pr` alone should produce one gate run instead of two, and
a merge commit reading `merge: docs/ship-pr-is-the-whole-chain (#NN)`.
