---
name: adopt-workflow-folder
description: Scaffold the workflow's own root folder -- workflow-davekjohn/ -- in a consuming repo, in one move; the folder docs (README, CLAUDE.md, CONTRIBUTING.md), the releases root with this repo's release answers, and the branch dossier in its reset state. Use this when the script-contract session check reports the folder missing, or right after installing the workflow-davekjohn plugin, since an install alone writes nothing into the repo. Strictly additive and dry-run by default; it never overwrites anything.
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
  releases/README.md     this repo's answers to RELEASES-portable.md (the release LIST is not here)
  releases/audience/     where the cut drafts the hand-written note (a .gitkeep until then)
  branch/                the two branch files in their reset state, plus the generated templates
```

**And one file outside it**, since August 20, 2026 (inbound
[#789](https://github.com/DaveKJohn/claude-code-specialists/issues/789)):

```text
.github/workflows/branch-entry.yml   the CI gate that holds every PR to carrying a written entry
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
  markers is yours. **Nothing is ever rewritten**, which is new since August 23, 2026: `new-branch` used
  to refresh the generated `branch/templates/` on drift, and the merged development cycle carries its own
  guidance, so there is no reference beside it left to keep current.
- **The branch document comes from the shared formatter** -- the same one `new-branch` and the fold
  call -- so the scaffold cannot write a shape of its own.
- **Refused in a repo that publishes plugins** (`.claude-plugin/marketplace.json` present). The source
  repo of this workflow keeps its `CONTRIBUTING.md` and `releases/` at its root by its own decision;
  only its branch dossier lives in the folder there.
- **A leftover root `branch/` from before the move is yours to remove by hand** -- the scripts read
  only the new location, deliberately without a dual-read fallback.

## The CI gate it places, and the one choice inside it

The branch entry is a convention this plugin ships every reader of, and until August 20, 2026 **nothing
enforced it**: `open-pr` refuses to push an unwritten entry and `ship-pr` refuses to merge on an
unresolved step, but both are *local*. A branch pushed by hand, or a PR opened in the GitHub UI, meets
neither. So both existing consumers wrote a CI gate from scratch against the same convention -- a second
definition of the format in every repo, free to drift from the fold that reads the first one, and **both
had already drifted**: each refuses a merge over a missing significance score, which is a refusal this
workflow deliberately places at the *release cut* instead.

So the gate ships as a script, `check-branch-entry.ps1`, and this command places the six lines that call
it. It adds no rule of its own -- it calls the same two functions `open-pr` calls -- and it reports the
significance rather than refusing on it.

**Which branches owe nothing** is a seam: `Get-EntryGateExemptPrefixes` in your `scripts/repo-config.ps1`,
defaulting to `sync`. A mirror branch carries somebody else's work rather than your repo's, so it has
nothing to declare -- both consumers reached that answer independently, with nothing recording that it was
the expected one. An **unknown** prefix is deliberately *not* exempt: a typo would otherwise skip the gate
in silence.

**The workflow pins `ref: main` rather than a tag, and that is the one choice worth arguing.** A pinned
gate keeps enforcing the shape it was pinned at -- and the entry's own path has moved twice, so a stale
pin does not fail loudly, it fails the *wrong way*: refusing branches that do carry an entry at the
current path. Tracking the tip means the gate follows the convention it enforces. Pin a tag instead if you
would rather own the bump.

**Making the check *required* is yours.** The file makes it run and report; whether a red gate blocks a
merge is a branch-protection setting, which is a repo decision rather than something a scaffolder should
reach into.

## After the scaffold: one seam to answer, and one to leave alone

The release machinery finds the folder through a `decide` seam in your `scripts/repo-config.ps1`
(the `adopt-config` skill explains the marker):

```powershell
Get-ReleaseNoteRoot     -> 'workflow-davekjohn/releases/audience'
```

**`Get-ReleaseHistoryPath` is deliberately not beside it.** Leave it at its default,
`releases/README.md`, which is where the source keeps its own release list too (Dave, August 19,
2026). The test is whether a thing survives this folder being deleted: a repo that has cut releases
has a **history** whichever tooling cut it, so the list is the repo's and does not belong in a folder
a teardown removes. A per-reader **note** is the opposite -- it exists only because the tier model
does -- which is why `Get-ReleaseNoteRoot` does point in here. Both pointed in here between August 14
and 19; only the list moved back.

**So the page this command scaffolds at `workflow-davekjohn/releases/README.md` carries no history
table**, and until August 20, 2026 it did -- a `## Release history` heading, a table, and a `VUL-IN`
promising that the cut would insert its rows there, in the same run whose closing advice told you to
leave the seam pointing at the repo root. Two statements that cannot both be true, and a consumer who
followed the advice was left with a table that stays empty forever (inbound
[#786](https://github.com/DaveKJohn/claude-code-specialists/issues/786)). The page now points at
whatever `Get-ReleaseHistoryPath` answers instead.

**The file that seam names is yours to create, before your first cut**, and this command deliberately
does not scaffold it:

```markdown
#### 1.x

| Version | Date | Type | Title |
|---|---|---|---|
```

Two reasons, and the first is the one that matters. A file that exists with a table but **no
`<major>.x` heading reads as done** to `cut-release`: the row lands in it, while the guardrail that
refuses to file a `v2` row under a `1.x` heading is silently off, because that check skips when it finds
no section. That is the same "hole with a comment on it" that keeps `adopt-shopify-floor` from writing a
`VUL-IN` stub. And the major in that heading is a version decision no scaffolder can make for you.

**Forgetting it is not silent, which is why an instruction is enough here.** With the file missing the
cut warns `<path> is missing -- row not added: <the row>` and cuts the release anyway, so the cost is
one row added by hand rather than a broken release.

The generated `releases/development/` and `releases/github/` trees stay at the repo root for the same
reason (Dave, August 14, 2026): they are the machine-written record and the publish artefact, not the
folder's hand-kept pages.

And if your `Get-MojibakePaths` copy predates August 14, 2026, re-adopt it via `adopt-config`: the old
copy still names the retired root `branch/` location, so the moved files sit outside its coverage --
nothing errors, the coverage is simply gone until the copy is refreshed.
