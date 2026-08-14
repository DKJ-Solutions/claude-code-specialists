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

This is the **plugin mirror** of `ship-pr.ps1`: the same tested source as in the workshop repo,
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
3. **Wait for CI.** See [Why step 3 polls before it watches](#why-step-3-polls-before-it-watches).
4. **Merge** (`gh pr merge`), but first the **step-list gate again**: `workflow-davekjohn/branch/branch-progress.md` must
   have nothing unresolved left in it, or the merge does not happen. Not belt-and-braces — the rule is
   about the *merge*, and step 1's copy of it lives in `open-pr.ps1`, which has a `-Force`. A PR opened
   through that valve, by hand on github.com, or days ago and resumed here would otherwise land with an
   unfinished plan. Checked against the working copy at this moment rather than trusted from step 1, and
   there is no `-Force` for it: `- [~] dropped -- <why>` is the way past a step that should not be done.
   The three marks are in the `open-pr` skill and in [`BRANCH-portable.md`](../../BRANCH-portable.md).
   See [The merge method is repo policy](#the-merge-method-is-repo-policy).
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
commits with an explicit pathspec — the changelog, the entries it actually folded, and the step list it
reset — and nothing else can enter however messy the tree is.

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

- **Known test gap, stated rather than implied.** Like `open-pr`, this orchestrator drives live `git`
  and `gh` against a real remote and is not covered by an automated suite. The sub-steps it calls are
  each tested on their own — step 6 was extracted into its own script for exactly that reason, being the
  one step that mutates state *outside* the repo (it comments and closes). What remains untested here is
  only the orchestration order.
- **If it fails between the merge and the fold, do not re-run it blindly.** The PR is already merged at
  that point; the fold's own output says whether the entry file was removed. Re-running a fold that
  already deleted the entry is a different problem from the one you had.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/release/ship-pr.ps1`) and then travels via a release to the
  plugin mirror — guarded by the shared-scripts drift lint.
