# Development cycle: `feat/rename-workflow-to-contributing-davekjohn-v1` · 20260825-151315

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `##` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `###` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `## PLAN`** -- everything between the H1 and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `###`
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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

## PLAN

### Where this stands (August 26, 2026)

**CREATE is RUNNING.** Dave gave the go on August 26, 2026, after the seven open issues were triaged and
#892 closed as not reproducible. **The deletion blocker #896 filed is GONE:** `rm` was probed against a
throwaway file in this checkout and succeeded, so that guardrail belonged to the reporting session rather
than to this repo -- an inferred constraint verified before being obeyed.

### Where this stands (August 25, 2026, late)

**The sequencing is CLEAR: all three branches this one waited on have landed.** #882 as
[#889](https://github.com/DaveKJohn/claude-code-specialists/pull/889), #885 as
[#890](https://github.com/DaveKJohn/claude-code-specialists/pull/890), and #884 as
[#895](https://github.com/DaveKJohn/claude-code-specialists/pull/895). This branch has been merged up to
`main` at `a8331dd7`, so CREATE would now only ever touch settled ground -- which is exactly the condition
decision E set.

**And one thing the PLAN below left open is settled by re-reading the issue rather than by asking.** The
PLAN never said whether the ROOT FOLDER `contributing-davekjohn/` renames along with the plugin, and it
matters more than the plugin id does: that path is baked into `Get-BranchFilePaths`, the seams,
`adopt-workflow-folder`, CI, every consumer's tree, and -- load-bearing -- **the bound on the fold's
direct-on-`main` exception in the root `CLAUDE.md`**. #886's own text answers it: *"The CLAUDE.md in the
**contributing-davekjohn (now contributing-davekjohn)** folder"*, and *"contributing-davekjohn will have his
own folder"*. The folder renames. Recorded here because a session that only reads this PLAN would have
had to guess.

**Re-measured against `main` today, because the PLAN's figures were taken at `459bf667` and three merges
have landed since:** `contributing-davekjohn` occurs in **147** tracked files (was 150 -- the prompts removal
took three), `workflow-default` in **33** (was 32). Neither number changes the shape of the job.

**BLOCKED, and not on a decision.** CREATE's first act is a deletion -- `workflow-default` is to be
REMOVED rather than renamed (the issue is explicit), and decision C retires the exclusivity guard with it:
`plugins/workflows/workflow-default/` (5 files), `plugins/teams/team-alpha/hooks/workflow-sessioncheck.ps1`,
and the two suites that exist only to test them (`workflow-exclusivity.tests.ps1`,
`discover-workflow.tests.ps1`). **The session's auto-mode guardrail refuses file deletion**, so that step
cannot be taken without Dave present to allow it. Nothing was half-done: the tree is clean and all eight
files are intact.

**Verified before stopping, so the removal is ready to run the moment it is allowed:** no consumer enables
`workflow-default`. All four connector records (`claude-code-specialists`, `djcylow-react`,
`smartwatchbanden`, `xoxowildhearts`) and this repo's own `.claude/settings.json` list
`contributing-davekjohn` only. That re-confirms the PLAN's research against today's tree.

**What the removal drags with it, mapped so the next session does not rediscover it.** The
`[plugin-kind]` lint check (`check-plugin-integrity.ps1`) justifies its whole rule by
`workflow-sessioncheck` counting enabled plugins by the `workflow-` prefix -- retire that hook and the
justification is gone, and rename the plugin off the prefix and the rule FAILS. It has to be restated in
the same movement, not afterwards. `shared-scripts-lib.ps1` carries a `check-report-lib-default` registry
entry pointing into the deleted plugin. `plugins/teams/team-alpha/hooks/hooks.json` registers the hook.
And `.claude/specialists/SPECIALISTS.md` names it in the always-loaded chain, so it is a token cost paid by
every session until it goes.

**Suggested order when this resumes**, gates between each: (1) remove `workflow-default` + retire the
guard; (2) rename the plugin id and its directory, restating `[plugin-kind]`; (3) rename the root folder,
which includes editing a safety-rule bound in the root `CLAUDE.md` and is the step to slow down on;
(4) merge this folder's `CLAUDE.md` into its `CONTRIBUTING.md`.

### The ask, and what research already answered

**The ask ([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886), Dave).** Three
things, all inside one branch because they are one decision read three ways:

1. **Rename the plugin to what it does.** `contributing-davekjohn` is not a workflow among several — it is
   Dave's own contributing rules, packaged as an opt-in for his own repos. `contributing-davekjohn` says
   that; `contributing-davekjohn` says "a way of working" and invites the false symmetry with
   `workflow-default`.
2. **Remove `workflow-default` rather than rename it.** There is no default *contributing* — a consumer
   already has its own contributing by default, before any plugin is installed. Renaming it to
   `contributing-default` would keep asserting a thing that does not exist; removing it is the honest
   move Dave already made in the issue text, not a choice this branch reopens.
3. **Merge `contributing-davekjohn/CLAUDE.md` into `contributing-davekjohn/CONTRIBUTING.md`**, one file instead
   of two, because `CONTRIBUTING.md` is what this folder is actually for once it stops pretending to be a
   workflow among several.

**Scope survey, so CREATE is sized against the real subject and not a guess.** `contributing-davekjohn`
occurs in **150** tracked files, `workflow-default` in **32** — grep counts taken on this branch's base
(`main` @ 459bf667), not yet triaged into what actually needs an edit vs. what is a historical mention
that must NOT move (see Non-goals). That triage is CREATE's first job, not PLAN's; the number is here so
nobody scopes this as a small rename.

**What research already answered, so CREATE does not re-derive it:**
- **No registered consumer has `workflow-default` enabled.** Checked all three connector records
  (`smartwatchbanden`, `xoxowildhearts`, `djcylow-react`) and this repo's own
  `.claude/settings.json` — every one of them runs `contributing-davekjohn` only, none `workflow-default`.
  Removing it breaks no registered install. The repo is public, so an unregistered third party could in
  principle have it enabled — Dave's own reasoning in the issue ("not expected to have other people...
  install the plugin") already accepts that risk; this branch does not need to re-litigate it.
- **All three external consumers, plus this repo, currently have `contributing-davekjohn@claude-code-specialists: true`.**
  A plugin *id* rename is a breaking change for every one of them at their next marketplace refresh — see
  open decision B below.
- **The "exactly one workflow" guard (`workflow-sessioncheck`, lives in `team-alpha`'s hooks per
  `plugins/workflows/README.md`) counts enabled plugin ids starting with `workflow-`.** Once
  `workflow-default` is gone and the remaining plugin is renamed off that prefix, this hook's whole
  reason for existing may be gone too — see open decision C.

**Non-goals, recorded so CREATE does not sweep them in:**
- **Historical mentions stay as written.** `CHANGELOG.md`, every `releases/development/**` and
  `releases/audience/**` note, and folded PRs are published records of what was true when they were
  written (the doctrine `contributing-davekjohn/CLAUDE.md` itself states for `releases/audience/`, applied
  here to the plugin's own name). They are not rewritten to say `contributing-davekjohn` after the fact.
- **`DEVELOPMENT-CYCLE-portable.md` and `RELEASES-portable.md` are not merged into anything.** The issue
  names only `CLAUDE.md` + `CONTRIBUTING.md`; those two stay separate portable pages.
- **The root `CLAUDE.md` / `CONTRIBUTING.md` split (repo-wide, not this folder's) is untouched.** It is
  the split the folder's own pages mirror, not the reverse — collapsing the folder's mirror does not
  imply collapsing the original. Root pages only need the sentences that cite the folder's split as a
  worked example rewritten (they currently point at `contributing-davekjohn/CLAUDE.md` in at least 4 places).
- **`.github/workflows/ci.yml`'s job id `lint-en-tests` is never touched.** Unrelated string, already
  called out by name in `.claude/rules/language-layers.md` as a binding to the `main` ruleset — a rename
  here would silently unmerge every future PR. Named so nobody's find-and-replace catches it by accident.
- **`development-cycle.md` keeps its name, and so does "development cycle" as a concept — Dave reversed
  himself on this explicitly (August 25, 2026), after first not objecting to it.** The rename is of the
  *plugin*, not of this document or the phase model (PLAN/CREATE/TEST/DEPLOY) it carries. `contributing-cycle.md`
  is NOT the target filename anywhere this branch touches — not the file this branch itself is writing in
  right now, not `DEVELOPMENT-CYCLE-portable.md`'s own name, not `Get-BranchFilePaths`' path constant, not
  any doc that names the file. A future find-and-replace across the 150-file survey must skip every
  occurrence of "development cycle" / "development-cycle.md" — those are not instances of the plugin's old
  name, they are the document's own name and stay exactly as written.

**Relationship to `feat/isolate-workflow-from-consumer-root-v1`, parked (Derek stashed its uncommitted
CREATE checklist before opening this branch; nothing lost, nothing committed there).** That branch is
mid-flight hardening the *same folder's* seam under the *current* name — `Get-ChangelogPath`,
`Get-ReleaseHistoryPath`, the provenance allowlist, all written against `contributing-davekjohn/...` paths.
Landing this rename first would make that branch's whole CREATE checklist stale before it is ever
resumed (wrong paths, wrong function names to grep for); landing the isolation branch first means this
rename's own CREATE has to move the seam's paths too, on top of the plain rename. **Open decision E**
below is which order Dave wants.

**Open decisions — for Dave, before CREATE is scoped:**

- **A. Does `plugins/workflows/` stay as the directory name?** Assumption unless told otherwise: yes —
  the issue asks to rename the *plugin*, not the category folder, and renaming both in one branch doubles
  an already-large diff. Lint check 23 (`[plugin-kind]`, `check-plugin-integrity.ps1`) currently pairs the
  `workflow-` id prefix with living under `plugins/workflows/`; if the id drops that prefix, this check's
  rule needs restating regardless of A's answer.

  
  Dave's answer: Yes, keep plugins/workflows/

  
- **B. Migration path for the 3 registered consumers + this repo, all on `contributing-davekjohn@claude-code-specialists: true` today.**
  A marketplace rename makes that id resolve to nothing at their next `claude plugin marketplace update`.
  Options: (i) accept the breakage, follow up with a manual PR per consumer repo — Dave owns all four
  checkouts, so this is small in absolute terms; (ii) a temporary alias/shim plugin id that points at the
  new one; (iii) something else. No CREATE work starts on this until Dave picks.

  Dave's answer: Option 1. I accept the breakage. I'm the only consumer so I it's something I can fix easily myself.

  
- **C. Retire the "exactly one workflow" exclusivity guard, or keep it for a category that (for now) holds
  one plugin?** If retired: `workflow-sessioncheck` (in `team-alpha`), the "At most one, ever" section of
  `plugins/workflows/README.md`, and its test coverage all become dead machinery to remove. If kept: it
  still needs to stop matching on a `workflow-` prefix that will no longer exist.

  Dave's answer: Yes retire workflow completely. 
  
- **E. Sequencing against `feat/isolate-workflow-from-consumer-root-v1`.** ~~Land the isolation branch
  first...~~ **RESOLVED (Dave, August 25, 2026), and widened.** This rename is the last of a four-issue
  set that all edit the same shared libs — see below. Order: **#882 → #885 → #884 → this branch (#886)**,
  each its own branch/PR, so this rename only ever touches settled ground.

  

**The wider picture, found while researching this branch: #886 is one of four open issues that all edit
`contributing-davekjohn`'s shared libs, and running them independently would collide.**

| Order | Issue | Ask | Shares a file with |
|---|---|---|---|
| 1 | [#882](https://github.com/DaveKJohn/claude-code-specialists/issues/882) | Remove `prompts/` entirely — folder, skill, scripts, hook | — (standalone, shrinks the surface for 2–4) |
| 2 | [#885](https://github.com/DaveKJohn/claude-code-specialists/issues/885) | Isolation/provenance — the parked `feat/isolate-workflow-from-consumer-root-v1` branch | `fold-changelog-entry.ps1` (also #884) |
| 3 | [#884](https://github.com/DaveKJohn/claude-code-specialists/issues/884) | DEPLOY heading consistent everywhere + locked once the PR opens | `fold-changelog-entry.ps1` (also #885) |
| 4 | **#886 (this branch)** | Rename + drop `workflow-default` + merge `CLAUDE.md` into `CONTRIBUTING.md` | everything #882/#885/#884 just touched |

**#884 carries a live reversal, confirmed by Dave rather than assumed:** it asks for "What makes this
**deploy** extra special", which is the wording issue **#865** (Aug 24, 2026 — one day before this
research) moved *away from*, back to "PR", specifically because the section also lands in
`CHANGELOG.md` and the release notes where "PR" fits no better. Dave confirmed today (August 25, 2026)
that **#884 wins — "deploy" wording, deliberately reversing #865** — recency was not treated as an
argument against changing it; the reasoning was reread and the call made fresh.

**Decision B (migration for the 4 installs pinned to `contributing-davekjohn@claude-code-specialists`) stays
open** — answer it when this branch resumes, not before; #882/#885/#884 do not touch the plugin id.

Nothing in CREATE starts until A, B, C and the table above have run — #882, #885 and #884 are not yet
branched. This branch stops here per Dave's instruction ("PLAN only for now — do not start CREATE until
Dave says go").

## CREATE


**Four steps, gates between each, in the order #896 set.** Step 3 edits a safety-rule bound and is the
one to slow down on. The triage PLAN left to CREATE is done: the live-vs-historical split is recorded
per step below, and three live references the PLAN never named are in step 1.

### 1. Remove `workflow-default` and retire the exclusivity guard (decision C)

- [x] Delete the plugin: `plugins/workflows/workflow-default/` (5 tracked files)
- [x] Delete the guard hook `plugins/teams/team-alpha/hooks/workflow-sessioncheck.ps1` and deregister it in `plugins/teams/team-alpha/hooks/hooks.json`
- [x] Delete the two suites that exist only to test them: `scripts/tests/workflow-exclusivity.tests.ps1`, `scripts/tests/discover-workflow.tests.ps1`
- [x] Drop the `workflow-default` entry from `.claude-plugin/marketplace.json`
- [x] Drop the `check-report-lib-default` registry entry from `scripts/lib/shared-scripts-lib.ps1` (+ its plugin mirror)
- [x] Restate `[plugin-kind]` in `scripts/lint/check-plugin-integrity.ps1`: its whole rule is justified by `workflow-sessioncheck` counting the `workflow-` prefix, and both halves are going
- [x] Update the lint fixture `scripts/tests/check-plugin-integrity-fixture.ps1` (6 references)
- [x] Rewrite the "At most one, ever" section of `plugins/workflows/README.md` (8 references)
- [x] Drop the hook from the always-loaded chain in `.claude/specialists/SPECIALISTS.md` — a token cost every session pays until it goes
- [x] **Three live references the PLAN did not name.** `scripts/repo-config.ps1` justifies the App exclusion by *both* workflows existing; `scripts/task/push-preview.ps1` claims identical behaviour "on `workflow-default`"; `scripts/release/fold-changelog-entry.ps1` justifies the `fold:` shape by the deleted discovery script. Each is a live justification, not a record — restate all three, plus the `team-shopify` and `contributing-davekjohn` mirrors of the latter two
- [x] Consumer-facing docs: `INSTALL.md` (13), `README.md` (9), `plugins/ADOPTION.md` (4), and Sylvester's lens `05-15-extension.md`
- [x] **Leave alone, verified as records not claims:** `CHANGELOG.md`, every `releases/**` note, and the `notes` field of `connectors/xoxowildhearts.json` — that last one narrates the commits that moved the consumer off `workflow-default` and is a measurement of the past, not a live setting
- [x] Gate: `check-plugin-integrity.ps1` + all suites green -- LINT_EXIT=0, GATE_OK=True, and the two deleted suites are gone from the run without anything else moving

### 1b. The four-heading rule, recorded and filed (Dave, mid-branch)

Dave caught a fifth `##` heading in this document -- `## Where this stands`, written into the parked commit
`e63ee41d` and above `## PLAN`. Repaired by demoting it to a `###` under PLAN. Tested rather than assumed:
`check-branch-entry.ps1` gives BYTE-IDENTICAL output at four headings and at five, so nothing saw it.

- [x] Demote the heading; this document is back to four `##` sections
- [x] Record the rule in `plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md` with the measurement
- [x] State it in the scaffolder preamble (`StepsGuidance`, `scripts/lib/entry-scaffold-lib.ps1`) so every future branch document carries it; mirror regenerated via `build-shared-scripts.ps1`
- [x] File the gate gap as [#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898) -- whether the check should refuse a fifth is Dave's call, not a measurement
- [x] File [#897](https://github.com/DaveKJohn/claude-code-specialists/issues/897): the shared-scripts counts in both `scripts/README.md` pages were stale (42 pairs, not 23; the mirror table nine rows short). **Closed on main by another session the same day**, and it chose the better answer than my correction did: the root page now states **no count at all** and points at the registry. This branch's merge-up then left the two pages on opposite strategies, so the mirror page was brought to the same doctrine -- numbers gone, the incompleteness stated in words, the missing rows still the issue's

### 2. Rename the plugin id and its directory (decisions A + B)

- [x] `plugins/workflows/contributing-davekjohn/` -> `plugins/workflows/contributing-davekjohn/` (62 files, `git mv`), `plugins/workflows/` itself stays (decision A)
- [x] The id in `.claude-plugin/marketplace.json` and the plugin's own `plugin.json`, plus its `displayName` ("DaveKJohn's workflow" -> "DaveKJohn's contributing rules") and a `contributing` keyword
- [x] `[plugin-kind]` now accepts **two prefixes for one kind**: `workflow-*` and `contributing-*` both map to `plugins/workflows/`. The directory names the KIND, the prefix names whose it is. `workflow-*` stays accepted deliberately -- it is what a plugin from anybody else would be called, and refusing it would make this family's rename somebody else's problem
- [x] The 34 `Plugin = '...'` entries in `scripts/lib/shared-scripts-lib.ps1`. Nothing else had to move: the mirror path is composed from the plugin's `source` in `marketplace.json`, so the layout is not stated in that file at all
- [x] This repo's own `.claude/settings.json` -- it consumes itself, so decision B's accepted breakage lands here first
- [x] Sweep of the live layers: the path (forward and backslash forms), the `@claude-code-specialists` id, and the bare prose mentions. `development-cycle` / `development-cycle.md` untouched throughout -- that is the document's own name, not the plugin's
- [x] Gate: `check-plugin-integrity.ps1` + all suites green -- LINT_EXIT=0, all 51 suites passed in 186s, GATE_OK=True

**Five things this step turned up that the plan did not predict.**

**A. A link target is not a mention, and the non-goal only protects the mention.** The non-goal says
historical notes stay as written -- but `[link]` scans `releases/**`, so the rename made 22 links in
published notes dead and the gate red. Measured before deciding: of 29 occurrences of the old path in
history, **22 are link targets and 7 are prose in backticks** ("this file, at that path, shipped with a
BOM"). Link targets updated, all 7 prose mentions left exactly as written. The record is testimony; the
hyperlink is navigation, and a dead one serves nobody.

**B. The connector register must keep the OLD id for the three external consumers.** The sweep changed all
four manifests and that falsified the register: those consumers still have `contributing-davekjohn` enabled in
their own settings, and this register records what a consumer **HAS**. Reverted the three; kept this repo's
own, whose settings this branch did change. `check-connectors.ps1` then confirmed the design in its own
words -- `[INFO] ... is not a plugin this marketplace declares any more -- this consumer has not migrated
to the current names yet. Correct as it stands.`

**C. `Get-TouchedPlugins` sorts alphabetically, and the rename flipped two asserts.**
`contributing-davekjohn` sorted after `team-alpha`; `contributing-davekjohn` sorts before it. Two asserts in
`release-lib.tests.ps1` swapped places without the function changing at all. Kept as index asserts with the
reason written down rather than relaxed into a set comparison -- the ordering IS part of what the function
returns, and a set comparison would have passed through the rename and told nobody.

**D. `adopt-workflow-folder.ps1` is deferred WHOLE to step 3**, deliberately. It carries 6 plugin mentions
alongside its folder ones, but the file's entire subject is the root folder that step 3 renames -- splitting
it across two steps would edit the same prose twice and leave it briefly self-contradictory.

**E. The fixture's loud failure fired exactly as its own comment predicts.** The path sweep changed the
fixture marketplace's `source` and left its `name`, so `Get-SharedScriptPairs` threw on a plugin the
fixture did not declare and killed **four** suites and ~130 asserts at once. The comment above that list
says loud is the design and a silently dropped pair would be worse; it was right.

### 3. Rename the root folder `workflow-davekjohn/` -> `contributing-davekjohn/`

- [x] The folder itself (34 tracked files, `git mv`) -- this document moved with it
- [x] `Get-BranchFilePaths` in `scripts/lib/entry-scaffold-lib.ps1` writes the new path and **reads the old folder too**
- [x] `Resolve-BranchFilePath`'s candidate list extended -- the new fields were data nobody read until the resolver named them
- [x] The isolation guard in `scripts/lib/seam-lib.ps1` (#885) accepts both folder names
- [x] `check-script-contract.ps1` accepts both, and says which one it found
- [x] `Get-MojibakePaths` in `scripts/repo-config.ps1` scans both
- [x] Sweep of 64 files, with 12 deliberately protected (every place that must keep an old-name literal)
- [x] Generated artefacts regenerated rather than edited: the config blueprint. The `skill-cost.json` baseline had its 13 **keys** renamed -- a key is an address, the value plus its `Version` is the record
- [x] History: 39 link targets followed the move, 303 prose mentions left as written -- same rule as step 2
- [x] **The safety-rule bound in the root `CLAUDE.md`** -- verified after the sweep rather than assumed: still *"Bounded to two paths -- `CHANGELOG.md` and `contributing-davekjohn/development-cycle.md`"*. Exactly two, still named, nothing widened. Only the path moved, which is what this step was for
- [x] Gate: `check-plugin-integrity.ps1` + all suites green -- LINT_EXIT=0, all 51 suites passed in 173s, GATE_OK=True

**The compatibility layer is the repo's own precedent, not a new invention.** `Get-BranchFilePaths` already
kept four legacy filenames readable, and the comment above them gives the argument verbatim: *"a location
can be tidied up once, while these files ARE the working state of every branch that exists right now --
here and in every consumer, who meet this change through a plugin update rather than by choosing to."* A
folder rename is the same class of change, so it got the same answer: **seven names read, one written.**

**Two of the three mechanisms would have failed LOUDLY in a consumer, which is why they were not left to
the sweep.** The seam guard refuses with `exit 1`, so allowing only the new name would have turned an
isolation check into a hard stop on every seam call in every unmigrated consumer. `check-script-contract`
is forwarded by a SessionStart hook as `[ERROR]`, so it would have greeted them with "your folder does not
exist" about a folder sitting right there. Neither was a hypothetical: three registered consumers have the
old folder today.

**Verified rather than asserted.** A probe repo containing only `workflow-davekjohn/development-cycle.md`
declaring an open branch resolves to that file; an empty repo sends a writer to
`contributing-davekjohn/development-cycle.md`. The `seam-lib` suite now asserts both folder names pass,
with the old-name asserts kept and labelled as what proves the tolerance.

**Not renamed, deliberately: the `adopt-workflow-folder` skill and script keep their names.** #886 asks to
rename the plugin, drop `workflow-default` and merge two documents; it does not ask to rename skills, and
a skill rename would move a canonical skill name, two `skills:all` spans, the script contract and the
measurement baseline for no gain the issue asked for. The name still describes what it does -- it adopts
the workflow's own folder. Flagged rather than decided.

### 4. Merge the folder's `CLAUDE.md` into its `CONTRIBUTING.md`, in the shape of #894

- [x] One `CONTRIBUTING.md` with the four `##` headers #894 asks for, in its order: NEW DEVELOPMENT ASSIGNMENT, OPEN PR, CUT RELEASE, SHIP MAIN LIVE. `CLAUDE.md` is gone
- [x] Every gate and every exception sits under the step where it **fires**, not in a list of its own -- the four gates under OPEN PR, the fold under 2C/2D, the release commit under 3B-3E, the notes commit under 3F
- [x] Repointed the root pages that cited the folder's `CLAUDE.md`: four links in the root `CLAUDE.md`, the folder `README.md` table, the `[link]` check's own comment, and one historical release note whose link target followed to the successor
- [x] The **consumer** side of the same merge: `adopt-workflow-folder.ps1` scaffolded a folder `CLAUDE.md` beside the `CONTRIBUTING.md`. It now writes one page, with the session rules folded in, and its skill page and docstring tree match
- [x] `DEVELOPMENT-portable.md` and `RELEASES-portable.md` stay separate (non-goal)
- [x] Gate: `check-plugin-integrity.ps1` + all suites green -- LINT_EXIT=0, all 51 suites passed in 196s, GATE_OK=True

**#894's paths do not exist, and Dave chose to document the tree as it is** (August 26, 2026). The issue names
`<folder>/changelog/4.x/`, `<folder>/github/4.x/` and `<folder>/audience/4.x/`; the tree has
`releases/development/` and `releases/github/` at the **repo root** and `releases/audience/` one level deeper
inside the folder. So #894 implies moving two trees, dropping a level from the third and renaming
`development` to `changelog` -- three seams, the cut, the `[consumer-tier]` lint and a `git mv` of 35 notes.
Filed as [#903](https://github.com/DaveKJohn/claude-code-specialists/issues/903) rather than decided here,
with the measurement and three shapes costed. **#894's other rule needed no work at all**: "tier 0 only is a
PATCH, higher is a MINOR" is already `EarnedBump` in `release-lib.ps1` -- the document only had to say so.

**Three root-page statements were stale the moment the two documents became one, and two of them were already
wrong before that.** The root `CLAUDE.md` said the layering "mirrors the one `CONTRIBUTING.md` already makes
over the root `CONTRIBUTING.md`" -- circular once `CONTRIBUTING.md` **is** the page -- and in the same
paragraph promised "the two gates on the branch dossier" and "the two exceptions with their bounds" while the
sections below describe **four** gates and **three** exceptions. Rewritten as one paragraph that says what
actually happened: two pages layering over two root documents, saying the same thing about their own layering
twice, merged into one that layers over both.

**An existing adopter keeps their scaffolded `CLAUDE.md`, and that is stated rather than repaired.** The
scaffold never overwrites, so this change reaches only new adopters -- the "right owner, wrong reach" shape
the technical writer's lens records for PR #734. Nothing breaks while they have it; removing it is theirs to
do. Written into the script beside the merged array, where the next reader of that code will meet it.

**The `adopt-workflow-folder` skill and script keep their names**, as flagged in step 3: #886 asks to rename
the plugin, drop `workflow-default` and merge two documents, and a skill rename would move a canonical skill
name, two `skills:all` spans, the script contract and the measurement baseline for nothing the issue asked
for.

## TEST

- [x] The lint gate and all 51 test suites, run at the end of **each** of the four steps rather than once at the end. Final run: `LINT_EXIT=0`, all 51 suites passed in 196s, `GATE_OK=True`
- [x] `build-shared-scripts.ps1 -Check` green -- every mirror byte-identical to its source after the plugin directory moved
- [x] `build-config-blueprint.ps1` regenerated rather than hand-edited; `check-plugin-integrity.ps1`'s byte-for-byte blueprint check passes
- [x] `check-script-contract.ps1`: 0 errors, and it reports `workflow folder: contributing-davekjohn/ exists`
- [x] `check-connectors.ps1`: the three unmigrated consumers produce the designed `[INFO]` -- *"not a plugin this marketplace declares any more -- this consumer has not migrated to the current names yet. Correct as it stands"* -- rather than an error
- [x] **The consumer-compatibility claims were probed, not asserted.** A throwaway repo containing only `workflow-davekjohn/development-cycle.md` declaring an open branch resolves to that file; an empty repo sends a writer to `contributing-davekjohn/development-cycle.md`. The `seam-lib` suite now asserts both folder names pass, with the old-name asserts kept and relabelled as what proves the tolerance
- [x] **The four-heading rule was measured rather than assumed**: `check-branch-entry.ps1` produces byte-identical output at four `##` headings and at five, which is what made it an issue ([#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898)) instead of a gate
- [~] No new automated test for the `[plugin-kind]` two-prefix rule. Dropped rather than skipped: the existing fixture already drives that check with a `contributing-*` plugin under `plugins/workflows/`, so the new branch is exercised on every run of `check-plugin-integrity-*.tests.ps1` -- a dedicated assert would restate what the fixture proves

**What the suites caught that a review would not have.** `Get-TouchedPlugins` sorts alphabetically, so
`contributing-davekjohn` moved ahead of `team-alpha` where `workflow-davekjohn` sat behind it, and two index
asserts in `release-lib.tests.ps1` swapped places without the function changing at all. And the lint fixture's
own loud failure fired exactly as its comment predicts: the path sweep changed its marketplace `source` and
left its `name`, so `Get-SharedScriptPairs` threw on an undeclared plugin and took **four** suites and ~130
asserts down at once.

## DEPLOY: `feat/rename-workflow-to-contributing-davekjohn-v1`

`workflow-davekjohn` is now `contributing-davekjohn` -- the plugin, its directory, and its root folder in the
repo -- and `workflow-default` is gone along with the "exactly one workflow" guard that only existed because
there were two. The plugin's name now says what it does: it serves one owner's contributing rules, not a
workflow among several. Its folder carries **one** page instead of two, arranged as the four steps work
actually moves through, and the folder's `CLAUDE.md` is merged into it.

**Nothing is renamed without the old name still being read.** That is this repo's own precedent rather than a
new idea: `Get-BranchFilePaths` already kept four legacy filenames readable, on the argument that a consumer
meets a rename through a plugin update rather than by choosing to, and that a half-finished branch must not be
stranded. So seven document names resolve where one is written, both folder names satisfy the isolation guard
and the script-contract check, the bootstrap recognises either plugin id, and the seam defaults prefer whichever
folder actually exists. Two of those would have failed **loudly** in an unmigrated consumer if they had been
swept: the isolation guard refuses with `exit 1`, and the contract check is forwarded by a SessionStart hook as
`[ERROR]`.

**Two rules Dave stated mid-branch are now written down and shipped**, after he caught both by eye in this
branch's own document: `development-cycle.md` has four `##` headings and never a fifth, and nothing
branch-specific sits above `## PLAN`. Neither is enforced by anything -- measured, not assumed -- so both went
into the portable page and into the scaffolder's preamble, where every future branch document in every repo
will carry them. The gate question is [#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898)
and [#899](https://github.com/DaveKJohn/claude-code-specialists/issues/899).

**A record's prose and its links were treated differently, deliberately.** Renaming twice made 61 links in
published release notes dead. Measured before deciding: of 29 occurrences of the old plugin path in history, 22
were link targets and 7 were prose in backticks. The link targets followed the move -- which the folder's own
doctrine explicitly permits -- and every prose mention stayed exactly as written. The same split applied to the
`skill-cost.json` baseline: its 13 keys are addresses and moved, its values and their `Version` fields are the
measurement and did not.

**Score:** 5

### What makes this deploy extra special

**Every consumer of this marketplace has to act, and nothing will tell them so.** Their
`.claude/settings.json` names `workflow-davekjohn@claude-code-specialists`, which resolves to nothing at their
next `claude plugin marketplace update` -- and the hook that would have had an opinion about their workflow
keys is the one this change retired. That breakage is accepted rather than avoided: Dave answered decision B
with *"I accept the breakage. I'm the only consumer so it's something I can fix easily myself."*

What softens it is that **only the install line is urgent.** Everything a consumer already has on disk keeps
working: their `workflow-davekjohn/` folder is still read, their branch documents still resolve, their seams
still pass the isolation guard, and their `CLAUDE.md` in that folder is untouched because the scaffold never
overwrites. So the migration is `claude plugin install contributing-davekjohn@claude-code-specialists --scope
project` plus one settings line, and the folder rename can wait for a quiet moment. This repo consumes itself,
so it is the first consumer to need exactly that -- `check-connectors.ps1` already says so.

**And a `workflow-default` install, if anybody has one, simply stops resolving.** No consumer in the register
had it enabled -- re-verified across all four connector records -- so the measured population of that breakage
is zero.

**Score:** 4

### Pull Request

Rename workflow-davekjohn to contributing-davekjohn, and remove workflow-default
