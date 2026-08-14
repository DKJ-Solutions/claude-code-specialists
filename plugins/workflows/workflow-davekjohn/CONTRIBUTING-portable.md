# The contribution cycle — the portable half

This is the cycle the `workflow-davekjohn` scripts run: a branch, its two files in `workflow-davekjohn/branch/`, a Pull
Request that has to get past its gates, a merge, and a fold. **It is written to be read in any repo that
enables this plugin**, which is why it names the *seam* wherever a repo owns the answer, rather than stating
one repo's answer as the rule.

**Your repo answers this document.** Every place below that says "your repo declares X" points at a
function in your own `scripts/repo-config.ps1` or `scripts/lib/branch-info.ps1`. Those answers belong
beside this file, in a `## Specific to this repo` section of your own root `CONTRIBUTING.md` — the same
split this plugin's family uses everywhere else: the portable half travels with the plugin, the local half
stays in the repo. Read this page for the cycle; read your own page for the values.

**Where the scripts actually live.** They are not in your repo. Each one is invoked out of the plugin
install, which resolves itself through `${CLAUDE_PLUGIN_ROOT}`:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/new-branch.ps1" -Name "<prefix>/<short-name>" -Title "…"
```

Each step below names the **skill** that owns the full detail for its script, and those skills are the
single source for their own flags and behaviour — this page is the connective tissue between them, not a
second description of each one. A repo that keeps a local copy of any of these scripts has taken on a
second source; [`scripts/README.md`](scripts/README.md) says why that is the one thing to avoid.

---

## The cycle

### 1. Branch — and its two files come along in the same move

[`skills/new-branch/SKILL.md`](skills/new-branch/SKILL.md) · `new-branch.ps1`

Creating the branch writes both of its working files, so **a branch is never entry-less**:

| file | subject | lifetime |
|---|---|---|
| `workflow-davekjohn/branch/branch-changelog.md` | what the change **does** — the entry that folds into your changelog | folded at the merge, then reset |
| `workflow-davekjohn/branch/branch-progress.md` | what still **must happen** — the step list, and where you left off | reset at the merge; never folded |

**Fixed names, not one per branch.** Git already tracks them per branch, so branches in flight cannot
collide. On the trunk both sit in an empty **reset state** carrying a warning not to write there until a
branch exists — that state opens with an `#`, which is exactly what stops the fold mistaking it for an
entry. The full convention is spelled out in [`BRANCH-portable.md`](BRANCH-portable.md), which travels
with this plugin; your repo's own `workflow-davekjohn/branch/README.md` holds its answers to it, and
`new-branch` keeps reference copies in `workflow-davekjohn/branch/templates/`, refreshing one that has drifted
from the current format.

**The branch name is validated by your own lib, not by the plugin.** `new-branch` calls
`Test-BranchName` out of `scripts/lib/branch-info.ps1`, which lives in **your** repo — so which prefixes
are valid, which GitHub label each earns, which changelog type each produces, and which names are refused
outright are all yours (`Get-BranchTypes` / `Get-BranchInfo`). `specialists-init` scaffolds a starting
version of that file; changing it is an ordinary edit in your repo, not a fork of anything shared. An
unknown prefix is a soft warning rather than a refusal, and falls back to the type your
`Get-EntryFallbackType` names.

So how many prefixes there are, whether a given one exists, and what your repo refuses on sight are
questions this page deliberately cannot answer for you — check your own table rather than assuming the
source repo's.

**`branch-changelog.md` holds the entry block and nothing around it**, so it pastes into your changelog in
one go. The entry is one heading with six `###` sections under it:

```text
## `<your branch>` changelog

### Branch title
### Branch ID
### Branch type
### What does the change on this branch bring to main?
### Significance
### Pull Request
```

The first three arrive filled in — the title you gave `-Title`, a timestamp, and the prefix. `Pull Request`
is filled in by the fold, from the merge itself: neither the PR number nor the landing date exists yet, and
a date written now would be the branch's birth date. Everything between is yours to write.

