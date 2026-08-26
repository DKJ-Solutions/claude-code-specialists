---
name: adopt-workflow-folder
description: Scaffold the workflow's own root folder -- contributing-davekjohn/ -- in a consuming repo, in one move; the folder docs (README and CONTRIBUTING -- one page since #886, not two), the releases root with this repo's release answers, and no branch dossier, since that document lives only while a branch is open. Use this when the script-contract session check reports the folder missing, or right after installing the contributing-davekjohn plugin, since an install alone writes nothing into the repo. Strictly additive and dry-run by default; it never overwrites anything.
---

# adopt-workflow-folder -- one folder for everything portable

Everything portable about the `contributing-davekjohn` workflow gathers in **one folder in your repo's
root** (Dave, August 14, 2026), instead of scattering through it -- `branch/` from the first
`new-branch` run here, a `releases/` tree from the first cut there, a `CONTRIBUTING.md` if somebody
wrote one. A plugin **install cannot create the folder**: an install is a clone into the plugin cache
and writes nothing into your repo. This command is what places it, and the script-contract session
check reports at session start while it is missing.

```text
contributing-davekjohn/
  README.md              what this folder is, and where each page's portable half lives
  CONTRIBUTING.md        this repo's answers to CONTRIBUTING-portable.md
  releases/README.md     this repo's answers to RELEASES-portable.md (the release LIST is not here)
  releases/audience/     where the cut drafts the hand-written note (a .gitkeep until then)
  (development-cycle.md is NOT placed -- it lives only while a branch is open)
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
- **The folder itself is permanent** (issue #885). No command in this plugin removes
  `contributing-davekjohn/`, and no future teardown may -- uninstalling the plugin takes the plugin, not the
  record that belongs to your repo. `development-cycle.md` is the one file inside it that does not share
  that lifetime: it exists only while a branch is open, which is a precision on the rule rather than an
  exception to it.

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
Get-ReleaseNoteRoot     -> 'contributing-davekjohn/releases/audience'
```

**`Get-ReleaseHistoryPath` is isolated by default now too** (issue #885, group E, reversing the
August 19, 2026 answer below). That answer kept the list at the repo root on a durability argument:
a repo that has cut releases has a **history** whichever tooling cut it, so it should not live in a
folder a teardown could remove. #885 also settled that `contributing-davekjohn/` is **permanent** -- see
[the rules above](#the-rules-it-works-under) -- which answers that same durability worry the other way:
the folder is now the safer place for the list, not the riskier one. So a fresh consumer gets
`contributing-davekjohn/releases/history.md` without configuring anything, the same computed-default
treatment `Get-ChangelogPath` already gets. **A repo that adopted before August 25, 2026 keeps its
existing list at the root**: the computed default only isolates a *consumer*, and re-adopting an
existing one starts a *second* list here rather than moving the first one under it silently -- repoint
the seam back to your root file if you would rather keep one list. `Get-ReleaseNoteRoot` still needs its
own explicit seam line below, for the separate reason its own contract record gives: it already has real
consumers relying on its literal fallback, which the three roots and the history path never had.

**So the page this command scaffolds at `contributing-davekjohn/releases/README.md` carries no history
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

The generated `releases/changelog/` and `releases/github/` trees belong in this folder too, beside
`releases/audience/` — nothing writes them but a cut, so they exist only because this workflow does
(#914, August 26, 2026). They are where the two root seams point by default, so a repo that answers
nothing gets them there; a repo whose notes already sit elsewhere repoints the seam at the tree it has.

And if your `Get-MojibakePaths` copy predates August 14, 2026, re-adopt it via `adopt-config`: the old
copy still names the retired root `branch/` location, so the moved files sit outside its coverage --
nothing errors, the coverage is simply gone until the copy is refreshed.
