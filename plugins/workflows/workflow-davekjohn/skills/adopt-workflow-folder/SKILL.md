---
name: adopt-workflow-folder
description: Scaffold the workflow's own root folder -- workflow-davekjohn/ -- in a consuming repo, in one move; the folder docs (README, CLAUDE.md, CONTRIBUTING.md), the releases root with its history table, and the branch dossier in its reset state. Use this when the script-contract session check reports the folder missing, or right after installing the workflow-davekjohn plugin, since an install alone writes nothing into the repo. Strictly additive and dry-run by default; it never overwrites anything.
---

# adopt-workflow-folder -- one folder for everything portable

Everything portable about the `workflow-davekjohn` workflow gathers in **one folder in your repo's
root** (Dave, August 14, 2026), instead of scattering through it -- `branch/` from the first
`new-branch` run here, a `releases/` tree from the first cut there, a `CONTRIBUTING.md` if somebody
wrote one. A plugin **install cannot create the folder**: an install is a clone into the plugin cache
and writes nothing into your repo. This command is what places it, and the script-contract session
check reports at session start while it is missing.

```text
workflow-davekjohn/
  README.md              what this folder is, and where each page's portable half lives
  CLAUDE.md              the working rules a Claude session needs in this folder
  CONTRIBUTING.md        this repo's answers to CONTRIBUTING-portable.md
  releases/README.md     this repo's answers to RELEASES-portable.md + the release history table
  releases/audience/     where the cut drafts the hand-written note (a .gitkeep until then)
  branch/                the two branch files in their reset state, plus the generated templates
```

## Run it

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/adopt-workflow-folder.ps1"
```

That is a **dry run**: it prints exactly what it would create and writes nothing. Add `-Apply` when
the list looks right.

`${CLAUDE_PLUGIN_ROOT}` resolves **only inside a plugin-owned component** -- that is, when your Claude
runs this skill. Typing the command by hand in a terminal means spelling out the absolute path to your
own plugin cache instead, so the easy route is to ask for the skill rather than to copy the line.

## Parameters

| parameter | what it does |
|---|---|
| `-Apply` | write the files. Without it the command is a dry run that prints the plan and touches nothing -- the same default `adopt-config` uses. |

## The rules it works under

- **Strictly additive, never overwrites.** Every file that already exists is left exactly as it is,
  whatever it contains -- so a re-run finds nothing to do, and everything you wrote past the `VUL-IN`
  markers is yours. The one later writer is `new-branch`'s own refresh-on-drift, which keeps the
  generated `branch/templates/` current; this command only creates them when absent.
- **The branch files come from the shared formatters** -- the same ones `new-branch` and the fold
  call -- so the scaffold cannot write a shape of its own.
- **Refused in a repo that publishes plugins** (`.claude-plugin/marketplace.json` present). The source
  repo of this workflow keeps its `CONTRIBUTING.md` and `releases/` at its root by its own decision;
  only its branch dossier lives in the folder there.
- **A leftover root `branch/` from before the move is yours to remove by hand** -- the scripts read
  only the new location, deliberately without a dual-read fallback.

## After the scaffold: two seams to answer

The release machinery finds the folder through two `decide` seams in your `scripts/repo-config.ps1`
(the `adopt-config` skill explains the marker):

```powershell
Get-ReleaseNoteRoot     -> 'workflow-davekjohn/releases/audience'
Get-ReleaseHistoryPath  -> 'workflow-davekjohn/releases/README.md'
```

Without them the cut keeps writing to the shared defaults at the repo root -- a working state, but not
the one this folder is for. The generated `releases/development/` and `releases/github/` trees stay at
the repo root deliberately (Dave, August 14, 2026): they are the machine-written record and the
publish artefact, not the folder's hand-kept pages.

And if your `Get-MojibakePaths` copy predates August 14, 2026, re-adopt it via `adopt-config`: the old
copy still names the retired root `branch/` location, so the moved files sit outside its coverage --
nothing errors, the coverage is simply gone until the copy is refreshed.
