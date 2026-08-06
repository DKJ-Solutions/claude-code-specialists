# Branch progress

**Branch:** `docs/main-moves-under-a-branch`

## Steps

- [x] Record the lesson in Derek #05's branch hygiene, beside the fold collision and the parked-branch
      one it completes
- [x] Include the conflict shape, not just the check -- the wrong resolution is the tidy-looking one
- [~] Add it to Chris's stand-verification list -- dropped: that list answers "what is the state" at
      the start of a session, this answers "is it still the state" at the push. Two places, one rule,
      is the drift shape this repo pays for.
- [x] Write the entry
- [x] Take `main` in and re-run the gates on the merged tree (the rule this branch is about)
- [x] PR

## Where I left off

Done. One thing found on the way out and deliberately NOT fixed here, because it is a different
subject: the link scan now covers `branch/` and resolves an entry's root-relative link from `branch/`
instead of from the repo root -- where the text actually ends up after the fold. Five of the pending
entries in `CHANGELOG.md` carry such a link, so this blocks the next entry that cites a file. This
entry dropped its own link to get past it; the repair is its own `fix/` branch, next.
