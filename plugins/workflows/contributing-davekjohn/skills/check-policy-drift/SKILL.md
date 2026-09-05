---
name: check-policy-drift
description: Scan a consumer repo's root CLAUDE.md for contradictions against the portable policy of its installed plugins -- contributing-davekjohn always, bwj-codex too when it is also enabled and installed here -- and report which side wins (always the plugin) and what the consumer's text should say instead. Use this on a consumer's own CLAUDE.md when it may have drifted from a plugin's stated policy, after a plugin update that changed a portable policy doc, or whenever the fixed precedence (contributing-davekjohn > bwj-codex > the consumer's CLAUDE.md) needs checking against what a repo's own file actually says. Report-only: it never edits the consumer's CLAUDE.md or any other file -- the actual edit is a separate, ordinary branch+PR in that consumer's own repo, done later.
---

# check-policy-drift -- does this repo's CLAUDE.md contradict the plugin policy that outranks it?

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/check-policy-drift.ps1"
```

`${CLAUDE_PLUGIN_ROOT}` resolves **only inside a plugin-owned component** -- that is, when your Claude
runs this skill. Typing the command by hand in a terminal means spelling out the absolute path to your
own plugin cache instead, so the easy route is to ask for the skill rather than to copy the line.

**Read-only.** The script above locates files and prints their paths; nothing is written, nothing is
pushed, nothing is edited. The comparison itself -- reading those files and deciding whether a sentence
in one genuinely contradicts a sentence in the other -- is yours to do afterward, not the script's.

## Why this is a procedure with a small locator script, not a parser

Semantic contradiction between two prose documents ("does this sentence in the consumer's CLAUDE.md
assert the opposite of that sentence in the plugin's policy?") is a judgement call an LLM makes, the
same way [`report-issue`](https://github.com/DKJ-Solutions/claude-code-specialists/blob/main/plugins/workflows/bwj-codex/skills/report-issue/SKILL.md)
treats its colleague-facing translation as "a judgement call, not a transform" and ships no script of
its own for it. A PowerShell script cannot parse "contradicts" out of two markdown files.

What a script CAN do reliably, and where getting it wrong would matter most, is answer *which* plugins
this repo actually has enabled and installed, and *where* their policy docs sit on this machine -- so
nothing is missed before the reading starts. That is the whole job of
[`check-policy-drift.ps1`](../../scripts/task/check-policy-drift.ps1): it reuses `Get-EnabledPlugins`
and `Get-InstallRecord`/`Test-PluginInstalledHere` from `check-report-lib.ps1` -- the exact seam
`check-roster-sync` and `check-script-contract` already read to answer "which plugins does this repo
actually load" -- instead of inventing a second answer that can disagree with the first.

**`Resolve-PluginDir` itself cannot be reused for this**, and the script's own header says why: it
requires an `agents/` directory at every return path, built for a roster check, and a workflow plugin
(`contributing-davekjohn`, `bwj-codex`) ships `skills/`, not `agents/` -- so calling it here would answer
"not found" for both plugins, on every machine, always. The script carries a small adaptation,
`Resolve-PolicyPluginDir`, that keeps the same three-step precedence (the running session's own
`CLAUDE_PLUGIN_ROOT` first, the install record for this repo second, the highest cached version last)
and asks for the ONE file each caller needs present instead of a hardcoded folder name.

## What it prints, and what to do with each line

| marker | meaning |
|---|---|
| `[FOUND]` | this document is in scope -- read it in full before comparing. |
| `[SKIP]` | this plugin is not enabled, or enabled but not installed for this repo -- its doc is out of scope, and the run says why (with the `claude plugin install` line to fix it, where that is the cause). |
| `[MISSING]` | this document *should* be in scope but could not be located -- a stale cached copy, most likely. Say so in your report rather than silently comparing against nothing. |

`CLAUDE.md` itself missing is the one case the script refuses on (`exit 1`): there is nothing to compare
a plugin's policy against, so the run stops before it prints anything else.

## After the script: the comparison itself

1. Read every `[FOUND]` document in full -- the consumer's `CLAUDE.md`, and each located portable
   policy doc.
2. Compare them statement by statement. Flag a **genuine contradiction only**: the consumer's text
   asserts something the plugin's text asserts the opposite of, or a procedure the consumer's doc
   contradicts. A topic the plugin is silent on, or detail the consumer added on its own, is fine and
   expected -- that is not drift.
3. For each contradiction found, report:
   - the **consumer's claim**, quoted, with its file and location (a heading or a line reference);
   - the **plugin's claim** it conflicts with, quoted, with its file and location;
   - **one line** stating which side wins -- always the plugin, per the precedence
     `CONTRIBUTING-portable.md` states (`contributing-davekjohn` outranks `bwj-codex`, which outranks
     the consumer's own `CLAUDE.md`) -- and what the consumer's text should say instead.
4. If nothing contradicts, report **"no contradictions found"** plainly. That is a complete, expected
   answer, not a failure to find something.
5. **Never edit the consumer's `CLAUDE.md`, or anything else.** This is a finding. The actual edit is a
   separate, ordinary branch+PR in that consumer's own repo -- by a person, or by another session, later.
   A consumer's real choice, per the precedence rule, is full adoption of the plugin's policy or no
   install of the plugin at all; never a blend, and never a blend this skill produces by patching the
   file itself.
