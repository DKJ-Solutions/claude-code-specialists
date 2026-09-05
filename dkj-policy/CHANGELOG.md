# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: docs/1467-rename-workflows-to-dkj-policy · 20260905-224147

`plugins/workflows/` is `plugins/dkj-policy/`, and the prime ministry's own files sit at that root with
`dkj-policy-bwj/` nested inside it as a ministry. That completes the government metaphor #1437 opened:
the directory used to name the KIND -- a way of working -- and now names the government, with the rank
order carried by the tree instead of by a sentence.

The two READMEs that ended up in one folder are one page now. `plugins/dkj-policy/README.md` is the
plugin's own, and it absorbed the consumer-facing halves of the old kind page -- why there is no default
workflow, what enabling and disabling actually mean. The naming and directory doctrine went the other
way, up to `plugins/README.md`, where the same rule for teams already lived.

**The `[plugin-kind]` gate narrowed, deliberately, and that is the part worth reading twice.** Only two
name shapes still claim a directory: `team-*` claims `plugins/teams/`, and `*-policy` / `*-policy-*`
claim `plugins/dkj-policy/`. `workflow-*`, `contributing-*` and `*-codex` keep the naming half and lose
the directory half -- there is no directory left to send them to, and pointing a stranger's workflow at
this government would be worse than saying nothing. The else-branch is untouched: a name matching none
of the five shapes is still an error, because a plugin silently held to nothing is the failure that has
actually happened here.

Archived release notes were split rather than swept: their link **targets** are repointed so navigation
still works, and their **prose** is untouched, because `plugins/workflows/...` in a 4.8.0 note is a
correct statement about the layout that shipped in 4.8.0.

**Score:** 3

#### What makes this deploy extra special

**If your repo ran `adopt-workflow-folder`, one line of your own CI breaks the moment this lands, and
re-running the skill will not repair it.** `.github/workflows/branch-entry.yml` checks this repo out at
`ref: main` -- not at a tag -- and runs the gate by path, so the break arrives before you update any
plugin. The skill is additive and never overwrites, so the file it wrote once is yours to edit:

```text
- .workflow-scripts/plugins/workflows/dkj-policy/scripts/lint/check-branch-entry.ps1
+ .workflow-scripts/plugins/dkj-policy/scripts/lint/check-branch-entry.ps1
```

That is the whole migration -- one line, one file, and it is the only place a consumer's own tree names
a shared script by path. Nothing else moves for you: plugin **ids** are unchanged, so
`claude plugin install/enable`, `${CLAUDE_PLUGIN_ROOT}` and every skill invocation resolve exactly as
before, and the orchestrator `@`-import points into `plugins/teams/`, which this change does not touch.

**Score:** 5

#### Pull Request

Rename plugins/workflows to plugins/dkj-policy

Plugins: dkj-policy, dkj-policy-bwj

