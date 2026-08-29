# The contribution cycle — the portable half

This is the cycle the `contributing-davekjohn` scripts run: a branch, its `contributing-davekjohn/development.md`, a Pull
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

Creating the branch writes its working document, so **a branch is never entry-less**. It has two halves
with two different readers:

| half of `contributing-davekjohn/development.md` | subject | lifetime |
|---|---|---|
| `## PLAN` · `## CREATE` · `## TEST` | what still **must happen** — the step list | removed at the merge; never folded |
| `` ## DEPLOY: `<branch>` `` | what the change **does** — the entry that folds into your changelog | folded at the merge, then removed with the rest |

**A fixed name, not one per branch.** Git already tracks it per branch, so branches in flight cannot
collide. **And it exists only while a branch is open**: `new-branch` creates it, the fold removes it at the
merge, so on the trunk there is no copy. It used to sit there in an empty state carrying a warning not to
write in it; a repo updating from an older plugin still has that copy until its next fold clears it, and
what marks it is the **trunk's name in its heading**, which is what stops the fold mistaking it for an
entry. The full convention is spelled out in
[`DEVELOPMENT-portable.md`](DEVELOPMENT-portable.md), which travels with this plugin; the
guidance for every field is inside the document itself, so there is no reference copy to keep current.

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

**The DEPLOY section holds the entry block and nothing around it**, so it pastes into your changelog in
one go. The entry is one heading with two `###` sections under it:

```text
## DEPLOY: `<your branch>` · <stamp>

### What makes this deploy extra special
### Pull Request
```

**The headings carry what three sections used to.** The `##` names the branch — so the branch *type* is its
prefix — and the stamp on that same heading is the moment the branch landed, written by the fold. The moment
it *began* is stamped on the document's own `#` heading. A section restating any of them would be one fact
in two places.

**The entry holds both tiers, and neither names a number.** Tier 0's reason goes directly under the DEPLOY
heading — that heading IS its section; the audience tier gets `### What makes this deploy extra special`, and it
means the one tier your repo has stated in `Get-ReleaseAudienceTier`. Each carries its reason and its
`**Score:**`; that is the description, written once per audience rather than once as prose and again per tier.
**A repo that has stated no audience tier gets the older shape instead** — a `#### Tier N` sub-section for
every tier the model has, tier 0 included — because a heading with no tier to resolve to would read as tier 0
and empty your release documents.

`Pull Request` opens with **the PR title** — the sentence you gave `-Title`, which `open-pr` puts the
branch type in front of. The number and the landing date go underneath it, written by the fold from the
merge: neither exists yet, and a date written now would be the branch's birth date rather than its
landing date.

**Every heading this replaced is still read**, so an entry already in your changelog, or on a branch in
flight, keeps folding exactly as it did. Nothing has to be migrated.

**Those section names are repo-owned prose.** A repo whose changelog is not in English sets its own through
`Get-EntrySectionHeadingOverrides` in `scripts/repo-config.ps1`, alongside the guidance comments
(`Get-EntryGuidanceOverrides`), the significance wording (`Get-EntrySignificanceWordingOverrides`) and the
step-list wording (`Get-BranchFileWordingOverrides`). If your headings do not read like the skeleton above,
that is the seam doing its job — compare against your own file, not against this one. The word `Tier` is
the exception: it is a machine-read key that the writer, the PR gate and the fold all match on literally,
so it is never translated.

**The guidance is in the document** — an HTML comment over every field, saying what a good answer looks
like. The fold strips comments on the way to your changelog, so leaving one standing is not a defect.

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