**Those section names are repo-owned prose.** A repo whose changelog is not in English sets its own through
`Get-EntrySectionHeadingOverrides` in `scripts/repo-config.ps1`, alongside the guidance comments
(`Get-EntryGuidanceOverrides`), the significance wording (`Get-EntrySignificanceWordingOverrides`) and the
step-list wording (`Get-BranchFileWordingOverrides`). If your headings do not read like the skeleton above,
that is the seam doing its job — compare against your own file, not against this one. The word `Tier` is
the exception: it is a machine-read key that the writer, the PR gate and the fold all match on literally,
so it is never translated.

**The file is bare** — headings and the space under them. The guidance for each field lives in
`workflow-davekjohn/branch/templates/`, which is what those copies are for.

### 2. Work, and keep the plan current

Write the entry's description as you go, and resolve every step in the step list before the PR: `- [x]`
done, or `- [~]` dropped with the reason kept on the line. **Steps 3 and 4 both refuse while anything is
still `- [ ]`, and there is deliberately no `-Force` for it** — the dropped mark already is the way past a
step that turned out not to be needed, so nobody is ever pushed into ticking a box for work they did not
do.

A branch with **no** step list at all is not refused: that is the one-commit typo fix.

### 3. Open the PR

[`skills/open-pr/SKILL.md`](skills/open-pr/SKILL.md) · `open-pr.ps1`

**No title is passed.** It is composed as `<branch type>: <the entry's Branch title>`, so the sentence is
typed once — at `new-branch -Title` — and the PR, the changelog and the release documents cannot disagree
about what the change is called.

**The body comes from your own `.github/pull_request_template.md`, and that one file cannot travel with
the plugin.** GitHub reads it only from that path in your repo, so unlike everything else in this cycle it
has to be a copy rather than an import. The plugin ships the reference to copy and to diff against at
`${CLAUDE_PLUGIN_ROOT}/templates/pull_request_template.md`, and the whole interface is two lines: a
**first heading** (any level — `-RefreshBody` replaces the description under it) and a **placeholder
line** the script recognises verbatim, which is where the description is inserted. Break either and
nothing errors; you get PRs whose body has no description. The
[`open-pr` skill](skills/open-pr/SKILL.md) carries both promises, the recognised strings, the
`Get-PrDescriptionPlaceholder` seam for a line of your own, and — worth reading before you copy the
two-line default — the measurement behind why it *is* two lines, which is a method to re-run on your own
history rather than an answer to inherit.

Before anything is pushed the script runs two gates:

- **your lint gate**, whose path your repo declares in `Get-LintScript` (`scripts/repo-config.ps1`). Every
  repo has a different one, and this is the only repo-specific part of `open-pr`;
- **the test gate** — every `scripts/tests/*.tests.ps1`, plus whatever the optional `Get-TestCommands` in
  your `scripts/repo-config.ps1` names (an `npm test`, a `pytest`) for a repo whose tests are not all
  PowerShell. Each command fails the gate exactly like a failing suite; a repo that states nothing keeps
  the bare convention.

On an error or a failing suite nothing is pushed and no PR is opened. If your repo also runs those gates as
CI, the merge waits on whatever status check your branch protection requires; both the workflow and the
name of that check are yours, and your own page is where they are written down.

Four further gates judge the branch's own paperwork rather than its code, and none of them is advisory —
the [`open-pr` skill](skills/open-pr/SKILL.md) is the full account of each:

- **the scaffold gate** — an entry still carrying the wording the scaffolder wrote, or a description, body
  or tier reason still empty once the guidance comments are stripped. `-Force` is the escape valve here,
  deliberately separate from `-SkipLint`/`-SkipTests`, because it overrules a judgement about content
  rather than skipping a tool;
- **the step-list gate** — any step still `- [ ]`, as in step 2 above. No `-Force`;
- **the impact gate** — the Significance sections; see below;
- **the resolves gate** — a plain `#123` in a PR body closes nothing on GitHub, so issues a PR resolves are
  passed as `-Resolves` and written as their own `Closes #<n>` lines.

### 4. Merge

[`skills/ship-pr/SKILL.md`](skills/ship-pr/SKILL.md) · `ship-pr.ps1` — open, wait for CI, merge and fold in
one motion, using the merge method your `Get-PrMergeMethod` names.

