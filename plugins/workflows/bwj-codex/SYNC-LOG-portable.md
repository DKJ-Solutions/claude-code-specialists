# The sync log -- the portable rule

**This page applies in exactly two repos: `BWJ-ecommerce/smartwatchbanden` and
`BWJ-ecommerce/xoxowildhearts`.** It is chapter two of this plugin, beside
[`WORKFLOW-portable.md`](WORKFLOW-portable.md), and it answers one question that chapter does not:
**what a sync owes.**

It is a layer on top of `contributing-davekjohn` in the same way the ticket chapter is -- it changes
nothing about branch naming, what an ordinary change owes before a PR, or what a release is.

**How to read this page.** It travels with the plugin, so a link that walks out of this plugin's own
folder is written as an absolute URL -- an installed plugin is read from its own cache directory,
where the repo tree around it does not exist. Measurements and issue numbers on this page are the
**source repo's** (claude-code-specialists); they are the evidence behind a rule, never your repo's
own record.

## Why this is policy and not mechanism

`team-shopify` ships the **mechanism** -- `sync-main.ps1`, `Get-SyncFileVerdict`, the live-theme
guard. That is generic: any repo serving a Shopify theme has third-party drift, and every one of them
gets the machinery through a plugin update whether or not it ever reads this page.

This page is the **policy** -- *what a sync owes, where that record lands, and what it must stay out
of*. That is BWJ's house rule for two repos, not a Shopify fact. Keeping mechanism in `team-shopify`
and policy here is the same seam split the two repos already run everywhere else.

**The practical consequence:** the machinery is silent until a repo asks for it. A repo that has not
answered `Get-ShopifySyncLogPath` gets no log, no file and no line of output, and that is correct
rather than unconfigured.

## The rule

**A `sync/` branch owes a sync-log entry, exactly where an ordinary branch owes a changelog entry.**

That symmetry is the whole rule, and it is worth stating as a symmetry because the two halves are
easy to argue separately and wrong separately:

- **A sync stays out of the changelog, and that half needs no repair.** The entry gate exempts the
  `sync/` prefix (`Get-EntryGateExemptPrefixes`, whose default *is* `sync`), nothing folds, and
  `CHANGELOG.md` carries no sync entry. Measured in `smartwatchbanden` at `7bcefe6`: two `merge:
  sync/` commits, zero `fold: sync/` commits. **This page codifies that behaviour rather than
  changing it** -- a sync mirrors what a third party did to a live theme, which is not this repo's
  change and does not belong in this repo's account of what it shipped.
- **A sync therefore owes something else, and until inbound #1382 it owed nothing at all.** A sync
  branch was the only branch in the workflow with no durable record anywhere in the tree.

### What a sync owed before, and why the PR body is not it

The only account of what a third party did on the live theme was the **PR body on GitHub**. Nothing
in the repo said it.

That matters more here than it would elsewhere, because of a standing rule in both store repos: **a
sync PR does not wait for review.** The body is therefore the entire review moment -- and a review
moment that exists only in a merged PR body is one nobody re-reads, nothing greps, and no clone
carries.

**Also worth knowing before anyone proposes reading the diff instead:** the diff of a sync branch
shows what was *taken*, never what live no longer has. A deletion on live is the one kind of drift
that most needs a second look and the one kind a diff cannot show you. The PR body already spells
that out in words; so does the log entry, from the same rows.

## Where the record lives

**`bwj-codex/SYNC-LOG.md`, in the repo's own root.** One file, **newest at the top**, one entry per
sync branch.

**One file, not one per year.** Start here and split only if it ever gets genuinely unwieldy -- and
if a repo ever does split it, the other repo splits it the same way on the same day, because the
point of this plugin is that the two cannot diverge. Stated here so nobody has to decide it twice.

**The folder is `bwj-codex/`**, matching the plugin that owns the rule, exactly as
`contributing-davekjohn/` matches the workflow that owns the branch documents.

**Nothing scaffolds it, deliberately.** The file appears the first time there is something to put in
it -- the run that writes the first entry creates the file and its folder. An empty log scaffolded on
adoption day says "no syncs have happened" and "nobody has run the adopt step" in exactly the same
way, and one of those is a fault.

## What the log must stay out of

- **`CHANGELOG.md`.** Never folded. A sync is not this repo's change.
- **The release notes, at any tier.** Never read by `cut-release.ps1`, never generated into an
  audience or internal note.
- **The trunk, directly.** The entry is committed on `sync/live-YYYY-MM-DD` and arrives on the trunk
  through the merge, like every other change. **This must not become a fourth exception to "never
  commit directly on main"** -- `guard-direct-main-hook.ps1` lets exactly three subjects through on
  the trunk (`fold:`, `release:`, `sync:`), and keeping that list at three is what keeps the guard
  narrow enough to mean something.