**A repo that cannot have a required check is not left open, and this is worth knowing before you go
looking for the setting.** A private repository on the GitHub Free plan cannot have branch protection at
all — `gh api ... /branches/main/protection` answers *"Upgrade to GitHub Pro or make this repository
public to enable this feature"* — and that is the shape most new repos start in. Two things hold there
without any configuration: `ship-pr` waits for **every** check the PR has rather than only the required
ones, so the wait works with no ruleset; and where nothing is required, the merge verdict cannot tell
*"this repo requires nothing"* from *"the required checks have not reported yet"*, so it **refuses** on a
red check instead of proceeding. The repo without a ruleset is therefore guarded conservatively rather
than left unguarded — you simply cannot be told which check governed, because no check governs.

Four further gates judge the branch's own paperwork rather than its code, and none of them is advisory —
the [`open-pr` skill](skills/open-pr/SKILL.md) is the full account of each:

- **the scaffold gate** — an entry still carrying the wording the scaffolder wrote, or a description, body
  or tier reason still empty once the guidance comments are stripped. `-Force` is the escape valve here,
  deliberately separate from `-SkipLint`/`-SkipTests`, because it overrules a judgement about content
  rather than skipping a tool;
- **the step-list gate** — any step still `- [ ]`, as in step 2 above. No `-Force`. It runs a second time at
  the merge, and there it judges the branch's own commit rather than the checkout, because the merge may be
  minutes of CI away from the moment you started it — the [`ship-pr` skill](skills/ship-pr/SKILL.md) has the
  two measurements behind that;
- **the impact gate** — the Significance sections; see below;
- **the resolves gate** — a plain `#123` in a PR body closes nothing on GitHub, so issues a PR resolves are
  passed as `-Resolves` and written as their own `Closes #<n>` lines.

