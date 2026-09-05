## feat/plugin-policy-precedence

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### Why this branch exists

Dave: a consuming repo's root `CLAUDE.md` must never contradict the policy shipped by an installed
plugin. Fixed precedence when both are installed: `contributing-davekjohn` outranks `bwj-codex`, which
outranks the consumer's own root `CLAUDE.md`. A consumer's only choice is to install and follow, or not
install and run its own policy -- never a blend. A new on-demand, report-only skill (pattern:
`adopt-config`/`check-branch-entry`, not a SessionStart gate) scans a consumer repo for contradictions
against the installed plugins' portable policy and states which side wins; it never edits the
consumer's file itself.

#### What the plan assumed, and what the tree already had

Step 1 below was written as if the precedence rule were unstated. It is not: **"A third rank sits above
both, and nothing named it until inbound #1379"** landed on `main` on September 4, 2026 (`6a110262`),
one day before this branch was cut, and it states the order, its scope, the corollary that keeps it and
the two narrow greps that enforce slices of it. Checked before writing anything, on the rule that a
briefing is a pointer and the repo is the answer. So step 1 was **not** rewritten -- what it turned into
is the one thing that section genuinely did not answer, and could not have: with a **second** workflow
plugin now installed beside it, the top rung has an internal order and the diagram was silent on it.

#### Two sessions built this branch, and the merge is a reconciliation

