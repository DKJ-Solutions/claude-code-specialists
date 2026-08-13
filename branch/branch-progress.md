## `docs/v4-7-0-release-note` progress

### Steps

- [x] Rewrite the *For consumers* section from the cut's draft against the seven writing tests: second
      person, most urgent first, and say plainly whether the reader must act
- [x] Author *What it is worth* with step 0a's first timing pass — clock start, the legs readable from
      timestamps, the frozen subtotal, and which of them blocked a person
- [x] Author *What was still open at this release* as a snapshot, past tense
- [x] Check no link points into `releases/development/` or `releases/internal/` (lint check 25)

### Where I left off

The document is written and the branch is ready for its gates. Everything remaining happens after the
merge and is therefore not a step above: opening the PR, waiting for `lint-en-tests`, merging, folding
the entry, then publishing the GitHub Release for `v4.7.0` (step 5 — the generated body is
`releases/github/4.x/4.7.0.md`, with the development notes and this document attached under unique
filenames).

After the publish, step 0a's second pass follows in its own small pull request: the end-to-end total,
which cannot exist until the Release is public.