**All four are local, and that is the hole the CI gate closes** (inbound
[#789](https://github.com/DaveKJohn/claude-code-specialists/issues/789)). A branch pushed by hand, or a PR
opened in the GitHub UI, meets none of them — so the convention was enforced by whoever remembered to use
the scripts. `check-branch-entry.ps1` ships for exactly that, and `adopt-workflow-folder` places the six
lines of workflow that call it. **It re-uses the same two functions**, so there is one definition of
"written" rather than a second one in every repo's CI: that is not a nicety, and two consumers measured
what the alternative costs — both wrote a gate in shell, and both refused a merge over a missing
significance score, which is a refusal this workflow deliberately places at the **release cut** instead.
The shipped gate reports the significance and merges anyway.

### 4. Merge

[`skills/ship-pr/SKILL.md`](skills/ship-pr/SKILL.md) · `ship-pr.ps1` — open, wait for CI, merge and fold in
one motion, using the merge method your `Get-PrMergeMethod` names.

**Run it in the background.** The merge waits on the required status check whatever you do, so holding a
session open for it buys a second look at a result the local gate already gave. Measured in the source repo
on August 27, 2026: `lint-en-tests` at **11m48s** against the same suites locally at **292s**, and over 65
blocking runs a median CI leg of **8m 01s** — 9h 45m a week at 73 merged PRs. **One condition comes with it:**
step 5 checks out the trunk in the tree the script was started from, so the session's next move is either a
lane ([`skills/worktree-lane/SKILL.md`](skills/worktree-lane/SKILL.md)) or nothing at all. Both halves, and
the two larger shapes that were declined, are in the
[`ship-pr` skill](skills/ship-pr/SKILL.md#the-wait-runs-in-the-background-and-that-is-the-default).

**Whether a finished branch is allowed to run through that motion on its own, or has to wait for a person's
word, is your repo's rule** — and one of the few things on this page that no seam can answer, because it is
a governance decision rather than a configuration value. Write it in your own `CONTRIBUTING.md` or
`CLAUDE.md` and link it from there; a contributor who has to guess will guess from whichever repo they last
worked in.

### 5. Fold

[`skills/fold-changelog/SKILL.md`](skills/fold-changelog/SKILL.md) · `fold-changelog-entry.ps1`

On the trunk, right after the merge, the fold moves the entry into your changelog, appends the PR link as
its closing line, stamps the landing moment onto the `Pull Request` heading, strips the guidance comments,
and **removes the branch document** — so the trunk is ready for the next branch and the merged branch's
ticked-off steps do not greet whoever opens it. It commits that directly on the trunk, naming exactly those
paths so nothing else in the tree can ride along.

The entry is inserted at **the top of the list**: `CHANGELOG.md` is newest-first, a record of what landed
in the order it landed. Insert-only, never a re-sort — the fold commit goes straight onto the trunk, so a
bug must be able to misplace at most the entry being folded.

**The Significance sections still have to be right before the merge**, for two other reasons: the release
documents rank *themselves* on those scores, and the version bump follows the highest tier pending. What
they no longer decide is this document's order.

Where your repo has a plugin tier — declared by `Get-ReleasePluginTier` — the fold also derives a
`Plugins:` line from the PR's files, which the release documents read. A repo with no plugins never sees
that line.

---

## Significance — two questions, one per reach

Every entry answers one reach per block — the DEPLOY heading's own text for tier 0, `### What makes this PR
extra special` for your audience tier. **The tier says how far the change reaches**, and therefore which
release document the entry appears in:

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
the document points back at that printout. The bands are anchored on purpose — an unanchored ordinal
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

## The two contributing layers, and which one wins

A repo running this workflow carries **two layers**, deliberately (Dave, August 14, 2026):

- a **floor** — what holds before any plugin is consulted, and what stays meaningful the day the plugin
  is absent: a fresh checkout, a teardown, a contributor who installed nothing. Normally that is your
  root `CONTRIBUTING.md`;
- `contributing-davekjohn/CONTRIBUTING.md` (the `adopt-workflow-folder` skill scaffolds it) is the
  **workflow's layer**: everything this plugin owns, plus your repo's answers to its seams. **Where the
  two disagree, the workflow's page wins.**

So adopting this workflow never rewrites your root page — the folder file arrives beside it and takes
precedence only where they conflict.

**Which file carries the floor is yours, and the source repo answers it differently from the
recommendation.** On August 27, 2026 it deleted its root `CONTRIBUTING.md` and kept the floor in its
`CLAUDE.md`, on the grounds that an always-on document already stated the same three rules — never
directly on the trunk, a branch + PR, the required CI check — and a second copy is a thing to keep in
sync rather than a safety net. **Nothing in this workflow depends on that choice**: every gate reads your
branch's own `development.md`, never a contributing page, so both answers work.

**The recommendation is still the root page, for two reasons that have nothing to do with the gates.**
GitHub links a root `CONTRIBUTING.md` from the new-issue and new-pull-request pages and from the
repository sidebar, and it recognises that file only in the root, `.github/` or `docs/` — a page in
`contributing-davekjohn/` gets none of that surfacing. And it is the file a drive-by contributor looks
for by name. Both matter most in a public repo with contributors who have installed nothing, which is
precisely the reader the floor exists for. Keep the root page unless you can say why your repo is not
that case.

**If you do retire the root page, inventory it section by section BEFORE you delete it.** That is the
step that makes the removal safe rather than merely tidy, and it is cheap: for each section, find where
that rule is actually decided — your root `CLAUDE.md`, a seam lib, a gate, this page — and move anything
that lives **nowhere else** before the file goes. Most of a drifting root page is restatement and moves
nowhere; the danger is the minority that is not. Measured in one consumer on August 27, 2026: of seven
sections, six were restatements of its root `CLAUDE.md` and three rules lived only on the page being
deleted — one of them a **safety rule about pushing to the live theme**. Deleting the page without that
pass would have dropped a live-push rule in silence, and no gate in that repo would have said a word,
because no gate reads a contributing page. That is the whole reason this is an instruction rather than
a suggestion: the failure is silent by construction.

**And the drift that prompts the removal is itself the evidence for doing the pass.** The same page's
gate list named three test suites on a day its root `CLAUDE.md` named ten. A page far enough out of date
to be worth retiring is exactly the page whose contents you can no longer predict from memory.
