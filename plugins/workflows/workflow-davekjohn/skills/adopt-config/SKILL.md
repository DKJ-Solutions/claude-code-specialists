---
name: adopt-config
description: Adopt the source repo's workflow configuration from the shipped blueprint -- place the values that state the shared way of working into this repo's own seam libs, and get a written proposal for the ones only this repo can answer. Use this after specialists-init has laid down scripts/repo-config.ps1 and scripts/lib/branch-info.ps1, or whenever the script-contract check reports functions this repo has never configured.
---

# adopt-config -- the source's answers, offered rather than assumed

The shared workflow scripts (`open-pr`, `ship-pr`, `cut-release`, `new-branch`, ...) are repo-agnostic
and dot-source two **repo-owned** libs from your repo:

```text
scripts/repo-config.ps1        20 functions -- what this repo is and how it releases
scripts/lib/branch-info.ps1     2 functions -- the branch prefix table and its validator
```

`check-script-contract.ps1` already tells you which of those are missing and what the shared script
falls back to. What it cannot tell you is **what the source repo chose, and why** -- so every consumer
has been re-deriving those answers by hand, or not at all.

This command closes that gap. It reads the blueprint the plugin ships
(`blueprint/config-blueprint.json`), compares it against what your repo actually defines, and acts on
the marker each record carries.

## Run it

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/adopt-config.ps1"
```

That is a **dry run**: it prints exactly what it would do and writes nothing. Add `-Apply` when the plan
looks right.

`${CLAUDE_PLUGIN_ROOT}` resolves **only inside a plugin-owned component** -- that is, when your Claude
runs this skill. Typing the command by hand in a terminal means spelling out the absolute path to your
own plugin cache instead, so the easy route is to ask for the skill rather than to copy the line. That
cache holds the last *released* mirror, which matters in the repo the scripts are **maintained** in: the
mirror lags its own source there by however many merges have landed since, so a maintainer runs the copy
under `scripts/`. The `adopt-config.ps1` command above is the one exception, since there is nothing for
the source repo to adopt from itself.

## The two markers, and why one of them never writes anything

| marker | what the value states | what happens |
|---|---|---|
| `copy` | the shared **way of working** -- it asserts nothing about your repo | the source's own function text, comments included, is written into the right lib |
| `decide` | **what a repo is** -- copying it would claim something about yours that may be false | it goes into a proposal document for a person to answer |

**A `decide` record is never written as a stub, and that is a mechanism rather than a preference.** A
stub returning a placeholder is *worse* than an absent function: absent means the shared script uses its
documented fallback, and for `Get-ReleasePluginTier` that fallback is computed from your tree and is
usually right. A stub returning `VUL-IN` would override a correct computation with a value nothing
checks.

**Nothing is ever overwritten.** A function you already define is left exactly as it is, whatever the
blueprint says. That makes the command safe to re-run -- a second run finds nothing to place.

**It is not a bootstrap.** If a seam lib is missing altogether, the command stops and points you at the
`specialists-init` skill: that skill owns whether the file exists, this one owns what is in it.

## Parameters

| parameter | what it does |
|---|---|
| `-Apply` | Actually write. Without it the command is a dry run that touches nothing -- the default, because the first run of a command that edits your config should show you the edit first. |
| `-ProposalPath` | Where the proposal document for the `decide` records is written, repo-root-relative. Default: `config-adoption-proposal.md` in the repo root. |

## What you get

- the `copy` functions appended to your seam libs under a header naming where they came from -- they
  are your files now, edit them freely;
- `config-adoption-proposal.md`, one section per decision, each with **why it is yours to answer**, what
  the function must return, what happens if you leave it out, and the source's own version quoted for
  reference. Delete the file once you have worked through it; re-running regenerates it.

Leaving a proposed value unanswered is a valid outcome. Every record in that document is optional or
has a documented fallback -- answer the ones where your repo genuinely differs from the source.

## Afterwards

Run the contract check to see the same seam from the shared scripts' side:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-script-contract.ps1"
```

**In the source repo, run its own copy instead -- `scripts/sync/check-script-contract.ps1`.** That one is
a gate there rather than a one-off, and reading the seam through a lagging mirror is exactly the reading
it exists to prevent.
