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

**The line directly under `## [Unreleased]` is a tally, and nobody types it.** It reads
`**4 / 9 minor entries**`: how many of the pending entries reach the audience this repo publishes to, out of
how many are waiting for the next release, and which bump that work has earned. The two numbers answer
different questions and may differ — the fraction counts tier 2 and above, the bump follows tier 1 and
above — so `**0 / 8 minor entries**` says nothing reaches a subscriber while the version still owes a minor
for what reaches management. It is
**derived from the entries below it every time it is written**, by the fold that adds one and the cut that
removes them all, so it holds no state of its own and a hand-edited count is simply corrected on the next
fold. It ends with an HTML comment that marks it as machine-written; that marker is what the next run
replaces, so anything else written in this space is left alone.

---

## [Unreleased]

**10 / 27 minor entries** <!-- pending-tally -->

### DEPLOY: feat/1870-reach-label-portable · 20260911-191808

The reach label becomes part of `dkj-policy` rather than of its BWJ chapter, and its name becomes
`minor`. It is the tier model -- which this workflow already reads on every changelog entry, and which
already decides patch versus minor -- read one step earlier, on the issue instead of on the entry. An
issue whose landing will be written at tier 1 or 2 carries the label; tier 0 carries none, and doubt
resolves there. `Get-ReachLabel` states the string a tracker stores, defaulting to `minor`, so a repo
that spells the axis otherwise answers one function instead of being renamed.

**Score:** 4

#### What makes this deploy extra special

This is the first issue label this workflow has ever prescribed, and it arrives with the sentence that
used to forbid it rewritten rather than quietly contradicted: your other labels are still your
tracker's business. A consumer gets a worklist -- `is:open label:minor` is every open issue whose
landing will be visible past their own developers -- for the price of one `gh label create`, which
`adopt-dkj-policy` Part 4 now hands them. A consumer already running the axis as `tier-1` is not
renamed by this: they either rename the label themselves, which GitHub does without dropping it from a
single issue, or answer `Get-ReachLabel` with the word they have.

**Score:** 3

#### Pull Request

The reach label goes portable: every consumer carries 'minor'

Plugins: dkj-policy, dkj-policy-bwj

