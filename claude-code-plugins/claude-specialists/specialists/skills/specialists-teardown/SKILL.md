---
name: specialists-teardown
description: >-
  Remove what specialists-init put into a consuming repo, so the repo can stand free of the plugin:
  the generated lens scaffolds, the two @-imports in CLAUDE.md, the untouched script-config
  scaffolds and the settings proposal. Strictly subtractive and the mirror image of the bootstrap --
  it never deletes anything the repo owner filled in, and never edits settings.json. Dry run by
  default. Use this when a consumer is being disconnected from the plugin, or to verify that
  adoption is genuinely reversible before relying on it.
---

# specialists-teardown -- give the repo back

The counterpart to [`specialists-init`](../specialists-init/SKILL.md). Adoption is reversible by
design (Dave's requirement, July 29, 2026): a consumer must be able to install **and uninstall** at
any moment, and afterwards carry no *live* reference to a specialist, manual, persona or roster --
nothing a session loads, a script resolves, or a gate depends on. Its own changelog history is
exempt, and stays as written.

## Run it

From the root of the consuming repo:

```powershell
# Preview -- nothing is removed
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1"

# Act
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1" -Apply
```

**Dry run by default.** A destructive script that runs on somebody's repo should have to be asked
twice, and the preview doubles as the inventory a reader needs in order to say yes.

## What it classifies, and why that is the whole design

Consumer-side content is three things and only one is disposable. Deleting indiscriminately would
destroy governance and repo knowledge the owner authored -- a worse outcome than leaving clutter. So
the script classifies before it removes:

| category | what it is | what happens |
|---|---|---|
| **Generated and untouched** | a lens still carrying its `VUL-IN` marker, an unfilled script scaffold, the `@`-imports, `settings.suggested.jsonc` | **removed** |
| **Authored by the owner** | a filled-in lens -- repo knowledge somebody wrote | **reported, never touched** |
| **Owned by the repo anyway** | a `repo-config.ps1` with real values, a filled branch table: this repo's own conventions | **reported as yours to keep or drop** |

The signals are the scaffold shapes **this plugin writes**: a `(VUL-IN)` slot heading for a lens, a
`VUL-IN` in an assignment's *value* for `repo-config.ps1`, an empty prefix table for `branch-info.ps1`.
Deliberately a content test rather than a timestamp or hash: a reformat or a merge does not make content
authored.

> **It only recognises its own conventions, and says so rather than guessing.** A round-trip in
> `davekokbwj/smartwatchbanden` (July 29, 2026) found 20 of its 22 lenses empty under **that repo's own**
> "clean slate" convention — a closing sentence, no `(VUL-IN)` heading anywhere. All 22 were kept, and the
> report claimed they were "filled in". Right answer, wrong reason, and adoption was less reversible than
> this skill implied. Two changes followed: the report no longer asserts authorship it cannot establish
> (it says the file is *not recognised as a scaffold*, which is all it knows), and a consumer can declare
> its own convention with **`-EmptyLensPattern <regex>`**, e.g.
> `-EmptyLensPattern 'Nothing recorded yet'`. Without it those lenses are kept — the safe direction,
> since a false keep leaves clutter while a false remove destroys someone's work.

## What it deliberately will not do

- **It never edits `.claude/settings.json`.** Disabling or uninstalling the plugin is the owner's act,
  and the bootstrap never wrote that file either -- the symmetry that makes this safe to run cuts both
  ways. It is reported instead, with the note that the subagents and session hooks stay active until
  the entry is gone and the session restarted.
- **It never removes roster rows or repo-specific prose from `CLAUDE.md`.** Those are authored text in a
  file full of other authored text, and no rule this script could apply safely tells where a roster row
  ends and your own prose begins. The only lines it touches there are the two `@`-imports, which are
  knowably bootstrap-written and cannot be anything else -- the same property that let
  `check-roster-sync` stop counting them as roster rows.
- **It never touches the plugin install or cache.** `claude plugin uninstall` is a separate step.

## Verifying a round-trip — and why `git status` is not enough

The first real round-trip (`davekokbwj/smartwatchbanden`, July 29, 2026) was verified with
`git status` / `git diff`, and that method turned out to be **partly blind**: that repo ignores
`.claude/*`, so `settings.suggested.jsonc` never appeared in `git status` and `git checkout .` did not
clean it up. Since `.claude/` is where most of what the bootstrap writes lives, git can miss the bulk of
it. Worse, in such a repo git cannot **restore** a wrongly deleted lens either — so establish whether
`.claude/` is tracked *before* running with `-Apply`.

Take a **filesystem** inventory at each stage instead, and compare the numbers:

```powershell
# count of lenses, imports, scaffolds, and the settings proposal
@(Get-ChildItem .claude -Recurse -Filter '*-extension.md' -File).Count
@([System.IO.File]::ReadAllLines('CLAUDE.md') | Where-Object { $_ -match '^\s*@' }).Count
Test-Path scripts\repo-config.ps1; Test-Path scripts\lib\branch-info.ps1
Test-Path .claude\settings.suggested.jsonc
```

Two further checks the hooks will not do for you, both of which caught real defects:

- **Count the bootstrap's note line.** A `teardown` → `init` cycle used to add one copy per cycle
  (measured 1 → 2 → 3) while all three session hooks reported "in sync". Run the cycle **twice**: once
  cannot distinguish "does not accumulate" from "accumulates once".
- **Count lone LFs in `CLAUDE.md`.** `([regex]::Matches($text, "(?<!\`r)\`n")).Count` — the bootstrap
  used to paste LF into a CRLF file, invisible to every gate.

And declare your own empty-lens convention if you have one, or the report will keep files it cannot
recognise: `-EmptyLensPattern '<your marker>'`.

## What is left over afterwards, honestly

A repo that ran the bootstrap, filled in its lenses, and then tore down is **not** blank. The remaining
distance was measured by hand in `davekokbwj/smartwatchbanden` (July 29, 2026) rather than estimated,
and it is four different kinds of leftover. Only the second is this skill's own limitation. Note that
the target is **no *live* reference, not zero references** -- see
[what is correctly left standing](#and-what-is-correctly-left-standing) at the end of this section, and
the requirement itself in the [family README](../../../README.md#removal-the-teardown-gap).

**1. A runtime dependency no teardown can undo -- the one that actually hurts.** The plugin is the
single source of truth for the operational scripts (`new-branch.ps1`, `park-branch.ps1`,
`new-changelog-entry.ps1`, `open-pr.ps1`, `fold-changelog-entry.ps1`;
[issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)), and a consumer reaches them
through a resolver of its own that locates the marketplace cache and **throws** when that cache is gone.
In the measured consumer that resolver is `scripts/lib/plugin-paths.ps1`, and three operational scripts
dot-source it: `start-task.ps1`, `open-pr.ps1`, `fold-changelog-entry.ps1`. So after a teardown plus a
`claude plugin uninstall`, the repo does not merely carry clutter -- **its daily git workflow stops
working.** No option to this script can fix that: adopting the shared-script model is what creates the
dependency, and undoing it means the consumer holding local copies of those scripts (or its resolver
degrading instead of throwing). State the promise precisely, then: what the bootstrap *wrote* is
reversible; what the consumer *built on top of the plugin* is not, and a consumer that relies on the
shared scripts has to plan that step itself. Note also that the dry run says nothing about this today --
it reports what it would remove and what it keeps, not what breaks afterwards. Warning about it would be
a change to the script, not to this page.

**2. Authored text this script refuses to touch.** By design, per
[the section above](#what-it-deliberately-will-not-do) -- and measured, so the size of the hand work is
known. `CLAUDE.md` carried the roster table (22 rows), the work-division block, the loading-strategy
paragraph, and the safety cross-references into the orchestrator's lens: roughly 43 lines across some 6
sections. Outside that file the mentions are loose and few -- `README.md` (5),
`research/plugin-sharing/README.md` (14), `releases/README.md` (1),
`.github/pull_request_template.md` (1). As long as specialist content is woven through `CLAUDE.md`
rather than sitting behind a single inclusion, a script cannot finish this without guessing where a
roster row ends and the owner's prose begins. Closing it is the seam in
[issue #221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221) -- this skill is the half that
can be built and tested today.

**3. A lens that outlives the import which loaded it.** The orchestrator's lens
(`01-01-extension.md`) is authored content, so it is kept -- while the `@`-import that loaded it is
removed, being knowably bootstrap-written. The file therefore survives as an orphan: present, tracked,
and read by nothing. Both halves are correct, and the combination is worth naming, because a `[KEEP]`
line reads as "still working" when all it means is "still there".

**4. A consumer gate that goes blind rather than red.** A consumer that lints its own lens files keeps
that check afterwards, and in the measured repo the lens category **silently skips** once the directory
is gone: nothing errors, nothing is reported, and the gate stays green while checking nothing. That is
the right outcome for a deliberate teardown and the wrong one for an accidental loss -- a silent skip
cannot tell an operator's removal from a bad merge or a mistyped path, so the one case it must warn about
is the one case it stays quiet in. Not this script's to fix (the gate is the consumer's own), but worth
knowing before you rely on a green gate to tell you the repo is intact: a skip that *says* it skipped
costs one line.

And `.claude/settings.json` is unchanged -- that is the refusal above rather than a leftover. The plugin
stays enabled, subagents and session hooks included, until the owner removes the entry and restarts.

### And what is correctly left standing

Some references are supposed to survive, and counting them as debt would be a mistake. In the measured
repo, `CHANGELOG.md` (3) and `releases/development/*` (43) mention specialists -- 46 references that are
each an accurate record of something that happened. **History is finished business: it is never
rewritten, and a teardown must not touch it.**

Which is why the goal is *no live reference* rather than *no reference*: nothing a **session loads**, a
**script resolves**, or a **gate depends on** may still point at the plugin. Read that way the four
leftovers sort by what they actually cost -- (1) breaks a run, (2) and (3) mislead a reader, (4) misleads
a gate, and the changelog is simply the record of having adopted the plugin in the first place.
