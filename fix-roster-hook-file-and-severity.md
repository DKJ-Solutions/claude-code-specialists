### The roster hook names the right file, and a fresh bootstrap is not nineteen errors · Fix · 2026-08-01

Test round v10's #333, reported as two problems in one hook output. Measured here, the first half turned
out to be a real bug rather than a wrong message — and it is the cause of part of the second.

**The scaffold pointed at the wrong file.** `bootstrap.ps1` wrote `$script:RosterPath = 'CLAUDE.md'` into
every consumer's `repo-config.ps1`, while that same bootstrap puts the roster slot in
`.claude/specialists/SPECIALISTS.md` and its own next-steps block says, in so many words, that the roster
does **NOT** go in `CLAUDE.md`. So `check-roster-sync` dutifully read a file containing nothing but the
`@`-import, found no roster rows, and reported every specialist as missing — naming `CLAUDE.md` as the place
to fix it. The issue reported this as the hook pointing at the wrong file; it was the check *reading* the
wrong file, and the message was merely honest about it.

The value now comes from `Get-SeamPaths`, the same source that decides where the bootstrap writes the slot —
so the writer and the reader cannot drift apart again. `RelInclusion` is new there for exactly that reason:
it was a hand-typed literal in the scaffold, and it was typed wrong. A single-quoted here-string cannot
interpolate, hence a placeholder substituted after the fact, with the fallback repeating the literal
knowingly (shipping a consumer the token `__SEAM_ROSTER_PATH__` would be worse than the bug being fixed) and
a fixture asserting the two agree.

**The documented happy path ended in nineteen `[ERROR]` lines.** Measured on a virgin profile, in the session
right after a completely successful `specialists-init` — every count correct — one error per specialist
saying it has no roster row. Nothing was broken: the QUICKSTART tells that reader to fill the lenses in *at
your own pace*, and `[ERROR]` is the heaviest level these checks have. The cost is habituation, which is the
real damage: whoever learns to ignore nineteen false errors ignores the twentieth too.

The state was invisible to the existing `[BOOTSTRAP]` predicate because that one is strict on purpose — no
lens **anywhere** and no roster row for **any** id — and a bootstrapped repo has lenses. So it fell through
to full drift reporting, which is right for a maintained repo and wrong for one whose owner has not started.

**The discriminator is measurable, and that is what makes the new state safe to add rather than a guess:**
every lens the bootstrap writes is a `VUL-IN` scaffold. If lenses exist, **every one** is still an unfilled
scaffold, and no roster row exists for any id, then nobody has written anything — there is no work to have
drifted from. `[ROSTER-PENDING]` says that once, non-counting, exit 0. It is deliberately not folded under
`[BOOTSTRAP]`, whose advice is *"run specialists-init"* — advice this reader has just followed successfully,
and being told to run it again is how a reader learns the checks are wrong.

**The boundary cases carry more weight than the marker**, because the failure mode of this fix is trading
false alarms for silence. Four fixtures pin it: one lens filled in → drift errors return; one roster row
present → the same, from the other direction; a specialist that arrived later with a plugin update has no lens
at all → that half still errors while the scaffolded ones stay quiet (the suppression is scoped to ids that
*have* a lens for exactly this reason); and a repo that was never bootstrapped still gets `[BOOTSTRAP]`, not
this one.

**A real bug the fixture caught on its first run.** The marker text originally ended with *"this becomes real
drift (and `[ERROR]` lines) as soon as…"*. The session hook counts its error signals by matching the literal
`[ERROR]` over the check's whole output — so a marker line merely **mentioning** the token would have been
counted as an error and pushed the hook into its drift branch, announcing *"roster drift found"* about the one
state this marker exists to call fine. Reworded, and pinned by its own assert so the next marker text is held
to the same rule.

### Tested

- `roster-sync.tests.ps1` (307 asserts) — 11m–11q for the new state and its four boundaries, plus
  H12/H12b/H12c for the hook: its own verdict between "not set up yet" and "in sync", riding along with a real
  drift finding, and adding nothing to a repo whose roster is filled in.
- `bootstrap-drift.tests.ps1` (104 asserts) — the scaffold points at the seam, not at `CLAUDE.md`, the
  placeholder is substituted rather than shipped, and the value equals `Get-SeamPaths`' own.

**Process note, stated because it is exactly the check that exists to prevent it:** the first edits of this
work were made on `main`, before the branch existed. Derek's rule is that not a single file is written before
`git status` + `git branch`, and it was skipped. Nothing was committed there, so the changes moved onto this
branch intact and `main` never carried them — but what catches this is the habit, not the recovery.

Plugins: specialists
