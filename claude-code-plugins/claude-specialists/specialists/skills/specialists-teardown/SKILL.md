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
any moment, and afterwards carry no lingering reference to a specialist, manual, persona or roster.

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

A repo that ran the bootstrap, filled in its lenses, and then tore down is **not** blank. The lenses it
authored and the roster sections in `CLAUDE.md` remain, reported rather than removed. That is the
correct outcome for the content, and it is also the known limitation: as long as specialist content is
woven through `CLAUDE.md` rather than sitting behind a single inclusion, a script cannot finish the job
without guessing. Closing that gap is the seam described in
[issue #221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221) -- this skill is the half that
can be built and tested today.