[PR #1872](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1872)

---

### DEPLOY: feat/1869-consumer-divergence-check · 20260911-190506

The connector register can now answer the question it was asked for. `check-consumer-siblings.ps1`
compares the tooling layers of consumers that declare a shared `siblingGroup` and reports three classes:
`ONLY-IN` (a mechanism one has and the other does not), `DRIFTED` (two copies of one mechanism that have
grown apart) and `ALIASED` (one capability under two filenames -- the class no path comparison can make).

Every other check here runs source-to-consumer. This is the first that runs consumer-to-consumer, and
#1869 measured what that axis was hiding: of the 48 tooling paths the two BWJ stores share, 47 have
diverged, and the only one that has not is a template this marketplace ships. `prune-merged.ps1` is the
argument in one file -- shipped centrally in `dkj-policy` 4.21.0, adopted by one store and not the other
three weeks later, with nothing watching the gap.

It reports and refuses nothing. Converging is an ownership decision, not a repair a script can make.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing here reaches a subscriber of a service. The register, the check and the group label are
internal maintenance machinery of this marketplace, and the two consumers it compares are private repos
whose own tooling is unchanged by this branch.

**Score:** N/A

#### Pull Request

Report mechanisms a sibling consumer has and this one does not

Plugins: dkj-policy, dkj-subagents-alpha

[PR #1879](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1879)

---

### DEPLOY: docs/1874-preview-control-variant · 20260911-185450

`dkj-policy-bwj` gains a third chapter, [`PREVIEW-portable.md`](../plugins/dkj-policy/dkj-policy-bwj/PREVIEW-portable.md):
**a preview handover is a pair per market -- the preview, and the live control variant.**

A preview alone shows what a page will look like; it never shows what *changed*. The reader supplies the
other half from memory while looking at something else, which is the exact judgement the preview was
pushed for. The rule comes from a five-market handover in `smartwatchbanden` that was complete by the
letter of the rule then in force and still left that half undone.

**The part that had to be measured is what the control URL is.** It names the **live theme id**, and not
the same URL with the parameter dropped -- `preview_theme_id` sets a cookie, so once a market's preview
has been opened the bare URL keeps serving the preview theme. The control tab then agrees with the preview
and the reviewer concludes nothing changed: a false negative that looks like a clean result. Measured on a
live store, with both neighbouring wrong answers recorded on the page -- including `preview_theme_id=0`,
which renders the "missing one of these required files" error rather than resetting anything, and reads
like a broken preview theme.

The live id needs no seam of its own: `Get-ShopifyLiveThemeId` already states it for
`dkj-subagents-shopify`'s live-theme guard, and the page points there rather than at a pasted number.
Nothing here decides which changes owe a preview, or when a PR may open -- both stay the consumer's and
`dkj-policy`'s, unchanged. No new seam, no adopt step, no CI.

The ships-assert in `dkj-policy-bwj.tests.ps1` now covers the portable pages it had never guarded --
the new one and `SYNC-LOG-portable.md` beside it.

Resolves [#1874](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1874).

**Score:** 3

#### What makes this deploy extra special

N/A -- a workflow plugin's house rule for two store repos. It changes what one colleague hands another
before a merge; no subscriber of any service reaches it.

#### Pull Request

A preview handover owes the control variant, not only the preview

Plugins: dkj-policy-bwj

[PR #1877](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1877)

---

### DEPLOY: fix/1867-git-author-identity-probe · 20260911-181859

A machine with no usable git author identity is now reported at session start and refused by
`new-branch` before a branch is cut, instead of failing at exit 128 once HEAD has already moved.
`git var GIT_AUTHOR_IDENT` replaces `user.name` as the reading, because `user.name` disagrees with
git in both directions: set-but-no-email still refuses, and unset-but-auto-guessable commits fine.
The three silent `[SKIP]`s keep their silence; only the one that was never "nothing to compare" is
split out of them.

**Score:** 3

#### What makes this deploy extra special

N/A -- developer tooling in a workflow plugin. It reports a git configuration state to whoever is
running the cycle; no subscriber of any service reaches it.

Worth recording for the next reader of this tree, though: it repairs a gap a previous fix
deliberately left. [#1830](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1830) removed a
false claim of agreement by routing every `[SKIP]` to silence -- correct for two of the three, and for
the third it replaced a wrong statement with no statement, on the one machine state where silence
costs a branch. The lesson is in the split rather than in a revert: three conditions sharing an exit
code are not thereby the same finding.

**Score:** N/A

#### Pull Request

Report a checkout that cannot commit at all, before a branch is cut

Plugins: dkj-policy

[PR #1871](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1871)

---

### DEPLOY: fix/1865-fixture-dep-scan-set · 20260911-165129

The fixture dependency gate reads every `.ps1` under `scripts/tests` instead of only the files named
`*.tests.ps1`, so the fixture builder that four lint suites share is now a subject rather than the one
blind spot in a gate built to prevent exactly its failure mode. On #1860's branch that gate reported
seven findings, was right about all seven, and the four lint suites died on lib load anyway.

**Score:** 3

#### What makes this deploy extra special

N/A -- a test gate in this repo's own tree. No subscriber of anything reaches it, and it ships in no
plugin payload.

**Score:** N/A

#### Pull Request

The fixture dependency gate reads every file under scripts/tests, not only the suites

[PR #1868](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1868)

---

### DEPLOY: fix/1860-shared-fetch-freshness · 20260911-145710

An unreachable `origin` no longer stalls the opening of an issue-driven assignment twice. `claim-issue`
and `new-branch` run back to back by design and both fetch the same remote, each bounded at two
minutes independently -- so a session that had nothing on screen yet could wait four. They now share
one record of the last fetch attempt (`scripts/lib/fetch-attempt-lib.ps1`, mirrored into the plugin),
and the second call reports the first one's failure instead of buying another bound.

**A recent SUCCESS never lets a fetch be skipped, deliberately** -- the symmetric version of this was
built first and refused by `new-branch.tests.ps1`, whose #1139 and #1439 cases reproduce two runs
seconds apart with another session's push between them. So the duplicated ~700ms #1860 also reports
is still paid: it is what those two probes are reading.

**Score:** 2

#### What makes this deploy extra special

The suite refused the design, not the implementation. The seam was built to the issue's own first
option, passed every assert written for it, and then took eleven off an unrelated file -- each one a
guardrail about another session's push, which is the event a freshness window is exactly wide enough
to hide. The half that survives is the half with no counterparty: a failed attempt refreshed nothing,
so standing on it blinds nothing.

**Score:** N/A

#### Pull Request

One shared fetch-attempt record, so an unreachable origin is not waited out twice

Plugins: dkj-policy

[PR #1866](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1866)

---

### DEPLOY: fix/1852-timeout-decisive-in-sessioncheck · 20260911-142702

The session-start version check no longer reports a run that was killed mid-flight as a clean result.

`connector-sessioncheck.ps1` bounds the plugin-versions engine and then chose its verdict from whatever
landed in the capture. But a bound that fires does not empty the capture: `Invoke-NativeCapture` kills
the child's process tree and reads its output files regardless, so a child that outlives the kill by a
moment -- which needs nothing worse than `taskkill.exe` paying its own cold startup under load -- comes
back complete, flagged `TimedOut` in a field this hook never read. The result was an all-clear printed
for a check that did not finish: the `[UNREGISTERED]` hazard the hook's own wording exists to prevent,
arriving through the one field it was not reading. A capture truncated by the kill can also end after a
`[SUMMARY]` and before an `[ERROR]`, which reads as "up to date" about a checkout that is behind.

The hook now reads `TimedOut` and `ShortRead` -- as the other bounded callers that judge from a
capture's content already do -- and degrades to its honest one-line verdict instead of parsing a
document the engine never finished writing. `Stop-NativeProcessTree`'s docstring, which had told
callers a failed kill costs nothing but a stray process, now says what it actually costs and where the
answer is.

It surfaced as an intermittent red suite (#1852, CI run 34596638888) whose own comment said it could
not fail under load. That comment was arguing from the bound, which is load-proof, rather than from the
verdict, which was not. The new block 7 pins it deterministically, and fails with exactly the two
assertions CI saw when the repair is removed.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's audience is its own maintainers. The two changed sources ship inside plugins, to a
consumer who runs this workflow, rather than to a subscriber of a service.

**Score:** N/A

#### Pull Request

A timed-out version check no longer reports its killed run as a clean verdict

Plugins: dkj-policy, dkj-subagents-shopify

[PR #1864](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1864)

---

### DEPLOY: fix/1858-bidi-console-strip · 20260911-140829

`claim-issue` neutralised only the ASCII control range in the text it prints, so a Trojan-Source-shaped
spoof reached the terminal untouched: a U+202E RIGHT-TO-LEFT OVERRIDE, a bidi isolate pair or a
zero-width run in an issue title, a commit subject or a branch name could visually reorder the line
reporting it, without a single byte below 0x80. It now strips `[\p{Cc}\p{Cf}]` -- the same class
`pr-issues-lib.ps1` and `ref-print-lib.ps1` already apply to the other four consoles this workflow
writes foreign text to -- which closes the C1 range (0x9B reads as CSI in some terminals) in the same
move. Each character still becomes a space rather than vanishing, so nothing can be welded into a
title that reads as a different sentence, and nothing is collapsed or trimmed: a title is quoted
evidence. The cost is stated rather than hidden -- a title written in Arabic or Hebrew loses the marks
that order it, and an emoji joined by U+200D prints as its parts.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing outside this repo's own workflow surface changes. It hardens a console line a maintainer
reads; no subscriber of any service touches `claim-issue`.

**Score:** N/A

#### Pull Request

Format-ForConsole also neutralises Unicode bidi and zero-width controls

Plugins: dkj-policy

[PR #1863](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1863)

---

### DEPLOY: fix/1853-parked-fix-scan · 20260911-134537

`claim-issue` now reads the **branches** as well as the tracker. Before this, all three signals a
session has when it picks up an issue -- the issue's state, its assignees, and any pull request
resolving it -- read exactly the same whether the work was untouched or already finished and pushed
on a **parked** branch, because the PR-shaped check has nothing to find when there is no PR. Measured
September 11, 2026 ([#1853](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1853)): #1847
was claimed correctly, read, repaired and committed, and only `open-pr`'s remote-ahead gate revealed
that the identical fix was already sitting on `origin/feat/1842-unify-prio-labels-bwj` and said so in
its own commit message. The claim step now scans the commit messages off the trunk for the issue
number -- in the three spellings this workflow writes: `#1853`, the commit scope `fix(1853):`, and
the branch name `/1853-` that a freshly parked branch carries -- and names the branch and the commits
it found, grouped by branch and capped so a long branch cannot bury the rest of the output. It
**warns and never refuses**: an issue can be legitimately named by a commit that does not fix it, and
a claim that blocks costs the whole assignment. It runs on a resume as well as a fresh claim, and it
is silent about the session's own branch and about the trunk.

**Score:** 3

#### What makes this deploy extra special

N/A. The audience here is whoever picks up an issue in a repo running this workflow -- a developer,
never a subscriber of any service either consumer repo sells. What it saves them is the work between
a claim and the first gate that would have noticed: in the measured instance, one file read, one line
edited, one lint run and one commit, all discarded. That cost scales with how long the fixing branch
stays parked without a PR, which can be indefinite.

**Score:** N/A

#### Pull Request

claim-issue reads the branches for a fix already pushed without a PR

Closes #1853

Plugins: dkj-policy

[PR #1861](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1861)

---

### DEPLOY: feat/1857-mirror-depth-gate · 20260911-132257

A shared workflow script exists twice -- the workshop source and the plugin mirror a consumer runs --
and check 8 holds the two byte-identical. That proves they are the same TEXT and says nothing about
behaviour, and the equality is what hides the gap: the two copies sit at different depths, so a
`$PSScriptRoot` resolution ascending two levels lands on the repo root from one and the plugin root
from the other. Identical characters, different folder, nothing to diff.

Check 39 refuses such a resolution while it is UNDECLARED: the pair must name the suite that runs its
mirror, and that suite must exist and name the mirror, so a declaration cannot be fiction. Whether the
run asserts anything stays the suite's job -- the same line check 18 draws between this gate and a
skill page. One hop is deliberately not a subject, because `..\lib\...` is the same folder relative to
the file in both copies; flagging it would bury the crossings under the thirty-odd that cannot differ.

All three crossings were already correct. What was missing was the proof: they had been verified by
hand, and the copy that fires in every released install is the one no suite executed. All three now do.

**Score:** 3

#### What makes this deploy extra special

Nothing here reaches a subscriber: it is a gate over this repo's own shared-script mechanics, and a
consumer sees no behaviour change at all. What it protects is theirs, though -- the mirror is the copy
they run, and it was the copy nothing exercised.

**Score:** N/A

#### Pull Request

Gate the depth-sensitive resolutions in mirrored shared scripts

[PR #1862](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1862)

---

### DEPLOY: feat/1843-portable-pr-template · 20260911-130430

`adopt-dkj-policy` Part 1 now places `.github/pull_request_template.md` in a consuming repo, copied from
the plugin's own reference and never overwriting one that is already there. It was the last file in the
adoption a person had to copy by hand, and the only one whose absence was silent: `open-pr` builds a PR
body only when that path exists, so a repo that skipped the copy got pull requests with **no body at
all** -- no description, no form -- and no warning saying why. The warning that block does carry fires
on a placeholder that does not *match*, which is the other failure and the loud one.

The content is read from the shipped reference rather than retyped into the scaffolder. The interface is
a single line -- the placeholder `open-pr` matches verbatim -- and a literal copy of it in the adopter
would have been a second definition free to drift from the first, which is the same argument the
branch-entry gate makes for calling a shipped script instead of hand-writing its check in shell. Where
the reference cannot be read, nothing is placed and the run says so; there is deliberately no fallback
string, because a fallback is that second definition wearing an emergency jacket and it is the copy that
ships in the one case nobody is watching.

This is one step of [#1843](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1843), which asks
for more than this and stays open: a portable `repo-settings.yml`, a CI skeleton, and the label question.
Each of those needs a decision first, and the issue carries the assessment and the red-team of it.

**Score:** 3

#### What makes this deploy extra special

The defect it closes was invisible from both ends. A consumer never saw a warning, because there is no
`else` on that path test; the source never saw it either, because every doc describing the copy was
written as an instruction to a person, and an instruction nobody follows leaves no trace. What made it
fixable was checking the reported reason instead of the reported symptom -- the report said `open-pr`
warns on a missing template, and reading the code showed it does not.

**Score:** 2

#### Pull Request

Place the PR template in a consumer's .github during adoption

Plugins: dkj-policy

[PR #1859](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1859)

---

### DEPLOY: docs/1846-adopt-step4-documentation-label · 20260911-125339

`adopt-dkj-policy-bwj` step 4 now creates every label its own existence check greps for.
`documentation` was checked for and never created, so a repo without it got a hit in the check and no
instruction -- while `report-issue` files `--label documentation` on a doc finding and `gh issue
create` fails outright on a label the repo does not have, exactly as it does for the reach label. The
step gains the create line, a paragraph recording why the gap never bit (`documentation` is a GitHub
default and both BWJ stores carry it) and why the label is load-bearing rather than decorative, and a
second stating that it deliberately gets no seam: nobody has renamed it, so what was missing is a
command and not a seam. A guard in `dkj-policy-bwj.tests.ps1` asserts the invariant rather than the
one name -- every literal label in the grep has a create line -- so a third name added to the check
without one is refused.

**Score:** 2

#### What makes this deploy extra special

The report behind it, [#1846](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1846), was
right about the symptom and wrong about everything else, and its headline repair would have damaged
the consumer it was filed from: `smartwatchbanden` did not lack `tier-1`, it **renamed** it to `minor`
with all 24 issues intact, so creating it back is the empty-duplicate state
[#1845](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1845) had forbidden by name hours
earlier. Verifying the reason rather than the symptom is what turned a harmful one-line fix into the
one narrow thing that actually stood.

**Score:** N/A

#### Pull Request

adopt-dkj-policy-bwj step 4 creates every label it checks for

Plugins: dkj-policy-bwj

[PR #1855](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1855)

---

### DEPLOY: docs/1851-two-propagation-channels · 20260911-123849

`CLAUDE.md`'s repo slot named one way a change reaches a consumer -- the plugin payload, gated by a
release and a version bump, landing in a session after `plugin update`. There are two. The three
runners `adopt-dkj-policy` scaffolds check this repository out at `ref: main` and run a path into
it, so a change to `check-branch-entry.ps1`, `check-unfolded-entry.ps1`, `fold-changelog-entry.ps1`
or `verify-resolved-issues.ps1` is live in every adopted consumer's next CI run: no tag, no bump, no
refresh, no restart.

Strictly the old sentence was never false -- CI is not a session. What made it worth repairing is
that the paragraph reads as the whole propagation model, and it is the document every session loads,
so a reader reasoning from it concludes that a shared gate script cannot reach a consumer before a
cut. That is the opposite of what happens, and the layer it was silent about is the one that can
change a consumer's required check with nobody bumping anything.

Nothing about the runners changes. The `ref: main` pin is argued by name in `adopt-dkj-policy`'s
skill page and #1805 already sharpened that argument; the addition points at it rather than
restating it. What is new is the writing rule: name the two channels together or name neither.

**Score:** 2

#### What makes this deploy extra special

A consumer reading this repo's `CLAUDE.md` as the model for their own now sees that adopting these
runners means tracking this trunk -- which is the one thing about the arrangement they cannot learn
from their side, and the reason a tag they own the bump on is offered as a trade in the skill page.
Nothing they run changes.

**Score:** 1

#### Pull Request

CLAUDE.md names the consumers' CI second checkout as the second propagation channel

[PR #1856](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1856)

---

### DEPLOY: fix/1850-runner-adoption-visible · 20260911-123203

The connector register can now tell an unadopted consumer from a clean one. Check 6 judges the paths
a consumer's CI runners name, so a consumer running NONE of the three runners this workflow
scaffolds named none, produced no finding, and read exactly like a fully adopted repo -- the limit
`consumer-runner-lib.ps1` had written into its own docstring without closing. Check 6c asks the
other question: does anything in that consumer reach into this tree at all.
`DaveKJohn/djcylow-react` is the measured case -- full core-team adoption registered, workflow
plugin listed, entire `.github/workflows/` one `ci.yml` -- and it reported green.

It is an `[INFO]`, on the line this register already draws for an unmigrated plugin id: both halves
of `adopt-dkj-policy` that place those runners are optional, so their absence is a state that may be
a decision. The finding says so, and points at the manifest's `notes` for recording one. Two bounds
are in the finding itself: only a manifest naming the workflow plugin is asked, and this repo's own
record never is -- it runs those scripts by local path, being the tree every consumer checks out, so
it is the one registered repo that can never produce a reference. It runs on the disk and, under
`-RemoteRunners`, over the network, where `no-workflows` used to be deliberate silence.

Worth keeping from the build: reading only one of the two record shapes the callers hold is a silent
miss rather than an error -- a hashtable's `PSObject.Properties` are Keys/Values/Count, so `Text` is
never found and every file reads as unreadable. That is what the first real run said, and
`Get-RunnerRecordField` is the answer.

**Score:** 3

#### What makes this deploy extra special

Nothing a consumer runs behaves differently -- this check lives in the maintainer's register and
reads consumers from the outside. What it changes is on the maintainer's side: a repo that never ran
parts 1 and 3 of the adoption is now visible instead of reading as clean, which is the difference
between knowing the gate is off and assuming it is on.

**Score:** N/A

#### Pull Request

the connector register reports a consumer that runs none of the scaffolded runners

[PR #1854](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1854)

---

### DEPLOY: feat/1842-unify-prio-labels-bwj · 20260911-122226

The BWJ store repos rank their issues on the same four labels as every other repo in the family:
`prio-1` to `prio-4`, on the same four colours, replacing `very low` / `low` / `high` / `very high`.
One vocabulary across the family, reversing half 1 of
[#1686](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1686) on Dave's instruction.
The score bands behind them are untouched -- the same mapping, said in the other repos' words -- and
what now says which motor set a rung is the label's **description**, which a rename leaves alone:
`Asana Prio-Score 2.00-2.99` over there against `Priority 2 of 4` here. The sweep sheds the four old
names as it sets a new one without ever writing them, so a repo migrated with the additive create
step instead of the rename is swept clean rather than left claiming two priorities at once.

**Score:** 3

#### What makes this deploy extra special

N/A. This workflow's consumers are the BWJ store repos, whose *developers* read these labels; no
customer of either store ever sees one. The migration itself is two `gh label edit` commands per
store, documented in the skill.

**Score:** N/A

#### Pull Request

Unify the BWJ priority labels on prio-1..prio-4

Plugins: dkj-policy-bwj

[PR #1849](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1849)

---

### DEPLOY: feat/1832-shared-document-newline · 20260911-120331

`Get-DocumentNewline` is now the one place this workflow reads a document's own newline style, in
`scripts/lib/document-newline-lib.ps1`. It was hand-typed at nine call sites across six files -- six
carrying the one-liner verbatim and three spelling the same answer over two statements, which is why a
grep for the one-liner undercounted it. Nothing about the answer changed: every caller reads the same
whole-file question it read before, and the six files' behaviour is identical.

What the absence cost is inbound #1829, one merge earlier: `adopt-workflow-folder.ps1` composed its one
rewritten block with a hardcoded LF while comparing it against a page read byte-exact, so the verdict
read `drifted` on every CRLF checkout. Four scripts in this tree already knew the answer to that exact
question; the fifth did not, and nothing connected them. A named helper is what the sixth one finds.

Inside this repo the gain is the guard rather than the tidy-up. The suite carries a tree-wide AST gate,
so a tenth hand-typed reading cannot land quietly -- and it pins the whole-file limit that #1829
accepted deliberately, which was previously a comment beside one of the nine sites and is now the
banner of the answer itself. That matters because the limit is the kind of thing a later reader
"improves" in one caller, and a local answer in one file would break the argument the other eight rest
on. A second thing surfaced on the way, from the gate built for exactly it: giving
`entry-scaffold-lib.ps1` a second unconditional leaf means every fixture that hand-copies its
dependencies owes the new file, so `fixture-lib-deps.tests.ps1` went red and eight fixtures were
repaired on `ref-print-lib`'s own #1650 precedent.

**Score:** 2

#### What makes this deploy extra special

Nothing a consumer runs behaves differently -- the mirror carries one more dot-sourced lib and every
command gives the same answers it gave before -- so the reach here is genuinely nil rather than small.
Worth saying because the change is adjacent to a v5.0.0 consumer-facing repair and could be mistaken for
part of it: #1829 fixed the drifting verdict, and this one only makes sure the next document-editing
script cannot reintroduce it.

**Score:** N/A

#### Pull Request

one helper for reading a document's own newline style

Plugins: dkj-policy

[PR #1840](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1840)

---

### DEPLOY: fix/1841-reach-label-seam · 20260911-115239

`dkj-policy-bwj` no longer writes the reach label's name as a literal. The string GitHub stores comes
from `Get-ReachLabel` in the consumer's own `scripts/repo-config.ps1`, defaulting to `tier-1`, so
every existing consumer is unchanged and silent; the reach axis itself keeps its own name in the prose
that explains it, because what a consumer renames is a row in their label settings, not the model. The
filing command, the decision table, both after-the-fact `gh issue edit` lines, the worklist query and
`adopt-dkj-policy-bwj`'s existence check and `gh label create` all read the seam. Step 4 also stops
before creating: a missing reach label means either that the repo never had one or that it renamed it,
and only the first is safe to add -- creating it in the second case leaves two labels for one axis,
one of them empty, with nothing reporting it. A guard in `dkj-policy-bwj.tests.ps1` refuses the
literal in the command shapes if it is ever written back.

**Score:** 2

#### What makes this deploy extra special

`BWJ-Development/smartwatchbanden` renamed its reach label to `minor` on September 11, 2026 and
`report-issue` has been failing outright there since -- `gh issue create` errors on a label the repo
does not have. Answering `Get-ReachLabel` with `'minor'` is the whole fix on their side, and the next
`adopt-dkj-policy-bwj` run no longer quietly re-creates `tier-1` beside the label their issues are
actually on.

**Score:** 4

#### Pull Request

A seam for the reach label's name, so a consumer that renames it keeps report-issue working

Plugins: dkj-policy-bwj

[PR #1845](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1845)

---

### DEPLOY: fix/1838-runid-repo-root-shape · 20260911-100046

`record-suite-durations.ps1` now refuses a run-id-shaped `-RepoRoot` by name instead of failing deep
inside `Resolve-Path` with no mention of `-RunId`, and its docstring states the comma-separated form
the script actually expects for several run ids under `-File`.

**Score:** 1 -- a docstring clarification and an error-message fix on a script only a session invokes
by hand; it prevents a failure that costs a minute of re-diagnosis, nothing more.

#### What makes this deploy extra special

N/A -- an internal maintenance-script fix, not visible to a subscriber of any service this repo ships.

**Score:** N/A

#### Pull Request

record-suite-durations.ps1: space-separated -RunId binds second id to -RepoRoot

[PR #1839](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1839)

---

### DEPLOY: fix/1831-connector-swb-candidate · 20260911-095211

`connectors/smartwatchbanden.json` records a fourth `localCheckout` candidate,
`../../bwj-development/smartwatchbanden`, so a machine laying the BWJ trees out that way checks that
consumer instead of skipping it. Before this, `check-connectors.ps1` asserted the checkout was absent
and exited 0, suppressing five plugin blocks, their extension inventories and their version drift --
the silent class #1524 named and #1807 repeated, one machine further.

The append is pure: `localCheckout` is first-match-wins and additive, so the three earlier candidates
keep working on the machines they are true on. #1807's note had anticipated this entry, guessed it as
`bwjdevelopment/` and deliberately declined to record an unobserved layout; the real folder is
hyphenated, so that guess would have been wrong -- which is the argument for the rule rather than
against it.

**Score:** 3

#### What makes this deploy extra special

N/A -- the connector register is this repo's own maintenance bookkeeping. A consumer of the
specialists system neither reads it nor is affected by it; what changes is what a maintainer's own
`check-connectors` run can see on one machine.

**Score:** N/A

#### Pull Request

Record the bwj-development/ layout as a smartwatchbanden connector candidate

[PR #1836](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1836)

---

### DEPLOY: fix/1833-suite-durations-refresh · 20260911-093745

`scripts/tests/suite-durations.json` is re-recorded from two CI runs that carry the suite set as it now
stands, and the refresh turned out to be larger than the row #1833 was filed about. That row --
`adopt-workflow-folder.tests.ps1`, understated after `fix/1829-crlf-section-drift` took it from 20 to 25
scaffold spawns -- moves from 32.6s to 40.6s. The bigger find is the count: the file held **84** rows
against **91** suites on disk, so seven suites had no row at all and `Invoke-TestSuiteGate` was charging
each of them the largest recorded value when it packed the four shards. That is the safe direction by
design -- a new suite starts early and can never be the one left last -- but seven suites priced at 290.2s
apiece is a packing the measured pool does not support.

`record-suite-durations.ps1` also now names the one run a caller reaches for first and cannot use. A ship
pushes to the trunk twice and both pushes get a CI run; the **fold** commit's is the newer of the two, so
it sits at the top of `gh run list`, and #1300 skips the suites step on it outright. Its four suite jobs
check out, stop, and complete green, so nothing about the run says it measured nothing -- the script's
`printed no per-suite duration table` throw asked "is it a CI run that ran the suites job?" and the honest
answer was yes. It now says which commit kind to avoid and which to take instead.

What is deliberately **not** here is #1833's second half. The issue asks whether something should *report*
this staleness -- option 2, a detector comparing `recordedFrom` against the current suite set -- and calls
it a decision rather than a repair. It stays on the issue.

**Score:** 3

#### What makes this deploy extra special

N/A -- neither changed file is plugin payload. `suite-durations.json` and `record-suite-durations.ps1`
both live under this repo's own `scripts/`, are mirrored into no plugin, and so reach no consumer.

**Score:** N/A

#### Pull Request

Re-record suite-durations.json from CI runs that carry the new CRLF fixture

[PR #1837](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1837)

---

### DEPLOY: fix/1830-git-identity-skip-vs-ok · 20260911-093136

`git-identity-sessioncheck.ps1` (the SessionStart hook of the workflow plugin) now distinguishes a
genuine `[OK]` from a `[SKIP]` instead of treating both as "clean" because both exit 0. Previously,
on a machine with no git identity at all (or one `check-git-identity.ps1` could not compare for any
of its three `[SKIP]` reasons), the hook still printed "the gh account and the git identity agree" --
a claim that a comparison happened when none had. That is what it cost a session on the measured
machine: the false "agree" line was read as "identity is fine", and the session's first commit then
failed outright (`Please tell me who you are`). `[SKIP]` now stays silent at session start, matching
the check script's own documented promise; `[OK]` keeps its one-line agreement sentence, and
`[ERROR]` keeps its full report -- neither of those two paths changed.

**Score:** 3

#### What makes this deploy extra special

Every consumer repo running the workflow plugin gets the corrected hook on its next plugin release --
one fewer false "identity is fine" signal on any machine with no git identity or a display-name
`user.name`, which is the exact shape that produced a failed first commit here.

**Score:** 2

#### Pull Request

git-identity-sessioncheck distinguishes [OK] from [SKIP] instead of branching on exit code

Plugins: dkj-policy

[PR #1835](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1835)

---

### DEPLOY: fix/1829-crlf-section-drift · 20260911-092050

`adopt-dkj-policy` Part 1's README top-up now judges the block it owns, not the line endings of the page
around it. It reads the page's own newline style and composes the block with it, so a page checked out
CRLF -- which is what `core.autocrlf=true` gives every Windows clone -- no longer reports
`the plugin's block has drifted` on every fresh checkout, and `-Apply` no longer leaves the page with LF
between CRLF. A genuinely stale block is still replaced, and an LF page is still written pure LF.

**Score:** 2

This repo refuses that scaffold outright -- it publishes the workflow -- so nothing here changes but the
suite. What it gains is the regression test: every fixture in it wrote LF until now, which is how a
Windows-only defect survived in the one block the suite pins hardest.

#### What makes this deploy extra special

Consumers on Windows get a verdict that carries information again. The failure was quiet and permanent
rather than one-off: the command said "drifted" every time, so a block that really was stale read exactly
like one that was current, and the only way to tell them apart was to run `-Apply` and check `git diff`
afterwards. That is the feature v5.0.0 announces as "can be kept current with one command".

**Score:** 3

#### Pull Request

The README block top-up preserves the page's own line endings

Plugins: dkj-policy

[PR #1834](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1834)

---

### DEPLOY: docs/1823-uninstall-step5-machine-wide · 20260911-073858

`UNINSTALL.md`'s Step 5 ran `claude plugin marketplace remove` with no reader-facing statement that the
command is machine-wide over install records, so a reader tearing down one of several checkouts, exactly
by the book, silently took this family's install records off every other repo on the machine. The page was
thorough about that command and measured a different axis: its per-file table credited Step 5 with the
clone and the `known_marketplaces.json` entry, attributed every install record to Step 2, and every
bracket on the page was taken on a single-adoption profile — where Step 5 provably touches no record,
because Step 2 already took the only one. Such a reader is now told to **skip Step 5** and stop at Step 4,
and the claims written for a reader who finishes there each get their second reading: *"the registration
comes off last"*, the `marketplace list` verification, and the clean-machine section. What skipping costs
is stated so it can be weighed, and the query that answers *"am I the last checkout?"* is given — with the
three ways it misreads, including the false negative found by running it here: a machine registered under
the marketplace's retired name answers nothing to a filter naming the current one.

**The reason #1823 gave for the severity does not hold, and the page now says what does.** That issue
argued the damage has no floor because nothing reinstalls. Step 3's own measured table (inbound
#327/#382) says a sibling checkout repairs itself in two session starts with no command run, because a
teardown removes only the keys its own repo wrote and `extraKnownMarketplaces` is what puts the
marketplace back. The real cost is narrower and worth avoiding anyway: one session that silently loads
nothing, a clone rebuilt at the marketplace's current HEAD rather than the version that repo was running,
a recovery that is CLI behaviour nobody owns, and no recovery at all for a checkout whose owner has since
tidied that key away. `INSTALL.md` also loses a false claim caught alongside this: `--scope` is documented
on `marketplace remove`, verified against the CLI, though it still fences nothing that was measured. The
mechanism lands in Sylvester's portable manual rather than a lens, being a property of the CLI, and it
carries the corrected version plus a standing warning against the confident one.

**Score:** 3

#### What makes this deploy extra special

`UNINSTALL.md` is one of the two procedures a consumer of this marketplace meets, and this is the step
where following it correctly reaches into their other repos. Anyone running the teardown on a machine with
more than one adoption is affected, and it was silent in all three of the places they would look. The
failure being prevented, named because no teardown run has been measured hitting it: a consumer
disconnecting one of several checkouts loses this family's install records from every other repo on the
machine with no signal anywhere — `enabledPlugins` still reads correct and the hooks that would complain
went with the plugin — and gets them back, if at all, from a self-repair nobody commanded, onto whatever
the marketplace's HEAD is by then.

**Score:** 4

#### Pull Request

UNINSTALL.md's Step 5 states its machine-wide reach, and a multi-checkout reader is told to skip it

Plugins: dkj-subagents-alpha

[PR #1828](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1828)

---

### DEPLOY: docs/1824-install-cross-plugin-reinstall · 20260911-070940

`INSTALL.md`'s migration sequences each uninstall one family of ids, then run
`claude plugin marketplace remove claude-code-specialists`, then reinstall what they uninstalled. That
middle command is not selective by plugin: install records are keyed `<plugin>@<marketplace>`, so
retiring the marketplace half takes **every** plugin's record with it -- including the ones the section
never named. Both partial sections ended with a plugin silently uninstalled and `enabledPlugins` still
naming it under a marketplace that no longer exists. Nothing errored and nothing printed.

The `dkj-team-*` section was the worse of the two, because its blockquote told the reader in so many
words that the workflow ids were **unchanged -- do not touch them**, which is exactly what stopped them
looking. Both sections now reinstall what step 3 takes, as a `4b`, and the step-3 comment in all three
states both axes of the command's reach instead of only the cross-checkout one.

**Score:** 4 -- a consumer following either section loses a working plugin and gets no signal at all;
the page is the only thing that can tell them, since a session that loads no plugin has no hooks left
to complain.

#### What makes this deploy extra special

The report named one section; the defect was symmetric and the neighbouring section had the mirror of
it, which verification found rather than the report. Repaired together, because half of this repair
would have left the page saying two different things about the same command.

**Score:** N/A

#### Pull Request

INSTALL.md: marketplace remove drops every plugin's record, so each migration section must reinstall what it dropped

[PR #1827](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1827)

---

### DEPLOY: fix/1821-connector-origin-mismatch · 20260911-005322

`check-connectors.ps1` followed a record's `localCheckout` by path and never asked which repository
the folder actually was. Measured on two machines: the record for `BWJ-Development/smartwatchbanden`
resolves to a clone of the archived `BWJ-ecommerce/smartwatchbanden` -- two distinct repositories that
merely share a name half -- and the check printed five confident `[ERROR]` lines about a repository it
had never opened. That is worse than silence, because it invites somebody to repair a consumer that is
already correct.

Check **1b** now reads the checkout's own `origin` before anything reads that disk on the named repo's
behalf, and says what it measured rather than what it guessed. Agreement is silent. A mismatch is one
`[ERROR]` naming both slugs, stating that nothing about the named repository was checked, and giving
the two things it can be -- a clone of a different repository, or a `localCheckout` pointing at the
wrong folder here -- with the command for each; every verdict below is withheld rather than printed
against a repo that was never read. It does not claim more than a local read can support: without a
network call this run cannot tell a different repository from an old spelling still answering a
transfer redirect, and the finding says so.

Two things the review round changed, both of which the finding turns on. The question asked is whether
the checkout is the work tree **root**, not whether it sits inside one -- `--is-inside-work-tree` is
true for any folder nested in a parent repo, so a `localCheckout` resolving to a folder that was never
a clone used to be reported under its enclosing repository's `origin`: a false `[ERROR]` blaming the
wrong repo, or a false *silent agreement* where the enclosing repo happened to match. And the printed
remedy holds the register's slug to GitHub's own shape before composing a copy-pasteable command from
it -- the guard this same file already applies to that field before it reaches an API call, which the
first draft skipped.

The arm that makes it safe to ship is the one the issue did not anticipate. A plain comparison fires
falsely on the source repo's **own** connector -- `connectors/dkj-claude-plugins.json` names
`DKJ-Solutions/dkj-claude-plugins` while this checkout's `origin` is still
`DKJ-Solutions/claude-code-specialists`, the #1769 rename landing on a transfer redirect. So a mismatch
that this repo's own rename history explains is a dim `[SKIP]` naming the one command that ends it, and
the run proceeds untouched. Without it the check would have cried wolf about itself at every session
start, in the repo that ships it.

**Score:** 3

#### What makes this deploy extra special

A consumer's own session runs this check too, scoped to its own manifest, so a consumer whose checkout
was cloned before a rename or an org move stops being told that five plugins are not enabled and is
told the one true thing instead: the folder being read is not the repository the register names. It
only fires where that is actually the case, which is why it is not higher.

**Score:** 2

#### Pull Request

check-connectors names the repository a checkout actually is

[PR #1826](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1826)

---

### DEPLOY: docs/1820-marketplace-remove-machine-wide · 20260910-231520

`INSTALL.md`'s three migration sequences now say that step 3's `claude plugin marketplace remove` is
machine-wide over install records, and a new section states what that means for a machine with more than
one checkout. It also splits step 3, which is two commands with two different reaches: `remove` drops the
registration for the whole machine and is run once, while `marketplace add … --scope project` writes the
source key into the repo it is run in and is owed to every checkout. So the first checkout runs the whole
sequence and each one after it skips step 2 and the `remove`, then runs the `add` and step 4. The section
carries the measured record counts, both of the CLI's failure messages verbatim — the second reads as a
`--scope` mistake by the operator and is not one — and the bounds of what was measured. The same
mechanism is now a hard rule in the system administrator's portable manual, so it travels to every
consumer rather than living only on this page.

Before this, a reader with three checkouts was told by the page's own per-checkout framing to run the
sequence three times, and the first run silently made steps 2 and 3 impossible in the other two — with
two error messages that name a missing plugin or the wrong scope rather than the cause.

**Score:** 3

#### What makes this deploy extra special

A consumer migrating more than one checkout hits this on the second one, and the page gave them a red
error at a step its own step 3 had already made impossible. Nothing was broken on their machine and the
CLI's wording says otherwise. It is a procedure repair on the page consumers are told to follow, so it
reaches anyone still to migrate.

**Score:** 3

#### Pull Request

State that marketplace remove ends the other checkouts' migration

Plugins: dkj-subagents-alpha

[PR #1825](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1825)

---

### DEPLOY: fix/1769-flag-day-register-and-install-page · 20260910-224248

The connector register now records the five consumer repositories as they actually are after the
`v5.0.0` flag day: `<plugin>@dkj-claude-plugins`, with the current plugin names. Every record was
written from the consumer's own `.claude/settings.json` on `main` rather than from the migration plan,
which matters because three of them were two renames behind and the plan's one-axis swap would have
written ids that never existed.

This is decision A coming due rather than a change of mind about it. The doctrine in
`connectors/README.md` -- write a renamed id only after the consumer itself has migrated, so the
register never raises a false alarm about a migration nobody performed -- held the whole way: all five
consumers merged first, and their records followed within the hour.

**And `INSTALL.md` stops handing a reader the retired slug in a command they are meant to paste.**
Four sites resolved the repository name rather than merely printing it, and two contradicted
themselves inside three lines by naming the marketplace `dkj-claude-plugins` while pointing its
`repo` at `DKJ-Solutions/claude-code-specialists`. They worked, because GitHub answers the transfer
redirect -- which is exactly the dependency `CLAUDE.md` says must never be load-bearing, since it
holds only while nothing is created at the old path. The three old-slug hits still on the page are
issue URLs and are correct as they stand.

**Score:** 3

#### What makes this deploy extra special

**A page that tells a new consumer to register the wrong source is the one doc defect that cannot be
noticed by the person it hurts.** The registration succeeds, the plugins install, and nothing is
visibly wrong -- until the day the redirect stops answering, at which point the failure lands on
somebody who followed the instructions exactly. Three adoption rounds' worth of lint rules in this
repo exist for that class, and this is the same class arriving through the rename that was supposed
to close it.

The register half has a quieter payoff: `check-connectors.ps1` is the thing that answers *"is this
consumer behind?"*, and it SKIPS a plugin whose id it cannot resolve. With five records naming a
marketplace that no longer exists, every one of those consumers would have been unreportable in
exactly the way #1465, #1525 and #1698 each recorded before -- the fourth time by the same route.

**Score:** 3

#### Pull Request

The connector register and the install page catch up with the flag day

[PR #1822](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1822)

---

