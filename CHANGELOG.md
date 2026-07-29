# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #258 · The post-merge sync names one ref · Fix · 2026-07-29

The post-merge sync step said `git pull --ff-only`, in
[Derek's lens](.claude/specialists/lenses/05-05-extension.md) and — the part that matters more — in
[`ship-pr.ps1`](scripts/release/ship-pr.ps1), which automates the whole merge → fold chain. That bare
pull aborted on July 29, 2026 with `fatal: Cannot fast-forward to multiple branches` on a clean `main`
immediately after `gh pr merge --delete-branch` plus a `git fetch --prune` that removed two remote refs.
`git merge --ff-only origin/main` ran straight through.

**Where it aborts is the whole point.** In `ship-pr.ps1` that step sits between the merge and the fold —
the one gap in the chain that nothing reports. The PR is merged, the entry file is still in the root,
every gate stays green, and it surfaces only when a release trips over an entry that should no longer
exist. That is precisely the half-finished state PR #256's own fold was found in earlier the same day.
Both call sites now `git fetch --prune origin` and then merge `origin/main` explicitly.

**The mechanism was deliberately not guessed at.** Git raises that error when it is handed more than one
ref to merge, and why the pull got more than one was not established: the repo's config is ordinary (one
`remote.origin.fetch` refspec, `branch.main.merge` naming a single ref, `pull.rebase=false`), and a later
inspection showed a single `for-merge` line in `FETCH_HEAD`. So this is not recorded as a mechanism note,
and the rule does not rest on one. It rests on determinism: naming `origin/main` explicitly hands git
exactly one ref, so the step cannot reach that failure mode at all, while a bare pull's behaviour depends
on whatever `FETCH_HEAD` happens to contain. For a step wedged between a merge and a fold, the more
predictable command is the right one regardless of what caused the stall.

**Test gap, stated rather than papered over:** `ship-pr.ps1` has no suite. Driving it under test means
standing in for `gh pr merge` against a real remote, and a mock convincing enough to be worth trusting
would be testing the mock. The lint gate's parse check covers the syntax; the changed step is two native
calls whose failure modes are the exit codes already checked inline.

