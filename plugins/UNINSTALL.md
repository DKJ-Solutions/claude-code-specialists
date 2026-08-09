# Uninstall — how to disconnect your repo

The counterpart to [INSTALL.md](INSTALL.md), and written for the same reader: someone who did
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
[Step 5](#step-5--drop-the-marketplace-registration-last) deletes that clone in its entirety — the measured
before/after sizes are in the [#339 table](#step-5--drop-the-marketplace-registration-last), with the
profile they were taken on.
After that the document exists **nowhere on this machine**, so a reader who is interrupted, stops for the
day, or just wants to re-read a step has nothing left to read (inbound
[#328](https://github.com/DaveKJohn/claude-code-specialists/issues/328)). Keep this page open or save it to
disk; the durable copy is
[on GitHub](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/UNINSTALL.md).
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
#    No output together with exit code 1 is the answer you WANT here (see below)
git check-ignore -v .claude/specialists/lenses/ |
  Where-Object { ($_ -split '\t')[0] -notmatch ':$' }   # keep only hits with a filled pattern field

# 2. Is it COMMITTED right now? Staged does not count -- this reads the commit, not the index
git ls-tree -r --name-only HEAD .claude | Select-String 'extension\.md|SPECIALISTS\.md'
#    empty output              = not committed yet
#    "fatal: ... HEAD"         = this repo has no commits at all, so also not committed
```

**Command 2 reads the commit rather than the index, and that distinction is the whole point of this
section** (inbound [#332](https://github.com/DaveKJohn/claude-code-specialists/issues/332)). It used to be
`git ls-files`, which reports the **index**. Measured in round v10: a `git add -A` went through, the
following `git commit` failed, and the command flipped from empty to 20 lines with **zero commits added to
the repository**. Its old comment — `# empty = not committed yet` — was therefore false in the direction
that matters: non-empty did not mean committed. A reader whose commit fails on a hook, a missing git
identity, or a typo in the message got a green pre-flight and went on believing there was an undo.

**That is the third generation of the same defect in this one pre-flight, so the fix ships with a test
rather than as a third correction.** #280 was `git ls-files` failing to tell *"this repo cannot"* from
*"you have not yet"*; #283 was the CRLF blank-line artefact in command 1; this is the surviving half, still
measuring the wrong object. The fixtures live in `scripts/tests/teardown-protocol.tests.ps1` in the source
repo, and one of them now stages without committing and asserts this command stays empty.

**Command 1's success case exits `1`, and that is the answer you want.** `git check-ignore` returns 1 when
nothing matches. In an interactive shell that is invisible; an agent harness reads a non-zero exit as a
failed command and has to decide whether to trust it. Nothing is wrong — no output plus exit 1 means the
lens tree is not ignored.

The filter on command 1 is load-bearing rather than tidiness: on Windows a `.gitignore` with CRLF line
endings and a blank line makes git report a hit with an **empty pattern field** for any path ending in a
slash, which reads exactly like a real ignore rule. The full measurement is in the
[skill](teams/team-alpha/skills/specialists-teardown/SKILL.md#pre-flight-is-your-lens-tree-actually-under-version-control).
And note where the undo really begins: at the **commit**, not at the bootstrap. If command 2 comes back
empty because the lenses were never committed, commit them first — a wrongly removed file is only one
`git checkout` away once git has a copy. **Commit more than the lens tree, though.** This paragraph used to
name only that tree, while the teardown also edits `CLAUDE.md` and, with `-VendorScripts`, writes under
`scripts/` — both of which were *also* untracked at that moment in the v10 measurement. A reader who
committed literally what was named had no undo for two of the three things about to change. `git add
CLAUDE.md .claude scripts` covers it.

**If your own scripts reach into the plugin, plan that before you uninstall.** This family is the single
source of truth for the shared workflow scripts, and a consumer that adopted them reaches them through a
resolver that **throws** when the marketplace cache is gone. After an uninstall such a repo does not
merely carry clutter — its daily git workflow stops working. `-VendorScripts` in
[Step 1](#step-1--take-the-plugin-out-of-your-repo) is the way out, and it has to happen while the plugin
is still installed.

## Step 1 — take the plugin out of your repo

From the root of the consuming repo. Dry run by default, because a script that deletes things in
somebody's repo should have to be asked twice — and the preview doubles as the inventory you say yes to.

**`<plugin>` below is your installed plugin directory, and it is worth pinning down before you paste**
(inbound [#330](https://github.com/DaveKJohn/claude-code-specialists/issues/330)): the previous edition left the
placeholder unexplained, and a reader had to reason it out. It is the **version-pinned cache** copy, which is
the `installPath` field of your own install record:

```powershell
$root = (Get-Location).Path
(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |
    ForEach-Object { "$n -> $($_.scope) $($_.version) $($_.gitCommitSha) $($_.installPath)" } }
```

It prints the same four fields as the install check plus the path, and that is not padding: **read the scope
before you tear anything down.** Step 2's uninstall is scope-keyed and refuses at the wrong one, and one line
per plugin each saying `project` is the state the rest of this document assumes. Typically the path is
`~\.claude\plugins\cache\<marketplace>\<plugin>\<version>`. **Do not use the path from your
`SPECIALISTS.md` imports** — those point into `~\.claude\plugins\marketplaces\<marketplace>\`, the git clone,
which is a *different directory* carrying the sources in a different layout. Both exist on a machine that has
run this family, which is exactly why picking the wrong one is easy; the adoption page's
[Staying up to date](INSTALL.md#staying-up-to-date) section explains why there are two.

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

**Keep that output.** You can reproduce it for longer than an earlier edition of this page claimed, but not
for the whole procedure, and saving it now costs nothing.

**Be precise about where the tool actually dies, because this page used to get it wrong** (inbound
[#373](https://github.com/DaveKJohn/claude-code-specialists/issues/373)). Earlier editions said the audit goes
with [Step 2](#step-2--uninstall-the-plugin-one-command-per-plugin). It does not. `teardown.ps1` sits in the
**version-pinned cache** — the same `<plugin>` path you resolved at the top of this step — and the cache
follows the *marketplace*, not the install, which is what the
[#339 table](#starting-from-a-genuinely-clean-machine) at the foot of this page has said all along.
Measured walking the steps in their printed order (rounds v11 and v12, August 1–2, 2026, CLI `2.1.220`):
after `claude plugin uninstall … --scope project`, both `teardown.ps1` and this `UNINSTALL.md` were still
on disk and the cache directory was still there. Step 2 takes the install record and the plugin's **data**
directory and drops an `.orphaned_at` marker; the instruments survive it.

What finally takes them is the **manual cache delete in
[Step 5](#step-5--drop-the-marketplace-registration-last)** — the one removal no command does for you. So the
real shape of the constraint is the one [#328](https://github.com/DaveKJohn/claude-code-specialists/issues/328)
was filed about, just one step further down the page: the procedure does remove its own instruments, at the
end rather than in the middle. Re-run the audit as often as you like at any point before that; it removes
nothing and needs no `-Apply`.

## Step 2 — uninstall the plugin, one command per plugin

From your repo root:

```powershell
claude plugin uninstall team-alpha@claude-code-specialists --scope project
# and once more for each add-on team you enabled -- and for
# workflow-davekjohn if you enabled the workflow
```

**If you ran the workflow, take its scripts out before you uninstall it.** Step 1's
`-VendorScripts` hands back working copies of the **core's** payload only, and says so in its own
output: the two plugins are separately versioned and separately installed, so the teardown that ships
in one deliberately does not reach into the other's cache. `new-branch`, `open-pr`, `ship-pr`,
`fold-changelog-entry`, `cut-release` and the libs they dot-source live in
`~\.claude\plugins\cache\claude-code-specialists\workflow-davekjohn\<version>\scripts\` —
copy that tree into your own `scripts/` first if you want to keep the workflow after disconnecting.
Its structure matters: those scripts reach their siblings `$PSScriptRoot`-relative, so a flattened copy
breaks at the next branch rather than at the copy.

**Keep the scope flag.** `uninstall` defaults to `--scope user` like its siblings, so without it the
command does not act on a project-scoped install. What it says instead depends on your CLI version — on
`2.1.220` (measured, round v11) it is:

```text
✘ Failed to uninstall plugin "team-alpha@claude-code-specialists": Plugin "team-alpha@claude-code-specialists"
  is enabled at project scope (.claude/settings.json, shared with your team). To disable just for you:
  claude plugin disable team-alpha@claude-code-specialists --scope local
```

**Do not follow the remedy the CLI suggests there.** `plugin disable --scope local` is a different
operation: it writes a local *disable* key on top of your project setting and leaves the install in
place, so Step 4's verification will not come back empty and you will have added a key instead of
removed one. The command you want is the one above, with `--scope project`.

> **The exact wording is version-bound; the flag is not.** Earlier releases phrased this as *"Plugin
> `specialists` is not installed at scope user"* — literally true and easy to misread as *not installed
> at all*. If your CLI says something different again, the sentence to trust is this one: the scope flag
> is required, and the failure means the command looked in the wrong scope, never that the plugin is
> absent.

**If that refuses with *"installed in local scope, not project"*, you are in the third scope and it is not
your doing.** A session start can write a record by itself and flip an existing `project` record to
`local` — no command run, no file in your repo changed, nothing reporting it. Remove that one with
`claude plugin uninstall team-alpha@claude-code-specialists --scope local`. Which scope you are actually in
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
- **It leaves an `.orphaned_at` file behind** (inbound
  [#337](https://github.com/DaveKJohn/claude-code-specialists/issues/337)). Measured in round v10 and named in no
  document until now, which is why it stood out: this section predicts its own side effects carefully, so the
  one it missed reads as an omission rather than a detail. It is the CLI's own bookkeeping, harmless, and it
  is cleaned up along with the cache directory in Step 4 below. Expect it; do not go hunting for what wrote
  it.

## Step 3 — remove the keys you wrote, then restart

The uninstall clears the *entry*; the keys you added in adoption Step 1 are yours to take back out. In
`.claude/settings.json` (and `.claude/settings.local.json` if you used it), remove:

- `enabledPlugins` — the `team-alpha@claude-code-specialists` entries, or the whole key if it is now `{}`;
- `extraKnownMarketplaces` — the `claude-code-specialists` block. **Of the two, this is the one to be sure
  about**: left behind, it can put the marketplace back and the machine rebuilds its own install without a
  command being run (the measured detail is a few paragraphs below);
- **any `permissions` entry pointing into the plugin directory** (inbound
  [#337](https://github.com/DaveKJohn/claude-code-specialists/issues/337)). After a full teardown, round v10
  found this still sitting in `.claude/settings.local.json`:

  ```json
  { "permissions": { "allow": [ "Read(//c/Users/<you>/.claude/plugins/**)" ] } }
  ```

  It is not something this family writes, but `settings.suggested.jsonc` is a plausible route for one to get
  there, and an allow-rule pointing at a directory you are about to delete is exactly the kind of leftover a
  teardown is supposed to leave you free of. Check both settings files for `plugins` inside `permissions`.

**Then restart your Claude Code session** — the subagents and the session hooks stay active until the
entry is gone *and* the session has restarted.

The marketplace registration itself lives outside your repo and is deliberately **not** removed here: it
is [Step 5](#step-5--drop-the-marketplace-registration-last), after the verification, because removing it
takes this document off the machine with it.

**Do Step 3 before you re-check Step 2, or you will keep finding a record you just deleted.** An enable
key alone is enough for a session start to write a missing install record by itself — as long as the
marketplace registration is still standing, which at this point in the procedure it is. So a machine where
`enabledPlugins` still names this plugin heals its own uninstall, silently, on the next session — and
your verification will show a fresh record with a fresh timestamp and nothing to explain it.

**The trap needs the marketplace registration standing, and finishing this procedure takes it away — but
only if you remove both keys.** Round v12 measured three states on one profile with a stray enable key left
in place each time; round v13 re-measured the last of them with **both** keys deliberately left behind
(inbound [#327](https://github.com/DaveKJohn/claude-code-specialists/issues/327) and
[#382](https://github.com/DaveKJohn/claude-code-specialists/issues/382), August 2, 2026):

| state of the machine | does a session start write a record? |
|---|---|
| keys set, but no marketplace and no clone at the session's start | **no** — `plugins: {}`. That session did register the marketplace and create the clone, but wrote no record |
| marketplace registered and the clone present | **yes** — a full, correct `project` record, from a session that itself loaded nothing. The **unpacked cache does not have to be there**: round v13 got a full record whose `installPath` pointed into a `cache/claude-code-specialists/…` directory that did not exist |
| after a full teardown including Step 5's manual cache delete, with only `enabledPlugins` left behind | **no** — the record stayed `{}`, and nothing re-registered itself |
| after that same teardown, with `extraKnownMarketplaces` left behind as well | **yes, in two session starts** — row 1 fires, and it *produces* what row 2 needs: session 1 re-registered the marketplace and rebuilt the clone (4,665,111 bytes) while the record stayed `{}`, and session 2 wrote the full record |

Read the first two rows as a sequence, not as alternatives: the state row 1 leaves behind **is** the state
row 2 fires on. That is what makes the last row possible without a single command being run.

A **half-finished** teardown — plugin uninstalled, marketplace and clone still standing — is therefore the
state that regenerates records behind you, which is why Step 3's key removal matters most while you are
still mid-procedure.

**What disarms the mechanism is Step 3 taking out both keys, not reaching the end of Step 5.** Finish the
whole procedure with `enabledPlugins` left behind and the machine does stay free — that was measured, and it
is the reassuring half. Leave **`extraKnownMarketplaces`** behind and it does not, however far you got: that
is the dangerous one of the two, because it is the key that can put the marketplace back, and the rest of
the table follows from there. Round v13 walked the procedure through to the end of Step 5 — record `{}`,
`known_marketplaces.json` `{}`, clone gone, cache gone — left both keys, opened two sessions and ran no
commands at all, and stood on an install record again.

**A record a session start wrote is recognisable by its key order** (inbound
[#389](https://github.com/DaveKJohn/claude-code-specialists/issues/389)). A real
`claude plugin install --scope project` puts `projectPath` second; a session start puts it last:

```jsonc
// written by the install
{ "scope": "project", "projectPath": "…", "installPath": "…", "version": "3.1.2", … }
// written by a session start
{ "scope": "project", "installPath": "…", "version": "3.1.2", …, "projectPath": "…" }
```

Two writers, two serialisation orders. That is a second signal next to `installedAt`, and independent of it:
reading it costs no edit, which matters here because the standing advice is *not* to hand-edit
`installed_plugins.json` — an edit being exactly what wipes the evidence you were after. Treat it as
confirmation and not as proof: this is CLI `2.1.220` behaviour and can shift with any version.

## Step 4 — verify that you actually stand free

- **The record query from Step 2 comes back empty.** Empty output means nothing is installed for this
  path. Run it from the repo root; it is keyed on `projectPath`.
- **A fresh session has no `specialists-*` skills and no specialist hooks.** Beware of how this reads: a
  session that loads no plugin has no hooks to complain, because the hooks are *in* the plugin. Absence of
  complaint is not evidence — check the skill list itself.
- **Chris no longer takes the floor**, and your `CLAUDE.md` has no `@`-import pointing at the seam.
- **The teardown's audit said `[FREE]`** — read it back from the output you kept in
  [Step 1](#step-1--take-the-plugin-out-of-your-repo). **If you did not keep it, run it again from the
  cache**: `teardown.ps1` survives Step 2 and is still at the `<plugin>` path Step 1 resolved, right up
  until you delete the cache by hand in Step 5. It removes nothing and needs no `-Apply`, so a re-run here
  is free. Run at this point it also *confirms* Step 2 rather than contradicting it: its note reads
  *"No install record points at this repo any more"*, because it asks the same `projectPath` question you
  just did (inbound [#381](https://github.com/DaveKJohn/claude-code-specialists/issues/381)). If it instead says
  it could not read `installed_plugins.json`, that is a gap in the reading and not a verdict — check the
  path it names. Only once Step 5 is done is re-installing the plugin the honest route — and by then the question
  has stopped mattering, because the marketplace is gone too.

Everything above is verifiable with the marketplace still registered, which is why the registration comes
off last.

## Step 5 — drop the marketplace registration, last

This is the step that also takes the cached clone — and with it this page — off the machine, which is why
it waits until Step 4 is done:

```powershell
claude plugin marketplace remove claude-code-specialists
```

It takes an optional `--scope <user|project|local>`; omit it and the declaration is removed from every
scope. Then the last verification: **`claude plugin marketplace list` no longer names
`claude-code-specialists`.**

**If you declared the marketplace at *user* scope, expect it to edit `~/.claude/settings.json` and to leave
an empty key behind** (inbound [#357](https://github.com/DaveKJohn/claude-code-specialists/issues/357)). The
`claude-code-specialists` block goes, `"extraKnownMarketplaces": {}` stays, and the file is re-serialised so the
key order may shift:

```jsonc
// before
{ "extraKnownMarketplaces": { "claude-code-specialists": { … } }, "theme": "dark" }
// after
{ "extraKnownMarketplaces": {}, "theme": "dark" }
```

Exactly the mirror image of what Step 2 says about `"enabledPlugins": {}`, and the same reading applies:
a diff there is the command working, not a fault. Remove the empty key by hand if you want the file back to
where it started.

**On the path INSTALL.md prescribes, none of that happens — and that is the expected result, not an
anomaly** (inbound [#374](https://github.com/DaveKJohn/claude-code-specialists/issues/374)). Two independent
reasons: the adoption page's pasteable block puts `extraKnownMarketplaces` in **your repo's**
`.claude/settings.json`, and its `marketplace add` alternative is given as `--scope project` for exactly
this reason; and [Step 3](#step-3--remove-the-keys-you-wrote-then-restart) already removed that key several
steps ago, so in the printed order there is nothing left here for `marketplace remove` to empty out.
Measured on a virgin Windows profile (round v12, August 2, 2026, CLI `2.1.220`): `~/.claude/settings.json`
did not exist before or after, `known_marketplaces.json` came back to `{}` at 2 bytes, and
`claude plugin marketplace list` printed `No marketplaces configured`.

So a clean-machine check after a by-the-book project-scoped teardown **is** literally clean; it is only a
user-scope declaration that leaves keys behind, empty rather than absent. An earlier edition said *never*
literally clean, full stop — which sent a project-scope reader hunting for a key that was never there.

**What that command does and does not delete, measured rather than assumed** (inbound
[#339](https://github.com/DaveKJohn/claude-code-specialists/issues/339), August 1, 2026, on a virgin Windows
profile — the one environment where the answer was not obscured by an earlier install):

| location | before | after |
|---|---|---|
| `~/.claude/plugins/marketplaces/claude-code-specialists/` — the cached clone | 2,930,310 bytes | **gone** |
| `~/.claude/plugins/cache/claude-code-specialists/` — the unpacked payload | 939,860 bytes | **still there** |

**So the unpacked cache belongs to the marketplace, not to the install**, and that rule is worth carrying
rather than the two numbers. `claude plugin marketplace add` *creates* it — measured on that same virgin
Windows profile on August 1, 2026: absent → 939,768 bytes, while the install record stayed at `{}` —
`marketplace remove` does not take it
away, and no `plugin install` or `plugin uninstall` is involved in either direction. This page used to say
the question was unestablished and told you to go look; the looking has been done. Delete the leftover by
hand if you want the machine genuinely untouched:

```powershell
Remove-Item "$env:USERPROFILE\.claude\plugins\cache\claude-code-specialists" -Recurse -Force
```

## What is left behind, honestly

A repo that adopted this family and then tore down is **not** blank. Four of the six below are correct
rather than debt — they stay, and that is the right outcome. The last two are things to act on, and they
are marked as such:

- **Your history stays.** `CHANGELOG.md` and release notes that mention specialists are an accurate record
  of something that happened. History is finished business and is never rewritten.
- **Lenses you filled in stay**, including the orchestrator's — they are your writing. The `@`-import that
  loaded them is gone, so they survive as files nothing reads. Present, tracked, and inert.
- **Roster rows and specialist names in your own prose stay.** No rule a script could apply safely knows
  where a roster row ends and your prose begins. The audit lists them by line so you can reword the ones
  that were rules phrased through a character (*"Derek opens the PR"* → *"changes go in via a branch and a
  PR"*) and delete the ones that only ever existed for the plugin.
- **A `.claude/settings.json` you created for adoption Step 1 stays, holding `{}`.** For a repo that
  had no `.claude/` before adoption — the first-time consumer this family documents — that file and its
  directory exist *because* of the adoption. [Step 3](#step-3--remove-the-keys-you-wrote-then-restart)
  takes the keys out and says so; the empty file it leaves is 3 bytes, harmless, and yours to delete if
  you want the repo back to where it started. Named here rather than left out because this list claims to
  be the whole of it (inbound [#386](https://github.com/DaveKJohn/claude-code-specialists/issues/386), round
  v13), and the `CLAUDE.md` row below covers the same category: a file that would not exist without the
  adoption.
- **The scaffold prose stays in a `CLAUDE.md` the bootstrap created — and unlike everything else in this
  list, it keeps talking.** The one entry here the plugin itself wrote. If you had no `CLAUDE.md` before
  adoption, two of its lines are `specialists-init`'s (*"This repo is governed by **Claude Specialists**
  …"*), and the teardown reports them as `[KEEP]` instead of deleting them. The line it keeps is
  deliberate: an `@`-import *loads* something, so removing it is safe and necessary; cutting sentences out
  of somebody's governance file to satisfy a counter is the wrong side of that boundary.

  **But `CLAUDE.md` is itself loaded into every session as project instructions**, so this is the one
  leftover that is not merely inert — it tells every future session, in the channel that outranks its
  defaults, that the repo is governed by a system that is no longer installed. Measured over three rounds,
  two fresh sessions each (inbound [#362](https://github.com/DaveKJohn/claude-code-specialists/issues/362) and
  [#392](https://github.com/DaveKJohn/claude-code-specialists/issues/392)): **v11 flagged it 2 out of 2, v12
  and v13 both 1 out of 2.** The v11 pair is where the quotable line came from — one session noted that
  the named `specialists-init` skill *"is not present in my available-skills list"* — and it is not the
  rate to plan around.

  What the later rounds add is *when* it surfaces. Of the four sessions across v12 and v13, the ones that
  said something were asked to **orient** (*"what is this and what conventions apply here?"*); the ones
  that did not were given a **task** (*"small clarification in the README, how do I go about it?"*). A
  task-shaped session looks at what there is to do, not at what the repo claims about itself — one of them
  did flag `CLAUDE.md` as an untracked leftover *"that does not belong in the fixture"* while walking
  straight past the contradiction inside it. Four observations over two rounds is a pattern and not a law,
  but it is more use than a bare number.

  **So this row is a to-do rather than a note, and 1-in-2 is the argument for that, not against it**: a
  leftover that only sometimes announces itself is exactly the one you close by hand. Two ways to do it,
  both one edit:

  ```powershell
  # If the bootstrap created the file, it now holds nothing else -- delete it.
  Remove-Item CLAUDE.md
  # If you have since written your own governance text, replace just those two lines with what is true,
  # e.g. "Conventions for this repo" -- and drop the sentence naming Claude Specialists.
  ```

  Until August 1, 2026 those lines were reported as **neither** `[remove]` nor `[KEEP]` while the audit
  printed `[FREE]`, which is what got this row written (inbound
  [#331](https://github.com/DaveKJohn/claude-code-specialists/issues/331)).
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
[#339](https://github.com/DaveKJohn/claude-code-specialists/issues/339)):

| location | what closes it |
|---|---|
| `installed_plugins.json` | Step 2 removes the record; the file itself stays, holding `{"version": 2, "plugins": {}}` |
| `marketplaces/<marketplace>/` | Step 5 — `marketplace remove` deletes the clone |
| `cache/<marketplace>/` | **no step** — it follows the marketplace, not the install. Delete it by hand in Step 5 |
| `data/<plugin>-<marketplace>/` | Step 2's uninstall, unless you passed `--keep-data` |
| `known_marketplaces.json` | Step 5 removes the entry; the file stays |
| `~/.claude/settings.json` | Step 3, by your own edit |

**A torn-down profile is not necessarily byte-identical to a virgin one** — a more useful answer than
"clean". What is left over is **whatever the teardown could not un-create**, so it depends on what your
profile looked like going in, and two measurements bracket the range:

| file | a profile that had run other plugins | a profile that had only ever run this one |
|---|---|---|
| `installed_plugins.json` | 35 bytes, `{"version": 2, "plugins": {}}` | same — 35 bytes |
| `known_marketplaces.json` | 288 bytes, no longer naming this marketplace | **2 bytes**, `{}` |
| `~/.claude/settings.json` | 22 bytes, `{"theme": "dark"}` | **absent** — never created |

Neither state holds anything belonging to this family; the difference is only how much of the surrounding
file survives. The right-hand column is round v12 on a virgin Windows profile (August 2, 2026), where all
six rows of the check above came back literally clean. **Read your own numbers against your own starting
point, not against either column** — a file this family never wrote is not evidence of a teardown that
under-performed.

**Do not hand-edit `installed_plugins.json`.** It is this family's standing rule for its own test rounds
and it applies here too: the `installedAt` stamps are how a record that was *adopted* from another repo is
told apart from one that was *created*, and an edit wipes exactly that evidence. Use the commands, or
delete nothing.

## Reporting something wrong with this page

The same route as everything else: an issue on this repo with the label `inbound`, using the
[issue template](../.github/ISSUE_TEMPLATE/inbound-improvement.md). A step that did not work as printed
is worth reporting even if you found the way around it — that is the class of defect this family keeps
finding in its own documents.
