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

The `VUL-IN` marker is the test, because that is the exact contract `bootstrap.ps1` writes those files
under. Its absence means somebody edited the file, which makes the file theirs. Deliberately a content
test rather than a timestamp or hash: a consumer may have reformatted line endings or been through a
merge, and neither makes the content authored.

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

## What is left over afterwards, honestly

A repo that ran the bootstrap, filled in its lenses, and then tore down is **not** blank. The lenses it
authored and the roster sections in `CLAUDE.md` remain, reported rather than removed. That is the
correct outcome for the content, and it is also the known limitation: as long as specialist content is
woven through `CLAUDE.md` rather than sitting behind a single inclusion, a script cannot finish the job
without guessing. Closing that gap is the seam described in
[issue #221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221) -- this skill is the half that
can be built and tested today.