[PR #258](https://github.com/DaveKJohn/davekjohns-workshop/pull/258)

---

### #257 · check-roster-sync calls the seam canonical · Fix · 2026-07-29

`check-roster-sync.ps1` still carried the **pre-seam path hardcoded in two places**, while the shared
source it is supposed to agree with — `Get-LensDirCandidates` / `Get-SeamPaths` in
[`check-report-lib.ps1`](scripts/lib/check-report-lib.ps1) — had named the seam
`.claude/specialists/lenses/` canonical since [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221).
Reader and writers had drifted apart, and this repo tripped over it the moment it migrated onto the
seam itself in [#255](https://github.com/DaveKJohn/davekjohns-workshop/pull/255).

**1. Its own lenses were reported as living off-path.** `Get-CanonicalLensDir` returned only
`.claude/plugins/<family>/<plugin>/`, so all 19 seam lenses produced one `[INFO]` telling the reader to
move them — back to the layout the repo had just left. A reader who followed that advice would undo the
migration. Replaced by `Get-OnPathLensDirs`, which derives **both** currently-written locations from the
shared source: the seam (candidate 0) and the pre-seam plugin path (candidate 1, still written by
`Get-LensWriteDir` for a consumer that already has a tree there). Neither is a misalignment now, and the
finding keeps meaning exactly what #179 built it for: the marketplace-named family that only the
reader's back-compat list keeps working.

**2. A seam consumer could be declared "never bootstrapped".** The `$anyLensFile` probe behind the
`[BOOTSTRAP]` marker scanned `.claude/plugins` and `.claude/extensions` — not the seam. So for any
consumer bootstrapped since #221 the probe saw no lenses at all, and a single unfilled roster was enough
to swallow every real finding behind advice to run `specialists-init` on a repo whose whole lens tree
was already in place. The seam directory joined the scan.

Worth noting how invisible this was: the false finding was an **`[INFO]`**, which the session hook
suppresses by design — so nothing reported it, and the check's exit code stayed 0. It surfaced only
because someone ran the script deliberately and read the one line the hook filters away. The same shape
as the `[INVENTORY]` case: a rule nobody was ever prompted about.

Both are covered by regression tests in
[`scripts/tests/roster-sync.tests.ps1`](scripts/tests/roster-sync.tests.ps1) (scenario 9c: the seam is
canonical and a migrated repo reports *completely* clean — asserting "no `[ERROR]`" would have missed
this entirely; 9d: the pre-seam path stays tolerated **silently**, so the fix cannot be "corrected" by
swapping one hardcoded path for another; plus the seam case in 5d for `[BOOTSTRAP]`). Verified the
honest way: all five new assertions fail against the unfixed script and pass against the fixed one.

Plugins: specialists

[PR #257](https://github.com/DaveKJohn/davekjohns-workshop/pull/257)

---

### #256 · Two plugins both setting agent: settled by experiment · Docs · 2026-07-29

The open question from [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) — *what
happens when two enabled plugins both set `agent` in their root `settings.json`* — is no longer an
unknown. It was the **first** of the three reasons the main-thread switch stays off, and the one the
family README called "the honest prerequisite… by experiment rather than by reading". So it was
measured rather than reasoned about.

**The answer: the last-listed plugin silently wins.** Two throwaway plugins, each with an `agent` in
its root `settings.json` pointing at its own agent, run in both orders along **both** load paths:

| Path | Order | Winner | Main model |
|---|---|---|---|
| `--plugin-dir A --plugin-dir B` | alpha, beta | `IDENTITY=BETA` | haiku |
| `--plugin-dir B --plugin-dir A` | beta, alpha | `IDENTITY=ALPHA` | sonnet-5 |
| `enabledPlugins` | alpha, beta | `IDENTITY=BETA` | haiku |
| `enabledPlugins` | beta, alpha | `IDENTITY=ALPHA` | sonnet-5 |

Three things follow, and the second is the one that matters for the switch:

- **The whole agent config travels, not just the system prompt.** The winner's `model` came through
  too — the two experiment agents were deliberately given different models, so the JSON `modelUsage`
  proves which one won independently of what the model *said* about itself.
- **There is no error and no warning.** The harness knows and logs it exactly once, at debug level:
  `[DEBUG] Plugin "expbeta" overrides setting "agent" (previously set by another plugin)`. That is
  worse than a hard failure: a consumer who enables a second `agent`-setting plugin loses their
  orchestrator to whichever plugin sits last, with nothing on screen to say so.
- **Ordering is positional, not alphabetical.** Reversing the order reverses the winner, which rules
  out the obvious alternative explanation (`expalpha` < `expbeta`).

Recorded in the family README, in the *"Delivering the orchestrator from the plugin"* section, as a
measured fact replacing the "not documented" wording. **The switch stays off** — reasons 2 (it changes
every consumer's main loop from a version bump they did not read) and 3 (Chris ships as a persona, so
there is no agent file whose `tools:`/`model` may become the whole main thread's) are untouched by
this, and flipping it is Dave's call regardless.

**Two things the method is worth more than the result for.**

- **The control run came first, deliberately.** One plugin alone was run before the pair, because a
  null result from a misconfigured harness is indistinguishable from a real "neither wins". It
  answered `IDENTITY=ALPHA` on alpha's own model, so the mechanism was proven live before anything was
  concluded from its absence.
- **That precaution immediately paid for itself.** The first attempt at the consumer path answered as
  plain Claude Code — no identity at all. Not a finding: `extraKnownMarketplaces` had
  `"source": "local"`, which is invalid (the valid type is `"directory"`), and `-p` mode *silently
  ignores* settings files that fail validation. `claude doctor` named the offending key exactly. A
  project-declared marketplace also needs an install step before `enabledPlugins` bites — headless,
  the plugins were simply never loaded. Both were fixed and the run redone before any conclusion.

**One side effect worth knowing before anyone repeats this:** `claude plugin marketplace remove`
rewrites the **project** `settings.json` of the current working directory, not just the scope the
marketplace was declared in — it emptied the test consumer's `enabledPlugins` and
`extraKnownMarketplaces`. Run it from a throwaway directory, never from a repo whose `settings.json`
you want to keep. The experiment's own cleanup was done that way; this repo's `.claude/settings.json`
and Dave's user settings are verified unchanged.

**Also in this change:** the `gh pr checks --watch` pitfall is now recorded in
[Derek #05](.claude/specialists/lenses/05-05-extension.md#merging-to-main)'s lens rather than living
only in one session's memory. Chaining the watch onto a merge looks safe and is not: with no run
started yet the watch returns immediately with `no checks reported` — a success-looking exit meaning
"I found nothing" — so the chained merge fires against an unevaluated gate, gets blocked by the `main`
ruleset, and leaves an unmerged PR behind while every step appeared to pass. The note also flags that
PowerShell 5.1 has no `&&`, so such a chain is `;` or `if ($?) { … }` here, which runs the merge
regardless of what the watch concluded.

[PR #256](https://github.com/DaveKJohn/davekjohns-workshop/pull/256)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.15.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.15.0.md](releases/development/2.x/2.15.0.md) for the full release notes.

---

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
