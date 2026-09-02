---
name: ship-pr
description: >-
  Ship a finished branch in one command via the shared, centralized ship-pr script from the plugin
  (single source of truth, issue #411) -- open the PR, wait for CI, merge, fold the changelog entry,
  and verify the issues the PR declared it closes. Stops on the first failure and never forces:
  a failing gate means nothing is pushed, a red CI means nothing is merged. This is the sequence the
  registry classifies safety-critical, because it merges to the main branch and then commits directly
  to it under the fold exception. Use this when a branch is finished, committed, and the repo's
  governance rule allows the PR to be opened.
disable-model-invocation: true
---

# ship-pr — the shared PR chain for consumers

This is the **plugin mirror** of `ship-pr.ps1`: the same tested source as in the source repo,
shared here so consumers do not run the five-step chain by hand. Background in
[issue #411](https://github.com/DaveKJohn/claude-code-specialists/issues/411).

It also documents **`verify-resolved-issues.ps1`**, which is not a separate procedure but this
script's step 6 — see [Step 6 on its own](#step-6-on-its-own-repairing-bookkeeping-after-the-fact).

## When it may run is governance, not script logic

**The script executes; the repo's own rule decides whether it may.** Under the shared rule a finished
branch ships by default once the gates are green, and waits for the owner's explicit word only for
work with a **visible result** (a frontend, styling, rendered output, an artifact — no gate proves
that something *looks* right) or work that is **irreversible or outward-facing** (a release, a version
bump, a tag, repo settings, publishing beyond the PR flow).

That distinction matters more here than for `open-pr`, because this script does not stop at the PR: it
merges and then commits directly to the main branch. Running it is the whole movement, not the first
step of one.

## What the skill does

Run the shared script from the **root of the consuming repo**, on the branch you want to ship:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/ship-pr.ps1"
```

**In the source repo, run its own copy instead — `scripts/release/ship-pr.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

**Nothing is passed, because there is nothing left to say.** Since
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506) the PR title is composed from the
branch prefix and the entry's `Branch title` section, so it was already written when the branch was
created. `-Title` is still accepted and ignored, and is forwarded to `open-pr` only when you actually pass
one — see the [`open-pr` skill](../open-pr/SKILL.md) for why the parameter was kept rather than removed.
Running from the main branch is refused before anything happens — this ships a branch.

The six steps, stopping on the first failure:

1. **Open the PR** via `open-pr.ps1` — which runs the resolves gate, the scaffold gate, the impact gate,
   the step-list gate, the repo's own
   lint gate and all test suites, then pushes and opens. If any of those fails, nothing is pushed and
   this stops here. See the `open-pr` skill for what those gates check.

   **A branch whose PR is already open is resumed, not refused.** `open-pr.ps1` skips only the
   `gh pr create` in that case — the gates and the push still run — so this step succeeds and the chain
   carries on to step 2. Until August 4, 2026 it did not: the create was unconditional, a duplicate
   returned non-zero, and **steps 2-6 never ran**, so a branch whose PR was opened in an earlier session
   had to be merged and folded by hand. An existing PR keeps its own title — as every PR now does, the
   title being composed at creation and never rewritten afterwards — while
   `-Resolves` is still honoured — the closing keywords are appended to the existing body, because
   step 6 verifies exactly what the merged body declared. Measured on
   [PR #457](https://github.com/DaveKJohn/claude-code-specialists/pull/457).
2. **Find the PR number** for the current branch (`gh pr list --head <branch> --base main`).

   **`--base main` is load-bearing.** Without it the query asks "does this branch have an open PR
   *anywhere*", so if you run **stacked PRs** (`branch -> branch -> main`) the answer can be the stacked
   one — and step 4 would merge it into its intermediate base. GitHub allows one open PR per
   `(head, base)` pair, so with the base pinned there is at most one answer.

   This step also used to mis-parse gh's answer, repaired August 4, 2026: its "no open PR found" guard
   could never fire and a missing PR arrived as the empty string, so the script would have run
   `gh pr merge ''`. Worth knowing if you are on an older version of the plugin — the symptom is a
   `ship-pr` run that reports no PR number and then fails at the merge with an unhelpful gh error.

   **And then the checkout goes home, before the wait rather than after it (step 2b).** In the primary
   checkout, on a clean tree, with nobody else holding the trunk, `HEAD` moves to the main branch here —
   so a backgrounded ship leaves the session where a finished chain leaves it. Never a refusal; a tree
   that cannot go home stays where it is and says why. See
   [And stopping now leaves the checkout on the trunk](#and-stopping-now-leaves-the-checkout-on-the-trunk-1073).
3. **Wait for CI.** See [Why step 3 polls before it watches](#why-step-3-polls-before-it-watches).
4. **Merge** (`gh pr merge`), but first the **step-list gate again**: the phases above the DEPLOY heading in
   `contributing-davekjohn/development-<branch>.md` must
   have nothing unresolved left in them, or the merge does not happen. Not belt-and-braces — the rule is
   about the *merge*, and step 1's copy of it lives in `open-pr.ps1`, which has a `-Force`. A PR opened
   through that valve, by hand on github.com, or days ago and resumed here would otherwise land with an
   unfinished plan. Checked here rather than trusted from step 1, against `refs/heads/<branch>` rather than the
   working copy, and there is no `-Force` for it: `- [~] dropped -- <why>` is the way past a step that should
   not be done.
   The three marks are in the `open-pr` skill and in [`DEVELOPMENT-portable.md`](../../DEVELOPMENT-portable.md).
   See [The merge method is repo policy](#the-merge-method-is-repo-policy), and
   [which copy of the document both gates read](#the-two-merge-gates-read-the-branchs-commit-and-why-they-used-to-read-the-tree).
5. **Check out the main branch, fast-forward, and fold** — handed to `fold-changelog-entry.ps1 -Push`,
   which folds the entry, commits it and pushes it. See
   [Why the fold is delegated](#why-the-fold-is-delegated-rather-than-inlined).
6. **Verify the issues the PR declared it closes are actually closed**, and close any that are not.

## The parameters

| Parameter | What it does |
|---|---|
| `-Title` | **Accepted and ignored** since [#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506). The PR title comes from the entry's `Branch title` section; passing one here forwards it to `open-pr`, which warns and names the title the entry actually gives. |
| `-NoMerge` | Open the PR and stop — no CI wait, no merge, no fold. The same as calling `open-pr` directly, but convenient when scripting. |
| `-Resolves` | Passed through to `open-pr`: the issues this PR closes, **as a string** (`"331,332"`). Step 6 verifies them. |
| `-NoResolves` | Passed through to `open-pr`: declare that this PR closes no issue. |
| `-SkipLint` | Passed through to `open-pr`: skip the lint gate. An escape valve. |
| `-SkipTests` | Passed through to `open-pr`: skip the test gate. An escape valve. |
| `-Force` | Passed through to `open-pr`: ship an entry that still carries its scaffold wording. Deliberately separate from the two above — those skip a tool, this overrules a judgement about content. |
| `-RefreshBody` | Passed through to `open-pr`: on a branch whose PR is **already open**, rewrite that PR's description from the current changelog entry. Opt-in, so a body edited on github.com is never overwritten unasked. No effect when the PR is created in this run. |
| `-PollSeconds` | Poll interval in seconds for the CI wait. Default 15. |

**Reach for `-RefreshBody` on a branch you extended after opening its PR.** Without it the PR keeps
describing an earlier version of the work while the merged changelog entry carries the new one — and the
entry is what ends up in the release notes, so the two disagree in the place people go looking. Only the
description section is touched; see the [`open-pr` skill](../open-pr/SKILL.md#resuming-a-branch-whose-pr-is-already-open)
for exactly what is preserved.

**`-Resolves` takes a string on purpose, and this is the one parameter where the type is load-bearing.**
Across `powershell -File` a comma list is cast to a single number via the thousands separator, so an
`[int[]]` would silently turn `-Resolves 332,340` into issue `332340` — no error, just the wrong issue.
This script hands the raw string on to `open-pr`, which parses it there, precisely because the hop goes
through `powershell -File`.

```powershell
# ships and closes two issues
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/ship-pr.ps1" -Resolves "331,332"

# open the PR only, e.g. to wait for a review
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/ship-pr.ps1" -NoResolves -NoMerge
```

## The two merge gates read the branch's COMMIT, and why they used to read the tree

Both gates in step 4 read `contributing-davekjohn/development-<branch>.md` as **`refs/heads/<branch>` has it** —
the commit, not the file on disk. Which is the document the merge is about to merge, so it is the document the
gates judge.

**They read the checkout until August 27, 2026, and the script's comment explained why:** *"Read from the
branch's own checkout, which is where HEAD still is at this point -- step 5 is what moves to main."* True of
an ordinary foreground run, and an **assumption rather than a check** — nothing compared the branch you were
standing on against the branch whose PR was merging.

**It broke twice, in two different shapes.** On **August 20, 2026** two sessions shared one checkout: one had
`ship-pr` waiting on CI, the other created a branch and moved `HEAD`. On **August 27, 2026** it needed no
second session at all (issue [#970](https://github.com/DaveKJohn/claude-code-specialists/issues/970)) — one
session backgrounded the ship, started the next piece of work while CI ran for 10m57s, and the gate read the
new branch's freshly scaffolded list. Both times it refused over
`- [ ] TODO: the first step of this branch`, a step belonging to nobody's work on that PR, while the PR's own
list was complete and committed.

**Neither instance damaged anything, and that is what made the second one the evidence.** The refusals were
safe and re-running from the right branch picked up where it left off. But the assumption fails the other way
too — a tree standing on a *finished* branch lets an unfinished one through — and **that direction is silent**:
a gate with no `-Force`, satisfied by a file the PR does not contain, reports the requirement as met while
nothing checked it. One benign instance was written down rather than repaired; two, the second of them needing
only the script's own ordinary usage, are a defect.

**The repair is the read, not a new refusal.** Refusing once `HEAD` has moved was the other shape on the table
and was declined: backgrounding a ship and starting the next thing is the ordinary shape of that window, so the
guard would break the ordinary case in order to protect it. The commit needs no network either, which matters
in a gate that must not refuse because a token expired. Two things follow that are worth knowing at the
keyboard:

- **A step ticked in the editor and never committed no longer gets past the merge gate.** It used to. Both
  messages have always said *"commit, and re-run"*.
- **`refs/heads/<branch>` is what step 1 pushed**, on every path through this script — a fresh PR and a resumed
  one alike — so there is nothing extra to do to keep the two in step.

**The wider rule this belongs to has since been closed at its last open point.** These scripts assumed one
working tree per session; the gates stopped depending on it here, and step 5 stopped depending on it in
[#972](https://github.com/DaveKJohn/claude-code-specialists/issues/972). Nothing in this workflow locks a
checkout — no script claims one, and none ever did. What changed is that no script silently moves one either.

## The wait runs in the background, and that is the default

**Do not hold a session open for the length of CI.** Start this script as a background command and carry
on; the merge cannot happen before the required check is green either way, so a foreground wait buys only
a second look at a result the local gate has already given. Measured in the source repo on
[PR #980](https://github.com/DaveKJohn/claude-code-specialists/pull/980) (August 27, 2026): `lint-en-tests`
took **11m48s**, while the same suites had run locally minutes earlier in **292s**. Over 65 blocking runs
the CI leg has a median of **8m 01s**, which at 73 merged PRs in a week is **9h 45m** of session time
spent watching a second opinion. Dave, [issue #985](https://github.com/DaveKJohn/claude-code-specialists/issues/985):
*"dit kan gewoon gerust in de achtergrond verder draaien"*.

**One habit comes with it, and it is no longer a condition.** So the session's next move is one of two
things:

- **open the next branch as a lane** — `worktree-lane.ps1 -Name <name>`, the
  [`worktree-lane` skill](../worktree-lane/SKILL.md); or
- **stop.** A close-out that says *"PR #N opened, shipping in the background"* is a finished assignment,
  not an open point — nothing about an in-flight ship needs answering before the session can be closed.

### And stopping now leaves the checkout on the trunk ([#1073](https://github.com/DaveKJohn/claude-code-specialists/issues/1073))

**That second move used to be only half true**, and the missing half is the one the owner reads. The
orchestrator's own body carries two rules about this moment — *"parking is a state, not a promise to come
back within the turn"* and *"it ends on the trunk, which is what makes the session safe to clear"* — and
until step 2b existed a backgrounded ship could not satisfy both. `HEAD` did not move until step 5, after
the CI wait, so at the moment the close-out was written the tree was necessarily still on the branch.
Following the first rule meant breaking the second. Dave, after being handed exactly that session:
*"ik wil pas een sessie sluiten als ik terug op de main branch ben. Dat is voor mij het teken dat de sessie
veilig gesloten kan worden."*

**Step 2b hands the trunk back as soon as the PR exists**, before the wait rather than after it — so the
close-out can say both things at once. It is available because two earlier repairs already landed: since
[#970](https://github.com/DaveKJohn/claude-code-specialists/issues/970) both merge gates read
`refs/heads/<branch>` rather than the working copy, and since
[#972](https://github.com/DaveKJohn/claude-code-specialists/issues/972) step 5 reads `HEAD` before it moves
anything. Read together they say something neither one set out to: **nothing after step 2 reads the content
of the working tree.** Step 3 is `gh` over the network, step 4 is the ref plus `gh`, and step 5 folds
wherever `HEAD` already is — `main` being one of the two arms it has had all along.

**Three conditions, and it is never a refusal.** A tree that cannot go home stays where it is, says which
of the three it was, and the ship carries on:

| condition | why, and what skipping it costs |
|---|---|
| **the primary checkout only** | a lane taking the trunk here would hold the clone-wide lock of [#1069](https://github.com/DaveKJohn/claude-code-specialists/issues/1069) for the whole CI wait instead of for the length of a fold — worse than the defect that repair closed. A lane goes home at step 5b instead |
| **nobody else holds the trunk** | git allows one worktree per branch, so the checkout would simply fail. Asked rather than attempted, because failing here is free |
| **a clean tree** | #972's two outcomes met one step earlier: a colliding edit makes the checkout exit 1, and a non-colliding one **travels to the trunk**. The branch's own work is committed and pushed by step 1, so anything left here is something else |

**One thing it buys that was not the point.** A concurrent lane-ship that would have collided with the
primary's step 5 — the narrow window step 0 cannot cover — now meets step 0's own refusal instead, because
the primary takes the trunk before the wait rather than after it. A post-merge half-state becomes a
pre-push refusal, which is the trade step 0 was written for.

The decision itself is `Get-TrunkReturnDecision` in `worktree-lib.ps1`, a pure function of the porcelain
plus `git status --porcelain`, so it is asserted in `worktree-lib.tests.ps1` rather than only exercised by
a live ship.


**Working in the primary anyway used to cost you your checkout, and no longer does.** Step 5 ran
`git checkout main` in the tree the script was started from, unconditionally, one line after the merge.
Measured on git 2.54.0.windows.1 for
[#972](https://github.com/DaveKJohn/claude-code-specialists/issues/972), that had exactly two outcomes:

| the tree when the merge lands | `git checkout main` |
|---|---|
| an uncommitted edit that collides with the trunk | **exit 1** — `"Your local changes ... would be overwritten by checkout"`. The run stops between the merge and the fold: PR merged, branch document still in the tree, every gate green until a release trips over it |
| an uncommitted edit that does not collide | **exit 0** — `HEAD` moves to the trunk **and the uncommitted work travels with it**, so the session carries on editing on `main` with its own work already sitting there |

Step 5 now reads `HEAD` first. Still on the shipping branch, or already on the trunk: it runs exactly what
it always ran. Anywhere else: it leaves your checkout alone and folds in a throwaway `git worktree` on the
trunk instead, then takes it down again. The lane is still the better move — it is where you build, and it
keeps one tree doing one thing — but forgetting it now costs a temporary directory rather than your work.

### And a lane no longer holds the trunk hostage ([#1069](https://github.com/DaveKJohn/claude-code-specialists/issues/1069))

git allows **one worktree per branch**, so a tree standing on the trunk locks it for the whole clone.
That is the other half of the same line: step 5 checks the trunk out *in the tree it runs in*, and in
the primary checkout that is deliberate — a finished chain ends on the trunk, which is what makes the
session safe to clear. In a lane it meant the lane held the trunk for **every later chain on the
machine**, nothing warned, and the bill was paid by an unrelated branch after *its* merge had landed.
Measured on PR #1068: merged, unfolded, changelog still pending.

Three answers, and the order is the point:

| when | what happens |
|---|---|
| **before step 1** (step 0) | another worktree holds the trunk → **refuse**, naming that directory and the two commands that release it. Nothing is gated, pushed or merged yet, so this is the one place where stopping is free |
| **at step 5**, in-place arm | the narrow window step 0 cannot cover — another session took the trunk while CI was being watched. It now prints the same hand-fold instruction the worktree arm always had, including the `-RepoRoot` call that folds from the tree that *does* hold it |
| **after the fold** (step 5b) | a tree that is **not** the primary checkout returns to its own branch, releasing the lock. Only after a *successful* fold: a failed one leaves you standing on the trunk, which is where a hand repair happens |

**Nothing takes the trunk away from anybody.** The holder may be a lane with work in it, and this script
does not know what — so both arms name the directory rather than acting on it. Handing a finished lane
back is still `worktree-lane.ps1 -HandBack`, and it is still the better move than relying on step 5b.

`prune-merged.ps1` was unavailable in exactly this state too, which mattered because it is the script a
session is told to run *instead of* hand-reading `git ls-remote`. It **runs** in this state now
([#1147](https://github.com/DaveKJohn/claude-code-specialists/issues/1147)): it advances the trunk with a
refspec fetch rather than a checkout, so a held trunk costs it the fast-forward and nothing else — and the
warning still names the worktree holding it instead of relaying git's message.

**What this deliberately is not.** Two larger shapes were named and declined when the default was written
down. A *green-and-unmerged reporter* at session start would re-add half of a status reporter the source
repo had removed on purpose five minutes before #985 was filed. A *detached watcher* that merges when the
check passes would put the merge and the fold — a commit that lands directly on the trunk under a named
exception — behind a process nobody is reading. Neither is ruled out forever; both need designing rather
than adopting, and #985 stays open as their home.

**Backgrounding tells you nothing while it runs, and that is normal.** The output is buffered, so an empty
log and an idle `gh` child are not evidence of a stall. Judge progress from `git log` and `gh pr view`, never
from the log file.

## Why step 3 polls before it watches

`gh pr checks` prints `no checks reported` **and exits 0** while no check has registered yet — which is
indistinguishable by exit code from "everything passed". A bare `--watch` right after the push can
therefore return immediately, and the merge below then runs straight into a `BLOCKED` wall from branch
protection.

So step 3 first polls the *text* until at least one check is registered (up to 180 seconds), and only
then watches it. A non-zero exit from the watch means **not merged** — the script stops rather than
retrying, because branch protection would block it anyway and forcing past a red CI is exactly what
this chain must not do.

**It deliberately does not name a check.** Step 3 watches whatever checks the PR has and reads the exit
code. Naming one here would be a claim about the consumer's CI that this script cannot keep — and it
was the half of the "this is too repo-specific to share" argument that did not survive being read.

### A repo with no required check at all

**A private repository on the GitHub Free plan cannot have branch protection**, so it can have no
required check — and that is the shape most new repos start in. Nothing here needs configuring for it,
and two behaviours are worth knowing rather than deducing ([inbound
#1083](https://github.com/DaveKJohn/claude-code-specialists/issues/1083)):

- **the wait works unchanged**, because step 3 watches every check the PR has rather than a named or
  required one;
- **the merge verdict refuses on a red check rather than proceeding.** With nothing required,
  `gh pr checks --required` exits non-zero, and *"this repo requires nothing"* is indistinguishable from
  *"the required checks have not reported yet"* — so the verdict blocks. The repo without a ruleset is
  guarded conservatively rather than left open.

**The wait report is not where you learn whether a ruleset exists.** With nothing required it simply
omits the required/not-required label and prints the rest of the line. The fallback —
`waited 2s -- no readable check facts, so nothing to report about the wait` — means something else
entirely: gh answered nothing, or no check in the payload carried a readable completion time. It used to
read *"which check governed could not be read"*, which was reported from a fresh repo as sounding like a
fault; it is a statement about the payload, and never about the ruleset.

### When the required check never appears at all

After 180 seconds step 3 gives up and says so, without merging. That timeout usually means CI is slow —
but it also covers a real failure mode worth recognizing, because the remedy is counter-intuitive:
**the forge sometimes simply fails to fire a run** on the `pull_request opened` event. The tell is a
merge that stays blocked with **no check rollup on the PR at all** while minutes pass. It is a
platform-side hiccup rather than a repo error, and it has been observed with an unrelated PR
triggering normally moments before.

**Confirm there is no run before you retrigger.** A very late run and an absent run look identical on
the PR page, and retriggering a late one creates the second problem below. Ask the API for the head
SHA directly — a total of `0` rules out a run, and also rules out being fooled by an unrelated check
suite from another integration that shows up without being the check the branch is waiting on:

```powershell
gh api "repos/<owner>/<repo>/actions/runs?head_sha=<sha>" -q '.total_count'
```

**Then close and immediately reopen the PR.** The `reopened` event fires a fresh run. Pushing an empty
commit also retriggers CI, but close/reopen is preferred: it keeps the branch history free of noise
commits.

```powershell
gh pr close <branch>; gh pr reopen <branch>
```

**If you retriggered and the original then shows up anyway, expect two runs briefly.** The reopen-run
finishes first and goes green while the late original is still in progress — and during that window the
merge state can drop back to `BLOCKED`, with the merge refused for a base-branch policy. Wait for both
to go green, then merge normally. **Never reach for `--admin` here.** That bypasses the gate the check
exists for, and a forge suggesting it in its own error text does not make it the fix.

## The merge method is repo policy

`gh pr merge` runs with `--merge` by default. A consumer that squashes or rebases declares that in
`Get-PrMergeMethod` in its own `scripts/repo-config.ps1`; the function is optional, so a repo that
never thought about it gets `merge`.

**The merge commit is named `merge: <branch> (#NN)`**, rather than GitHub's default
`Merge pull request #NN from Owner/branch`. That default is the one line in the graph with no type in
front of it, while everything around it has one — `feat:`, `fix:`, `docs:`, `fold:`, `release:` — so a
history scan has to read two shapes instead of one. It also pairs the merge with the fold commit that
follows it (`fold: <branch> changelog (#NN)`). Passed as `--subject`; a repo that squashes or
rebases has no merge commit for it to name, and `gh` ignores it there.

**The fold was typed `chore:` until August 10, 2026**, and the rename is worth knowing about if you
scan your own history: folding is a named act with its own script and its own exception to
"never commit directly", while `chore` said only "housekeeping". Nothing reads the subject, so every
`chore: fold ...` already in your log stays exactly as valid as it was — there is nothing to migrate.

The value is **validated before use** — anything other than `merge`, `squash` or `rebase` stops the
script with a named error. An unrecognized value would otherwise reach `gh` as an unknown flag at the
one moment this script is about to write to the main branch, which is the worst possible place to
discover a typo in a config file.

**There is no `--admin`, and that is not an omission.** Bypassing the CI gate is the thing this chain
exists to make unnecessary.

## Why the fold is delegated rather than inlined

Step 5 hands the fold, its commit **and** its push to `fold-changelog-entry.ps1 -Push`. That delegation
is the point, not a tidy-up.

This step used to run its own `git add -A` plus `git commit`. `git add -A` stages the **whole tree**, so
anything else modified or already staged rode along into a commit that lands **directly on the main
branch** under one of the two named exceptions to "never commit directly". The fold script instead
commits with an explicit pathspec — the changelog, the entries it actually folded, and any legacy step list
it removed beside them — and nothing else can enter however messy the tree is.

**An exception is only safe while it stays the size it was granted at.** The workshop's own governance
doc had stated since August 2, 2026 that the fold commit "names its paths, so nothing else in the tree
can ride along" — true of the fold script, false of this orchestrator, which is the more commonly used
route of the two. Repaired here rather than in the doc.

The fast-forward before it is an **explicit** `git fetch --prune` plus `git merge --ff-only origin/main`,
not a bare `git pull --ff-only`. The bare pull aborted with *"Cannot fast-forward to multiple branches"*
on a clean main immediately after a merge and prune — and it aborts in the one gap between the merge and
the fold, which is the state nothing reports: the PR is merged, the entry file is still in the root, and
every gate stays green until a release trips over it. Git raises that when handed more than one ref;
naming `origin/main` explicitly hands it exactly one.

## Step 6 on its own: repairing bookkeeping after the fact

Step 6 is **`verify-resolved-issues.ps1`**, mirrored alongside this script because a consumer whose
`ship-pr` called a file that was not in the mirror would fail at the last step of a sequence that has
already merged.

**A plain `#332` in a PR body closes nothing** — GitHub only auto-closes on a closing keyword. `open-pr`
writes those keyword lines; this step checks the **outcome**, and closes what stayed open. A belt on top
of a brace: if it never fires, the keyword did its job. It **cannot fail the ship** — the merge has
already happened by then, so a problem here is a warning, not a failure.

It is also usable on its own, which is what it was needed for on August 1, 2026, when eight findings
repaired by three PRs had stayed open because those bodies carried plain mentions instead of keywords:

```powershell
# report what a merged PR declared, and close what is still open
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/verify-resolved-issues.ps1" -Pr 343

# report only, change nothing
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/verify-resolved-issues.ps1" -Pr 343 -ReportOnly
```

| Parameter | What it does |
|---|---|
| `-Pr` | **Required.** The (merged) PR number to verify. |
| `-ReportOnly` | Report the state of each declared issue without closing anything. |
| `-Repo` | `owner/name`. Defaults to `Get-RepoName` from the consumer's `scripts/repo-config.ps1`. |

Two design decisions worth knowing, because both look like bugs until you know them:

- **It reads the issue numbers back out of the merged PR body** rather than taking them as a parameter,
  so the verification is against what the PR actually declared. A second tally would be a second thing
  to drift from the first.
- **A closing keyword inside backticks is ignored**, because GitHub does not link a reference inside a
  code span either — so it closes nothing there. That is what makes it possible to write a document
  explaining this gate without the gate acting on the document.

## Requirements in the consumer

The script is repo-agnostic, but reads its repo data from the **root** of the consumer (dual-context via
`${CLAUDE_PROJECT_DIR}`):

- `scripts/repo-config.ps1` with `Get-RepoName` (the `gh --repo` target), and optionally
  `Get-PrMergeMethod`. `Get-RepoName` is hard-required: without it every `gh` call below would target
  the wrong repo or none at all, so the script stops with a pointer instead of a raw dot-source error.
- Everything `open-pr` and `fold-changelog` need in turn — `scripts/lib/branch-info.ps1`,
  `scripts/tests/*.tests.ps1`, `.github/pull_request_template.md`, and a `CHANGELOG.md` carrying the
  configured heading.
- `git` and a logged-in `gh` CLI.

The `specialists-init` bootstrap puts `repo-config.ps1` in place as a `VUL-IN` scaffold; fill it in
before you use this skill.

## Important

- **Re-running it on a branch that already shipped is safe, and says so.** Step 1 stops on a merged PR
  and step 2 recognises the same state for itself, so the run ends `PR #N for '<branch>' is already
  merged -- nothing to ship` on exit 0 rather than on an error naming `gh` authentication ([inbound
  #1077](https://github.com/DaveKJohn/claude-code-specialists/issues/1077)). The local branch survives a
  merge — `--delete-branch-on-merge` removes the remote one only — so this is exactly what a second
  session, an interrupted wait, or a `git checkout <branch>` out of habit sets up. And the *fold* refuses
  a second entry for a branch the changelog already carries, which is the other half of the same route
  ([#1082](https://github.com/DaveKJohn/claude-code-specialists/issues/1082)).
- **Do not redirect this script's stderr.** It runs `open-pr.ps1` as a child process on purpose, and
  under Windows PowerShell 5.1 a `2>&1` on the parent turns every stderr line the child writes into a
  `NativeCommandError` record — which collapses the output to a truncated path fragment and hides the
  one line you need. The child's stderr is normal output here; leave it alone and read it as it comes.
  Two runs were spent on this before the real message was seen.
- **Known test gap, stated rather than implied.** Like `open-pr`, this orchestrator drives live `git`
  and `gh` against a real remote and is not covered by an automated suite. The sub-steps it calls are
  each tested on their own — step 6 was extracted into its own script for exactly that reason, being the
  one step that mutates state *outside* the repo (it comments and closes). What remains untested here is
  only the orchestration order.
- **If it fails between the merge and the fold, do not re-run it blindly.** The PR is already merged at
  that point; the fold's own output says whether the entry file was removed. Re-running a fold that
  already deleted the entry is a different problem from the one you had.
- This script is maintained in the source repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/release/ship-pr.ps1`) and then travels via a release to the
  plugin mirror — guarded by the shared-scripts drift lint.
