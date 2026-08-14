---
name: new-branch
description: >-
  Create (or idempotently resume) a git branch AND its two files in workflow-davekjohn/branch/ -- the changelog entry
  and the step list -- in one move, via the shared, centralized new-branch script from the plugin
  (single source of truth, issue #81), so a consumer does not have to duplicate this script locally.
  Use this whenever a new piece of work starts: a branch is never entry-less -- creating it brings
  both files to life in the same step, instead of a separate later scaffolding step.
---

# new-branch -- the shared branch+entry creator for consumers

This is the **plugin mirror** of `new-branch.ps1`: the same tested source as in the workshop repo,
shared here so consumers do not duplicate it. Background in
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/new-branch.ps1" -Name "<prefix>/<short-name>" -Title "short title"
```

**In the source repo, run its own copy instead -- `scripts/task/new-branch.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

The script:

1. Validates the branch name via the shared SSOT helper `Test-BranchName`
   (`scripts/lib/branch-info.ps1`) -- hard-rejects an empty name, `main`, or a name containing
   `final`; soft-warns (but proceeds) on an unknown prefix.
2. Creates the branch (`git checkout -b`), or checks it out if it already exists -- **idempotent**:
   running it again on the same branch simply resumes it instead of failing.
3. Immediately writes that branch's **two files in `workflow-davekjohn/branch/`** by calling the shared
   `new-branch.ps1` as a child step (own script, own mirror) -- so the branch and its files
   come into existence in a single step. Idempotent **per file**: a file that already belongs to this
   branch is left exactly as it is.

## The two files, and why there are two

```text
workflow-davekjohn/branch/
  branch-changelog.md   what the change DOES  -- nothing but the entry, so it pastes into CHANGELOG.md
  branch-progress.md    what still MUST HAPPEN -- the branch's name, its step list, where you left off
```

**Fixed names, not one per branch.** Git already tracks these per branch, so two branches in flight
cannot collide on them and the repo root stops filling up with other people's work. On the trunk both
sit in an empty **reset state**, with a warning saying not to write there until a branch exists; the
fold puts them back in that state after the merge.

**Why the split earns its keep.** One file used to do both jobs — it was scaffolded with a
`**To do / where I left off:**` heading *and* folded verbatim into `CHANGELOG.md`, so "replace this
whole block before the PR" had to be a written instruction. Two files make it obvious. The entry now
prompts for what the change does, and nothing else.

**`branch-changelog.md` holds the entry block and nothing around it** — no preamble, no warning. That is
what makes it pasteable in one go. Its heading names the **branch** (`` ## `feat/x` changelog ``), which is
also how the fold finds the PR, and the human-readable name of the change is its first section.

**The file is bare** — headings and the space under them. The guidance for each field lives in the copies
under `workflow-davekjohn/branch/templates/`, which is what those copies are for: the file you type in is the questions and
your answers, and the reference is one directory away.

**`new-branch` writes those templates into your repo too**, and rewrites one that has drifted from the
current format. You get them on your first branch and they stay current through plugin updates, so the
guidance travels with the scripts rather than living only in the repo the scripts came from. They are
generated: edit one and the next run puts it back.

Six sections, three of them filled in for you:

```text
## `<your branch>` changelog

### Branch title           <- the title you gave -Title; also the PR title
### Branch ID              <- a timestamp, stamped at creation
### Branch type            <- the branch prefix
### What does the change on this branch bring to main?
### Significance
### Pull Request           <- filled in by the fold, from the merge
```

**`Branch title` is what the change is CALLED, everywhere.** Since
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506) `open-pr` composes the PR title as
`<branch type>: <this section>` instead of taking one on the command line — so the sentence you give
`-Title` here is the one on the PR, in `CHANGELOG.md` and in the release documents, written once. Give it
**without** a `feat:`/`fix:`/`docs:` prefix: the branch name already carries the type and `open-pr` puts it
in front. The section was called `Branch description` until that day and is still read under that name, so
a branch created before the change folds unharmed.

**An empty field is refused.** There is no visible `TODO:` anywhere, so `open-pr` measures instead of
matching: it names the description, the body and any tier whose reason is still blank. That catches an
untouched entry *and* one whose prompt was deleted rather than answered.

**The step list is enforced, not decorative.** `open-pr` refuses to push and `ship-pr` refuses to merge
while anything is still `- [ ]`. Resolve each step as `- [x]` done or `- [~]` dropped, with the reason
kept on the line — that third mark exists so nobody is ever pushed into ticking a box for work they did
not do. There is no `-Force`. Full convention and reasoning: the `open-pr` skill, and
[`BRANCH-portable.md`](../../BRANCH-portable.md), which travels with this plugin.

**So work that happens AFTER the merge is not a step** — opening the PR, waiting for CI, merging, folding,
publishing a Release, any measurement that only exists once the run is over. Put it under
`### Where I left off`, which is what that section is for. The reason is the gate's own timing rather than
a matter of taste: it reads the list *before* the push, so a post-merge step cannot be done yet, and
**neither mark fits** — `- [x]` reports work that has not happened, `- [~]` claims the step turned out not
to be needed when it is needed and merely comes later. The only way past the gate is to tick a box for
work you did not do, which is the failure the third mark exists to prevent, arriving through the front
door.

Measured in the source repo across the 105 branches that have carried a step list: **17** wrote a
post-merge step, **4** were blocked by it, and **14** ticked it in advance — provably in advance, since
the fold *resets* this file at the merge. One branch is in both counts: it hit the gate on
`- [ ] Lint + tests green, then PR + merge + fold`, and its next commit changed nothing but that box to
`- [x]`. **No gate enforces this and none should**: a check would have to spot a post-merge step by its
wording, and `open-pr`, `merge` and `fold` are also the subjects of ordinary steps (*"`open-pr.ps1`:
recognise the new placeholder"* is real work), so separating them needs an exclusion list. Run the same
count over your own branches if you want to know whether it bites here too.

## The entry declares its Significance, one section per tier it asks about

Under `### Significance` the entry gets a `#### Tier N` sub-section per tier your repo asks about, each
waiting for a reason and a score. In a repo whose audience is tier 2 that is these two — which tiers, and
why it is not three, is the knob further down:

```text
#### Tier 0

**Score:**

#### Tier 2

**Score:**
```

Two questions in one section. **The tier says how far the change reaches**, and therefore which release
document the entry appears in:

| tier | who notices |
|---|---|
| `0` | only this repo's own developers -- docs, config, internal work |
| `1` | management and the employer/commissioner get something out of it |
| `2` | a subscriber of the service notices it |

Tiers 1 and 2 are two **kinds** of audience, not two rungs, and the webshop worked example is what
separates them: a webshop's customers buy a product and never read a release note, so its audience is `1`
even though its customers are literally "consumers" -- while a repo that IS the service somebody subscribes
to answers `2`.

**The significance says how much it weighs for that reader**, and therefore where in the document it sits --
the most consequential change leads instead of sitting third under whichever heading its branch prefix
produced. Score it 1 to 5 against this rubric:

| | |
|---|---|
| `5` | the reader must act -- a breaking change, a required migration, or a long-standing blocker that is now gone |
| `4` | materially changes how they work; they notice within a day without being told |
| `3` | a clear improvement, noticed the moment they touch that part |
| `2` | small; noticed if somebody points it out |
| `1` | cosmetic, or prevents a failure that has not happened yet -- then name the failure, because that is the only part a later reader can use |

**Two tiers are in the file: tier 0, and the one audience tier your repo has.** Tier 1 and tier 2 are not
two rungs of a ladder but two KINDS of reader, and a repo has exactly one -- fixed before any entry is
written. State it in `Get-ReleaseAudienceTier` in your own `scripts/repo-config.ps1`, and the scaffolder
writes only what it names. **A repo that has stated nothing is asked about every tier**, exactly as before
the knob existed, so three sections means your repo has not answered yet rather than that something is
broken.

**Each tier in the file is answered, and `N/A` is how one says the change reaches nobody there.** Put it in
the score with one line saying why -- that is an answer rather than a gap, and it is what lets a gate tell
"reaches no subscriber" from "nobody has got to that section yet". **The reach is the highest tier carrying a
number**, and **tier 0 is the one tier that can never be `N/A`**: every change reaches the people
maintaining the repo at least a little.

**Every tier needs a reason, `N/A` ones included.** What is no longer asked for is a second reading of the
same change for an audience the repo does not publish to. Until August 12, 2026 the ladder was cumulative --
a tier-2 entry OWED a tier-1 section -- and the source repo measured what that cost: of its 89 tier-1
sections, **81 existed only because a tier-2 section sat above them**, the same reach argued twice in a
second register for a reader who was the same person. A tier your repo does not ask about is still **read**
wherever an older entry carries one, so nothing already written stops folding.

Below is what a **tier-2** repo's file looks like. A repo that answered `1` gets the same two sections with
`#### Tier 1` in the second one's place:

```text
#### Tier 0

The routine version bump stops needing a developer.

**Score:** 4

#### Tier 2

Consumers must re-add the marketplace under its new name; installs break without it.

**Score:** 5
```

**`**Score:**` and the plain `Score:` are both read**, and only the bold form is written — the standing
"recognise both, write one" rule, because every entry written before this carries the plain one.

**What it costs to leave it at tier 0.** Nothing breaks, which is exactly why it is worth knowing: where the
repo's entries declare their impact at all, the release cut refuses a bump the entries have not earned -- a
bump follows the highest tier pending (tier 0 only is a patch, tier 1 or higher earns a minor) -- and it **also** refuses a release whose
tier-1-or-higher entries carry no significance, because an unscored entry cannot be placed. So an entry left at 0 is work that
cannot carry a release on its own. `open-pr` prints what it read and names anything still unsettled, so you
learn that before the PR rather than at the cut.

**The score is scaffolded empty on purpose.** The tier defaults to 0 because 0 is a harmless final answer;
a *score* has no harmless value, so any number scaffolded here would be a guess at a ranking. The rubric is
what makes it a measurement rather than a mood, and the reason above it is what makes the resulting order
auditable.

**There is no `-Tier` parameter, deliberately.** Whoever finishes the branch already has to answer the
description and the body before the PR (open-pr's gate refuses an empty one), so the Significance sections
are one more edit in a file that is being edited anyway.

**Older shapes keep working.** The impact table this replaced and the single `Tier: 0` line before it are
both still read everywhere -- "recognise both, write one" -- so entries written on either side of the change
keep folding correctly.

**Do not derive it from your branch prefix.** The prefix decides the entry's *type*, which the entry states
under its own heading -- it predicts nothing about impact: a `docs/` branch can carry a tier-2 change and a
`feat/` branch a tier-0 one. The source
repo measured this -- its single most consequential change for a consumer, a rename that broke every
existing install, arrived on a `chore/` branch.

The tier's word (`Tier`) is a machine-read key and is **not** translated, unlike the four scaffold strings
below: the writer, the PR gate and the fold all match on the literal, so a translated key would make an
entry unreadable to your own fold.

## Recording intent and parking a branch (#162)

Two optional parameters cover the "start now, continue later (maybe on another device)" case:

- **`-Intent "<what is next / where I left off>"`** -- recorded in **`branch-progress.md`**, under
  its "where I left off" section. Omit it and that section is simply left empty for you.
  **It deliberately does not touch the entry.** An intent is a status, and the entry's text folds
  verbatim into `CHANGELOG.md` -- this repo measured three released entries that shipped a progress
  note that way. The entry's body is left empty, and the PR gate keeps refusing it until somebody
  writes what the change does.
  **The prose in these files is repo-owned.** The guidance comments (which reach the templates rather
  than the working files), the section headings, the routing questions and the rubric can all be set from
  your own `scripts/repo-config.ps1`
  (`Get-EntryGuidanceOverrides`, `Get-EntrySectionHeadingOverrides`,
  `Get-EntrySignificanceWordingOverrides`, `Get-EntrySignificanceRubricLevels`,
  `Get-BranchFileWordingOverrides`), along with the type an unknown prefix falls back to
  (`Get-EntryFallbackType`; issue #410). Define none of them and you get exactly the English text above.
  **That now includes the trunk warning's opening sentence** (`TrunkWarningLead`, inbound #562): it used to
  be built by the formatter, so a repo that translated everything else still got
  `> **You are on \`main\`.**` in English as the first line its readers saw, and forking the script was the
  only way out. Put `{0}` where the trunk name belongs in your sentence — a translation rarely wants it in
  the English position — or leave it out and let the heading above carry the name.
  That exists so a repo whose changelog is not in English does not have to keep a private copy of the
  script -- which is the duplication this skill exists to prevent. The three retired placeholder strings
  (`Get-EntryTitlePlaceholder`, `Get-EntryBodyHeading`, `Get-EntryBodyPlaceholder`) are **no longer
  written by anything**; they survive only as wording `open-pr` still refuses wherever an older entry
  carries it.
- **`-Park`** -- after creating the branch + entry, commits the entry (the intent carrier) and
  pushes the branch to `origin` with `git push -u`. **This opens no PR.** Push is not a PR: parking
  makes the branch reachable from another device, while the PR rule stays intact and separate.

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/new-branch.ps1" `
  -Name "feat/spotify-dashboard" -Title "Spotify dashboard" `
  -Intent "Skeleton + routing done; next: wire the API client." -Park
```

Parking additionally needs a configured, reachable `origin` (git only -- no `gh`, no PR).

## Requirements in the consumer

The script is repo-agnostic, but reads its repo data from the **root** of the consumer
(dual-context via `${CLAUDE_PROJECT_DIR}`):

- `scripts/lib/branch-info.ps1` (dot-sourced) -- the single source of truth for the branch-prefix
  table (`Get-BranchInfo`/`Test-BranchName`).
- `git`.
- `scripts/repo-config.ps1` -- **optional here**, unlike in `open-pr`/`fold-changelog-entry`, which
  pre-flight on it. If present, its four `Get-Entry*` functions set the stub wording (#410); if it
  is absent or fails to load, the entry is written with the built-in English defaults and a
  warning. This is the lightest script in the set, and every string it reads from there has a
  working fallback.

If `branch-info.ps1` is missing -- typical on a clean consumer -- the script stops before the
dot-source with a clear pointer instead of a raw error (#86); fill it in first (see the workshop
repo as a model, or use the `VUL-IN` scaffold the `specialists-init` bootstrap places).

## Important

- **No push, no PR by default.** Without `-Park` the script only runs `git checkout`/`checkout -b`
  locally and writes the two branch files; nothing leaves the machine. With `-Park` it also commits
  **both** of them and pushes the branch to `origin` -- but still **opens no PR**. Both, because the
  step list is the half that says what was still in flight, and that is what parking hands over.
  Opening a PR remains a separate, explicit step (the `open-pr` skill).
- **Idempotent repetition, per file.** Running the script again on a branch that already exists does
  not fail or overwrite -- it resumes. The two branch files are judged **separately**, and on what
  each one says it belongs to rather than on whether it exists (both exist on the trunk by design):
  an entry that has been written stays written, and a step list you have been ticking off is never
  clobbered by a rerun.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/task/new-branch.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
