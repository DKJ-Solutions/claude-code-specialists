# BWJ ticket handling -- the portable rule

**This page applies in exactly two repos: `BWJ-ecommerce/smartwatchbanden` and
`BWJ-ecommerce/xoxowildhearts`.** They are one business (BWJ) running two Shopify stores that behave
identically and differ only in brand, so they handle a discovered issue the same way. This page is
that way, written once so neither repo can drift from the other.

It is a layer on top of `contributing-davekjohn`, not a replacement for it. It extends that
workflow's **ticket-work step -- the layer before the branch** -- and changes nothing else:
branch naming, what a change owes before a PR, and what a release is are still that workflow's
answers. Read this page after
[`contributing-davekjohn`'s ticket-work section](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md#ticket-work--the-layer-before-the-branch),
which this one sharpens rather than repeats.

**How to read this page.** It travels with the plugin, so a link that walks out of this plugin's own
folder is written as an absolute URL -- an installed plugin is read from its own cache directory,
where the repo tree around it does not exist. Measurements and issue numbers on this page are the
**source repo's** (claude-code-specialists); they are the evidence behind a rule, never your repo's
own record.

---

## The rule

### 1. GitHub first -- GitHub is the source of truth

A real issue found in a BWJ store repo -- a bug, a broken customer-facing behaviour, a stale or wrong
doc, a decision that is not yours to make -- is **filed on GitHub first**, in the repo it was found
in. Full technical detail; repo and code jargon are fine, because the reader is whoever picks the
work up.

The `team-alpha` orchestrator's filing bar applies **unchanged** -- this rule adds *where the issue
is mirrored*, it does not loosen *when or whether it is filed*:

- The question to answer first is *does it still stand?*, not *may I file it?* -- read the code, the
  script or the output that would have to be true for the finding to hold, and if it collapses, say
  so instead of filing a weakened version.
- Search the tracker first, so you add to an existing thread rather than open its duplicate.
- One subject per issue.
- Say what you **measured** and what you only **inferred**.
- Filing needs no permission, and asking for it is the same failure as not filing.

#### Classify it as you file it -- three fields, all set at creation

An issue that arrives typeless and unlabelled has to be classified by hand afterwards, and afterwards
never comes. Both BWJ trackers were brought to 100% type coverage by hand on September 1, 2026 -- 135
issues across the two -- and that state holds only if every filing from here on maintains it.

| field | what it carries | how |
|---|---|---|
| **issue type** | Bug / Feature / Task | `--type Bug` -- a defect in behaviour that already exists is **Bug**, a capability the store does not have yet is **Feature**, and **Task** is everything else, which is most of it |
| **`tier-1` label** | how far the issue reaches | `--label tier-1`, and only where it reaches the audience tier. Absence is the answer for tier 0 and is not a missing field |
| **`documentation` label** | the one content distinction the type system cannot express here | `--label documentation` on a doc finding, on top of whatever type it has |

**The type is set directly, not derived from a label.** `bug` and `enhancement` were deleted from both
repos on September 1, 2026, because the type already carried them: all 28 `bug` issues held type `Bug`
and all 16 `enhancement` issues held `Feature`. Nothing was lost with them, and they are not re-added.

**`documentation` was deliberately kept** (Dave). The `BWJ-ecommerce` org has exactly three issue types
and none of them is Documentation, so its 42 doc issues sit on `Task` and `Feature`. Deleting the label
would have buried them in a 91-issue `Task` pile -- that is not *covered by the type*, that is lost. A
`Documentation` type was considered and not taken: issue types are **org-wide**, so adding one would put
it in every BWJ repo, which is a wider decision than these two.

#### The `tier-1` label -- the reach axis, carried onto issues

The label is the
[tier model](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/contributing-davekjohn/RELEASES-portable.md#the-tier-model)
applied to an issue instead of a changelog entry. Both BWJ repos answer `Get-ReleaseAudienceTier = 1`, so:

- **`tier-1` present** -- management and the commissioner notice it.
- **`tier-1` absent** -- tier 0: only this repo's developers notice.

Tier 2 does not exist in these repos, so one label carries the whole axis and
`is:open label:tier-1` is the business-facing worklist.

**The model transfers; the mechanism does not.** A changelog entry is a form with a field per reader, and
every tier is scored on it -- tier 0 included, because an unanswered field reads as an omission rather
than a decision. A label is not a field, it is a filter, and *a filter that matches everything filters
nothing*. So: **score every tier on an entry, label only the exception on an issue** (Dave, September 1,
2026, after two other shapes were tried -- `tier-0` marking the exception, which labelled 106 of 135 and
left the actionable set unmarked, and a `tier-0` floor with `tier-1` stacked on it, which is the changelog
model exactly and is where the two genuinely part company).

**The test is whether the reader notices the DEFECT, not whether the file renders to them.** This is the
mistake the file path invites, and it was made: `smartwatchbanden#455` is a Liquid block on the product
page -- inline CSS, invented hex instead of the token, five unsynchronised copies across the market
templates. It renders correctly to every shopper. The named failure is that a copy change has to be made
in four places with nothing reporting the one left behind, which only a developer can see. Tier 0, first
classified tier 1 on the wrong question (*the PDP is customer-facing, so a PDP file is tier 1*).
Re-testing all 31 tier-1 issues on the sharper question moved a second. **The inverse holds too**: a build
script no customer will ever load, whose breakage stops a release the business is waiting on, is not tier
0.

**Doubt resolves to tier 0** -- no label (Dave, September 1, 2026, on three borderline cases in the
backfill). The point of the label is a short list somebody can work, and a tier-1 issue is cheap to add
later with `gh issue edit <n> --repo <owner>/<repo> --add-label tier-1`.

### 2. Then Asana -- a translation, not a copy

Once the GitHub issue exists, mirror it to Asana in the project
`Get-AsanaProjectGid` names. The Asana task is **not** a paste of the issue body. It is written for
a BWJ colleague who does not read code and does not know the repo:

- **Plain language, outcome-framed.** What a customer or colleague actually experiences, not what the
  code does.
- **No jargon** -- no file paths, no function names, no branch names, no GitHub label vocabulary.
- **A fixed skeleton**, so every mirrored task reads the same way:

  ```text
  What is wrong:   <one or two plain sentences -- what a visitor or colleague sees>
  Where:           <which store, and which page or flow>
  How urgent:      <blocking a sale / visible but not blocking / cosmetic / not customer-facing>
  Tracked on GitHub: <issue URL>
  ```

- The task's assignee, section and due date are for the BWJ team to set in Asana. This page does not
  prescribe them.

The colleague-facing wording is Claude's to draft; a colleague may refine it in Asana afterwards
**without touching GitHub**. GitHub stays leading -- if the two ever disagree on substance, the
GitHub issue is right and the Asana task is corrected to match.

### 3. Cross-link both ways

The link is stored on both sides, and one half is machine-readable because the automation in step 4
matches on it:

- **On the GitHub issue** -- appended to the issue body:

  ```text
  Asana: <task URL>
  <!-- asana-task: <numeric task GID> -->
  ```

  The HTML-comment marker holds the bare numeric GID and nothing else. It is what the CI workflow
  reads; a task URL alone is not enough.

- **On the Asana task** -- the `Tracked on GitHub:` line of the skeleton already carries the issue
  URL. Nothing else is required there.

### 4. Close the GitHub issue -> the Asana task resolves itself

**Closing the GitHub issue is the signal.** A GitHub Actions workflow in the repo
(`.github/workflows/asana-mirror.yml`, copied from this plugin's `templates/`) does the rest:

| GitHub event | what happens in Asana |
|---|---|
| issue **closed** | the linked task is marked complete, with a comment `Resolved via GitHub <repo>#<n>` |
| issue **reopened** | the linked task is set back to incomplete |
| daily schedule | a reconciliation sweep completes any task whose linked issue is closed but which a missed event left open |

No one resolves the Asana task by hand. If a task has no `<!-- asana-task: ... -->` marker on its
issue, the workflow logs it and moves on -- it never guesses.

### 5. What still needs a person

- **Setup, once per repo:** the repo secret `ASANA_PAT` and the variables `ASANA_WORKSPACE_GID` /
  `ASANA_PROJECT_GID`, plus copying the two `templates/` files into `.github/`. The
  [`adopt-bwj-asana`](skills/adopt-bwj-asana/SKILL.md) skill walks this.
- **The Asana project answer:** whether both stores mirror into one shared project or one project
  each is a BWJ decision. `Get-AsanaProjectGid` returns whatever each repo sets, so either works --
  but the two repos must make the *same* kind of choice, or this page's promise of "identical" is
  broken.

---

## Why it is shaped this way

- **GitHub first, not Asana first**, because the people who fix the issue live in GitHub and the
  fix's lifecycle (branch, PR, merge, release) is already tracked there by `contributing-davekjohn`.
  Asana is the window the rest of BWJ looks through, not the workbench.
- **A translation, not a copy**, because a mirrored task that is just the issue body helps nobody: a
  non-technical colleague cannot act on a stack trace, and a technical reader already has the issue.
- **CI, not a session**, for the resolve step, because it must happen every time an issue closes
  whether or not anyone is running Claude, and because a workflow file is version-controlled and
  reviewable where an Asana-side automation rule is not.
- **A reconciliation sweep**, because a single webhook can be missed and a task stuck open in Asana
  is exactly the drift this plugin exists to prevent.
