# Uninstall — how to disconnect your repo

The counterpart to the [Quickstart](QUICKSTART.md), and written for the same reader: someone who did
**not** build this system and now wants it out again. Adoption is reversible by design — a consumer must
be able to install *and* uninstall at any moment (Dave's requirement, July 29, 2026) — and this page is
the procedure for the second half.

## Two removals, and confusing them is the usual mistake

They are independent, they are done in a fixed order, and neither one does the other's job:

| | what it removes | how |
|---|---|---|
| **Out of your repo** | the seam (`.claude/specialists/`), the `@`-import in your `CLAUDE.md`, the settings proposal, the unfilled scaffolds | the `specialists-teardown` skill |
| **Off your machine** | the install record, the enable keys, the marketplace registration, the cached clone, the plugin's data directory — plus the unpacked cache, which no command removes | `claude plugin` commands + your settings files, then one delete by hand |

A repo teardown leaves the plugin installed and loading. A plugin uninstall leaves your repo full of
lenses and a broken import. You almost certainly want both.

## Before you start

**The order is not free: repo first, machine second.** `specialists-teardown` ships **inside the
plugin**. Uninstall the plugin first and the skill goes with it — leaving you a repo full of generated
files and no tool that knows which of them it wrote, because the distinction it makes (see
[Step 1](#step-1--take-the-plugin-out-of-your-repo)) lives in the skill and not in the files. Everything
else in this procedure can be redone in any order; this one cannot.

**The same trap applies to this page itself, so keep a copy before you begin.** `UNINSTALL.md` is not
part of the plugin payload — it ships only in the cached marketplace clone, and
[Step 5](#step-5--drop-the-marketplace-registration-last) deletes that clone (measured: 2.9 MB, gone).
After that the document exists **nowhere on this machine**, so a reader who is interrupted, stops for the
day, or just wants to re-read a step has nothing left to read (inbound
[#328](https://github.com/DaveKJohn/davekjohns-workshop/issues/328)). Keep this page open or save it to
disk; the durable copy is
[on GitHub](https://github.com/DaveKJohn/davekjohns-workshop/blob/main/claude-code-plugins/claude-specialists/UNINSTALL.md).
That is the paragraph above applied to the manual instead of the tool: this page made the argument for
`specialists-teardown` and then missed it for itself. It missed it a second time for its own audit tool —
[Step 1](#step-1--take-the-plugin-out-of-your-repo) now says so. Both only surfaced when someone walked
the procedure end to end for the first time.

**Check whether your lens tree is under version control, because that is your undo.** Two commands, from
your repo root — they answer different questions and only the first decides whether this procedure *can*
be reversed:

```powershell
# 1. Can this repo track the lens tree at all?
#    A line that SURVIVES the filter = ignored -> there is NO undo, stop and read the skill first
git check-ignore -v .claude/specialists/lenses/ |
  Where-Object { ($_ -split '\t')[0] -notmatch ':$' }   # keep only hits with a filled pattern field

# 2. Is it committed right now?
git ls-files .claude | Select-String 'extension\.md|SPECIALISTS\.md'   # empty = not committed yet
```

The filter on command 1 is load-bearing rather than tidiness: on Windows a `.gitignore` with CRLF line
endings and a blank line makes git report a hit with an **empty pattern field** for any path ending in a
slash, which reads exactly like a real ignore rule. The full measurement is in the
[skill](specialists/skills/specialists-teardown/SKILL.md#pre-flight-is-your-lens-tree-actually-under-version-control).
And note where the undo really begins: at the **commit**, not at the bootstrap. If command 2 comes back
empty because the lenses were never committed, commit them first — a wrongly removed file is only one
`git checkout` away once git has a copy.

**If your own scripts reach into the plugin, plan that before you uninstall.** This family is the single
source of truth for the shared workflow scripts, and a consumer that adopted them reaches them through a
resolver that **throws** when the marketplace cache is gone. After an uninstall such a repo does not
merely carry clutter — its daily git workflow stops working. `-VendorScripts` in
[Step 1](#step-1--take-the-plugin-out-of-your-repo) is the way out, and it has to happen while the plugin
is still installed.

## Step 1 — take the plugin out of your repo

From the root of the consuming repo. Dry run by default, because a script that deletes things in
somebody's repo should have to be asked twice — and the preview doubles as the inventory you say yes to:

```powershell
# Preview -- nothing is removed
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1"

# Act
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1" -Apply

# Act, and keep a working git workflow afterwards
powershell -NoProfile -File "<plugin>/skills/specialists-teardown/teardown.ps1" -Apply -VendorScripts
```

It classifies before it removes: a lens still carrying its `VUL-IN` marker is generated and goes, a lens
you filled in is **yours** and is reported rather than touched, and files the repo owned anyway (a real
`repo-config.ps1`, a filled branch table) are reported as yours to keep or drop. If your repo marks an
empty lens its own way, say so with `-EmptyLensPattern '<your marker>'` — without it those lenses are
kept, which is the safe direction.

**Read the report lines, not just what is left on disk.** `[remove]` versus `[KEEP]` is what tells you
which case you were in; a `[KEEP]` means *still there*, not *still working*.

**Three things it deliberately will not do**, and each one becomes your work in the next steps:

- it never edits `.claude/settings.json` — disabling the plugin is your act (Step 3);
- it never removes roster rows or your own prose from `CLAUDE.md` — only the `@`-import(s), which are
  knowably bootstrap-written;
- it never touches the install or the cache — that is Step 2.

The run closes with a free-standing audit that goes looking for what still points at the plugin, by file
and line. `[FREE]` is the clean answer; anything else is a checklist for
[Step 4](#step-4--verify-that-you-actually-stand-free).

**Keep that output, because this is the last point at which you can produce it.** The audit is part of
`teardown.ps1`, which lives in the payload that [Step 2](#step-2--uninstall-the-plugin-one-command-per-plugin)
removes — so by the time Step 4 asks you for the audit line, the tool that prints it is gone (inbound
[#328](https://github.com/DaveKJohn/davekjohns-workshop/issues/328)). Re-run it here as often as you like;
it removes nothing and needs no `-Apply`. Afterwards it is unavailable at any price short of re-installing
the plugin, which is why Step 4 reads the output you saved here rather than asking for a fresh run.

## Step 2 — uninstall the plugin, one command per plugin

From your repo root:

```powershell
claude plugin uninstall specialists@davekjohns-workshop --scope project
# and once more for each domain group you enabled
```

**Keep the scope flag.** `uninstall` defaults to `--scope user` like its siblings, and without the flag it
will not find a project-scoped install — it reports the plugin as not installed at that scope, which is
literally true and easy to misread as *not installed at all* on a machine where it is.

**If that refuses with *"installed in local scope, not project"*, you are in the third scope and it is not
your doing.** A session start can write a record by itself and flip an existing `project` record to
`local` — no command run, no file in your repo changed, nothing reporting it. Remove that one with
`claude plugin uninstall specialists@davekjohns-workshop --scope local`. Which scope you are actually in
is the last thing this query prints:

```powershell
$root = (Get-Location).Path
(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |
    ForEach-Object { "$n -> $($_.scope) $($_.version) $($_.gitCommitSha)" } }
```

Two more things this command does that are worth expecting rather than discovering:

- **It edits your settings file.** A project-scoped uninstall removes your plugin's entry and leaves
  `"enabledPlugins": {}` behind — in a **tracked** governance file, so it shows up in `git status`. The
  local-scoped one does the same in `.claude/settings.local.json`. That is the CLI's doing; the plugin's
  own scripts never write those files.
- **It deletes the plugin's data directory** (`~/.claude/plugins/data/<plugin>-<marketplace>/`) unless you
  pass `--keep-data`. On a machine that has run this family, that directory exists. It is empty in the
  measured case, so the default is fine — but if you ever put state there, that is the flag.

## Step 3 — remove the keys you wrote, then restart

The uninstall clears the *entry*; the keys you added in Quickstart Step 1 are yours to take back out. In
`.claude/settings.json` (and `.claude/settings.local.json` if you used it), remove:

- `enabledPlugins` — the `specialists@davekjohns-workshop` entries, or the whole key if it is now `{}`;
- `extraKnownMarketplaces` — the `davekjohns-workshop` block.

**Then restart your Claude Code session** — the subagents and the session hooks stay active until the
entry is gone *and* the session has restarted.

The marketplace registration itself lives outside your repo and is deliberately **not** removed here: it
is [Step 5](#step-5--drop-the-marketplace-registration-last), after the verification, because removing it
takes this document off the machine with it.

**Do Step 3 before you re-check Step 2, or you will keep finding a record you just deleted.** An enable
key alone is enough for a session start to write a missing install record by itself. So a machine where
`enabledPlugins` still names this plugin heals its own uninstall, silently, on the next session — and
your verification will show a fresh record with a fresh timestamp and nothing to explain it.

## Step 4 — verify that you actually stand free

- **The record query from Step 2 comes back empty.** Empty output means nothing is installed for this
  path. Run it from the repo root; it is keyed on `projectPath`.
- **A fresh session has no `specialists-*` skills and no specialist hooks.** Beware of how this reads: a
  session that loads no plugin has no hooks to complain, because the hooks are *in* the plugin. Absence of
  complaint is not evidence — check the skill list itself.
- **Chris no longer takes the floor**, and your `CLAUDE.md` has no `@`-import pointing at the seam.
- **The teardown's audit said `[FREE]`** — in the output you kept from
  [Step 1](#step-1--take-the-plugin-out-of-your-repo). This is a check you read back rather than re-run:
  the audit ships in the payload Step 2 removed, so there is nothing left to run it with. If you did not
  keep it and you want the line, the honest route is to re-install the plugin, re-run the audit, and
  uninstall again — which is why Step 1 says to keep it.

Everything above is verifiable with the marketplace still registered, which is why the registration comes
off last.

## Step 5 — drop the marketplace registration, last

This is the step that also takes the cached clone — and with it this page — off the machine, which is why
it waits until Step 4 is done:

```powershell
claude plugin marketplace remove davekjohns-workshop
```

It takes an optional `--scope <user|project|local>`; omit it and the declaration is removed from every
scope. Then the last verification: **`claude plugin marketplace list` no longer names
`davekjohns-workshop`.**

**What that command does and does not delete, measured rather than assumed** (inbound
[#339](https://github.com/DaveKJohn/davekjohns-workshop/issues/339), August 1, 2026, on a virgin Windows
profile — the one environment where the answer was not obscured by an earlier install):

| location | before | after |
|---|---|---|
| `~/.claude/plugins/marketplaces/davekjohns-workshop/` — the cached clone | 2,930,310 bytes | **gone** |
| `~/.claude/plugins/cache/davekjohns-workshop/` — the unpacked payload | 939,860 bytes | **still there** |

**So the unpacked cache belongs to the marketplace, not to the install**, and that rule is worth carrying
rather than the two numbers. `claude plugin marketplace add` *creates* it — measured on the same profile,
absent → 939,768 bytes, while the install record stayed at `{}` — `marketplace remove` does not take it
away, and no `plugin install` or `plugin uninstall` is involved in either direction. This page used to say
the question was unestablished and told you to go look; the looking has been done. Delete the leftover by
hand if you want the machine genuinely untouched:

```powershell
Remove-Item "$env:USERPROFILE\.claude\plugins\cache\davekjohns-workshop" -Recurse -Force
```

## What is left behind, honestly

A repo that adopted this family and then tore down is **not** blank, and three of these are correct rather
than debt:

- **Your history stays.** `CHANGELOG.md` and release notes that mention specialists are an accurate record
  of something that happened. History is finished business and is never rewritten.
- **Lenses you filled in stay**, including the orchestrator's — they are your writing. The `@`-import that
  loaded them is gone, so they survive as files nothing reads. Present, tracked, and inert.
- **Roster rows and specialist names in your own prose stay.** No rule a script could apply safely knows
  where a roster row ends and your prose begins. The audit lists them by line so you can reword the ones
  that were rules phrased through a character (*"Derek opens the PR"* → *"changes go in via a branch and a
  PR"*) and delete the ones that only ever existed for the plugin.
- **A gate of your own that lints lens files may go quiet rather than red.** Once the directory is gone
  the category silently skips: nothing errors, nothing is reported, and the gate stays green while
  checking nothing. Right for a deliberate teardown, wrong for an accidental loss.

## Starting from a genuinely clean machine

Useful if you are testing the adoption path as a first-time consumer would meet it, where a leftover from
a previous install is indistinguishable from the path working. Everything this family leaves outside your
repo lives under `~/.claude/`, and the list below was taken from a machine that has run it:

| location | what it holds |
|---|---|
| `~/.claude/plugins/installed_plugins.json` | the install records, keyed on `projectPath` |
| `~/.claude/plugins/marketplaces/<marketplace>/` | the cached git clone the install copies from |
| `~/.claude/plugins/cache/<marketplace>/` | the unpacked payload, per plugin and version |
| `~/.claude/plugins/data/<plugin>-<marketplace>/` | the plugin's persistent data directory |
| `~/.claude/plugins/known_marketplaces.json` | the marketplace registration |
| `~/.claude/settings.json` | a user-level `enabledPlugins` / `extraKnownMarketplaces`, if you used one |

Which step closes which — including the one entry that no step closes for you (inbound
[#339](https://github.com/DaveKJohn/davekjohns-workshop/issues/339)):

| location | what closes it |
|---|---|
| `installed_plugins.json` | Step 2 removes the record; the file itself stays, holding `{"version": 2, "plugins": {}}` |
| `marketplaces/<marketplace>/` | Step 5 — `marketplace remove` deletes the clone |
| `cache/<marketplace>/` | **no step** — it follows the marketplace, not the install. Delete it by hand in Step 5 |
| `data/<plugin>-<marketplace>/` | Step 2's uninstall, unless you passed `--keep-data` |
| `known_marketplaces.json` | Step 5 removes the entry; the file stays |
| `~/.claude/settings.json` | Step 3, by your own edit |

**And a torn-down profile is not byte-identical to a virgin one** — a more useful answer than "clean".
Measured after the full procedure, three files exist that were absent before adoption:
`installed_plugins.json` (35 bytes, `{"version": 2, "plugins": {}}`), `known_marketplaces.json` (288
bytes, no longer naming this marketplace) and `~/.claude/settings.json` (22 bytes, `{"theme": "dark"}`).
None of them holds anything belonging to this family. What remains is those three files, empty of ours.

**Do not hand-edit `installed_plugins.json`.** It is this family's standing rule for its own test rounds
and it applies here too: the `installedAt` stamps are how a record that was *adopted* from another repo is
told apart from one that was *created*, and an edit wipes exactly that evidence. Use the commands, or
delete nothing.

## Reporting something wrong with this page

The same route as everything else: an issue on this repo with the label `inbound`, using the
[issue template](../../.github/ISSUE_TEMPLATE/inbound-improvement.md). A step that did not work as printed
is worth reporting even if you found the way around it — that is the class of defect this family keeps
finding in its own documents.