## What an entry carries

```markdown
## 2026-09-04 -- `sync/live-2026-09-04`

**Taken from live (3)**

*live holds content this repo has never had*

- changed on live -- `sections/header.liquid`
- new on live -- `snippets/badge-usp.liquid`
- gone from live -- `templates/page.back-to-school.json`

**Held back, the trunk wins (1)**

*live is holding an older version of this repo's own content*

- changed on live -- `assets/theme.css`
```

Four things, and each is there because the other three cannot supply it:

| | why it is in the entry |
|---|---|
| **the date** | what orders the file, and the only field a reader scans by |
| **the branch** | it is the pull request's head ref, which is how the entry reaches the discussion -- `gh pr list --head sync/live-2026-09-04 --state all` |
| **what was taken**, per path with its kind | `changed on live` / `new on live` / `gone from live`. The kind is spelled out per file because a flat list cannot tell a deletion from an edit, and the deletion is the one that needs the second look |
| **what was held back**, per path with its reason | the half **nothing else records at all**. The taken half is at least in the diff; the held-back half exists only because the content rule suppressed it, and this is its only account |

**There is no PR-number field, and that is deliberate rather than missing.** The entry is composed and
committed *on* the sync branch, before any pull request exists -- and the default seam answer
(`Get-ShopifySyncMerges` unanswered, i.e. `$false`) stops the run at the push, so it never learns a
number at all. A field that is blank on the common path is worse than a field that is not there. The
branch name is the head ref; the one-line lookup above completes the trail.

## Where the data comes from -- one definition, two outputs

The entry is a **second rendering of the same rows**, never a second measurement.

`sync-main.ps1` classifies each drifted file once, into rows carrying `Status`, `Path` and `Reason`.
Those exact rows go three places:

1. the console report the operator reads during the run,
2. `New-SyncPrBody`, which composes the PR body -- and the `Get-ShopifySyncPrBody` seam, which
   receives the same `-Take` / `-Keep` and may put a repo's own template around them,
3. `New-SyncLogEntry`, which composes this entry.

The second and third **share their renderers** (`Get-SyncPrBodySection`, `Get-SyncFileKind`) rather
than each writing files out in their own words. Two composers side by side is duplication that drifts
in one particular direction: the day a new verdict class is added, one of them learns about it and
the other keeps producing a complete-*looking* record with a class missing from it. Nothing in the
output says so.

**So a change to how a row reads in words is made once**, in `team-shopify`'s `sync-rules.ps1`, and
both the PR body and the log entry change with it.

## How it lands -- write-at-creation, not a gate

`sync-main.ps1` creates the branch, copies the drifted files, **writes the entry, and commits all of
it together.** The entry is written before the `git add`, because that add is path-bounded: a file
produced after it would sit untracked in the working copy and the run would report a clean success.

**This is why there is no sync-log gate, and the absence is a decision.** Inbound #1382 proposed
making the `sync/` exemption from the entry gate *conditional* -- exempt from a changelog entry
*because* it owes a sync-log entry -- so that the exemption could not silently become "a sync owes
nothing". The concern is right and the gate is the wrong instrument for it:

- **The script that creates the branch writes the record in the same breath**, which is the shape
  `new-branch.ps1` already uses for a changelog entry. A sync branch cannot be record-less, so there
  is nothing left for a check to catch after the fact.
- **A gate would put a `bwj-codex` concept inside `contributing-davekjohn`'s generic entry gate** --
  a check shipped to every consumer of that workflow, asking about a file only two repos have. That
  is exactly the mechanism-versus-policy split this page opens by defending, inverted.

**What is still checkable, and by whom:** whether a repo's seam is answered at all. `sync-main.ps1`
prints the path it wrote to on every run, and says so in words when the seam still holds a `VUL-IN`
marker. A repo that has silently stopped logging says so on its next sync, in the run's own output,
which is where the operator already is.

## Adopting it in a repo

One line in your repo-owned `scripts/repo-config.ps1` -- the same file
[`adopt-shopify-floor`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/teams/team-shopify/skills/adopt-shopify-floor/SKILL.md)
already writes the other Shopify seams into, and which lists this one in its commented block of
optional answers:

```powershell
function Get-ShopifySyncLogPath { return 'bwj-codex/SYNC-LOG.md' }
```

That is the whole adoption. There is no folder to create, no template to copy and no CI to wire: the
first sync creates the file, and every sync after it prepends.

**Both repos answer it with the same path.** The two are one business running one procedure; a log at
a different address in each is the drift this plugin exists to prevent.
