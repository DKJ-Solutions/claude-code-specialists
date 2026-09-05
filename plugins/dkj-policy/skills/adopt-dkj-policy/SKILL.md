---
name: adopt-dkj-policy
description: Adopt the dkj-policy workflow in a consuming repo, in two independent parts that can run in either order or alone. Part 1 scaffolds the workflow's own root folder -- dkj-policy/ -- the folder docs (README and CONTRIBUTING), the releases root with this repo's release answers, and the branch-entry CI gate; use this right after installing the plugin, or when the script-contract session check reports the folder missing, since an install alone writes nothing into the repo. Part 2 adopts the source repo's workflow configuration from the shipped blueprint -- placing the values that state the shared way of working into this repo's own seam libs, and proposing the rest for a person to answer; use this after specialists-init has laid down scripts/repo-config.ps1 and scripts/lib/branch-info.ps1, or whenever the script-contract check reports functions this repo has never configured. Both parts are strictly additive and dry-run by default; neither overwrites anything.
---

# adopt-dkj-policy -- scaffold the folder and place the config seams

An install writes nothing into your repo: it clones the plugin into your cache, and that is all. This
command is the two things that actually place `dkj-policy` on your side, and they are independent of
each other -- run either one first, or run only the one you need:

- **Part 1** creates the workflow's own root folder and its CI gate.
- **Part 2** places or proposes the answers to the repo-owned config seam the shared scripts read.

Neither part depends on the other having run. Both are dry-run by default and never overwrite a file
that already exists.

## Part 1 -- scaffold the workflow folder

Everything portable about the `dkj-policy` workflow gathers in **one folder in your repo's
root** (Dave, August 14, 2026), instead of scattering through it -- `branch/` from the first
`new-branch` run here, a `releases/` tree from the first cut there, a `CONTRIBUTING.md` if somebody
wrote one. A plugin **install cannot create the folder**: an install is a clone into the plugin cache
and writes nothing into your repo. This part is what places it, and the script-contract session
check reports at session start while it is missing.

```text
dkj-policy/
  README.md              what this folder is, and where each page's portable half lives
  CONTRIBUTING.md        this repo's answers to CONTRIBUTING-portable.md
  releases/README.md     this repo's answers to RELEASES-portable.md (the release LIST is not here)
  (releases/audience/ is NOT placed -- your first cut creates it when it writes the note there)
  (<branch>.md is NOT placed -- one per branch, living only while that branch is open)
```