**Whether a finished branch is allowed to run through that motion on its own, or has to wait for a person's
word, is your repo's rule** — and one of the few things on this page that no seam can answer, because it is
a governance decision rather than a configuration value. Write it in your own `CONTRIBUTING.md` or
`CLAUDE.md` and link it from there; a contributor who has to guess will guess from whichever repo they last
worked in.

### 5. Fold

[`skills/fold-changelog/SKILL.md`](skills/fold-changelog/SKILL.md) · `fold-changelog-entry.ps1`

On the trunk, right after the merge, the fold moves the entry into your changelog, appends the PR link and
the merge date as its closing line, strips the guidance comments, and **resets both branch files** to
their empty state — so the trunk is ready for the next branch and the merged branch's ticked-off steps do
not greet whoever opens it. It commits that directly on the trunk, naming exactly those three paths so
nothing else in the tree can ride along.

The entry is inserted at **the position its own Significance sections rank it at** — furthest reach first
and, within a reach, highest significance first. **The fold is the only moment that order can be decided**,
which is why the Significance sections have to be right before the merge: a release cut empties the list,
so whatever order the fold leaves is what the release documents inherit. Nothing is re-sorted afterwards.

Where your repo has a plugin tier — declared by `Get-ReleasePluginTier` — the fold also derives a
`Plugins:` line from the PR's files, which the release documents read. A repo with no plugins never sees
that line.

---

## Significance — two questions in one section

Every entry carries a `### Significance` section with a `#### Tier N` sub-section for each reach. **The
tier says how far the change reaches**, and therefore which release document the entry appears in:

| tier | who notices |
|---|---|
| `0` | only this repo's own developers — docs, config, internal work |
| `1` | management and the employer/commissioner get something out of it |
| `2` | a subscriber of the service notices it |

Tiers 1 and 2 are two **kinds** of audience, not two rungs, and the webshop worked example is what
separates them: a webshop's customers buy a product and never read a release note, so its audience is `1`
even though its customers are literally "consumers" — while a repo that IS the service somebody subscribes
to answers `2`.

**The significance says how much it weighs for that reader**, and therefore where in the list it sits — the
most consequential change leads instead of sitting wherever its branch prefix happened to put it.

**Score it against the rubric your repo declares**, in `Get-EntrySignificanceRubricLevels`. You do not have
to go looking for it: `new-branch` prints the rubric when it writes the file, and the guidance in
`workflow-davekjohn/branch/templates/` points back at that printout. The bands are anchored on purpose — an unanchored ordinal
scale invites false precision, and the anchors are what make the number a measurement rather than a mood.
**The `Why` above each score is the lasting half**: the rubric says which band, the `Why` says why *this*
change is in it, and that is the only part a reader a year later can use.

**Two tiers are in the file: tier 0, and the one audience tier your repo has** (Dave, August 12, 2026).
Tier 1 (management and the employer/commissioner) and tier 2 (the subscriber of a service) are two **kinds**
of reader rather than two rungs of a ladder, and a repo has exactly one — decided before any entry is
written, and stated once in `Get-ReleaseAudienceTier` in your own `scripts/repo-config.ps1`. A shop selling a
**product** answers `1`: its buyers never read a release note, while management and whoever pays for the work
do. A repo that **is** the service somebody subscribes to answers `2`. **State nothing and you are asked
about both**, exactly as before the knob existed — so three sections in your file means the question is still
open on your side, not that anything is broken.

Where a change reaches nobody at the level you *do* ask about, write `N/A` in the score and say in one line
why. **That is an answer, not a gap** — a blank means both "reaches nobody" and "nobody has got to this yet",
and a gate has to be able to tell those apart. The reach is the **highest tier carrying a number**, so an
`N/A` costs a sentence and nothing else, and the reasoning behind a negative claim survives into the record.

**Tier 0 is the one tier that cannot be `N/A`**: every change reaches its own repo's developers at least a
little. The floor is a score of 1.

