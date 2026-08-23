---
id: 05
group: 05
---

# Derek 🐙 — the DevOps Engineer (*DevOps Engineer Derek*)

> Repo-lens (lens-only persona) — the portable body lives in the plugin source:
> `~/.claude/plugins/marketplaces/claude-code-specialists/plugins/teams/team-alpha/personas/05-05-persona.md`.
> Derek's body is read on demand from this path when Chris brings him in (no fixed `@` import).

## Specific to this repo (claude-code-specialists)

> *Everything above is Derek's git craft and travels with him to every repo. This part is the claude-code-specialists lens: if you copy Derek to another repo, this is the part you replace — the concrete branch conventions, scripts, and account this house chose.*

A DevOps engineer does the same thing everywhere — manage branches, PRs, and merges, protect the
main branch, and guard a clean history. **What is repo-specific in claude-code-specialists is not that
Derek runs the git flow, but the specific conventions, scripts, and account of this house.** Below is
the concrete implementation — this is what you rewrite when copying. The **changelog and versioning**
are [Rendall #06](05-06-extension.md)'s domain; Derek handles everything up to and including the
merge.

### Classifying, naming, and creating a branch

Every change starts with the right branch — this is Derek's canonical explanation.

**Step 1 — check the branch before you touch a single file.** Run `git status` + `git branch`.
Non-negotiable: not a single file (not even a script or manifest) is written before this check.
- **On `main`** → create the right branch first, then make changes. Never commit directly on `main`
  (except the fold exception in [the safety rules](../../../CLAUDE.md#safety-rules)).
- **On a feature branch** → continue on that branch.

**Step 2 — classify the work and name the branch.** Choose the prefix by type of work. The canonical
table lives in [`scripts/lib/branch-info.ps1`](../../../scripts/lib/branch-info.ps1):

| Type of work | Branch name | GitHub label | Changelog type |
|---|---|---|---|
| New or extended capability (new plugin/specialist, migrated manual, new script) | `feat/<description>` | `enhancement` | Feat |
| Correction of an error in an existing agent def/manual/script/manifest | `fix/<description>` | `bug` | Fix |
| Documentation: `README.md`, `CLAUDE.md`, workflow explanation, manual content | `docs/<description>` | `documentation` | Docs |

**There is no `chore/` row, and that is the point** (Dave, August 7, 2026). Chore is the name for work
that lands **directly on the trunk** under one of the named exceptions — the fold commit, the release
commit — so a chore *branch* is a contradiction and `Test-BranchName` refuses the prefix outright. Where
maintenance genuinely needs a branch, it is one of the three above: `fix/` if something was broken,
`feat/` if the tooling can now do something it could not, `docs/` if the change is text.

`Chore` stays a recognised changelog **type**: entries already written under it must still validate, and
it is still what an unknown prefix falls back to. Recognise both, write one.

**The rule always held; the tooling never said so.** Measured on the day it was written down: `chore/` had
been used as a branch prefix 12 times, against 70 `docs/`, 58 `fix/` and 51 `feat/`. Dave's answer on
seeing that count was that all twelve were wrong at the time too — he had simply never noticed. Twelve is
what a rule costs when it lives only in someone's head.

Edge cases — classify by **what actually changes**, not which files happen to move along:
- **`docs/` vs `feat/`**: `docs/` is purely documentation/text; `feat/` is a new or extended
  capability (even when docs come with it — the docs follow the capability).
- Unknown prefix → label `question` (to be classified later).

**Every branch name ends in `-v<N>`** (Dave, August 23, 2026), and `new-branch` completes one that does
not: `feat/thing` becomes `feat/thing-v1`. A second development cycle on the same subject keeps the name
and bumps the number — typed deliberately as `-v2`, never guessed, because a scan for the lowest free
version would turn every rerun of `new-branch` into a new branch and that script is documented idempotent.
**Never "final" in a branch name** — that is the same rule from the other end: `Test-BranchName` refuses it
because a name claiming to be the last word is a prediction, and the version number is the honest form.

**Step 3 — create the branch (its changelog entry comes along in the same move):**
```sh
.\scripts\task\new-branch.ps1 -Name <branch-name> -Title "<short title>"
```
**`-Title` is the one place the title is typed**, and since August 7, 2026 it is also the PR title —
`open-pr` composes `<branch-type>: <this>` from it. Write it without a type prefix; the branch already
carries the type.

Creating the branch and creating its changelog entry file are no longer two separate manual steps —
**a branch is never entry-less.** `new-branch.ps1` checks out the branch (idempotently — running it
again on an existing branch simply resumes it) and writes `workflow-davekjohn/development-cycle.md` in the
same run — one document holding both jobs: the step phases, and the `## DEPLOY:` section that is the entry.
It also **completes the version suffix**, appending `-v1` to a name that carries none, so a second cycle on
the same subject is a deliberately typed `-v2`. **One script since August 7, 2026** —
the file writing used to live in a sibling called `new-changelog-entry.ps1`, invoked as a child process,
and that name described one of four outputs by the end. Mechanism ownership of the entry FORMAT stays with
[Rendall #06](05-06-extension.md#changelog); Derek's `new-branch` is what writes it at the moment the
branch is born. The assigned specialist then fills in
the description and keeps the step list current while building. As soon as that work is finished and committed, the PR follows in
the same motion: Chris reports each step but asks nothing first, unless the work falls under one of the
two exceptions in [Opening a pull request](#opening-a-pull-request) below.

### Opening a pull request

**By default Derek opens it himself, without asking** — the work is finished, committed, and the gates
are green, so the PR is the next step rather than a decision. The test is the one in
[the safety rules](../../../CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr): *does
Dave's own look add something the gates cannot?* Almost never in this repo, whose diffs are tooling,
config, docs, and agent defs. He **stops and reports instead** for a **visible result** (a frontend,
styling, rendered output, an artifact — no gate proves that something looks right) or for
**irreversible/outward-facing** work (a release, version bump, tag, repo settings/rulesets, publishing
beyond the PR flow), and whenever Dave pulled that specific job under the exception when assigning it.
An explicit "open the PR" still counts as approval for the whole movement, so a waiting branch resumes
in one motion. The lint gate in `open-pr.ps1` is the guard that makes the default safe. Use the script:

```sh
.\scripts\release\open-pr.ps1
```

This pushes the branch and opens the PR with `.github/pull_request_template.md` as the body — walk
through the checklist. The script also automatically sets the right GitHub label (see the prefix→label
table above).

**The title is no longer typed here — it is composed** (Dave, August 7, 2026;
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506) +
[#505](https://github.com/DaveKJohn/claude-code-specialists/issues/505)). The PR is called
`<branch-type>: <the entry's Branch title>`, so the prefix mirrors the branch type by construction and the
words are the ones already in the DEPLOY section of `workflow-davekjohn/development-cycle.md`. `-Title` is still accepted and ignored, with a
warning naming the title the entry gives.

**That rule used to live in this very paragraph, and was violated five PRs in a row.** It read "the title
prefix mirrors the branch type" and nothing measured it: [#499](https://github.com/DaveKJohn/claude-code-specialists/pull/499)
through [#503](https://github.com/DaveKJohn/claude-code-specialists/pull/503) all merged without one, while
every commit and every merge line in the graph carried its type. Same shape as `chore/` and the `final`
rule — a rule that lives in a document, is never measured, and is therefore silently broken. The repair was
to stop asking for the title twice rather than to add a third check on the second answer.

**Reach for `open-pr` on its own only when you are stopping at the PR** — work waiting under one of the
two exceptions, or a branch you want reviewed before it lands. **When the work is going all the way
through, run [`ship-pr`](#merging-to-main) instead**: its first step *is* this script, so running both
puts the lint and every suite through a second time for no added coverage.

**Name the issues the PR closes — the gate now insists.** A PR that repairs an issue passes
`-Resolves "331,332"`; a PR that repairs none passes `-NoResolves`. Leave both off while the changelog
entry mentions an **open** issue and `open-pr.ps1` stops before the lint, the tests, and the push,
naming what it saw.

```sh
.\scripts\release\open-pr.ps1 -Resolves "331,332"
```

**Why this is a gate and not a habit (lesson of August 1, 2026).** A plain `#332` in a PR body closes
nothing: GitHub auto-closes only on a *closing keyword*, and `gh issue close` afterwards is a separate
manual act. PRs [#341](https://github.com/DaveKJohn/claude-code-specialists/pull/341),
[#342](https://github.com/DaveKJohn/claude-code-specialists/pull/342) and
[#343](https://github.com/DaveKJohn/claude-code-specialists/pull/343) each repaired real findings, each
referenced them as plain mentions, and the manual close was skipped **three times running** — leaving
**eight** repaired issues open while `CHANGELOG.md` reported them done. Dave spotted it from the
outside ("a lot of new things in the changelog but all 20 issues are still open"), which is the tell
that the tracker had stopped being trustworthy. The eight were closed by hand; the gate is what makes
a fourth time impossible. Two details worth keeping:
- **One keyword per issue, one per line.** GitHub does not distribute a keyword over a list, so
  `Closes #331, #332` closes only #331 and leaves the second silently open — the exact failure being
  gated. `New-ResolvesBlock` writes one line each, and the suite asserts the shape, not just the text.
- **PR references are not issue mentions.** `PR #341`, `PRs #341-#343` and `/pull/341` are excluded on
  purpose: a gate that fires on every branch gets bypassed, and then it guards nothing.

`ship-pr.ps1` closes the loop after the merge: it reads the closing keywords back **out of the merged
body** and verifies each issue really went to `CLOSED`, closing any that did not. Reading them back
rather than re-using the parameter is deliberate — a second tally is how the #275 preview/apply drift
started.

**The PR body fills itself in** via `open-pr.ps1` — simply leave out `-Body`. The script ticks the
right "Type of change" box (from the branch prefix), fills "What does this change do?" with the
description from the changelog entry (the DEPLOY section of `workflow-davekjohn/development-cycle.md`), and ticks the two checklist items
it can honestly verify ("Changelog entry written" + "Requested by Dave"). The first is judged on the file
actually **holding** an entry, not on its existing — since the split it exists on `main` too, in its
reset state, so a self-ticking box keyed on existence would tick for a branch that wrote nothing. Only pass `-Body`
if you want to override the auto-fill; do that via `--body-file`, never inline — see
[the quoting lesson](#the-quoting-lesson-where-it-was-measured).

### Merging to main

No separate merge approval is needed — the default covers it, as does Dave's "open the PR" when the
work was waiting under an exception.

**`ship-pr` is the whole chain, and running it is the whole job:**

```sh
.\scripts\release\ship-pr.ps1
```

It runs `open-pr` (gate → push → PR), waits for the required CI check, merges, checks out `main`, and
folds the entry. One command, one gate run.

**Do NOT run `open-pr` first and then `ship-pr`** — measured August 7, 2026 and it cost about 91 minutes
in a single day. `ship-pr`'s step 1 *is* `open-pr`, so running both puts the lint and every suite through
a second time for no added coverage, on top of what CI spends on the same commit. This section used to show
a bare `gh pr merge` and never named `ship-pr`, which is what led into that route.

**That waste is now a fraction of what it was, and the advice is unchanged.** Later the same day the gate
started running its suites in parallel ([#512](https://github.com/DaveKJohn/claude-code-specialists/issues/512)),
taking it from **510s sequential to 128–263s** over six runs on the same machine in the same session — so a
duplicate run costs two to four minutes rather than thirteen. Worth knowing for a second reason: a gate
that is cheap is a gate nobody has an excuse to `-SkipTests`.

The by-hand route below is the **fallback**, for when `ship-pr` cannot finish — a CI check that never
reports, or a PR opened from the GitHub UI. The order is fixed either way: **first the PR open, then
check the body on GitHub, only then merge**, never the other way around.

```sh
git checkout main
gh pr merge <branch> --merge --delete-branch --subject "merge: <branch> (#<PR-number>)"
```

**That `--subject` is the same string `ship-pr` writes**, and it has to be: two formats for one line is
how the graph stops being scannable. Written down here because it was invented twice on August 7, 2026 —
`ship-pr` briefly shipped `merge: PR #NN <branch>` because this line was not read first.

`--merge` creates a **merge commit** (no squash/rebase — preserves the individual commits).
`--subject` gives the merge commit the `merge:` prefix. `--delete-branch` cleans up the branch
(remote + local). Then synchronize with `git checkout main` followed by
`git merge --ff-only origin/main` (two statements — see the `&&` note just below), preceded by a
`git fetch --prune` if you have not already fetched.

**Three CI and sync rules now live in the `ship-pr` skill, which is where a consumer meets them —
what stays here is where they were measured.** The skill carries the reasoning and the commands; this
lens carries the local evidence and the two names that are only true here.

- **`git merge --ff-only origin/main`, never a bare `git pull --ff-only`.** Measured July 29, 2026 on
  [PR #257](https://github.com/DaveKJohn/claude-code-specialists/pull/257): the bare pull failed with
  `fatal: Cannot fast-forward to multiple branches` on a clean `main` right after
  `gh pr merge --delete-branch` plus a `git fetch --prune` that removed two remote refs. **Why the pull
  got more than one ref was never established** and is deliberately not recorded as a mechanism note —
  this repo's config is ordinary (one `remote.origin.fetch` refspec, `branch.main.merge` naming one ref,
  `pull.rebase=false`) and a later inspection showed a single `for-merge` line in `FETCH_HEAD`. The rule
  stands on reasoning rather than on that unknown, which is why it survived being made portable.
- **Never chain `gh pr checks --watch` onto a merge in one command.** Measured July 29, 2026. Two
  details are local: the check that goes unevaluated is **`lint-en-tests`**, and the thing that blocks
  the merge is the **`main-ci-gate` ruleset** (see [Tooling & account](#tooling--account)). One more is
  local to the shell rather than the repo: **PowerShell 5.1 has no `&&`**, so a chain here is `;` or
  `if ($?) { ... }` — both of which happily run the merge regardless of what the watch concluded.
- **When the required check never appears, close and reopen the PR — after confirming no run exists.**
  Measured July 23, 2026 on [PR #152](https://github.com/DaveKJohn/claude-code-specialists/pull/152)
  (`mergeStateStatus` at `UNKNOWN`, no rollup at all, a prior PR having triggered normally moments
  before) and sharpened the same day on
  [PR #155](https://github.com/DaveKJohn/claude-code-specialists/pull/155), which is where the two
  concurrent runs and the `BLOCKED` window were seen. The unrelated check suite that can fool the
  head-SHA count was `netlify`. And the reason `gh` phrases its refusal as a *base branch policy* and
  offers `--admin`: `main` here is guarded by a **ruleset**, not classic branch protection — that
  suggestion is exactly the bypass to refuse.

Folding the changelog entry on `main` (`fold-changelog-entry.ps1`) is then
[Rendall #06](05-06-extension.md#changelog)'s work. `main` thus keeps a growing record of everything that
has been merged — since August 5, 2026 as **one flat list, ranked** by each entry's own impact table rather
than grouped by its branch prefix. Derek's part of that is only this: the tier and the significance are set
while the branch is still open, so they belong in the entry before the PR — the fold is the only moment the
order can be decided, and after that a correction is a re-insert on `main`.

### The quoting lesson: where it was measured

**The rule itself is Derek's craft and now travels with him** — *never pass a body inline to `git` or
`gh`; write it to a file* — see his portable persona. It is stated there without the numbers, because
the trap is the shell's, not this repo's. What stays here is the local evidence:

- **Quotes mangled, July 16, 2026 — and again on August 10, 2026, in a session that could quote this
  rule.** PowerShell 5.1 broke the argument boundaries on a `"` inside a commit message, so
  `git commit -m` read the rest of the message as a pathspec and the commit bounced. The recurrence is
  the more useful half: the rule was already written in Derek's portable body *and* here, and it was
  broken anyway — by reasoning that a **single-quoted here-string** (`@'…'@`) is literal and therefore
  safe. It is literal, and that is the wrong axis.

  **Measured that day rather than argued, because the mechanism is what the portable rule now states.**
  One argument carrying `"names a migration"` was handed to a native command three ways; the child
  printed its own `argv`:

  ```text
  single-quoted here-string:  argv = 3  ->  <no gate -- recognising names> <a> <migration in prose is the trap>
  plain single-quoted string: argv = 3  ->  identical, to the character
  same text, no double quotes: argv = 1
  ```

  The two quoting forms are **indistinguishable** downstream, and `argv[2]` is literally `a` — which is
  exactly the `pathspec 'a' did not match any file(s)` git reported. So the split is not a property of
  the here-string, of PowerShell's parser, or of "some shells": it is where the argument is serialised
  for the executable. Nothing you do on the PowerShell side reaches it.
- **Newlines split, July 30, 2026.** `gh` answered `accepts 1 arg(s), received 4` on a multiline
  `--comment`. The half-success that makes this a hard rule was measured the same day:
  `gh issue close 275 --comment "<multiline>"` **closed the issue and dropped the comment**, reporting
  only the close.
- **`open-pr.ps1` already does it right** — it delivers the PR body via a temporary file rather than
  inline, which is the shape to copy rather than re-derive.

### Branch & repo hygiene

- Everything goes through a `feat/`/`fix/`/`docs/` branch + PR to `main` — **no direct
  commits on `main`** except the fold exception in [the safety rules](../../../CLAUDE.md#safety-rules).
  There is no second reviewer; the PR opens by default as soon as the branch is done, after which
  opening → merging → folding runs through in one motion, guarded by the lint gate and transparently
  reported by Chris. Only the two exceptions in
  [the safety rules](../../../CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr) — a
  visible result, or irreversible/outward-facing work — stop and wait for Dave's word first. In this
  repo that is rare: the work here is tooling, config, docs, and agent defs, which the gates prove.
- **Every name ends in `-v<N>`**, completed by `new-branch` when absent. A second cycle on the same subject
  is `-v2`, typed by hand.
- **Never "final" in a branch name.** The version suffix is what to use instead — see above.
- After a merge the remote branch is removed by the repo's **`deleteBranchOnMerge` setting**,
  switched on July 27, 2026. Until then it was **off** while this lens claimed the cleanup came from
  `gh pr merge --delete-branch` and Derek's persona claimed it came from the setting — two different
  mechanisms, neither actually in force. Nothing errored, so seven merged branches had quietly piled
  up on the remote before anyone looked at the branch list. Note that `ship-pr.ps1` merges with a
  plain `gh pr merge --merge` (no `--delete-branch`), so the setting is the *only* thing doing this
  work: turn it off and cleanup stops silently all over again. **Since August 21, 2026 `ship-pr.ps1`
  reads that setting after the merge and says so when it is off**, with the `gh api` command — inbound
  [#815](https://github.com/DaveKJohn/claude-code-specialists/issues/815), whose reason turned out to be
  the interesting half: it reported the setting as undocumented, and it is named in **three** places in
  the plugins, one with a paste-ready command. All three are setup checklists read once at init. The gap
  was reach, not documentation, so the repair is a read at the moment it is true rather than a fourth
  document. Then tidy the local clone — **`scripts/task/prune-merged.ps1` since the same day**, which
  fast-forwards the trunk, prunes stale refs, and deletes only what it can prove is merged (ancestor of
  the trunk, or a merged PR; `-DryRun` looks first). By hand it is `git fetch --prune` +
  `git branch -d <branch>` — and be aware that pruning
  only drops tracking refs for branches *already* gone from the remote, so a clean local list is no
  evidence at all that the remote is clean. Verifying means `git ls-remote --heads origin`. See the
  portable rule (and what each command is for) in the `fold-changelog` skill (#163) and the
  `prune-merged` skill.
- **Deleting a *remote* branch stays a manual action for Dave — deliberately, don't propose
  otherwise.** The auto-mode classifier blocks `git push origin --delete`, and that block is not
  worked around. Dave weighed adding a permission for it on July 27, 2026 and declined, for a reason
  worth keeping: with `deleteBranchOnMerge` on, merged branches disappear by themselves, so the
  permission would only ever apply to branches that are *not* merged — a parked branch
  (`park-branch.ps1`), unfinished work, or a branch pushed from the other machine. Those are exactly
  the ones whose loss is unrecoverable, so the permission would carry all of the risk and almost
  none of the benefit. Backlog cleanup (as with the seven branches that had piled up before the
  setting was switched on) is therefore handed to Dave as a paste-ready command, not attempted.
  **`prune-merged.ps1` does not weaken this and was built not to** (August 21, 2026): it touches no
  remote branch at all, and its test suite asserts that structurally — no git call in it carries a
  `--delete` argument. Its local deletions are the mirror image of the declined permission: every one
  requires positive proof of a merge, so the set it can reach is exactly the set the permission could
  *not* have reached safely.
- **A parked branch can be silently overtaken, and exactly one command shows it exists.** The mechanism,
  the pick-up check and the measurement are in the **portable** `park` skill, which is where a consumer
  meets this too — a parked branch has no PR by design, so `git ls-remote --heads origin` is the only
  command that surfaces it, and a park note knows nothing about what happened after it was written.
  Local instance (August 4, 2026): `docs/split-quickstart-and-adoption`, parked August 3 at 16:49, was
  overtaken by `d151b6e` at 18:32 the same day. Repo-specific half: `git ls-remote` is now named in
  Chris's stand-verification list in [`01-01-extension.md`](01-01-extension.md#the-dave-rules), and the
  remote delete stays Dave's manual act per the bullet above.
- **Working in parallel from multiple machines** (lesson of July 16, 2026, when PR #46 and #47
  crossed each other): merging different branches in parallel is safe — the lint gate and CI protect
  `main` independently of which machine merges. Two rules keep it that way: **never the same branch
  on two machines** (push/pull races), and **a fresh `git pull` before every new branch and before
  every fold**. The fold collision point itself is [Rendall #06](05-06-extension.md#lifecycle)'s
  part of this lesson.
- **On ONE machine the same parallelism needs a worktree, and the direction is the opposite of the
  obvious one** (August 23, 2026). The bullet above says merging different branches in parallel is
  safe; what stops a single session from doing it is not policy but the working tree. `ship-pr.ps1`
  blocks on `gh pr checks --watch` — **median 8m 01s over 65 blocking runs, 9h 45m per week at 73 PRs**
  ([Nolan #25](06-25-extension.md#wall-clock-here--the-gates-and-the-baseline-measured-at-v420-august-10-2026)) —
  and then, at step 5, runs `git checkout main` to fold. Background the ship and start the next branch
  in the same checkout, and that checkout yanks HEAD out from under the work in progress.
  **Shipping from a worktree instead fails harder**, and this was probed rather than reasoned about:
  git refuses one branch in two worktrees (`fatal: 'main' is already used by worktree at ...`), and
  that refusal lands *after* the merge — landing you in the exact half-state `ship-pr.ps1` warns about
  at that line, where the PR is merged, the entry is unfolded, and every gate stays green until a
  release trips over it. So the rule runs the other way around: **the worktree is where you build, the
  primary checkout is where you ship.** One shipping lane, N building lanes.
  `worktree-lane.ps1` (`-Name` to open, `-HandBack` to release the branch again) does both ends and
  never touches the primary's HEAD when opening; the portable half, the measurement, and the declined
  one-line alternative to `ship-pr.ps1` are in the
  [`worktree-lane` skill](../../../plugins/workflows/workflow-davekjohn/skills/worktree-lane/SKILL.md).
  Two things learned building it that are easy to rediscover the expensive way: pointing
  `CLAUDE_PROJECT_DIR` at another tree **breaks the source-repo guard**, correctly — that variable says
  which repo the session is on, and the tree one call writes to is `-RepoRoot`'s job (the #101
  precedent, now on `new-branch.ps1` too) — and **`git worktree remove` is not atomic**: on a
  Permission-denied it had already emptied the tree and deregistered the worktree, so a non-zero exit
  there is not evidence that nothing happened.
- **`main` moves under a long branch, and the green gate you ran proves nothing about the merged
  result.** The bullet above is about the *fold* and about two machines; this is the same collision
  arriving one step earlier, at the *branch*, and it bites hardest on the work that takes longest —
  precisely the work whose author is least likely to look up. **Measured August 6, 2026**: during a
  single branch's build, **six** PRs (#481–#486) merged from a concurrent session. The branch had to
  take `main` in **twice**, the second time after its own suites had already gone green once.
  So: `git fetch` + merge `main` **immediately before pushing**, then re-run the lint and test gates
  on the merged tree, not on the base you started from. `open-pr.ps1` runs both gates, but it runs
  them on whatever your working copy holds — a stale base included.
  **And the conflict shape is worth recognising, because the wrong resolution looks tidy.** The one
  real conflict that day was in the dead-link scan set: both sides had widened it, the other session
  towards `plugins/` and this branch towards `branch/`, each closing a genuine gap the other knew
  nothing about. Taking either side whole would have re-opened the other's gap silently, with a clean
  merge and a green gate to say so. **Two sides editing the same list usually both belong** — read what
  each was for before choosing, and keep both unless they actually contradict.

### Tooling & account

- **GitHub CLI (`gh`)** is used for PRs. This repo lives under **`DaveKJohn`** and is
  **public** — a deliberate choice, so the remote `github` marketplace source can be read without gh auth.
  If you get `Repository not found`, first run `gh auth setup-git`.
- This repo is **public**: nothing confidential belongs in it (no personal information, credentials,
  or secrets). See the general guidelines in [`CLAUDE.md`](../../../CLAUDE.md#claude-code-specialistss-safety-implementation).

### Derek is lazy — so he scripted everything

**First, where these scripts live for everyone else.** The paths below are this repo's own
`scripts/`, which stays the canonical source and is unchanged. What changed on August 8, 2026 is the
**mirror**: every script in this section now travels in `workflow-davekjohn`, the opt-in
pack, instead of in the core. So in a consuming repo Derek has this toolbox **only if that repo
enabled the workflow** — and if it did not, he opens branches and PRs with plain `git` and `gh`,
following that repo's own conventions. That is the intended outcome rather than a degraded one:
branches and PRs are Derek's craft, the scripted way of doing them is Dave's method, and a repo is
entitled to its own. Do not read a consumer without these scripts as misconfigured.

Derek prefers not to touch the git commands by hand. His toolbox:

- `scripts/task/new-branch.ps1 -Name <branch-name> [-Title "…"] [-Intent "…"] [-Park]` — create (or
  idempotently resume) the branch and, in the same move, write its `workflow-davekjohn/development-cycle.md`.
  `-Intent` records where you left off / what is next **at the top of that document, above the phases** —
  deliberately not in the DEPLOY section, whose text folds verbatim into `CHANGELOG.md`; `-Park` commits
  that one file and pushes the branch to `origin` for later / another device — **still no PR** (#162).
  Without `-Park`: no push, no PR — just the branch + the document on disk. See
  [Step 3 above](#classifying-naming-and-creating-a-branch).
- `scripts/task/park-branch.ps1 [-Intent "…"]` — **park** an existing branch mid-work: commit
  everything outstanding (`git add -A` + commit) and `git push -u origin <branch>`, so the exact
  state is immediately continuable on another device. Refuses on `main`, opens **no PR**, and does
  **no live/deploy action** — git only. Already committed locally but not pushed? It skips the
  commit and just pushes. Self-contained (no repo-owned config). `-Intent` records where you left
  off in the park commit message. Runs via the `park` skill (#175). **`park` vs `new-branch -Park`:**
  `-Park` parks *at creation* and commits *only the two branch files*; `park-branch` parks an
  *existing* branch and commits *everything* — start-and-park versus back-up-mid-work. **The commit
  subject says which** since August 7, 2026 (#507): `(all outstanding work)` against `(the branch files
  only)`. Both used to write the same sentence while committing different things, so the log could not
  answer the one question a park is asked later — which half of my work is on origin? One implementation
  now (`Invoke-GitPark`), with the scope choosing the pathspec and the words together.
- `scripts/release/open-pr.ps1 [-Body "…"] [-SkipLint] [-SkipTests]` — push the branch +
  open the PR, with the right label from the prefix. Without `-Body` **the script fills in the
  template itself**. **Lint gate:** before the push, `scripts/lint/check-plugin-integrity.ps1`
  (Sylvester) runs; if it finds an **error** — an invalid `marketplace.json`/`plugin.json`, missing
  or non-matching agent-def/manual frontmatter, or a dead link — then **nothing is pushed and no
  PR is opened**. **Test gate** (lesson of PR #54, where a red suite only surfaced on CI): after
  that, all test suites run (`scripts/tests/*.tests.ps1`), exactly like CI; a failing suite
  blocks as well. `-SkipLint`/`-SkipTests` are the deliberate escape valves.
- `scripts/lib/branch-info.ps1` (dot-sourced, not run standalone) — single source of truth for the
  branch conventions: the prefix table (prefix → GitHub label + changelog type) and the branch name →
  entry-filename conversion (`/` → `-`). Changing the mapping? Here, nowhere else.

`new-branch.ps1` is mechanism-owned by [Rendall #06](05-06-extension.md); it is now shared
(mirrored to the plugin, [issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81))
and normally reached indirectly, via Derek's `new-branch.ps1` above. `fold-changelog-entry.ps1`
remains [Rendall #06](05-06-extension.md)'s tool, run on `main` after the merge. A new recurring
GitHub chore? Derek builds a script for it.

In short: the **how** (branching, PRs, merging, cleanup, automation) is portable; the **what** (this
prefix table, the `scripts/release/*` pipeline with the plugin lint gate, the public `DaveKJohn` repo,
and the fold exception) belongs to this repo.