**And one file outside it**, since August 20, 2026 (inbound
[#789](https://github.com/DaveKJohn/claude-code-specialists/issues/789)):

```text
.github/workflows/branch-entry.yml   the CI gate that holds every PR to carrying a written entry
```

### Run it

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/adopt-workflow-folder.ps1"
```

That is a **dry run**: it prints exactly what it would create and writes nothing. Add `-Apply` when
the list looks right.

`${CLAUDE_PLUGIN_ROOT}` resolves **only inside a plugin-owned component** -- that is, when your Claude
runs this skill. Typing the command by hand in a terminal means spelling out the absolute path to your
own plugin cache instead, so the easy route is to ask for the skill rather than to copy the line.

### Parameters

| parameter | what it does |
|---|---|
| `-Apply` | write the files. Without it the command is a dry run that prints the plan and touches nothing -- the same default Part 2's command uses. |

### The rules it works under

- **Strictly additive, never overwrites.** Every file that already exists is left exactly as it is,
  whatever it contains -- so a re-run finds nothing to do, and everything you wrote past the `VUL-IN`
  markers is yours. **Nothing is ever rewritten**, which is new since August 23, 2026: `new-branch` used
  to refresh the generated `branch/templates/` on drift, and the merged development document carries its own
  guidance, so there is no reference beside it left to keep current.
- **The branch document comes from the shared formatter** -- the same one `new-branch` and the fold
  call -- so the scaffold cannot write a shape of its own.
- **Refused in a repo that publishes plugins** (`.claude-plugin/marketplace.json` present). The source
  repo of this workflow arranges that folder by hand, and its answer differs from what this command
  writes: it keeps no root `CONTRIBUTING.md` at all, holding that floor in its `CLAUDE.md` instead
  (Dave, August 27, 2026), while the page scaffolded here assumes you have one.
- **A leftover root `branch/` from before the move is yours to remove by hand** -- the scripts read
  only the new location, deliberately without a dual-read fallback.
- **The folder itself is permanent** (issue #885). No command in this plugin removes
  `dkj-policy/`, and no future teardown may -- uninstalling the plugin takes the plugin, not the
  record that belongs to your repo. `<branch>.md` is the one file inside it that does not share
  that lifetime: it exists only while a branch is open, which is a precision on the rule rather than an
  exception to it.

### The CI gate it places, and the one choice inside it

The branch entry is a convention this plugin ships every reader of, and until August 20, 2026 **nothing
enforced it**: `open-pr` refuses to push an unwritten entry and `ship-pr` refuses to merge on an
unresolved step, but both are *local*. A branch pushed by hand, or a PR opened in the GitHub UI, meets
neither. So both existing consumers wrote a CI gate from scratch against the same convention -- a second
definition of the format in every repo, free to drift from the fold that reads the first one, and **both
had already drifted**: each refuses a merge over a missing significance score, which is a refusal this
workflow deliberately places at the *release cut* instead.

So the gate ships as a script, `check-branch-entry.ps1`, and this part places the six lines that call
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

### After the scaffold: the note-root seam, which this run usually answers for you

The release machinery finds the folder through a `decide` seam in your `scripts/repo-config.ps1`
(Part 2 below explains the marker):

```powershell
Get-ReleaseNoteRoot     -> 'dkj-policy/releases/audience'
```

**Since [#1150](https://github.com/DaveKJohn/claude-code-specialists/issues/1150) the run writes that
line itself where it safely can, instead of printing it as an instruction** -- and only where all three
of these hold: your `scripts/repo-config.ps1` exists, it defines no answer of its own, and you have no
hand-written note at the shared `releases/notes` fallback. That is the fresh adoption and nothing else.
Whatever the run decides, it says which branch it took and why, so a seam left unanswered is never
silent.

**Why it is written rather than suggested.** The seam's default deliberately does not move with this
folder -- *a repo that answers nothing must keep meaning what it meant yesterday* -- and that argument is
about a consumer with notes **already on disk**. It does not reach a repo this command scaffolded a
minute ago. Measured in a fresh consumer following the documented path literally: one clean adoption plus
one clean release produced an empty committed `releases/audience/` and a release note at
`releases/notes/0.x/0.1.0.md`, outside the folder the adoption had just built, with the history table
linking back out of the folder to reach it. Every individual step behaved as documented; the two halves
of one run simply disagreed.

**Nothing is ever moved, and your own answer always wins.** A repo with notes at the fallback keeps them
and is told what repointing would cost -- the cut reports *"no release note was found"* against an empty
new root, which reads as a repo that has never cut one. A repo that already defines the function is left
exactly as it is, the same rule Part 2 follows.

**This is the one `decide` seam any command in this workflow answers for you**, and the narrowness is
the whole argument: Part 2 never places a `decide` record, because copying the source's answer
would assert something about a repo it merely *found*. This part **creates** the folder, so for a repo
with no answer and no notes it is not describing a tree -- it is making one.

**`Get-ReleaseHistoryPath` is isolated by default now too** (issue #885, group E, reversing the
August 19, 2026 answer below). That answer kept the list at the repo root on a durability argument:
a repo that has cut releases has a **history** whichever tooling cut it, so it should not live in a
folder a teardown could remove. #885 also settled that `dkj-policy/` is **permanent** -- see
[the rules above](#the-rules-it-works-under) -- which answers that same durability worry the other way:
the folder is now the safer place for the list, not the riskier one. So a fresh consumer gets
`dkj-policy/releases/history.md` without configuring anything, the same computed-default
treatment `Get-ChangelogPath` already gets. **A repo that adopted before August 25, 2026 keeps its
existing list at the root**: the computed default only isolates a *consumer*, and re-adopting an
existing one starts a *second* list here rather than moving the first one under it silently -- repoint
the seam back to your root file if you would rather keep one list. `Get-ReleaseNoteRoot` is isolated a
**different** way, for the separate reason its own contract record gives: it already has real consumers
relying on its literal fallback, which the three roots and the history path never had. So its *default*
still stays where it is, and the isolation happens by this run writing the answer into your lib -- an
explicit line in a file you own, rather than a default moving under an existing consumer's feet.

**So the page this part scaffolds at `dkj-policy/releases/README.md` carries no history
table**, and until August 20, 2026 it did -- a `## Release history` heading, a table, and a `VUL-IN`
promising that the cut would insert its rows there, in the same run whose closing advice told you to
leave the seam pointing at the repo root. Two statements that cannot both be true, and a consumer who
followed the advice was left with a table that stays empty forever (inbound
[#786](https://github.com/DaveKJohn/claude-code-specialists/issues/786)). The page now points at
whatever `Get-ReleaseHistoryPath` answers instead.

**The file that seam names is yours to create, before your first cut**, and this part deliberately
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

And if your `Get-MojibakePaths` copy predates August 14, 2026, re-adopt it via Part 2: the old
copy still names the retired root `branch/` location, so the moved files sit outside its coverage --
nothing errors, the coverage is simply gone until the copy is refreshed.

## Part 2 -- the config seams

The shared workflow scripts (`open-pr`, `ship-pr`, `cut-release`, `new-branch`, ...) are repo-agnostic
and dot-source two **repo-owned** libs from your repo:

```text
scripts/repo-config.ps1        20 functions -- what this repo is and how it releases
scripts/lib/branch-info.ps1     2 functions -- the branch prefix table and its validator
```

`check-script-contract.ps1` already tells you which of those are missing and what the shared script
falls back to. What it cannot tell you is **what the source repo chose, and why** -- so every consumer
has been re-deriving those answers by hand, or not at all.

This part closes that gap. It reads the blueprint the plugin ships
(`blueprint/config-blueprint.json`), compares it against what your repo actually defines, and acts on
the marker each record carries.

### Run it

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

### The two markers, and why one of them never writes anything

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

### Parameters

| parameter | what it does |
|---|---|
| `-Apply` | Actually write. Without it the command is a dry run that touches nothing -- the default, because the first run of a command that edits your config should show you the edit first. |
| `-ProposalPath` | Where the proposal document for the `decide` records is written, repo-root-relative. Default: `config-adoption-proposal.md` in the repo root. |

### What you get

- the `copy` functions appended to your seam libs under a header naming where they came from -- they
  are your files now, edit them freely;
- `config-adoption-proposal.md`, one section per decision, each with **why it is yours to answer**, what
  the function must return, what happens if you leave it out, and the source's own version quoted for
  reference. Delete the file once you have worked through it; re-running regenerates it.

Leaving a proposed value unanswered is a valid outcome. Every record in that document is optional or
has a documented fallback -- answer the ones where your repo genuinely differs from the source.

### Afterwards

Run the contract check to see the same seam from the shared scripts' side:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-script-contract.ps1"
```

**In the source repo, run its own copy instead -- `scripts/sync/check-script-contract.ps1`.** That one is
a gate there rather than a one-off, and reading the seam through a lagging mirror is exactly the reading
it exists to prevent.
