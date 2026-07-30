---
name: specialists-init
description: >-
  Bootstrap the Claude Specialists system in a new consuming repo: hook up the orchestrator
  (Chris) via one @-import in CLAUDE.md pointing at the seam (which in turn imports his portable
  body from the plugin install + his lens-only repo lens), put the plugin's other main-loop personas
  and the subagents in place as lens-only scaffolds in the seam plus the script-config scaffolds, and
  deliver a governance/safety-hooks proposal.
  Use this when the shared `specialists` plugin is installed and enabled but the conductor and the
  governance layer are still missing ("the workers are there, Chris is not").
---

# specialists-init — the adoption path for a new consumer

The shared `specialists` plugin delivers the **worker subagents** (Sylvester, Tessa, Edith, Victor,
Tycho, …). What a plugin **cannot** do is edit a consumer's `CLAUDE.md`. That is exactly where the gap
sits: **Chris** (the orchestrator) is loaded via an `@`-import in the repo `CLAUDE.md`; the plugin's
**other personas** stand ready as lens-only files in the seam and are read on demand. This skill sets
that up, plus the governance and safety layer that differs per repo.

> **One half of that used to be stated too broadly, and the correction matters here.** A plugin *can*
> inject always-on main-loop context — a root `settings.json` with an `agent` key activates one of its
> own agents as the main thread. Verified, and deliberately **not** switched on: it would change every
> consumer's main loop from a version bump they did not read, and a second `agent`-setting plugin
> silently wins on load order. The reasoning is in the
> [family README](../../../README.md#delivering-the-orchestrator-from-the-plugin--verified-deliberately-not-switched-on)
> and [issue #215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215). So this skill exists
> because of the `CLAUDE.md` half, which is true on its own.

## Chicken-and-egg — step 0 is done by the user

This skill lives inside the `specialists` plugin, so it only becomes available once the plugin is
**installed for this repo** and the session has been restarted. The skill cannot hook itself up. Step 0
is therefore manual, and it is **three acts, in this order**.

**0a — enable.** Verify that the consumer has this in `.claude/settings.json`:

```jsonc
"extraKnownMarketplaces": {
  "davekjohns-workshop": { "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" } }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true
  // plus a domain plugin of choice, e.g. "specialists-shopify@davekjohns-workshop": true
}
```

**0b — install, per plugin, from the repo root, at project scope.** Those settings keys on their own
install nothing. A plugin install is **project-scoped**: `~/.claude/plugins/installed_plugins.json`
keys every install by `projectPath`, and `enabledPlugins` + `extraKnownMarketplaces` produce no entry
for this repo by themselves. So run, from the root of the consuming repo, one command per plugin
listed in `enabledPlugins`:

```powershell
claude plugin marketplace update davekjohns-workshop   # first: refresh the cached marketplace
claude plugin install specialists@davekjohns-workshop --scope project
# plus each domain plugin, e.g.:
claude plugin install specialists-shopify@davekjohns-workshop --scope project
```

**That first line matters if the marketplace is already cached on this machine, and skipping it
installs an old version with a success message.** Measured in `davekjohns-workshop` on July 30, 2026,
minutes after `v3.0.2` was tagged and pushed: the cached clone still sat on the pre-release commit, so
the install produced **3.0.1** and reported `✔ Successfully installed`. Nothing in that output says
the version is stale. `claude plugin marketplace update davekjohns-workshop` followed by a `plugin
update` then moved it `3.0.1 -> 3.0.2` in one step. A refresh mechanism exists (the command reports
`Refreshing marketplace cache (timeout: 120s)`), so a cache does not stay stale indefinitely; on what
schedule it refreshes by itself was not established, which is why the explicit line is in the
procedure. On a machine that has never seen this marketplace the first line is a harmless no-op.

**`--scope project` is not optional here, and leaving it off fails quietly.** `claude plugin install`
defaults to `--scope user` (`claude plugin install --help` states it outright), which writes a record
with **no `projectPath` at all** — machine-wide, active in every repo on the machine, and precisely
not the per-`projectPath` entry the paragraph above says this step exists to create. Nothing errors:
the install reports success, and the only word distinguishing the two is `(scope: user)` in its own
output line. Project scope is the intended model for this family — it is what both real consumers
carry, it is what keeps a repo pinned to the version it was tested against, and every other document
here is written against it.

**The same default bites on the way back out, which is where it is actually expensive.** `claude
plugin update` also defaults to user scope, so on a project-scoped install the plain command fails:

```
✘ Failed to update plugin "specialists@davekjohns-workshop": Plugin "specialists" is not installed at scope user
```

That message is literally true and reads as *"this plugin is not installed"* on a machine where it
demonstrably is — so the obvious next move is to re-run the install, which adds a **second,
user-scope record** beside the project one and makes the plugin appear machine-wide. Update with the
flag instead, from the consuming repo's root, one command per plugin:

```powershell
claude plugin marketplace update davekjohns-workshop
claude plugin update specialists@davekjohns-workshop --scope project
```

Both lines, for the reason above: the update compares version numbers against the **cached** copy of
the marketplace, so a stale cache means a no-op reported as up-to-date. This pair is what every "pick
up the new release" pointer in this family means — in
[`sync-roster`](../sync-roster/SKILL.md), in `scripts/sync/check-script-contract.ps1`, in the
[QUICKSTART](../../../QUICKSTART.md#staying-up-to-date), and in the release notes. Read a bare
`claude plugin update` anywhere as shorthand for these two lines.

**0c — restart, then verify before invoking.** Verify rather than assume, because **the failure this
catches is silent and self-camouflaging**: in a session where the install never happened, this skill
is absent *and* the session-start hooks are absent — and "no hooks because the plugin is not loaded"
reads exactly like "no hooks because everything is in order". Nothing in the session announces the
difference.

**Do not verify with `claude plugin list` alone — it is not repo-scoped, and it will tell you
everything is fine in a repo that has no install.** Measured in `DaveKJohn/davekjohns-workshop` on
July 30, 2026: that repo has `enabledPlugins` set and **no install record of its own** (the only
`projectPath` in `installed_plugins.json` pointed at a different repo), and the plugin was
demonstrably not loaded — no `specialists:*` subagents, no skills, no session hooks. Run from that
repo's root, the list nevertheless reported:

```
❯ specialists@davekjohns-workshop   Version: 3.0.1   Scope: project   Status: ✔ enabled
```

The command enumerates install records beyond the current repo, so a green line is no evidence that
*this* repo is installed. Exactly why it reports the way it does was not established and is
deliberately not recorded here as a mechanism; what matters is that the output cannot carry the
verdict. Note too that the "you may see duplicates, just check each plugin appears as `enabled` at
all" reading — which earlier editions of this step recommended — steers you past the one signal that
would expose a stray second record.

**Check the record for this repo instead.** Run from the root of the consuming repo:

```powershell
$root = (Get-Location).Path
(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |
    ForEach-Object { "$n -> $($_.scope) $($_.version)" } }
```

One line per plugin you enabled, each saying `project`, is the green you need. **Empty output means
this repo has no install** — go back to step 0b. A plugin that shows up as `user` is the scopeless
install from 0b's warning; it works machine-wide but is not the model the rest of these documents
assume.

Then confirm the session actually loaded it: after the restart the `specialists-init` skill is in
your slash list and the session-start hooks have reported. Once both checks are green, invoke this
skill.

## What the skill does

Run the bundled bootstrap script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/skills/specialists-init/bootstrap.ps1"
```

The script performs only **safe, additive** actions — it never overwrites existing content:

**Where the lenses land — the seam (issue #221).** A **fresh** consumer gets one directory and one
line: lenses flat in `.claude/specialists/lenses/`, everything else behind
`.claude/specialists/SPECIALISTS.md`, and a single `@`-import in `CLAUDE.md`. A consumer that
**already has a lens tree** on the pre-seam plugin path (`.claude/plugins/<family>/<plugin>/`) keeps
writing there — this script never relocates a file the repo owner owns, and splitting the surface
across both paths would be worse than either. Migrating is your act, four steps, described in the
[family README](../../../README.md#the-seam-specified). Every reader accepts both layouts.

1. **Persona lenses (lens-only)** — for **every** main-loop persona the plugin ships, puts a
   `*-extension.md` in place in the lens directory chosen above, only if it is not already there. The
   lens carries **no body copy** — only the repo-lens slot; the portable body comes via an `@`-import
   directly from the plugin install. The set is read from the plugin's own `personas/` payload rather
   than from a list here, and it currently holds **four**: Chris `01-01`, Bianca `03-02`, Derek `05-05`,
   Rendall `05-06`. The closing line of the run states the number it actually placed — that count is
   the authority, and it grows on its own when a release adds a persona (inbound #275: this text named
   three while the script placed four, so a reader had to reconcile the prose with the counter).
2. **Empty lens scaffolds** — for each subagent of the **enabled** plugin(s), puts an empty
   `VUL-IN` scaffold in place in that same directory (never overwriting). This makes it
   visible from the first install where the repo-specific tasks per specialist are to be filled in;
   the agent-def automatically reads the lens along once it is filled. In the seam the directory is
   **flat**: `<group>-<id>` is unique family-wide, so several enabled plugins share one `lenses/`.
3. **Script-config scaffolds (#86)** — puts `scripts/repo-config.ps1` and `scripts/lib/branch-info.ps1`
   in place as `VUL-IN` scaffolds (never overwriting, with an **empty** branch table — the taxonomy
   differs per repo). Without these two files, the shared workflow skills `open-pr`/`fold` break on
   a clean consumer over a missing file.
4. **The import(s)** — ensures `CLAUDE.md` carries the orchestrator at the bottom. In the seam that is
   **one** line, `` `@.claude/specialists/SPECIALISTS.md` ``, and that file carries the body import, the
   lens import and this repo's roster slot; on the pre-seam path it stays the two imports it always was
   (portable body + repo lens). Creates a minimal `CLAUDE.md` scaffold if it is missing.
5. **Settings proposal** — writes `.claude/settings.suggested.jsonc` with the recommended
   `permissions.deny` + a hooks **stub**. It does **not** touch `settings.json`: a JSON merge is
   repo-specific and risky, so that judgment stays with you.
6. **Register proposal** — prints a paste-ready **connector manifest** for the *workshop* repo: the
   repo name derived from the git remote, plus the lens inventory per plugin (personas included).
   `visibility` and `localCheckout` stay `VUL-IN`, because this script cannot know them — it has no
   idea where the workshop checkout sits relative to this repo, and a guessed path is exactly what
   the register's marker check exists to prevent. Printed, never written: the register lives in the
   workshop and deliberately never receives cross-repo writes.

## Finishing up (manual — the judgment-call steps)

After the script:

1. **Fill in the repo lens.** Every `*-extension.md` put in place in the seam has an
   `## Specific to this repo (VUL-IN)` slot. Replace it with the repo-specific context: the roster/
   routing (Chris), the branch/PR conventions (Derek), the release mechanics (Rendall). The portable
   body lives in the plugin install (not in the lens) and is loaded along via the `@`-import — the
   marketplace's drift lint guards the lenses against the canonical source.
2. **Adopt the settings.** Copy what fits from `.claude/settings.suggested.jsonc` into
   `settings.json` (or `settings.local.json`), adapt the hooks stub to real repo scripts (or leave
   them out), and then remove the proposal file.
3. **Write the governance.** The `CLAUDE.md` scaffold is bare — fill in the safety rules and the
   working method of this repo (see an existing consumer as a model).
4. **Enable auto-delete of merged branches (#163).** Turn on the GitHub repo setting
   *"Automatically delete head branches"* (`deleteBranchOnMerge: true`) — via the repo settings UI
   or `gh api -X PATCH repos/<owner>/<repo> -F delete_branch_on_merge=true`. That makes remote
   branch cleanup automatic on merge; the local-clone cleanup (`git fetch --prune` +
   `git branch -d <branch>`) stays the fixed closing step of the fold (see the `fold-changelog`
   skill).
5. **Restart the session.** The new `@`-import and config only become active on a **restart** of
   Claude Code.
6. **Register the repo in the workshop.** Take the printed manifest block, fill in the two `VUL-IN`
   fields, and land it as `connectors/<repo>.json` in the marketplace repo via that repo's normal
   branch + PR flow. Skip this and the workshop stays blind to this repo: no plugin-version check, no
   lens-inventory check, no agent-def drift check. Until it is registered, this repo's own session
   start says so — `connector-sessioncheck` surfaces an `[UNREGISTERED]` line next to its verdict.

## Important

- **Do not overwrite.** If a `*-extension.md`, a scaffold, or the `@`-imports already exist, the
  script leaves them alone. The skill is safe to invoke repeatedly.
- **The personas are templates, not subagents.** They deliberately have no agent-def; they run in the
  main loop. Do not modify the portable body locally — a body change lands first in the marketplace
  (`personas/`), not in a consumer (just like a shared agent-def).
