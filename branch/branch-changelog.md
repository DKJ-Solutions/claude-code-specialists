## A branch verifies main before it pushes, because another session may have moved it

### What does this change do?

Derek's branch hygiene gains the collision this repo had written down at two moments and not at the
third. It already covered the **fold** (two machines folding into one `CHANGELOG.md`) and the **parked
branch** (silently overtaken while nobody looked). The one it did not cover is the plainest: `main`
moving underneath a branch that is still being built.

**Measured August 6, 2026.** During a single branch's build, **six** PRs (#481-#486) merged from a
concurrent session. That branch had to take `main` in **twice** -- the second time after its own suites
had already gone green once, which is the part worth naming: a green gate proves something about the
tree you ran it on, and after a merge that is no longer the tree you are pushing. So the rule is `git
fetch` plus a merge of `main` **immediately before the push**, with the gates re-run on the merged
result. `open-pr.ps1` runs both gates, but it runs them on whatever the working copy holds -- a stale
base included.

**The conflict shape is recorded with it, because the wrong resolution is the tidy-looking one.** The
single content conflict that day sat in the dead-link scan set: both sides had widened it, the other
session towards `plugins/` and this branch towards `branch/`, each closing a real gap the other knew
nothing about. Taking either side whole would have re-opened the other's gap in silence -- clean merge,
green gate, one class of file no longer scanned. Two sides editing the same list usually both belong.

The lesson lands in [Derek #05](.claude/specialists/lenses/05-05-extension.md#branch--repo-hygiene),
beside the two collisions it completes, rather than in a fourth place -- and deliberately not in
Chris's stand-verification list, which answers *what is the state* at the start of a session, not
*is it still the state* at the moment of a push.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | anyone building a branch that takes more than an hour here now has the check written down instead of finding out at the merge |
| 0 | 2 | nothing in the tooling changes; this is the third collision in a family the docs already described twice |

### Type of change

Docs
