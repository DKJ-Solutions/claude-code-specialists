# Release v2.13.0

**Date:** 2026-07-29  
**Type:** Minor

Adoption becomes reversible: a teardown skill, a fresh consumer told what to do instead of shown 44 errors, and a lighter always-on path

You are on this release.

## Features

### #233 · `specialists-teardown` — adoption is now reversible · Feat · 2026-07-29

Third item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221), and the half that
could be built and tested without restructuring anything first. Dave's requirement: a consumer must be
able to install **and uninstall** at any moment and afterwards stand free of the plugin. There was a
`specialists-init` to build up and nothing to take down.

[`specialists-teardown`](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md)
is the bootstrap's mirror image: where the bootstrap is strictly **additive** and never overwrites, the
teardown is strictly **subtractive** and never deletes what the owner wrote.

**Classifying before removing is the entire design**, because consumer-side content is three things and
only one is disposable:

| category | what happens |
|---|---|
| generated and untouched — a lens still carrying its `VUL-IN` marker, an unfilled script scaffold, the `@`-imports, `settings.suggested.jsonc` | **removed** |
| authored by the owner — a filled-in lens holding repo knowledge somebody wrote | **reported, never touched** |
| owned by the repo anyway — a real `repo-config.ps1`, a filled branch table | **reported as yours to keep or drop** |

The `VUL-IN` marker is the test, because that is the exact contract `bootstrap.ps1` writes those files
under; its absence means somebody edited the file, which makes it theirs. Deliberately a content test
rather than a timestamp or hash — a reformat or a merge does not make content authored.

**Dry run by default.** A destructive script running on somebody's repo should have to be asked twice,
and the preview doubles as the inventory a reader needs in order to say yes.

**Two things it refuses to do.** It never edits `.claude/settings.json` — disabling the plugin is the
owner's act, and the bootstrap never wrote that file either, so the symmetry that makes this safe cuts
both ways; it is reported instead, noting that the subagents and hooks stay active until the entry is
gone and the session restarted. And it never removes roster rows or repo prose from `CLAUDE.md`: the only
lines it touches there are the two `@`-imports, safe because an import naming a persona body or an
extension lens is knowably bootstrap-written — the same property that let `check-roster-sync` stop
counting them as roster rows (#227).

**Measured round-trip:** bootstrap a fixture → 24 items placed → teardown removes 22 and keeps the 2 the
owner filled in, with the owner's own `CLAUDE.md` prose intact.

**38 tests, and the ones that matter are the negative ones.** A teardown that removes plenty is easy; one
that can be trusted has to demonstrably not touch authored content, not edit `settings.json`, and not eat
an unrelated `@`-import. That last case is the sharpest risk in the design: a consumer's own
`@docs/git-instructions.md` is exactly the line a sloppy rule destroys, and they would have no idea why
their instructions stopped loading. The matcher keys on the specialist shape, and the test proves it.

**What it still cannot finish, stated rather than glossed.** A repo that authored lenses and roster
sections is not blank afterwards — those are reported, not removed. As long as specialist content is woven
through `CLAUDE.md` instead of sitting behind one inclusion, no script can finish without guessing where a
roster row ends and the owner's prose begins. That is the seam, and #221 stays open for it.

The lint gate's skill-enumeration check (#10) caught the new skill missing from two marked
`skills:all` spans in the family README before CI did — the guard working exactly as designed.
(Deliberately naming the marker without its comment delimiters: check 10 scans `CHANGELOG.md` for
those delimiters and does not skip code spans, so writing them out here would make this entry trip
the very check it describes — which is exactly what happened on the first attempt, see #234.)

[PR #233](https://github.com/DaveKJohn/davekjohns-workshop/pull/233)

## Fixes

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
[Sylvester #15's lens](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/.claude/plugins/claude-specialists/specialists/05-15-extension.md). The
non-counting marker is now a **standing pattern** rather than a fourth exception — `[ORPHANS]`,
`[UNREGISTERED]`, `[INVENTORY]`, `[BOOTSTRAP]` all answer the same problem, and the recipe is written
down so a fifth case reaches for it instead of inventing a shape. And: a repo-wide verdict must be
computed where the evidence is complete, not where it is cheapest. The first implementation
short-circuited before plugin resolution and immediately mistook *plugin not installed on this machine*
for *repo not set up* — two states that need opposite advice. The suite caught it in one run, which is
the argument for landing the guard case in the same commit as the feature.

[PR #228](https://github.com/DaveKJohn/davekjohns-workshop/pull/228)

---

Full workshop notes: [releases/development/2.x/2.13.0.md](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/releases/development/2.x/2.13.0.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
