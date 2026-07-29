# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #232 · The gatekeepers repetition stays — decided, with the evidence · Docs · 2026-07-29

Closes [#217](https://github.com/DaveKJohn/davekjohns-workshop/issues/217). Its third item was reserved
for Dave, not a mechanical trim: Chris's lens restates safety rules `CLAUDE.md` already carries in full,
~600 always-on tokens that could be reclaimed — but the repetition sits at the point of use, and
instructions are context rather than enforced configuration, so cutting it trades tokens for adherence.
Dave's answer was **"decide after the trim."**

The trim is done ([PR #231](https://github.com/DaveKJohn/davekjohns-workshop/pull/231): `CLAUDE.md` 328 →
282 lines, the language detail path-scoped, and the remaining sections measured against the same test and
found to fail it). So the decision is now due, and the same session produced the evidence that settles it.

**Decided: keep the repetition. Do not revisit it as a token saving.**

The reasoning is not a preference but an observation from this session. The session-reply language rule
lives in `CLAUDE.md` — always-on, re-injected after every compaction, as prominent as an instruction can
be in this system. It was **broken anyway**, for an entire session, until Dave pointed it out. Always-on
presence therefore demonstrably does not guarantee adherence.

That cuts in one direction only. If a single always-on statement is not reliably enough, a second
statement at the point of use is not redundancy — it is the second chance the first one measurably needs.
The ~600 tokens are real and reclaimable; what they buy is worth more. Recorded in
[Nolan #25's lens](.claude/plugins/claude-specialists/specialists/06-25-extension.md) as a closed
question rather than an open saving, so a future cleanup pass does not quietly take it — which is exactly
what #217 asked for.

Reversible in one PR if Dave disagrees.

`CLAUDE.md` stays above the documented 200-line target at 282 lines. That is the accepted end state: the
sections still on the always-on path are there because each one fails the relocation test on its merits
— routing is needed at intake before any file is read, and the safety rules must survive compaction.

[PR #232](https://github.com/DaveKJohn/davekjohns-workshop/pull/232)

---

### #231 · The language detail moves off the always-on path, and the rules of that lever are now verified · Feat · 2026-07-29

Part of [#217](https://github.com/DaveKJohn/davekjohns-workshop/issues/217). That issue proposed moving
content off the automatic loading path into path-scoped `.claude/rules/` files, and flagged one thing as
**unverified: whether such rules survive a `/compact`.** The whole strategy rested on it, so it was
checked before anything moved — and the answer constrains the lever rather than just enabling it.

| at `/compact` | what happens |
|---|---|
| project-root `CLAUDE.md` and rules **without** `paths:` | re-injected from disk |
| rules **with** `paths:` frontmatter | **lost until a matching file is read again** |

Two consequences that together define the whole trade. **A rule without `paths:` saves nothing** — it
loads unconditionally with the same priority as `CLAUDE.md`, so relocating text there is filing, not
trimming; the scoping *is* the saving. And **a `paths:`-scoped rule is deliberately not always-on**, so
the test for a candidate is whether the content is inert until someone opens a matching file. If yes the
scoping is self-healing, because touching the layer reloads the rule.

`### Language` was the textbook case: 65 lines, the largest section in `CLAUDE.md`, almost all of it
per-layer detail about `scripts/**`, `.github/**` and `releases/**`. It now lives in
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md), scoped to exactly those paths.
**`CLAUDE.md` goes from 328 to 282 lines.**

**The trap inside that section is the part worth keeping.** It also contained one sentence that had to
stay behind: *the session-reply language follows the user.* That governs every turn regardless of which
files it touches, so path-scoping it would have quietly weakened it after the first compaction — and it
is a rule that had already been broken in practice earlier the same day. Generalised in
[Nolan #25's lens](.claude/plugins/claude-specialists/specialists/06-25-extension.md): **read a candidate
section for the one sentence that is not about the files, before moving the block.** The docs' own escape
hatch is the tell — *"if a rule must persist across compaction, drop the `paths:` frontmatter or move it
to the project-root `CLAUDE.md`."*

**The easy room is now spent, and that is recorded too.** Applying the same test to what remains: the
roster/routing table fails it (routing is needed at intake, before any file is read), the safety rules
fail it (they must survive compaction), and `## The Claude Specialists` fails it. So `CLAUDE.md` stays
above the 200-line target, and closing the rest is the judgement call Dave already deferred — not more
relocation.

Verified beyond the gates: every link in the new rule file resolves (the lint gate does not scan
`.claude/rules/`, so that was checked by hand), and `check-roster-sync` still reports `0 error(s)`
against the shortened `CLAUDE.md` — the roster table was not touched, but a trim that silently broke the
roster check would be a poor trade.

[PR #231](https://github.com/DaveKJohn/davekjohns-workshop/pull/231)

---

### #230 · The bootstrap's scaffolds satisfy the plugin's own contract · Fix · 2026-07-29

Resolves [#226](https://github.com/DaveKJohn/davekjohns-workshop/issues/226). A freshly bootstrapped
repo got **3 `[ERROR]` lines about files the bootstrap had just written** — `Test-BranchName`,
`Get-RosterPath` and `Get-RosterIgnoredIds` missing from the `VUL-IN` scaffolds `specialists-init` places.

The issue asked which side was wrong, and the answer was in the scaffold's own docstring: it advertised
`Get-RepoName / Get-RepoBlobUrl / Get-LintScript`, the contract as it stood when the scaffold was
written. The contract then grew — `Test-BranchName` with `new-branch`, `Get-RosterPath` and
`Get-RosterIgnoredIds` with the roster-sync feature in v1.12.0 — and the scaffold never followed. So the
scaffold side was stale, and the check's wording made it read the other way round: *"this lib predates
the contract"* is the wrong story for a lib written seconds earlier by the current version of the plugin.

All three functions are now in the scaffolds, with the real semantics rather than stubs:
`Get-RosterPath` defaults to `CLAUDE.md`, `Get-RosterIgnoredIds` to an empty array (with a note that
adopting a specialist is the default, and that without this function "skip this one" is not an
implementable outcome at all — which is why the contract marks it required), and `Test-BranchName`
carries the actual reject rules, including that an unknown prefix is deliberately *not* a hard reject.

**The durable part is not the three functions — it is the invariant.** Every existing scaffold assertion
was a spot-check against a hand-maintained list, and that is precisely how this drifted. The new case
spot-checks nothing: it runs the **real contract check against the real bootstrap output**, so adding a
required contract entry without extending the scaffold now fails the suite, whatever the entry is called.
It also asserts the check genuinely probed the libs rather than passing because #225's `[BOOTSTRAP]`
short-circuit swallowed the run — a test that can pass for the wrong reason is not a test.

Measured with the harness from #224: a correctly bootstrapped consumer now shows **19 `[ERROR]` lines,
down from 22.** What remains is the roster rows the owner genuinely has to add, all 19 of them, which is
real work rather than a defect — though 19 near-identical lines is still more noise than one roll-up
would be, and that is worth a separate look now that this is out of the way.

Plugins: specialists

[PR #230](https://github.com/DaveKJohn/davekjohns-workshop/pull/230)

---

### #229 · An `@`-import no longer passes for a roster row · Fix · 2026-07-29

Resolves [#227](https://github.com/DaveKJohn/davekjohns-workshop/issues/227). `bootstrap.ps1` writes
`@.claude/plugins/<family>/<plugin>/01-01-extension.md` into `CLAUDE.md`, and that path *contains* the
token `01-01`. `Test-InRoster` scans the roster file for the token, so the import line satisfied it:
Chris counted as rostered with no roster row anywhere in the file. Measured on a bootstrapped consumer,
19 specialists produced **18** missing-roster findings, and the one that silently passed was the worst
possible id to lose — a persona appears in no always-on listing, so the roster row is the only thing
that makes them exist for a session. The check was blind exactly where blindness costs most, and blind
*because* the bootstrap had correctly done its job.

`check-roster-sync.ps1` now strips `^\s*@` lines from the roster text before anything reads it, which
fixes both directions: the missing row is reported, and an import naming an id with no backing
specialist no longer manufactures a phantom orphan.

**The fix is narrow on purpose, and that is the interesting part.** The obvious repair — bind the token
to a roster-row/table shape — is exactly what `Get-RosterIdTokenPattern`'s docstring records as
**deliberately rejected** under inbound #182: `Test-InRoster` is asked about an id in free prose, and a
table shape would change behaviour for consumers who format their roster as a list. That reasoning still
holds and is not overturned here. An `@`-import is a different animal: a line the bootstrap writes, never
a roster row under any formatting convention, so excluding it needs none of that risk. The docstring now
records where that documented limitation stopped being cosmetic, and the question to ask next time —
*does the offending text have a writer that is knowably not the roster author?* — so a future case is
weighed against this carve-out instead of reopening the rejected option from scratch.

**Residual, unchanged and deliberately not chased:** a roster file that references a lens path in
ordinary prose still satisfies the test for that id. This repo does precisely that — Chris's lens is
linked from the routing prose — so its `01-01` would pass even without a table row. Harmless here, since
the real roster row exists, and the same accepted class as the prose false positives in #182.

**The error count goes up, not down: 21 → 22.** This fix *adds* a correct finding rather than removing
one, because the bug was concealing real work. Worth stating plainly so the next measurement is not read
as a regression.

The regression test was verified to **fail without the fix** before being trusted — both halves, the
missing row and the phantom orphan.

Plugins: specialists

[PR #229](https://github.com/DaveKJohn/davekjohns-workshop/pull/229)

---

### #228 · A repo that was never set up is told so, instead of shouted at 44 times · Fix · 2026-07-29

Resolves [#225](https://github.com/DaveKJohn/davekjohns-workshop/issues/225). Dave's bar: a consumer
may still have work to do after installing, **as long as they are told**. Measured before the change
(PR #224), a fresh consumer got **44 `[ERROR]` lines** at session start and **zero** mentions of the
skill that resolves them — which reads as "this plugin is broken", not "you are not done yet". One
channel actively said *"no action is needed on your side."*

The root cause was a distinction the checks could not make: **drift reporting is right for a
bootstrapped repo and wrong for one that was never set up.** A repo with no lenses and no roster rows
has every enabled specialist "missing" twice over, which is not 38 findings — it is one.

Both checks now detect that state and emit a single non-counting **`[BOOTSTRAP]`** marker naming
`specialists-init`, and both hooks give it **its own verdict** rather than folding it under an existing
one. It arrives on an exit-0 run, so without a dedicated branch it would have fallen through to
"roster in sync with the enabled plugins" — a flat untruth for a repo that has no roster.

| a fresh consumer sees | before | after |
|---|---|---|
| `[ERROR]` lines at session start | **44** | **0** |
| lines naming `specialists-init` | **0** | **2** |

**The predicate is deliberately strict, and that is most of the work.** Only *neither lenses nor roster
rows* counts as never-bootstrapped; a repo with one half is a maintained repo that has drifted and must
keep erroring. Same for the contract check: one lib present means real drift, all absent means not set
up. Both directions are asserted, because a fix like this earns its keep by *not* swallowing genuine
findings.

**Also fixed: remediation pointers that named paths the reader does not have.** The hooks told
consumers to run `scripts/sync/check-roster-sync.ps1` and `scripts/sync/check-script-contract.ps1` —
repo-relative paths for scripts that ship in the plugin. Same class as the v2.11.0 fix ("consumer
messages stop pointing at the workshop"); these were remaining instances. The roster hook now names the
`sync-roster` skill, and the contract hook drops the pointer entirely since its findings already name
every function and its file.

**Honest about what is not fixed.** After a *correct* bootstrap the count is still **21**: three are
[#226](https://github.com/DaveKJohn/davekjohns-workshop/issues/226) (the bootstrap's own scaffolds
failing the plugin's own contract check) and eighteen are the roster rows the owner genuinely has to
add. Those eighteen now carry an actionable pointer instead of a path that does not exist, so the state
meets Dave's bar — but 18 lines is a lot of red for someone who just followed the instructions, and
that is worth revisiting once #226 lands.

Two engineering notes recorded in
[Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md). The
non-counting marker is now a **standing pattern** rather than a fourth exception — `[ORPHANS]`,
`[UNREGISTERED]`, `[INVENTORY]`, `[BOOTSTRAP]` all answer the same problem, and the recipe is written
down so a fifth case reaches for it instead of inventing a shape. And: a repo-wide verdict must be
computed where the evidence is complete, not where it is cheapest. The first implementation
short-circuited before plugin resolution and immediately mistook *plugin not installed on this machine*
for *repo not set up* — two states that need opposite advice. The suite caught it in one run, which is
the argument for landing the guard case in the same commit as the feature.

Plugins: specialists

[PR #228](https://github.com/DaveKJohn/davekjohns-workshop/pull/228)

---

### #224 · What a fresh consumer actually sees at session start, measured · Fix · 2026-07-29

Dave's requirement: it is fine that a consumer still has work to do after installing, **as long as
they are told**. That turns "nul verrassing" into something measurable, so it was measured instead of
reasoned about — and the reasoning had been wrong. The prediction was "three neutral messages that
read as *everything is fine*". The reality is the opposite.

**`scripts/tests/fresh-consumer.measure.ps1`** builds a synthetic consumer in the exact state a real
one is in right after enabling the plugin and restarting — its own `CLAUDE.md`, no lenses, no
repo-config, no orchestrator import — and runs the three `SessionStart` hooks against it the way the
harness does. Committed rather than run ad hoc, because the whole point is that round two is
comparable to round one; a measurement done by hand cannot be repeated identically. The `.measure.ps1`
suffix keeps it out of CI's `*.tests.ps1` glob: it reports numbers, it asserts nothing.

| | before bootstrap | after a successful bootstrap |
|---|---|---|
| `[ERROR]` lines at session start | **44** | **21** |
| lines naming `specialists-init` | **0** | **0** |

A consumer who enables the plugin and restarts gets 44 red lines and no mention of the skill that
resolves them. That does not read as "something still needs doing" — it reads as "this plugin is
broken". Meanwhile the one calmly-worded channel says literally *"no action is needed on your side."*
And the happy path does not end clean either: **21 error lines survive a correctly executed
bootstrap.**

Three defects follow from the numbers and are filed separately, since they are independently fixable:

- **Nothing points at `specialists-init`** — in either state, across all three hooks. The skill itself
  communicates well (five concrete next steps, a paste-ready register block); the defect is that
  nothing leads a consumer to it.
- **The bootstrap fails the plugin's own contract check.** Three of the 21 remaining errors name
  `Test-BranchName`, `Get-RosterPath` and `Get-RosterIgnoredIds` — functions absent from the `VUL-IN`
  scaffolds the bootstrap itself just wrote. The installer produces output its own checks reject.
- **The roster check silently passes Chris.** 18 ids report missing after a bootstrap, not 19: the
  `@`-import line `@.claude/plugins/.../01-01-extension.md` contains the token `01-01`, so
  `check-roster-sync` counts him as rostered. The worst possible id to lose — a persona appears in no
  always-on listing, so the roster row is the only thing making him exist for a session.

What is *not* broken, stated because it is the half worth protecting: nothing crashes, all three hooks
exit 0, and the subagents work. This is a communication failure, not a functional one.

**Two verification lessons recorded in
[Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md), both earned
the hard way in this same pass.** `Select-Object -First N` tears a pipeline down and kills the
still-running child process, while `-Last N` must drain the stream and therefore cannot: piping
`bootstrap.ps1` into `-First 1` created zero lenses and reported nothing wrong, into `-First 20` it
wrote 19 lenses and exited 255, and `-Last 25` on the identical command completed cleanly. The harness
then measured an unbootstrapped repo while labelling the numbers "after bootstrap", and the first
hypothesis reached for was a bug in `Get-DerivedRepoName` — tested across three git states, all exit
0, hypothesis wrong. The harness now captures in full before slicing and aborts on a non-zero setup
exit rather than measuring past it. The second lesson generalises the Chris finding: when a check's
evidence is "the token appears in the file", ask what else in that file legitimately contains the
token before trusting a pass.

[PR #224](https://github.com/DaveKJohn/davekjohns-workshop/pull/224)

---

### #223 · Verifying from the wrong vantage point — the false-failure half of the lesson · Docs · 2026-07-29

`roster-sync.tests.ps1` asserts that the git-root fallback lands on the repo the test runs inside. Run
by absolute path out of a linked worktree while the shell's working directory was still the main
checkout, it failed on precisely that assertion: `git rev-parse --show-toplevel` answers for the
*process's* directory, not for the script's, so `$PSScriptRoot` pointed at the worktree while git
pointed at the main tree. Result: 125 pass, 1 fail — a red suite caused entirely by where it was
launched from, and the obvious misreading is "the branch under test broke something". `Push-Location`
around the run (or `git -C`) is the whole fix.

Recorded in [Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md) as
the sibling of the `Write-Host` trap logged earlier the same day, because they are the same underlying
mistake seen twice: **verifying from the wrong vantage point.** The `Write-Host` case produced a false
*pass* (an in-process assertion about host output reads 0 whether the line is there or not); this one
produced a false *failure*. So the rule that ties them is not "distrust green" or "distrust red", but:
before believing either verdict, confirm the check was observed from the same place its real consumer
observes it — the hook runs the check as a child process, and a suite judges the tree it was launched
in.

Worth keeping because both happened within a single session on July 29, 2026, and the second one was
nearly reported to Dave as a genuine regression.

[PR #223](https://github.com/DaveKJohn/davekjohns-workshop/pull/223)

---

### #222 · Install and uninstall must be symmetric — the teardown gap, recorded · Docs · 2026-07-29

Dave set a requirement on July 29, 2026: a consumer must be able to **install and uninstall these
plugins at any moment**, and after an uninstall it must be able to stand fully free — no lingering
reference to a specialist, manual, persona, or roster anywhere in the repo. Adoption is reversible by
design, not a one-way door. `specialists-init` builds up; **nothing tears down.**

Measured against the `life-hub` consumer rather than estimated. The half that already works is worth
stating plainly: **everything the plugin owns disappears correctly** — agent defs, manuals, persona
bodies, skills, shared scripts, and the three `SessionStart` hooks, which are registered by the
plugin's own `hooks/hooks.json` and leave with it. The gap is entirely on the consumer side: 26
git-tracked lens files referencing nothing, 101 specialist mentions across 492 lines of `CLAUDE.md`,
scripts that exist only for specialists, and — the sharpest one — an `@`-import that points into the
marketplace cache and therefore **actively breaks**, leaving a dead instruction file at every session
start rather than merely clutter.

**The diagnosis is not "too much lives in the consumer".** Consumer-side content is three things, and
only one is disposable: what the plugin owns (already correct), what the repo owner wrote but built on
plugin concepts (the lenses, roster, routing, chains), and what is genuinely independent (the branch
taxonomy, the changelog convention, "never directly on `main`"). A teardown that deletes
indiscriminately would destroy governance and repo knowledge the owner authored — worse than leaving
clutter. The real defect is that the middle category is **woven in rather than bolted on**: 101
mentions spread through one file cannot be removed cleanly, one import pointing at one directory can.
And the third category needs rewording, not removing — "Derek opens the PR" turns a still-valid rule
into a reference to a character that no longer exists.

Recorded in the [family README](claude-code-plugins/claude-specialists/README.md) under **Removal: the
teardown gap**, next to the bootstrap path it is the counterpart to, with the measurement table, the
three categories, and the target shape (one seam for the plugin-shaped content, plugin-neutral wording
for the independent rules, a `specialists-teardown` beside `specialists-init`, and lens files off the
plugin path).

**A false claim corrected in the same pass.** The bootstrap section justified itself with *"a plugin
injects no main-loop context and edits no `CLAUDE.md`"*. The second half is true; the first is not — a
plugin can activate one of its own agents as the main thread via a root `settings.json`. That was
already established in [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) and filed
there as a token-saving idea. It is more than that: a plugin-delivered Chris removes the `@`-import,
which is the worst artifact an uninstall leaves. Same problem from the other side, so #215 is
re-weighted rather than left in the backlog as a nice-to-have.

Nothing is built here. This records the requirement and the measurement so the next change does not
weave more content onto the path that has to be untangled — the cost of the seam rises with every
addition.

[PR #222](https://github.com/DaveKJohn/davekjohns-workshop/pull/222)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

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