A second session (git identity `DaveKJohn`, a different Windows profile) built the same three
deliverables independently and parked them at 11:32 as `952e676e`, *"all outstanding work"*. Neither
session knew: the branch was already parked when both started, `git status` shows no divergence before a
fetch, and there is no issue to have claimed. It surfaced at `git push`, after both had run the full
gates. Filed as
[#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439) -- the remote head of a
parked branch is a duplicate signal nothing reads, and it is the case
[#1409](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1409) closed with *"nothing here
addresses that, and it may not be addressable."*

**Dave's call: reconcile, not discard.** So this branch carries both, and the merge commit is where the
choice per file is recorded:

| | kept | from |
|---|---|---|
| `## Precedence -- full adoption, or none` | the whole section | the other session -- it is the PLAN's literal ask and says something genuinely new: the choice is binary, one ship one captain |
| the top rung's internal order | the two paragraphs under the rank diagram | this session |
| `WORKFLOW-portable.md` | one paragraph naming its rung and linking **both** anchors | merged from the two |
| `check-policy-drift.ps1` | this session's, plus the other's install-record resolution and its `Test-PluginInstalledHere` report | both |
| the registry entry, the skill page, the suite | this session's | this session |

The one substantive thing taken from the other implementation is its **resolver**, and it is the better
answer: `Resolve-PluginDir` cannot be reused here because it requires an `agents/` directory at every
return path, so on a workflow plugin it returns `$null` on every machine, always. The other session
restated its three steps with the marker file as a parameter; this branch does the same, keeps its own
two extra probes either side, and adds the enable-versus-install-record distinction (#302) that this
session's version did not have at all.

### CREATE

- [x] Tessa: the precedence rule in `contributing-davekjohn/CONTRIBUTING-portable.md`. **Already stated**
      (see the note above), so the edit is the gap rather than a restatement: two paragraphs after the
      three-rank diagram giving the **top rung its own internal order** -- `contributing-davekjohn`
      legislates the cycle, a companion workflow plugin extends one step of it, and where two plugin
      pages speak to the same question this plugin's page wins and the companion's is an extension,
      never an override. Still three ranks and not four, deliberately: the sub-order sits *inside*
      rank 1. Plus the corollary applied one layer up -- a companion names its own rung and points back
      here, and does not copy the block.
- [x] Tessa: a cross-reference in `bwj-codex/WORKFLOW-portable.md` naming its own second place in that
      order (behind `contributing-davekjohn`, ahead of the consumer's always-on documents), pointing at
      the canonical statement rather than restating it. Placed directly under that page's existing
      *"a layer on top of `contributing-davekjohn`"* paragraph, which is the sentence it sharpens: that
      phrase was a figure of speech and is now a rank.
- [x] Sylvester: `check-policy-drift` -- a `SKILL.md` in the plugin plus
      `scripts/task/check-policy-drift.ps1` (root canonical, mirrored), registered in
      `Get-SharedScriptPairs` with its documenting skill. On-demand and report-only, in `adopt-config`'s
      shape rather than a gate's: it prints rank 1 (the `*-portable.md` pages of every plugin **enabled**
      here, `contributing-davekjohn` first), rank 2 (`contributing-davekjohn/`) and rank 3 (the always-on
      closure), echoes the two already-gated slices, and hands the judgement over. It exits 0 with
      findings on screen, because the verdict is the session's.
      **Three decisions worth a reader's time:** the plugin side is **discovered** (any enabled plugin
      carrying a portable page) rather than naming `bwj-codex` by hand; the consumer side is the #1380
      corpus via `Get-ConsumerProseDocuments`, not a second list; and the two echoed slices **skip the
      repo that publishes the workflow exactly as their own entry scripts do** -- the detector functions
      carry no such skip, so calling them straight printed two findings here under a heading claiming a
      hook covers it, two lines from where that hook prints `[OK]`. Caught on the first run of the script.
- [x] Roster/lint sanity: `check-plugin-integrity.ps1` and the full suite, locally, before review.

### TEST

- [x] `check-plugin-integrity.ps1` -- **0 errors**. It caught three real omissions on the first run
      (`check-policy-drift` missing from both `skills:all` spans in `README.md` and from the
      `skills:plugin` table in the plugin `README.md`); all three added, then green.
- [x] New suite `scripts/tests/policy-drift-report.tests.ps1` -- **22 asserts, all passing**. It pins the
      three things that are actually decisions rather than the prose: that the script **never refuses**
      (exit 0 on an empty tree and on a tree with findings), the **rank-1 order** (a fixture where the
      companion sorts first alphabetically, so a plain `Sort-Object` would fail it), and the
      **source-repo skip in both directions**. Plus the registration, the mirror being byte-identical,
      and the rank 2 / rank 3 split at the workflow folder.
- [x] Full gate via `open-pr.ps1 -GatesOnly` -- lint green and **all 69 suites passed in 365s**.
- [~] No live consumer run, and it is stated rather than glossed. `bwj-codex` is not enabled in this
      repo, so the companion path is exercised by a fixture instead of against an install. The fixture
      builds the shape the resolver actually probes -- `.claude-plugin/plugin.json` plus a portable page,
      declared by a marketplace and enabled in `.claude/settings.json` -- which is what makes it evidence
      rather than a stand-in.

### DEPLOY: feat/plugin-policy-precedence

`contributing-davekjohn` gains **`check-policy-drift`**, an on-demand, report-only skill that lays every
document legislating in a repo out in rank order -- the installed plugins' portable pages, then
`contributing-davekjohn/`, then the always-on `CLAUDE.md` closure -- so a session can read them against
each other and report contradictions. It decides nothing and edits nothing: the judgement is handed over,
which is exactly the half [#1380](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1380)
declined to give a script. Alongside it, `CONTRIBUTING-portable.md` gains a new
**"Precedence -- full adoption, or none"** section ahead of the cycle -- installing this plugin is not a
customisation laid beside a repo's own `CLAUDE.md`, it is a policy that outranks it, and the choice is
binary -- plus, in the rank-order section further down, the **top rung's own internal order** now that a
second workflow plugin exists. `bwj-codex/WORKFLOW-portable.md` names its rung and links both.

**Score:** 2 -- one new skill plus its script, mirror and 22-assert suite, and two sections of shared
prose. Nothing existing changes behaviour and no gate moves; the rank order it reports was already the
rule, and the new section states in one place what the detail further down already worked out.

#### What makes this deploy extra special

A repo running this workflow can now ask, in one command, whether its own `CLAUDE.md` has quietly
started restating rules the plugin owns -- the failure mode behind
[#1378](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1378), where a consumer's
constitution documented push-then-cut while `cut-release` fixed cut-then-push, and the disagreement read
as a constitution exercising supremacy rather than as drift. Until now two narrow greps covered a
filename and one inverted sentence; everything else was invisible from both ends, since a repo reads its
own page and follows it while the source never reads that page at all. Report-only by design: the repair
stays an ordinary branch + PR in the repo that owns the file.

**Score:** 2 -- opt-in and additive. A consumer that never invokes the skill sees no change, and the
script writes nothing, needs no token and reaches no network.

#### Pull Request

Plugin policy outranks a consumer's root CLAUDE.md