**The cumulative ladder is gone, and the measurement is why.** It used to be that `N/A` at tier 1 under a
scored tier 2 was refused by name, on the reasoning that a change consumers notice is also a change
colleagues get something out of. That reasoning holds for a repo with two genuine audiences and produces
nothing but duplication for the far more common repo with one: in the source repo, **81 of 89 tier-1 sections
existed only because a tier-2 section sat above them** — the same reach argued twice, in a second register,
for a reader who was the same person. What is still enforced is that every tier the file carries has a
reason, and that the audience tier is answered before a PR opens.

**The scores do not have to ascend, and that was true under the ladder too.** Tier 0 may legitimately score
below the audience tier, because these are different readers and not nested ones. A defect that exists only
outside your repo is worth a great deal to whoever is outside it and almost nothing at home.

**A tier your repo no longer asks about is still read.** Every entry already folded, here and in every
consumer's tree, was written under the cumulative model and carries all three — so nothing already written
stops folding, and an extra answered tier is never refused. Recognise both, write one.

**The score cells are scaffolded empty on purpose.** The tier defaults to 0 because 0 is a harmless final
answer about reach; a *score* has no harmless value, so any number scaffolded for you would be a guess at a
ranking.

**Do not infer any of it from your branch prefix.** The prefix decides the entry's *type*, which the entry
states under its own heading; it predicts nothing about impact. A `docs/` branch can carry a tier-2 change
and a `feat/` branch a tier-0 one. The repo this plugin comes from measured it: its single most
consequential change for a consumer — a marketplace rename that broke every existing install — arrived on
a branch whose prefix put it at the bottom of the document.

---

## Releases — a different cycle

[`skills/cut-release/SKILL.md`](skills/cut-release/SKILL.md) · `cut-release.ps1`

Everything above is the **contribution cycle**: everyone runs it, on every branch. Cutting a release is a
separate cycle with different rules, and the fact that the fold commits directly on the trunk must not be
read as something this page grants to ordinary contributions.

The one part worth knowing from here is the gate on the bump, because it is easy to mistake for your own
policy. **The shared gate refuses a bump the pending entries have not earned**: tier 0 only is a patch,
tier 1 or higher earns a minor, and a major additionally needs the number of minors your
`Get-ReleaseMajorMinMinors` names. It also refuses a release whose tier-1-or-higher entries carry no
score, because an unscored entry cannot be placed.

**That is a floor, not your policy.** A repo may legitimately draw the line tighter — reserving a minor for
what a customer notices, say, because a minor there forces a stakeholder-facing document into existence.
The gate cannot tell a stricter policy from a mistake, so it enforces only the floor and your own page is
where the stricter rule is written. If your two rules differ, say so out loud where a contributor picks
their bump type; both allowing a patch is not the same as agreeing.

Which documents a release writes, how they are foldered, and whether a stakeholder-facing consumer
document is generated at all are yours too (`Get-ReleaseNotesGrouping`, `Get-ReleaseConsumerBumps`,
`Get-ReleasePluginTier`). The cut-release skill covers all of it.

---

## The two contributing pages, and which one wins

A repo running this workflow carries **two** contributing pages, deliberately (Dave, August 14, 2026):

- the root `CONTRIBUTING.md` is the **standard workflow** — what holds before any plugin is consulted,
  and what stays meaningful the day the plugin is absent: a fresh checkout, a teardown, a contributor
  who installed nothing;
- `workflow-davekjohn/CONTRIBUTING.md` (the `adopt-workflow-folder` skill scaffolds it) is the
  **workflow's layer**: everything this plugin owns, plus your repo's answers to its seams. **Where the
  two disagree, the workflow's page wins.**

So adopting this workflow never rewrites your root page — the folder file arrives beside it and takes
precedence only where they conflict.

## One thing to do before you adopt a root `CONTRIBUTING.md`

If your repo overrides `Get-ReservedRootMd` — the list of root `*.md` files that are permanent documents
rather than unfolded changelog entries — **add the new document to it**. The shared default already
contains `CONTRIBUTING`, so a repo that defines nothing is fine; a repo that lists its own set and forgets
it meets a refusal at its next release, naming the new document as an entry somebody failed to fold. It
costs no data, because the cut stops before writing anything, but the message points at the wrong problem.
The same holds for every permanent root document you add: an entry for a file that is not there is inert,
so the risk runs one way only.