[PR #1474](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1474)

---

### DEPLOY: docs/1473-readme-hook-count · 20260905-222228

The README's plugin table no longer tells a reader how many session hooks `dkj-policy` ships. It
says the plugin ships *the session hooks that belong to running this across several repos* -- the
mechanism, not a count -- which is the wording `plugins/workflows/README.md` already carries for
the same set. The number that was there said **two** while `hooks.json` lists **five**.

That is the same answer `.claude/specialists/SPECIALISTS.md` reached after its own hook count went
stale twice inside two days: each plugin's `hooks/hooks.json` is the one place that cannot drift,
so the prose points at it instead of racing it. The **Stop** hook keeps its number, exactly as
SPECIALISTS.md keeps it -- *one* is not a running total there but the distinction the sentence is
making, between hooks that report and the one that acts.

`README.md:115` says *the two session hooks* as well and is deliberately untouched. It is the
account of what moved out of `team-alpha` on August 8, 2026, bracketed by that date at both ends,
and two is what there were that day; a dated measurement keeps the wording it was written with.

**Score:** 2

#### What makes this deploy extra special

The plugin table is what a prospective consumer reads to decide whether to enable `dkj-policy` at
all, so the one stale number in it was the one sizing figure they had. Nothing broke on the old
wording -- the failure it prevents is a consumer budgeting for two session hooks and adopting
five.

**Score:** 1

#### Pull Request

README's workflow-plugin row no longer states a session-hook count that goes stale

[PR #1478](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1478)

---

### DEPLOY: fix/1465-register-dkj-policy-id · 20260905-221616

`connectors/claude-code-specialists.json` now registers the workflow plugin under its current id,
`dkj-policy@claude-code-specialists`. It had held `contributing-davekjohn@` since the #1437 rename
while this repo -- as a consumer of its own product -- had already migrated, so `check-connectors`
stated the opposite of the truth and skipped the whole plugin block: for this repo's own entry the
workflow plugin was not version-checked at all. Three `[OK]` lines now stand where one skipped
`[INFO]` did. The `[INFO]` itself is deliberately unchanged, because a consumer catching up is the
repair and making it an error re-opens the four false alarms of August 9, 2026 -- and the five other
manifests still naming the retired id are correct as they stand, since the register records what a
consumer HAS. This is the same blind spot `connectors/xoxowildhearts.json` recorded for the #886
rename, re-opened by #1437 through the identical route: the class was never emptied, only its
instance was. The `notes` field also loses a stale count -- it claimed two session hooks where the
plugin ships five, beside a Stop hook -- dropped rather than renumbered, for the reason
`SPECIALISTS.md` gives for no longer listing that set anywhere.

**Score:** 3

#### What makes this deploy extra special

N/A -- `connectors/` is workshop administration and deliberately does not travel with the plugin
caches, so nothing a consumer installs or reads changes here.

**Score:** N/A

#### Pull Request

Register this repo's own workflow plugin under dkj-policy@, so check-connectors stops skipping the block

[PR #1475](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1475)

---

### DEPLOY: docs/1470-sessionstart-hooks-sentence · 20260905-220048

One sentence in the `specialists-init` skill page named its own evidence in a way that did not parse:
it introduced *"the two SessionStart hooks"* and then apposed two files that are not hooks. The
paragraph's claim was always true -- four places do name `/team-alpha:specialists-init` in full and
say the repo owner has to type it -- but the sentence carrying it could not be checked by a reader,
which is the only thing that makes such a citation worth writing. It now names all four, each with
the hook file and the script behind it.

The page carries `disable-model-invocation`, so a model never reads it; the reader here is the repo
owner adopting the family for the first time, and they are exactly the reader who has no other way to
verify that the no-bare-imperative rule is honoured anywhere. A citation they cannot follow is worse
than none, because it looks like evidence.

**Score:** 2

#### What makes this deploy extra special

Nothing structural -- one paragraph, no mechanism, no script. What is worth keeping is the method: the
intent the report said it could not determine was recoverable from the tree, in a comment sitting
directly above one of the lines the sentence cites. `adopt-config.ps1` says of itself *"Not a
SessionStart hook like the roster check, but the same trap"*, which settles both that the sentence
meant a list of four and that its author knew the distinction. Reading the cited code before guessing
at the wording is what turned "needs someone who remembers" into a mechanical repair.

**Score:** 1 -- cosmetic on the page itself; the failure it prevents is a reader checking a citation,
finding it names the wrong kind of thing, and discounting the paragraph's claim along with it.

#### Pull Request

The specialists-init 'two SessionStart hooks' sentence names its four places

Plugins: team-alpha

[PR #1472](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1472)

---

### DEPLOY: docs/merge-adopt-config-workflow-folder · 20260905-212108

`adopt-config` and `adopt-workflow-folder` were two separately-named skills for the same plugin,
`dkj-policy` -- one placing the config seam, one scaffolding the workflow folder. Renaming
`adopt-bwj-asana` to `adopt-dkj-policy-bwj` earlier the same day, for a sibling plugin that had grown a
second chapter under a name naming only the first, raised the same question here from the other
direction: two *separate* skills for one plugin, neither named after it.

Merged into one skill, `adopt-dkj-policy`, in two independent parts that can run in either order or
alone -- no behaviour change to either underlying script, only the page that documents them. A reader
enabling `dkj-policy` now finds one name to ask for, covering everything the plugin needs placed in
their repo, rather than having to already know there are two.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal skill name in this repo's own workflow plugin. No consumer-facing behaviour changed;
the two scripts a consumer actually runs are byte-for-byte what they were.

**Score:** N/A

#### Pull Request

adopt-config and adopt-workflow-folder merged into one skill, adopt-dkj-policy

Plugins: dkj-policy, team-alpha

[PR #1471](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1471)

---

### DEPLOY: fix/1464-gate-orphan-warning · 20260905-210737

Fixes #1464. `Invoke-TestSuiteGate` starts each suite with `Start-Process` but never tracked those
children beyond its own in-memory queue, so a harness-killed gate run left its `powershell.exe`
children running -- invisible and unreachable to the session that killed it. An immediate retry could
then be OOM-killed too, even with `-MaxParallel` set correctly, because the retry's own memory budget
assumed room the dead run's orphans were still holding: measured on one machine as 5 processes at
rest, 28 orphaned after a kill, and a second `-MaxParallel 4` attempt dying from 1.7 GB free before a
third, serial attempt finally passed.

This ships the cheapest repair the issue asked for, not the two heavier ones it named (PID
tracking/reaping, or a Windows job object) -- both are real changes to the spawn model and neither is
part of this fix. `Get-ResidentPowerShellCount` counts resident `powershell.exe` processes before the
gate starts its own pool, and `Invoke-TestSuiteGate` prints one `Write-Warning` line when that count
is above 20 (comfortably over this file's own documented 16-18-lane ceiling for a legitimately busy
run, and comfortably under the 28+ orphans measured in #1464). It is advisory only -- it never fails
the gate -- so a silent kill now has a chance to read as "something is still draining" instead of "the
machine got slower".

**Score:** 2

#### What makes this deploy extra special

N/A -- this is a diagnostic line inside the shared test-suite gate; no subscriber of any consuming
repo's service ever sees it.

**Score:** N/A

#### Pull Request

The gate warns when resident powershell processes look like leftover orphans

Plugins: dkj-policy, team-shopify

[PR #1468](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1468)

---

### DEPLOY: docs/1450-rename-adopt-bwj-asana · 20260905-204550

`adopt-bwj-asana` grew a second chapter it was never named for: since today it also scaffolds
`dkj-policy-bwj/SYNC-LOG.md` (step 7), the record chapter two's sync branches write into. A skill named
after one chapter while it sets up both reads as narrower than it is, and the next reader has no reason
to expect chapter two's setup to be hiding inside a name that only says "Asana."

Renamed to `adopt-dkj-policy-bwj` -- the whole plugin it adopts, not one chapter of it. Pure rename, no
behaviour change: same seven steps, same additive/dry-run-by-default guarantees, same two things it
places in a store repo's own tree.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal skill name in a workflow only two repos enable. Nobody outside this repo's own
maintenance ever sees the string `adopt-bwj-asana` or `adopt-dkj-policy-bwj`.

**Score:** N/A

#### Pull Request

adopt-bwj-asana renamed to adopt-dkj-policy-bwj -- it covers the whole plugin, not just Asana

Plugins: dkj-policy-bwj

[PR #1466](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1466)

---

### DEPLOY: fix/1450-open-pr-remote-ahead-gate · 20260905-201818

A branch resumed from a parked commit can still lose the full lint + test gate to a push rejection: if
another session pushes to the same branch after this checkout last looked, `open-pr.ps1` never re-checked
before spending two minutes proving a tree the push then refuses anyway (`! [rejected] ... fetch first`).
Measured on `fix/1446-tip-utf8-decode` on September 5, 2026 -- the fourth instance of this class (after
#1282, #1409, #1439), and the one #1439's own repair cannot reach: that check fires once, when a session
first resumes the branch, not at the one other door where a second session's push can still land unseen.

`open-pr.ps1` now fetches that one branch and compares `HEAD` against it immediately before the gate runs.
A real divergence is refused outright, with the fast-forward instruction, instead of discovered two minutes
and one discarded gate run later. The warning text itself -- the diverging commit's subject and author,
sanitised against control/format characters and capped -- is not a second copy: it is the same function
`new-branch.ps1`'s own resume warning already used, now shared so the day's other fix to that text (#1446)
cannot exist in one copy and not the other.

**Score:** 2

#### What makes this deploy extra special

N/A -- this is entirely mechanism between a session and its own push; nothing about it is visible to
anyone outside this repo's own contributors.

**Score:** N/A

#### Pull Request

open-pr checks for a diverged remote head before spending the lint+test gate

Reuses new-branch.ps1's own tip-warning composition (issue #1446's UTF-8 fix) via a new shared lib,
`scripts/lib/remote-ahead-lib.ps1`, rather than a second hand-typed copy of it. Resolves #1450.

Plugins: dkj-policy

[PR #1460](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1460)

---

### DEPLOY: fix/1453-token-recovery-from-worker · 20260905-201057

The release page's path token is the one file in this system that cannot be rebuilt, and both of its
refusals used to describe the loss as worse than it is. The token is deliberately uncommitted in a
public repo and nothing in git remembers the URL it forms -- but the script writes that route into the
worker bundle as a **literal**, so a deployment that is still up is itself a copy of the token, held by
Cloudflare rather than by any machine of yours. "There is no token on this disk" and "the URL is gone"
are different findings, and only the first one is answered by looking at your own tree.

`build-release-notes-page.ps1` now names three ways back rather than two, in the order worth trying:
the URL you have, then the deployment -- the worker's code view, or the Workers script API -- and only
then `-InitToken` for a fresh path. The ordering is the repair, because `-InitToken` is the step that
404s every link already sent, and a recovery instruction that reached it second walked the reader past
the recoverable route to the irreversible one. `-InitToken` now also says so at the moment it runs,
where the repo names a worker and a live page may already be serving the old token.

Measured on this repo: with every local copy genuinely gone (#1453), the conclusion drawn was that
every link already sent was unrecoverable -- and #1444 had reached the same reading one issue earlier.
Both followed from tooling that never mentioned the deployment.

**Score:** 3

#### What makes this deploy extra special

N/A -- the person a release page is written for never meets any of this. It is a guard between the
operator and an irreversible step, and it earns its place by changing what that operator concludes on
the one day the token is missing.

**Score:** N/A

#### Pull Request

The token refusal names the deployment before it names -InitToken

Plugins: dkj-policy

[PR #1461](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1461)

---

### DEPLOY: feat/claim-issue-skill · 20260905-195949

The claim rule, performed. A `claim-issue` skill and script put an issue on the account **this
checkout commits as** before any work on it begins -- and refuse the three states the documented
one-liner cannot see: a **closed** issue, which `gh issue edit --add-assignee` claims silently; one
**somebody else holds**, which it joins; and a **split identity**, where `@me` writes the tracker
account while every commit lands under another name. The claim is **read back** afterwards, because
`--add-assignee` reports success for a login GitHub drops. Two supporting libs, one of them extracted
from `check-git-identity.ps1` so the identity reads have a single source, a 27-assert suite, and the
three documents that state the rule now name the step that performs it.

**Score:** 4 -- it changes what happens at the start of every piece of issue work, and it does so
without being asked: the skill is model-invocable, so *"fix issue 1234"* now claims before it fixes. A
consumer notices the first time a session refuses to start on a closed issue.

#### What makes this deploy extra special

It closes a rule that had been enforced by memory alone, and the measurement is unusually blunt about
what that was worth: **0 of 67** assigned issues in this repo carried the identity with **132** merged
PRs and **83** authored issues
([#1456](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1456), filed the day before
this branch, whose own corrective action was *behavioural*). The rule was not unclear, unknown or
disputed -- it was simply never the thing anybody remembered to type. This repo's standing answer to
that is a gate rather than a firmer sentence, and the same measurement is why the skill is
model-invocable rather than reserved for an explicit `/claim-issue`: a step nobody may take until it is
typed has exactly the failure mode being repaired.

**Score:** N/A -- workflow tooling between a repo and its tracker; no subscriber of a service reads it.

#### Pull Request

the claim-issue skill

Plugins: dkj-policy, team-alpha

[PR #1463](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1463)

---

### DEPLOY: docs/1456-capped-listing-measurement · 20260905-194439

A fifth measured instance under the `triage-inbound` skill's fifth pattern, plus the mechanism behind
it. #1456 reported an absence that does not exist -- `DaveKJohn` is in fact the most-assigned identity
here, 88 of 221 assigned issues -- and all three of its figures reproduce exactly from a single `gh`
listing capped at `--limit 200`/`300`. The headline `67` was that account's own assignee count inside
the window, reported as the count that excluded it.

The four instances already recorded are reports that were real and mis-sized. This one is the variant
where the mis-measurement is the whole finding, so the pattern's intro now says so rather than leaving
its name to carry it.

**Score:** 2 -- a skill only a pickup reads, and it changes no gate. It earns more than cosmetic because
the mechanism is reproducible and silent: `gh issue list`/`gh pr list` return the newest `--limit` rows
and say nothing about what they left out, so a windowed figure is indistinguishable from a full-history
one in the report that quotes it.

#### What makes this deploy extra special

One capped window produced **three** mutually consistent figures, all three wrong. That is the part
worth carrying: a report whose numbers agree with each other is not thereby corroborated -- they can
share a single bad window. The report also carried its own counterexample, citing #1450 as claimed by
the filing session while #1450 is assigned to `DaveKJohn`, one of the 88 it argued do not exist.

**Score:** N/A -- internal triage evidence for this repo's own pickups; no subscriber of a service
reads it.

#### Pull Request

Record the capped-listing measurement failure in triage-inbound

[PR #1462](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1462)

---

### DEPLOY: fix/1447-release-page-path · 20260905-192056

Two path statements in `dkj-policy/releases/README.md` repaired after the #1437 folder rename. The
table row for the release page's output directory and the path-token paragraph both still named
`contributing-davekjohn/releases/page/`, which exists nowhere. The second one was actively misleading:
it told the reader `.gitignore` keeps that path out of git, while `.gitignore` covers
`dkj-policy/releases/page/` only -- so a token dropped where the document pointed would have been
committed into a public repository, which is precisely what that paragraph is there to prevent.

**Score:** 1 -- documentation-only, and the failure it prevents has not happened. Naming it, because
that is the part a later reader can use: publishing a no-login URL token into a public repo, on the
document's own instruction.

#### What makes this deploy extra special

A stale path is normally cosmetic. This one had inverted its own safety claim: the sentence warning
that the token must stay out of git named the one directory `.gitignore` does not cover. The repair is
two words; what it is worth is that the document's guarantee is checkable again --
`git check-ignore` now agrees with the path the prose names.

**Score:** N/A -- internal to this repo's own release tooling; no subscriber of a service reads it.

#### Pull Request

the release-page path in dkj-policy/releases/README.md

[PR #1457](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1457)

---

### DEPLOY: fix/1454-releases-readme-folder-name · 20260905-191304

`releases/README.md` told an agent setting this workflow up in another repo that the plugin is called
`contributing-davekjohn`, that the `adopt-workflow-folder` skill scaffolds a
`contributing-davekjohn/releases/README.md`, and that `Get-ReleaseHistoryPath` points at a
`contributing-davekjohn/releases/history.md` if left alone. All three are false, and false in the same
direction: a fresh consumer has none of the three folder names on disk, so every script hands them
`dkj-policy` while this page addressed them in the second person about a folder they do not have.

#1437 renamed the folder and #1447 covers the two `releases/page/` statements it left behind. These
three were scoped out of that branch because #1447 states its own bound -- and one of them is not a
folder-rename miss at all: line 5 names the **plugin**, which was never called `contributing-davekjohn`.

Three sentences rewritten. The dated sentences around them keep the name they were written with, and
lines 137 and 143 are left for #1447.

**Score:** 3

#### What makes this deploy extra special

The section these three sit in is `### How to build your own version of this page` -- the one document
that exists to answer *"what does this look like in my repo"*, addressed in the second person to a
consumer adopting the workflow. That is the worst place in the tree for a stale name, because the
reader has nothing of their own to check it against yet.

**Score:** 3

#### Pull Request

Correct three present-tense contributing-davekjohn references in the releases README

[PR #1458](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1458)

---

### DEPLOY: fix/claude-md-install-record-claim · 20260905-190509

`CLAUDE.md` no longer states that this repo carries an install record as a settled fact. Inbound #1449
measured the opposite on one machine and cited a precedent (#1371) that, on inspection, measured the
opposite of what it was cited for too — the record's presence is real but per-machine, and the paragraph
now says so, rather than asserting either "always present" or "always absent".

**Score:** 1

#### What makes this deploy extra special

N/A — internal documentation accuracy, no subscriber of the service is affected.

**Score:** N/A

#### Pull Request

CLAUDE.md states an install record's presence as a fixed repo fact, not a per-machine one

[PR #1459](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1459)

---

### DEPLOY: feat/1443-gate-lane-knob · 20260905-185207

`open-pr.ps1`, `ship-pr.ps1` and `cut-release.ps1` now take **`-MaxParallel <n>`** and hand it down to the
test gate, so a gate that will not *finish* can be run **smaller** instead of not at all. `0` -- the
default -- resolves exactly where it always did, inside `Invoke-TestSuiteGate`, so an ordinary run is
unchanged.

The parameter has existed at the bottom of the chain since the gate was written, and `ci.yml` passes it.
What was missing was every hop above it: `Invoke-WorkflowGates` sat between the two PR scripts and the gate
without carrying it, and `cut-release` calls the gate directly and never declared it. So on a developer's
machine the only route past a gate that dies was `-SkipTests` -- and that is strictly worse than a smaller
run, because it is the switch that says *this run did not measure*. Afterwards a branch pushed past a
memory limit reads exactly like one that skipped its suites for a bad reason.

**`cut-release` is the caller #1443 did not name and the one where it costs most.** The other two open a
PR, and a PR that does not open costs a retry; this one commits and tags on the trunk, where `-SkipTests`
means a release can be cut with a suite red.

Measured on the machine that filed [#1443](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1443)
-- 18 cores, so 16 lanes, same 68 suites, same function: the default passed once at 716s and was then
**killed twice by the harness for running out of memory**, where `-MaxParallel 4` passed in 888s. 24%
slower, and it finishes. Intermittent rather than a ceiling -- 16 lanes fits when the machine is quiet --
which is why this is a knob and not a new default. Worth knowing beside it: a starved run can also go
**false red**, and the killed run's log carried two `[FAIL]` lines in a suite that is 108/108 green run
alone.

**The default lane formula is deliberately untouched.** The reservation reasons about cores; what ran out
was memory, and one machine is not a measurement of a formula. This adds the way past, not a new policy.

**Score:** 3

#### What makes this deploy extra special

Every consumer reaches all three scripts through the plugin mirror, and their machines are the ones this
repo cannot measure -- more cores, more suites, or a laptop already running something else. Until now their
only answer to a gate that would not finish was the escape valve that erases the evidence, on the one run
whose whole job is to produce it. `cut-release` is the sharp end of that for them exactly as it is here.

The flag is documented where a session actually reads it: the `open-pr` skill page carries the numbers and
the *reach for this before `-SkipTests`* rule, and the `ship-pr` and `cut-release` pages an entry each
that forwards to it.

**Score:** 3

#### Pull Request

open-pr, ship-pr and cut-release carry the test gate's lane knob through

Plugins: dkj-policy

[PR #1455](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1455)

---

### DEPLOY: fix/1444-stranded-page-token · 20260905-184311

The release page's path token is the one file in this system that cannot be rebuilt: it is the only
lock on a public page, it is deliberately uncommitted in a public repo, and nothing in git remembers
the URL it forms. It lives in a directory derived from the note root and ignored by git -- two good
decisions that meet badly, because renaming the folder above it moves every tracked file and leaves the
token where it was. `git mv` cannot see an ignored sibling by construction, so the miss is silent on
the day it happens, and what is left over reads like rename debris.

`build-release-notes-page.ps1` now asks whether a token exists **anywhere in the tree** rather than
whether one exists at the derived path. A copy found elsewhere is named and never adopted: `-Worker`
points at the folder to move, and `-InitToken` -- whose refusal was the design's whole safety property
and which read the derived path alone -- refuses on it too. Where no copy is found, the refusal still
names the move that hides one, because the operator who has just renamed a folder is the reader most
likely to be looking at it.

Measured on this repo: #1437's rename left exactly that orphan (#1444), and the token is gone from this
machine with it.

**Score:** 2

#### What makes this deploy extra special

N/A -- the person who reads a release page never sees any of this. It is a guard between the operator
and one irreversible mistake.

**Score:** N/A

#### Pull Request

The missing-token refusal points at the copy a folder move left behind

Plugins: dkj-policy

[PR #1452](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1452)

---

### DEPLOY: fix/1446-tip-utf8-decode · 20260905-183608

`new-branch.ps1` reads the remote tip's subject with **`-Utf8`**, so the control-and-format strip added in
[#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439) sees the characters it exists
to remove. Until now it did not, on any Windows console whose code page is not UTF-8 -- which is the
default.

**The guard was green in the one environment that did not need it.** Windows PowerShell 5.1 decodes a
native child's stdout with `[Console]::OutputEncoding`. On a cp850 console the three UTF-8 bytes of an RTL
override (`e2 80 ae`) arrive as the three ordinary printable characters cp850 maps them to -- and
`\p{Cf}` does not match an ordinary printable character, so nothing was stripped. Encoding those same three
characters back out is byte-identical, so the payload was reconstituted intact the moment anything
downstream decoded as UTF-8. The ESC half of the guard always worked, because `0x1B` is ASCII and every
candidate code page agrees below `0x80` -- which is exactly the property
[`language-layers.md`](../.claude/rules/language-layers.md) already names as the reason to hold the wire to
ASCII and decode it yourself.

**The mechanism was already built, documented and unused at this call site.**
`Invoke-NativeCapture -Utf8` exists for precisely this
([#907](https://github.com/DKJ-Solutions/claude-code-specialists/issues/907)), and its docstring says *pass
it wherever the output is DATA rather than progress*. A commit subject that a matcher then inspects
character by character is the strongest form of that case, and the flag was simply not passed.

**And the suite could not have caught it.** Its premise assert -- *"the commit on origin really carries the
RTL override"*, written so the asserts below it are not vacuous -- read the subject back through `& git`,
the same console-code-page decode the product code used. So on a non-UTF-8 console it reported the fixture
as broken while the fixture was intact, and on a UTF-8 console everything passed. It now reads through the
same explicit decode, which is what makes it independent.

**Score:** 4

#### What makes this deploy extra special

Every consumer runs `new-branch.ps1` from the plugin mirror, on their own machine, and the guard this
repairs is about **somebody else's text**: the tip subject is written by whoever pushed to the shared
branch. A consumer on a default Windows console had the strip in their copy of the script and not in
effect -- and the output it protects is read by an agent session as well as by a person, where a crafted
subject wearing this script's own `WARNING` prefix is an injection surface rather than a display bug.

Nothing about how the script is used changes, and no flag is added for them to know about. The line they
already see is now the line the script promised.

**Score:** 4

#### Pull Request

the remote-tip read decodes as UTF-8, so the sanitiser sees the characters it strips

Plugins: dkj-policy

[PR #1451](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1451)

---

### DEPLOY: fix/1445-reminder-install-route · 20260905-181831

`cut-release`'s closing self-consumption reminder no longer prints a command that cannot run in the repo it
is printed for. It used to read `.claude/settings.json` and emit
`claude plugin update <id> --scope project` for every enabled plugin -- but `enabledPlugins` is the
**declarative** route while `plugin update` operates on an **install record**, so in a repo adopted that way
the very source the reminder consulted was the one guaranteeing the command it printed would refuse. Measured
here immediately after the v4.30.0 cut: the refresh succeeded, both update commands answered
`Plugin "..." is not installed`.

It now asks the install administration which of the two routes each enabled plugin actually took, through the
shared `Test-PluginInstalledHere` rather than a second private reader, and prints per plugin: an id with a
record for this path keeps its update command, an id without one is named under the marketplace refresh --
which is its whole remedy, a restart being what applies it. Both routes were measured rather than reasoned
about, because the report flagged the second as inferred and the repair differed per answer; the finding that
settled the shape is that `claude plugin install --scope project` writes the **same** `enabledPlugins` key the
declarative route uses, so the two are indistinguishable from settings and detection had to come from
elsewhere. Where the administration is absent or unreadable the old line is printed unchanged -- absence of
evidence is not evidence of absence, and that default is inherited from the shared predicate rather than
re-decided.

The reminder's premise, its conditionality and its 2026-08-15 reasoning are untouched: this is the remedy it
names, not the reason it exists.

**Score:** 3

#### What makes this deploy extra special

A consuming repo that cuts its own releases with this plugin gets the same correction, and it matters most
for the adoption route `INSTALL.md` does *not* document -- settings keys without an install. Such a repo used
to end every cut with a hard failure against a machine that was in fact fully up to date, with no way to tell
that from a real one. A repo adopted the documented way (`claude plugin install --scope project`) sees no
change at all: it has a record, so it still gets its update command.

**Score:** 2

#### Pull Request

Self-consumption reminder: only print an update command the repo's adoption route can run

Plugins: dkj-policy

[PR #1448](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1448)

---

