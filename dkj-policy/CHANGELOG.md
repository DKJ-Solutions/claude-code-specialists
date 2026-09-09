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

**29 / 63 minor entries** <!-- pending-tally -->

### DEPLOY: fix/1689-porcelain-path-decode-once · 20260909-074736

Reading a git path now happens in one place. `Convert-GitQuotedPath` — which decodes git's C-quoted
form, escape by escape, into the real filename — has moved out of `sync-rules.ps1` and into
`git-porcelain-lib.ps1`, beside the `core.quotePath` flag that produces the form it decodes. So the
porcelain reading no longer stops one step short: `park-lib`, `fanout-lib` and `sync-main` all get the
readable path, and `fanout-lib` loses a limit it had written down as permanent.

**The move went in the opposite direction from the one #1689 proposed, and that is the substance of the
change.** `sync-rules.ps1` is dependency-free on purpose — the live-theme guard loads it on every
command inside a catch that returns no live theme id — so making it dot-source anything is a way to
disarm that guard silently. It never called the function it defined, so it could lose it instead, and
`sync-main.ps1` takes the lib directly, unguarded, exactly as it already takes two others.

**And a decode obliges a print guard**, which is the second half of the change. Since a decoded
path can carry a live ESC byte or an RTL override, `fanout-lib`'s loss report now routes every printed
path through `Get-DisplayPath` and every printed ref through `Get-DisplayRef` -- three sites, one of
them older than this branch. The strip is at the report, so a finding still carries the exact path.

**Score:** 3

#### What makes this deploy extra special

N/A — nothing a consumer of the plugins notices, provided the release carries both mirrors, which is
what the new `sync-main.tests.ps1` assert exists to prove. A consumer running `dkj-team-shopify`
without `dkj-policy` gets the lib from its own plugin's payload; the readable path in a sync report is
the only visible difference, and reports are not a published surface.

**Score:** N/A

#### Pull Request

Reading a git path lives once: the quoted-path decoder moves into git-porcelain-lib

Plugins: dkj-policy, dkj-team-shopify

[PR #1696](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1696)

---

### DEPLOY: feat/1680-synopsis-check-list · 20260909-072322

The gate's `.DESCRIPTION` enumerates its checks in prose -- the summary a reader who has not opened four
thousand lines consults, and the one a lens, a hook, a test-scenario name or a released note quotes a
number from. It had stopped at `30.` while the code ran to `36.`, and its own item `30.` still described
the check #1494 renumbered to `33` a month after the list was written, so grepping the list for "check 30"
answered with a different check. Two more drifts were found on verification and neither was in the report:
items `9.` and `17.` still read as live checks a month after they were **retired**, and `13b` had no entry
at all.

**Check 37 now holds that list to the file's own column-0 headers**, because a hand rewrite resets the
clock rather than stopping it -- the conclusion check 32's header already records after three hand repairs
of the mirror table. It is opt-in through the same marked-span walk checks 10, 29 and 32 use, so it
inherits their three refusals for free and no unmarked script becomes a subject; it reads check 34's own
header pattern, so the two cannot disagree about what a header is; and it asserts **one direction only** --
every header needs an entry, an entry needs no header. That is what let it be born green rather than with
an exemption list: three entries legitimately have no header of their own, the two retirement tombstones
and the consumer-doc guard the suites call check 19. Measured after the repair: 1 span, 37 headers, 37
claimed, 0 findings, 0 exemptions. Its own first run is the argument for it -- `13b` was reported by the
check, not by a reader.

The review round moved four things, and three were one defect in different clothes -- a rule read off the
happy path. An entry must now **start inside the list's gutter**, so a nested enumeration in an entry's
prose cannot satisfy a header (found by probing the check, not by measuring the tree: the list contains no
such line today); the header comparison runs once per FILE over the union of its spans, where running it
per span doubled the count and named one gap twice; and the coverage note now distinguishes "no marker
anywhere" from "markers present, none of them paired", which used to print the reassuring sentence over a
run that had just raised an error about that very file. Two bounds are named rather than closed -- a
STALE entry still satisfies its number, and the two zero-state notes are unreachable from the suite
because every fixture run copies this script into the fixture -- both written into the check's own header,
because an unstated gap reads as coverage.

**Score:** 3

#### What makes this deploy extra special

N/A. `check-plugin-integrity.ps1` is this repo's own gate and is mirrored into no plugin, so nothing here
reaches a consumer: the repaired list, the new check and its scenarios all stay in the source tree. A
consumer's own lint script is theirs, and the marker is opt-in, so nothing starts asserting anything on
their side either.

**Score:** N/A

#### Pull Request

The gate's own check list is held to its headers, and the seven it had lost are back

[PR #1695](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1695)

---

### DEPLOY: fix/1682-porcelain-line-parse · 20260909-071236

The `git status --porcelain` reading lives once, in `scripts/lib/git-porcelain-lib.ps1`, dot-sourced by
`park-lib` for its uncommitted count and by `fanout-lib` for its per-path snapshot. Both callers had a
near-verbatim copy of the parse, and two of the three git quirks underneath it were properties of the
command rather than the parse — so the lib owns the command and its two flags too, with all the
reasoning in one header instead of half in each.

**It repaired a defect while consolidating, which is the argument for consolidating.** Both copies
normalised backslashes to forward slashes over *every* path, including the ones `core.quotePath` exists
to produce, so `"caf\303\251.txt"` read back as `caf/303/251.txt`. Latent in both callers — a count
still counts and a comparison still matches when both sides mangle identically — and wrong for the
first caller that looks for the file.

**Score:** 3

#### What makes this deploy extra special

N/A — nothing a consumer notices. The lib is mirrored into `dkj-policy` because both its callers are,
so a consumer's `park-cycle` Stop hook keeps working; the behaviour it produces is the same count and
the same snapshot as before, minus the mangled path nobody had hit yet.

**Score:** N/A

#### Pull Request

The git porcelain line parse lives once, in a lib both callers dot-source

Plugins: dkj-policy

[PR #1694](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1694)

---

### DEPLOY: docs/1686-priority-axis-decision · 20260909-065028

The priority axis exists twice in this family and now says so on purpose. The two schemes -- `prio-1`
to `prio-4` here, `very low` to `very high` in the BWJ store repos -- stay apart, because the names are
the only thing that says which motor owns the rung: one is a judgement typed by whoever files, the
other is derived from an Asana score by a daily sweep, and a single vocabulary would invite a session
to hand-set a rung that a sweep is about to overwrite. Measured on all three trackers, the two sets are
disjoint in both directions, so the collision the issue was filed about can only ever produce a refused
label that names itself -- not an issue filed at a rung meaning something else. And the rule that every
issue carries a rung stays this repo's own: nothing in the workflow reads a priority, so a portable
version would prescribe a convention no gate enforces and hand consumers four labels they never asked
for.

**One thing the decision deliberately does not close, and it is now named rather than implied.** The
same measurement that clears the names indicts the **colours**: `0E8A16` is the floor here and one rung
above the floor in a BWJ repo, and nothing refuses a colour the way `gh` refuses a name. The lens
carries that table and the instruction not to read a rung off a badge across the two families; the
repair itself is #1691, because its cheap half edits live labels in two repos this one does not own.

**Score:** 2

#### What makes this deploy extra special

One paragraph reaches a consumer, and it is the half worth having: a BWJ session that reaches for
`prio-4` and gets a refusal now reads that as the expected answer rather than as a broken setup, and
is told in the same breath that nothing on their side needs doing. The rule itself deliberately did
not become theirs to follow.

**Score:** 2

#### Pull Request

The two priority label sets stay apart, and the rule stays repo-local

Plugins: dkj-policy-bwj

[PR #1692](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1692)

---

### DEPLOY: fix/1679-utf8-short-read-class · 20260909-062511

`Invoke-NativeCapture` now says when a capture was read while a writer still held it, so a caller can
tell "the child said nothing" from "we read before the flush". Both are an empty `Output` at exit `0`,
and until now nothing separated them -- so six callers in the shipping scripts resolved the ambiguity
toward a substantive answer: "no PR", "no issue declared", "the body does not carry the section",
"the claim was refused". The sharpest refused the merge over a section that had not changed, in a
gate with no `-Force`. The quietest reported the resolves verification as a clean pass having checked
nothing. And the one that reaches furthest is the claim step, which told an operator to treat an
issue as UNCLAIMED on a claim that had in fact landed -- the first move of every issue-driven
assignment. The read itself is unchanged: `FileShare.ReadWrite` still returns whatever was flushed
(#1252), it simply no longer does so in silence, and on a clean exit it now waits briefly for the
handle to release rather than reporting a short read it could have avoided.

**Score:** 3

#### What makes this deploy extra special

These are the scripts a consumer runs through the workflow plugin, so the wrong verdicts were theirs
to meet: a merge refused by a gate with no way past it, an already-done check that quietly stopped
warning, and a claim step that refused a claim it had itself just written. Nothing to do on adoption
-- the field is additive and every existing caller keeps working -- but the refusals a consumer does
hit now name the read that failed instead of accusing their document, and the one skipped check that
cannot be recovered says so in a warning rather than in a dim grey line.

**Score:** 3

#### Pull Request

A short capture on exit 0 is reported as a short read instead of as a substantive answer

Plugins: dkj-policy, dkj-team-shopify

[PR #1690](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1690)

---

### DEPLOY: docs/1678-nested-worktree-refusal · 20260909-060959

The lint gate's tree walks are filesystem walks, so a worktree registered inside the repo is a second
complete copy of the tree it is standing in: every recursive count from the root doubles exactly
(`*-agent.md` 26 to 52, `*.ps1` 233 to 466) and the gate fails with 26 duplicate-id errors, each one
accusing the **real** file. #1673 repairs what an operator reads. What it deliberately left open, and
what this branch answers, is whether the gate should instead be made to work *through* such a worktree
-- roughly twenty `Get-ChildItem -Recurse` sites plus the suites that walk the root, behind a shared
predicate and a meta-check of its own.

It should not, and the exclusion is now recorded as DECLINED beside the gate's other measured-and-
declined rules, so the option is priced rather than re-argued the next time somebody meets the 26
errors. Four grounds, each measured on this tree: the lint half of `Invoke-WorkflowGates` returns
before the test gate is ever reached, so on the documented route the doubling suites never run and
excluding the path from them buys a caller nothing; the report's price was one suite too high --
`template-selfcontained.tests.ps1` walks `plugins/`, not the root, and its count is unmoved by a probe
worktree, leaving two rather than three; a predicate every future walk must remember to call is the
enforced-by-memory shape #1665 was filed against, in a file already carrying 36 numbered checks; and
`worktree-lane.ps1` has already decided where a worktree belongs, placing lanes outside the tree for
exactly this reason. The residual is stated rather than left to be found: under `-SkipLint` those two
suites still take a doubled set in silence, which is what that switch means everywhere here.

**Score:** 2

#### What makes this deploy extra special

N/A. One repo lens changes and nothing else -- no script, no manifest, no plugin payload. The gate it
describes is `check-plugin-integrity.ps1`, which is not mirrored into any plugin, so a consumer
receives nothing from this and their own gate's answer to the same fork stays theirs.

**Score:** N/A

#### Pull Request

The lint gate refuses a nested worktree rather than walking through one

[PR #1688](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1688)

---

### DEPLOY: feat/1685-prio-labels · 20260909-055712

Every issue in this repo's tracker now carries exactly one priority, `prio-1` (lowest) to `prio-4`
(highest). The four labels exist on GitHub, the ten issues open on the day were labelled in the same
movement — a taxonomy applied only to new issues splits the tracker in two, and the older half is
where the backlog is — and the rule that a finding is filed *with* its priority is written down in
the always-on layer, so the next session does it without being reminded. It is a separate axis from
the prefix→label mapping that classifies a pull request — `enhancement`, `bug` and `documentation` are
the labels this repo already had, written from the branch prefix; a `prio-N` is the new one, written by
whoever files. Derek's lens says so, and says which command re-ranks an issue without leaving two
rungs on it.

**Score:** 3

#### What makes this deploy extra special

N/A — nothing here reaches a consumer of the plugins. The labels are this tracker's own state and
both documents are repo-local lenses, which travel to nobody.

**Score:** N/A

#### Pull Request

Priority labels prio-1..prio-4 on every issue

[PR #1687](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1687)

---

### DEPLOY: feat/1670-fanout-shrinkage-detection · 20260908-222347

A dispatched fan-out can no longer discard this session's uncommitted work invisibly. `#1665` measured
a review specialist running `git stash` and then `git checkout HEAD -- <file>` in the orchestrator's
checkout, taking three files of uncommitted work with it: no error, no notice, no refusal, and a clean
`git status` afterwards -- which the review's own report cited as proof it had changed nothing. It was
found days later, by accident, when a `grep` showed old text where new text had been verified minutes
earlier. That was repaired with an instruction; `#1670`'s point was that **nothing anywhere detected
it**, so a repeat would be exactly as invisible as the first, and less conspicuous whenever what gets
discarded is a config value rather than a paragraph somebody later reads.

The new `check-fanout` skill takes a reading of the working copy before a dispatch and compares it
after, and what it reports is **shrinkage only** -- a path that was changed and is not any more, a
worktree edit reverted under a path that remains, or a stash entry gone by its own id. That asymmetry
is the whole design: a subagent legitimately writing files makes the list **grow**, which is expected
and never reported, so the detector has nothing to say on an ordinary fan-out. Five false positives are
answered rather than tolerated -- the orchestrator's own commits (their paths are excluded), a rewritten
history and a branch change (both refuse to difference at all, because a wrong list is worse than none),
`git reset`, which moves a change from the index to the worktree and destroys nothing, and a `git mv`,
which the comparison follows rather than exempts, so a loss on the far side of a rename is still caught.

**Three answers, not two, and the third is the one worth knowing.** Exit 0 means the comparison was
made and nothing shrank; exit 1 that something did; exit **3** that the comparison could not be made at
all -- a branch change, a rewritten history, or a git read that failed. That last is the likeliest
outcome in this tool's own scenario, where dispatched agents run `git` concurrently in one checkout and
a `git status` can lose a race for `.git/index.lock`, and an incomplete answer now keeps the baseline
instead of spending it, because a retry is exactly the right next move.

**It goes further than the issue asked in one place, and admits a weakness in another.** `#1670`
proposed counting stash entries and said a count is enough; it is not, and a subagent that pops one
entry while the orchestrator pushes another leaves the count unchanged -- so entries are compared by
their own commit ids and that case is pinned in the suite. The weakness is that the baseline has to be
taken by somebody: this is an invoked step, not a hook, because a `Pre`/`PostToolUse` pair around the
dispatch rests on the matcher name of the dispatch tool and that has not been measured. Nothing here
rests on anything unmeasured, the hook variant stays open on `#1670`, and it is cheap to add because
the judgement it would need is already the shared function rather than anything in the script.

**And it reports rather than restores, which is a property of the damage and not a choice.** Content
discarded by `git checkout HEAD -- <path>` was never committed and sits in no reflog, so there is
nothing to restore it from -- which is precisely why the detection gap was the one worth closing. What
a finding buys is knowing which file to write again, so it names the path, unlike `park-lib`'s
counts-only figure that ends up in a public commit.

**Score:** 3

#### What makes this deploy extra special

N/A. This repo is not a service anyone subscribes to; the reader here is a developer maintaining it or
consuming the plugins, and what they get is scored above. It reaches a consuming repo through a release
like any other shared script.

**Score:** N/A

#### Pull Request

A dispatched fan-out's working-copy losses are detected instead of found by accident

Plugins: dkj-policy, dkj-team-alpha

[PR #1683](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1683)

---

### DEPLOY: fix/1676-remote-ahead-tip-short-read · 20260908-220203

The remote-ahead warning now says when it could not read the diverged branch's tip, instead of dropping
that half of the sentence in silence. `Get-RemoteAheadNote` reads an empty `git log` capture on exit code 0
as a failure to read rather than as nothing to report, names which of three reasons it was, and states
that the author and the subject are missing from the warning and not absent from the branch.

The silent drop degraded the guard to exactly the sentence #1439 was filed for being insufficient: "1
commit(s) behind" reads identically for another session's push and for a fast-forward of your own autopark,
and the author and the subject are what separate them. It degraded on the loaded machine, which is when two
sessions are most likely to be racing.

**Score:** 3

#### What makes this deploy extra special

`remote-ahead-lib.ps1` is a shipping script, so this reaches every consumer through the next release, at
all three doors that ask the question -- `new-branch`'s resume warning, `open-pr`'s remote-ahead gate and
`park-cycle`'s refused-push report. Nothing a consumer types changes; the sentence gains a clause it used
to omit.

**Score:** 3

#### Pull Request

The remote-ahead warning says when it could not read the tip, instead of dropping it in silence

Plugins: dkj-policy

[PR #1681](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1681)

---

### DEPLOY: feat/1605-sessioncheck-version-cache · 20260908-204605

A session start on a machine with no source checkout stops paying for its version verdict twice.
`connector-sessioncheck`'s consumer fallback ran `plugin-versions.ps1 -Brief` -- two nested
powershell bring-ups plus git in the marketplace clone -- at every firing of the
`startup|resume|clear|compact` matcher, so a session with four compactions measured five times for an
answer that had not changed. The matcher stays exactly as it is; narrowing it is what makes the whole
report go silent after the first `/compact`. Instead the engine's output is now held for the life of
the session, keyed on the `session_id` the harness writes to the hook's stdin: a compaction keeps
that id and replays, a startup and a `/clear` bring a new one and re-measure, so nothing has to read
the payload's `source` field or decide which kinds of firing may trust a cache. Measured over five
measure-then-replay pairs against a synthetic five-plugin consumer fixture: a median of 1,288 ms
against 439 ms, about 850 ms back per compaction.

What a replay guarantees is a **bound, not an invariant**, and that is the one place this branch
disagrees with the issue that asked for it. #1605 argued the cached answer cannot go stale within a
session, citing the hook's own "restart the session" line -- but that line is about a hook's *code*
being pinned, while the verdict is about two ordinary mutable files, and a sibling terminal running
`claude plugin update` moves them with no restart involved. So a replay is bounded by age at one hour
rather than the four this started with, the reasoning is written into the lib's header instead of the
citation that does not carry it, and the direction a reader acts on self-heals: acting on "you are
behind" means an update, after which this hook says to restart -- which is a new id and a bypass.

Everything about it fails towards measuring. No session id, an unwritable cache directory, a corrupt
entry, a plugin payload predating the lib: each falls back to the spawn this branch exists to avoid,
which is exactly what the hook did before. The suite counts engine spawns on disk rather than
inferring them from wall-clock, so "the second firing spawns nothing" is a measurement.

**The cache does not live under the shared temp root**, and that answers #1666, which landed while
this branch was open: every temp path in this layer is now composed per run with a guid, so nothing
can be pre-planted at a name that does not exist yet. A cache is the one thing that cannot take that
shape -- a later process has to find what an earlier one wrote, and a guid is what a later process
cannot re-derive. So instead of a third exemption from that gate it leaves the shared root
altogether, for the per-user cache directory (`LOCALAPPDATA`, else `XDG_CACHE_HOME`, else
`~/.cache`), where a stable name sits in a directory only this user can write. Not under `~/.claude`
either: that tree is what these checks READ, and one of them snapshots it.

**Score:** 3

#### What makes this deploy extra special

N/A. This repo is not a service anyone subscribes to; the reader here is a developer maintaining it,
and what they get is already scored above. The saving lands in every consuming repo through a
release, but a consumer of this product is a developer too.

**Score:** N/A

#### Pull Request

connector-sessioncheck measures the version verdict once per session instead of on every compaction

Plugins: dkj-policy

[PR #1672](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1672)

---

### DEPLOY: docs/1667-review-dispatch-worktree · 20260908-204043

A dispatched review runs in the primary checkout and never in `isolation: "worktree"`, and Chris's
portable manual now says so at the one place a reader meets the question -- the *Delegating parallel
work* section, which already named worktree isolation as an option. #1667 filed the call as the
owner's because its own first bullet was inferred; both halves were probed instead, in this repo, on
September 8, 2026.

The flag is worse than the hazard it would remove. A dispatched worktree is a fresh checkout of the
primary's **HEAD commit** on a branch of the harness's own making, with a clean `git status`: an
untracked file and a tracked edit made seconds earlier were both invisible inside it. A review sits
*before* the PR, so the tree it would read is the one without the change, and what comes back is a
confident "no findings" carrying nothing that says which tree it read. And the worktree lands at
`.claude/worktrees/agent-<id>` **inside** the checkout, ignored by nothing, so while it stands the
primary's own `git status` carries `?? .claude/worktrees/` -- it dirties the tree it was dispatched
to protect. That is why the repo's lane mechanism puts its worktrees in a sibling directory; the
harness flag does not offer the choice.

So the `working-copy-boundary` block -- #1665, merged the same evening this was measured -- stays the
whole of the answer for reviewers, and it is not weakened by being unenforceable: `isolation` is set
by the caller at dispatch and lives in no agent def, so no lint gate could ever have reached it. The
section now sits under the bullets #1665 added rather than restating them, and worktree isolation
stands for the case the `fork` bullet named it for -- several sub-agents writing the same files at
once -- with both costs named there rather than waived.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service sees. This is guidance in an orchestrator's on-demand
manual about how sub-agents are dispatched; no behaviour anybody invokes changes.

**Score:** N/A

#### Pull Request

The review chain is not dispatched into a worktree, and the measurement says why

Plugins: dkj-team-alpha

[PR #1675](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1675)

---

### DEPLOY: docs/1668-fixture-teardown-measured · 20260908-203035

#1668 reported 413 leftover fixture trees in the temp directory and named a cause:
`fold-changelog.tests.ps1`'s per-case tree helper never tears down. Measured, the cause does not hold.
The helper registers every tree it builds and the register is swept twice, both since the file's
creation commit on July 24, 2026; run to completion the suite leaks **zero**, and so does
`new-branch.tests.ps1`, the second-largest contributor. What the standing entries have in common is
*where* they were registered -- all after a suite's last completed sweep -- which is the signature of an
interrupted run, and no in-process teardown reaches those.

The count was also read for more than it was. Of the directory measured, 546 entries were
`sync-pr-body-*`, written deliberately by `sync-main.ps1` for an operator to paste into
`gh pr create --body-file` and therefore required to outlive their run, and 162 belonged to an unrelated
tool; the suites' own share was ~215, not 413. So the largest group counted as litter was the one thing
in that directory that is retained on purpose.

`scripts/README.md` now carries both findings beside the `$PID` fixture convention, because the
distinction decides the repair: the obvious fix is to give a helper a teardown it already has, and the
fix that would actually reach an interrupted run's residue is a sweep by name pattern in a shared temp
directory -- the same delete primitive `New-ScratchPath` was introduced to remove. Written down rather
than re-measured, so the next reader of that directory does not re-file it.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service sees. `scripts/README.md` documents this repo's own script
layer, ships in no plugin, and no behaviour a consumer invokes changes.

**Score:** N/A

#### Pull Request

The fixture convention records that suites DO tear down, and what a leftover actually means

[PR #1674](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1674)

---

### DEPLOY: fix/1665-working-copy-boundary · 20260908-202038

A dispatched specialist holding `Bash` is now told, in its own always-loaded boundary, that the checkout
it stands in is not its own to move: no `git stash`, `checkout -- <path>`, `reset`, `clean`, `restore`,
branch switch, or anything else that mutates the tree, the index or **any ref** -- whatever files it may
legitimately edit. The block names the read-only way to read another ref instead, and says that a clean
`git status` proves nothing, because it is exactly what discarded uncommitted work looks like.

It closes a real loss rather than a hypothetical one: a review stashed, hit other sessions' stash
entries, and resolved the conflict with `git checkout HEAD -- <file>` on three files, taking four of the
orchestrator's uncommitted edits with it and reporting `No repo content was altered`. The old wording
did not reach that, because a stash corrects nothing and lands nothing.

**And the circle that carries it is now kept by a gate rather than by memory.** This is the first shared
block placed by **capability** instead of by craft -- it goes wherever `tools:` names `Bash` -- and that
is the one kind of circle a check can hold, so **lint check 36** reports any agent def that names the
tool and carries no block. Without it a specialist gaining `Bash` later would have sat silently outside
the boundary with every gate green, which is the same enforced-by-memory failure as the defect itself.

**Score:** 4

#### What makes this deploy extra special

N/A -- the block ships to every consumer of the four team plugins, but its reader is a subagent rather
than a subscriber of a service, and this repo publishes to none.

**Score:** N/A

#### Pull Request

A review may not mutate the working copy: no git stash, checkout --, reset or clean

Plugins: dkj-team-alpha, dkj-team-ecomm

[PR #1671](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1671)

---

### DEPLOY: feat/1659-temp-path-unpredictable · 20260908-190619

Seven sites across six scripts composed their temp path as `<label>-$PID`, which is a name a local
actor can reach first: `New-Item -Force` and `WriteAllText` both follow a symlink or junction, so a
pre-planted link redirects the write, and where the script then deletes recursively there, the same
window is a delete primitive in somebody else's directory. All seven now call one composer,
`New-ScratchPath`, which
returns `<temp>/<label>-<pid>-<guid>` -- there is no name to plant at. A reparse-point check was the
obvious alternative and was declined on the measurement: it is a check-then-write, and on macOS `/tmp`
is itself a symlink, so the same check refuses a whole platform for the ordinary case. A scan in
`native-capture.tests.ps1` now fails on the eighth site, which is what the class needed more than the
seven edits did.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service sees. These are the workflow's own scripts, and the hardening
is against a local actor on the machine running them; no behaviour a consumer invokes changes.

**Score:** N/A

#### Pull Request

No shipping script composes a predictable temp path any more

Plugins: dkj-policy, dkj-team-shopify

[PR #1666](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1666)

---

### DEPLOY: fix/1655-unjudged-fixture-git-check · 20260908-185415

A test suite can no longer reintroduce the fixture-git idiom that #1635 swept out. Check 35
(`[fixture-git]`) walks `scripts/tests/` for a git command whose output is discarded and whose exit
code is judged on neither the same statement nor the next -- the idiom that made a git which FAILED
indistinguishable from one that worked, so every assert below it read a repo that was never built and
blamed the script under test.

The sweep it enforces turned out to be unfinished, which is the finding rather than a side note. The
matcher read **27 unjudged calls still standing in four files** -- `find-specialist-mentions`,
`shared-scripts`, `source-repo-guard` and `fresh-consumer.measure`, whose spellings (`git ... 2>&1 |
Out-Null` with no `&`, and `& $git @(...)` over a scriptblock) the earlier search never reached. All
27 are converted here, so the check is born green with **zero exemptions**. Over the pre-sweep tree it
reads 182 findings in 18 files: the house style, measured.

What makes the check possible at all is that a git QUESTION reads its exit code **immediately** --
`rev-parse --verify --quiet` on a ref expected to be absent answers with exit 1 and is judged on the
next line. So a call is cleared when `$LASTEXITCODE` appears in the same statement or the next one, no
verb is special-cased, and no file is exempt: **zero probe false positives over both trees**. The
subject is deliberately a *discarded* result rather than every unjudged call -- widening to a bare
statement pipeline yields 20 findings here and all 20 are value-returning questions. All three ways to
discard are covered (`| Out-Null`, `$null =`, a `[void]` cast), each after one shared unwrap of any
`(...)` so a pair of brackets is not an escape hatch, and the clearing condition reads the AST rather
than the line text. None of those three came from the measurement -- this tree holds only the plainest
spelling of each -- but from probing the check's own stated boundary and from the review that followed.

**Score:** 3

#### What makes this deploy extra special

Nothing here reaches a consumer's own repo: the check reads `scripts/tests/`, which is workshop-only
and mirrored into no plugin. One portable page does change -- the system-administration manual gains
a tenth PowerShell trap (`@($i, $i + 1)` is `@($i, $i) + 1`, the comma binding tighter than the
addition), which travels to every consumer at the next release and is worth having: it produced nine
false findings inside the very pass that was deciding whether this check's false-positive rate was
acceptable.

**Score:** 1

#### Pull Request

A lint check for the unjudged fixture-git idiom, and the four suites the #1635 sweep missed

Plugins: dkj-team-alpha

[PR #1663](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1663)

---

### DEPLOY: fix/1650-shape-gate-local · 20260908-182018

The branch document's **shape** rules -- four `###` headings and never a fifth, and nothing
branch-specific above the first phase -- are one shared function now
(`Get-DevelopmentShapeFindings`), and `open-pr` refuses on them before the push. They lived only in
`check-branch-entry.ps1`, which runs in CI and only advisorily, so nothing stopped a malformed document:
PR #1644 shipped through push, the required check, the merge and the fold with its `### PLAN` heading and
most of its guidance block gone, every other gate correctly green -- and the fold then deleted the very
file the one red check named, so the evidence was destroyed by the thing whose success it was warning
about. CI still reports rather than refuses, from the same code, and `branch-entry` is still not a
required check.

**Score:** 4

#### What makes this deploy extra special

A consumer gets the same refusal, before the push, on the half of the rule that applies to them: branch
content in the generic guidance block. The heading-count half stays the source repo's own, so a document
where they keep a heading of their own is still not refused. Documented as its own gate on the `open-pr`
skill page and in the portable contributing page, both of which travel with the plugin.

**Score:** 3

#### Pull Request

The branch-document shape rule becomes a shared function and refuses before the push

Plugins: dkj-policy

[PR #1661](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1661)

---

### DEPLOY: docs/1656-gate-count-readme · 20260908-180529

The `dkj-policy` README's one-paragraph summary no longer counts the gates. It read *"Four gates hold the
whole thing together, and none of them is advisory"* and now reads *"Gates on the branch's own paperwork
hold the whole thing together"* -- the same claim, with the half that goes stale removed and the half that
does the work kept verbatim.

The count was correct when it was written and is correct today. What it was not is durable: the paragraph
sits one sentence above the pointer to
[`CONTRIBUTING-portable.md`](../plugins/dkj-policy/CONTRIBUTING-portable.md), whose matching sentence
becomes "Five further gates" the moment
[#1650](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1650) lands -- so the summary would
have started contradicting its own next paragraph without anybody editing it. That is the second time this
count has gone stale by standing still, which is the argument for naming the gates instead: *"Gates on the
branch's own paperwork"* is what `CONTRIBUTING-portable.md` already calls them, and it stays true at four,
five or six.

Deliberately scoped to this one sentence. The other counts in the tree are either a different subject or
sit in files #1650's own branch is already editing; the one it leaves behind,
`CONTRIBUTING.md:380`, is filed on
[that thread](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1650#issuecomment-5589481061)
rather than swept from here.

**Score:** 1

A wrong number in a summary paragraph misleads nobody today -- it prevents a contradiction that has not
happened yet, and names the failure it prevents. Cosmetic in isolation; worth doing because the alternative
is finding it a third time.

#### What makes this deploy extra special

This page ships with the plugin, and it is the one the README itself calls *"the page to read"* before
handing a consumer to `CONTRIBUTING-portable.md`. A consumer adopting the workflow reads the summary and
the page it points at in that order, so the pending contradiction would have landed on them first and with
nothing in their own tree to explain it.

**Score:** 1

They read a paragraph that stays true instead of one that quietly stops being true. Cosmetic on arrival,
and invisible if it works.

#### Pull Request

Drop the gate count from the dkj-policy README's opening paragraph

Plugins: dkj-policy

[PR #1658](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1658)

---

### DEPLOY: docs/1642-pre-split-entry-shape · 20260908-175640

Four comments in `../scripts/lib/entry-scaffold-lib.ps1` and its guardrail suite described the
pre-split root changelog entry incompatibly -- an H2 title naming no branch in one place, an H1 title
with a `**Branch:**` line below it in the other -- and each was the stated reason a piece of live
behaviour survives. The history settles it: of the **344** pre-split root entries this repo has ever
had, **0** carry a `**Branch:**` line and **0** open with an H1 (334 open at H3, 10 at H2 in the flat
window of August 5-6, 2026). The `**Branch:**` shape was never a root entry at all -- it sat below the
H1 title of the pre-split **per-branch** files, `branch/branch-changelog.md` (`# Branch changelog`) and
`branch/branch-progress.md` -- and the release cut's root scan is non-recursive, so `branch/` was never
in its reach either. All four sites now name that file, cite the measurement, and keep the one
justification that survives it: the fallback's regex is anchored end to end, which is what makes it
safe to leave un-narrowed. `Test-BranchChangelogIsFilled`'s docstring reads `AT AN ENTRY LEVEL` rather
than `as an H2`, since it accepts both and both were written. Behaviour is unchanged -- the report had
already established the code handles each shape correctly, and this measurement agrees -- but the
guardrail suite gains the H3 assert it never had, which is the shape 334 of those 344 files actually
have.

The failure this prevents had not happened yet: a maintainer following the un-corrected comments would
conclude that a root entry declares its branch, therefore that the name test already answers for it,
therefore that the level test beside it is dead -- and removing it is exactly what would let the
release cut, whose guard is "no unfolded entry anywhere", cut straight over all 344.

**Score:** 2

#### What makes this deploy extra special

N/A. The corrected text travels to consumers in the `dkj-policy` mirror, but nothing a consumer runs
changes: this is comment prose and one added assert in the source repo's own suite.

**Score:** N/A

#### Pull Request

Name the legacy shape the '**Branch:**' fallback actually answers for

Plugins: dkj-policy

[PR #1657](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1657)

---

### DEPLOY: fix/1635-fixture-git-judged-siblings · 20260908-173553

A test fixture's own git commands are now judged in every suite that builds one. The standing idiom was
`& git -C $dir init -q 2>$null | Out-Null` inside a lowered `$ErrorActionPreference` -- and lowering the
preference is right and stays, because git writes ordinary progress to stderr and under `EAP=Stop` that
is a terminating error before any exit code is read. What was wrong is that the **exit code went with
it**: a git command that failed was indistinguishable from one that worked. That matters more in a
fixture than in production code, where a failed git usually goes on to fail visibly: a fixture that
ignores one produces a repo that is *plausible* -- it exists, it has a HEAD, it just does not hold what
the case assumed -- and every assert below it then measures the wrong thing, attributing the failure to
the script under test. Thirty concurrent lanes over one temp tree make a transient `index.lock` sharing
violation ordinary rather than rare, so the shape to expect is a suite that is red under the gate, green
alone, and silent about why.

`scripts/lib/fixture-git-lib.ps1` now holds that rule once -- judge, print git's own output, count, and
fail the run on the count **even when every assert passed**, because a clean sweep over a repo that was
never built proves less than it appears to. Seventeen suites route through it; each keeps its own helper
signature, so the pass was a substitution rather than fifteen redesigns. Reads and existence probes are
deliberately not subjects, and the two that were converted by mistake are back to a raw `& git` with the
reason at the call site. `sync-main.tests.ps1` -- where #1622 wrote the rule inline, merged from `main`
part-way through this branch -- reads the shared source too, so the forty lines exist once rather than
sixteen times.

**Score:** 3

A red gate now names the broken fixture instead of the script that was fine, which is the difference
between reading a failure and spending a 190s run reproducing one that may not reproduce. Noticed the
moment it fires and invisible until then, so not higher.

#### What makes this deploy extra special

Nothing -- this is the source repo's own test suites, which no consumer runs and no release ships. The
lib is workshop-only by design: nothing under `scripts/tests/` is mirrored into a plugin.

**Score:** N/A

#### Pull Request

fixture git commands are judged in every suite

[PR #1646](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1646)

---

### DEPLOY: fix/1629-predecessor-paths-quotepath · 20260908-172319

`sync-main`'s standing-predecessor verdict now reads its file lists correctly, and prints them safely.
Two defects, and the first is the one that gave a wrong answer: the `git diff` that asks what a
predecessor branch captured set no `core.quotePath`, so git quoted any path with a byte above 0x7F while
the paths it was compared against arrived decoded. A theme file with an accent in its name matched
nothing, and a branch this run supersedes exactly was reported as independent -- which tells you to keep
a redundant sync PR open, while naming a path that is in the run. That read now forces the flag and
decodes it, the pair inbound #821 established and the neighbouring reads already used. Second, the paths
printed under each verdict row are stripped of control and format characters, like the branch name
#1623 stripped six lines above them. That strip became necessary rather than tidy with the first fix:
git C-quotes a control character in every `core.quotePath` setting -- measured on 2.55 -- so it was
closing that half by accident, and decoding on purpose hands the printer a live escape instead. Format
characters were never covered either way. The strip is `Get-DisplayPath`, the path-shaped one #1638
added, which does not collapse runs or trim -- so a path with a real space in it still names the file it
names.

**Score:** 3

#### What makes this deploy extra special

A consumer with a non-ASCII theme file name was getting a wrong verdict, and nothing said so: the run
was green, the report was confident, and the named path looked like evidence. The accented filename is
not hypothetical in a Shopify theme, and the failure needed no hostile input at all -- just an accent
and a standing sync PR. The second half prevents a file name from repainting the report it appears in.
Nothing changes for an all-ASCII theme.

**Score:** 3

#### Pull Request

sync-main reads and prints a predecessor's file paths correctly

Plugins: dkj-team-shopify

[PR #1652](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1652)

---

### DEPLOY: fix/1627-trunk-and-lsremote-paste · 20260908-170957

Two printed commands in `sync-main.ps1` no longer hand you a ref name your shell would act on. The
`gh pr create` line routed `--head` through the paste guard and left `--base` raw beside it, so one
command was visibly half-protected -- and the base is no safer for being the trunk: it is
`Get-TrunkBranchName`, a seam answer a consumer wrote, which git has never validated. It now carries
its own `<trunk>` placeholder and its own note, separate from the branch's, because a command printing
two placeholders has to let you tell them apart. The `gh pr list` line the standing-predecessor refusal
hands over is judged per branch, and those names are the most externally-authored refs in the script:
they come off `git ls-remote`, so whoever pushed a branch under the sync prefix chose them, and
`git check-ref-format` accepts `;`, `$(` and a backtick alike. A refused name prints as a placeholder
with the real branch named beneath as prose, where its characters are inert -- so you can still act on
it. #1623's comment, which named this very line as a place the raw trunk stays, is corrected in the
same change.

**Score:** 3

#### What makes this deploy extra special

A consumer running `sync-main` is the reader of both lines. The `gh pr list` one is the sharper of the
two for them: it is printed by a refusal, at the moment they are being told to go look at somebody
else's branch, and that branch was named by whoever pushed it -- which in a Shopify repo can be another
machine or another person. Nothing about the ordinary path changes: a normal branch name is safe by the
allowlist, so both commands print exactly as before and remain copy-and-run.

**Score:** 3

#### Pull Request

sync-main judges the trunk and each predecessor before printing a command

Plugins: dkj-team-shopify

[PR #1648](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1648)

---

### DEPLOY: fix/1641-autopark-runspace · 20260908-162118

The `cycle-autopark` Stop hook no longer starts a second PowerShell interpreter to run `park-cycle.ps1`.
It runs it through the same `Invoke-CheckScript` the six SessionStart hooks have used since #1625, which
gives ~102 ms back on **every turn** (666 ms -> 564 ms median on an ordinary turn with nothing to push,
7 runs each) -- one interpreter start-up exactly, which is what the change removes. This hook fires far
more often than that family, so it was paying the same avoidable start-up the most times.

Two additions to the shared lib made that possible, and both are opt-in with nothing changed for its
existing callers. `-MergeAllStreams` captures every stream rather than Write-Host and the pipeline
alone: the session checks must not merge stderr, because a stray line would sit in front of their
`[ERROR]` filter, while this hook has no filter and relays park-cycle verbatim -- which is what #1600
built its `2>&1` for. `-OutputTo` keeps what a check managed to write before throwing; in-process there
is otherwise no return value to read, and for a relaying caller those lines are the diagnosis.

Separately, `Invoke-GitPark`'s `git push` was the last call in this family reaching the network
unbounded; it now passes the same shared network timeout its three siblings do. That matters most
exactly here, where the caller is a hook firing every turn with nobody watching a prompt to interrupt.

Coverage grows with it. `hook-check-lib.ps1` arrived in #1644 with no suite of its own, and this branch
rewrote the capture path all seven of its callers run through, so it gets one: 18 asserts over the three
silent traps its header names, plus the two new parameters. The hook's own suite goes from 11 asserts to
20, one of which pins the saving itself -- park-cycle reports the hook's own process id -- because every
stream assert passes whether or not there is a child process, so nothing else would notice a silent
return to spawning.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's readers are its own maintainers, and the change is invisible from outside a session's
turn timing.

**Score:** N/A

#### Pull Request

cycle-autopark runs park-cycle in-process instead of a second interpreter

Plugins: dkj-policy, dkj-team-alpha

[PR #1649](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1649)

---

### DEPLOY: fix/1639-claim-issue-network-bound · 20260908-161105

`claim-issue` bounds all three of its `gh` calls at the shared network timeout, so a stalled `gh` is
reported instead of waited out. This is the worst step in the workflow to hang in: the claim is the
first move of an issue-driven assignment, so a stall there is a session that never starts with nothing
printed to say why -- and the shape is not hypothetical, since the measurement behind #1628 is a
checkout where `gh` returned exit 1 intermittently while working fine from the shell, minutes apart,
in one session.

**A timed-out write is reported as an unknown rather than a failure.** The read and the read-back only
ask questions, so a stall costs nothing but the answer; `gh issue edit` changes the tracker, and a
write that never reported back may have landed. Saying "the claim failed" there would be a claim about
the tracker the run cannot make, so it says it does not know, stops, and names re-running as the way
out -- an already-landed claim comes back as *already yours*.

And the reason the gap existed is closed too. The shared bound described itself as *"THE BOUND A GIT
NETWORK CALL PASSES"* and listed three sites while six files read it and two passed it to `gh`. That
comment is the one place a script author learns the policy, so the policy read as somebody else's. It
now names both commands and points at a `grep` instead of carrying a list no gate can keep true.

**Score:** 3

#### What makes this deploy extra special

Every consumer of this workflow runs this claim step, and it is the first thing their session does
with an issue number. Unbounded, a `gh` that never answers there presents as a session that simply
sits -- no output, no verdict, nothing naming the cause -- which is the failure that costs an operator
the most time to diagnose and the least to fix once named. They also get the corrected policy comment,
which is what stops the next `gh`-only script in their tree from repeating this.

**Score:** 3

#### Pull Request

claim-issue bounds its three gh calls, and the shared bound stops describing itself as git-only

Plugins: dkj-policy, dkj-team-shopify

[PR #1651](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1651)

---

### DEPLOY: fix/1632-missing-entry-refused · 20260908-160353

A branch document with its `### DEPLOY` section **deleted** carried no entry at all and passed every
gate that exists to catch exactly that -- both of `check-branch-entry.ps1`'s document checks in CI and
both of `open-pr.ps1`'s locally, which then composed the PR title and description out of the guidance
block. The cause is one value standing for two states: `Get-DevelopmentEntryText` hands back the whole
text when it finds no DEPLOY heading, which is the honest answer for a legacy entry file and the guidance
*preamble* for today's document, and a blockquote nobody scaffolded carries no scaffold marker -- so the
scaffold gate passed **by absence**. A new pure predicate, `Test-DevelopmentEntryMissing`, separates the
two beside the splitter it bounds, and both readers now ask it ahead of their scaffold check. It reads
shape rather than text, so it survives translation: no DEPLOY section *and* a plan present -- the
scaffolder's blockquote guidance under the title, or the phases by their seam names -- is a document that
lost its entry, while no DEPLOY section and no plan is the legacy shape whose fallback stands. Reachable
by accident rather than only by hand, which is what earns it a gate: the measured document was produced
by an edit truncating at `### PLAN`, a string that also sits *inside* the guidance blockquote.

**Score:** 3

#### What makes this deploy extra special

Three discriminators were tried and two rejected on evidence rather than taste, and the rejections are
the reusable part. A **level** test cannot work -- today's document title is an H2 and the flat-window
entry heading (August 5-26, 2026) is an H2 too, so `Test-IsChangelogEntryFile` and
`Test-BranchChangelogIsFilled` both read the broken document as an entry file, which is the same
collision that moved the latter to the name test. The **declared branch** looked clean until
`Get-BranchFileDeclaredBranch`'s deliberately un-narrowed `**Branch:**` fallback answered for a pre-split
root entry as well, so refusing on it would have refused a perfectly good entry. What is left errs
toward under-refusal on purpose: a document that lost its guidance *and* its phases is not recognised,
because a missed refusal is the state that already exists while a false one stops a branch that worked
yesterday. Ten shapes are pinned at the lib, five of them false-refusal cases somebody's branch is
carrying right now.

**Score:** N/A

#### Pull Request

Refuse a branch document whose DEPLOY section is gone

Plugins: dkj-policy

[PR #1647](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1647)

---

### DEPLOY: fix/1637-sync-main-path-print · 20260908-154618

`sync-main` no longer prints a file path raw. Its primary report -- the take, hold-back and conflict
listings -- goes through a new path-shaped display strip, and its conflict remedy no longer
interpolates a path into a paste-ready `git diff` at all: the path is judged against the same
allowlist a branch name is, and a refused one is replaced by `<path>` in **both** operands with a note
naming the real path outside any command context.

Two things make this more than a sweep. The double quotes that were there were the defect rather than
the guard -- command substitution runs inside double quotes in bash and PowerShell alike, so the line
read as protected while closing nothing, which is worse than a bare interpolation because the next
reader sees quotes and stops looking. And the display strip had to be a second function rather than a
reuse: `Get-DisplayRef` collapses space runs and trims, which is right for a ref (git forbids a space
in one) and wrong for a path, where a doubled or trailing space is part of the name. Preserving one
space per removed character is also what fixes the alignment -- a zero-width run spends format width
without spending display columns, so a padded row used to slide against its neighbours.

**Score:** 3

#### What makes this deploy extra special

The paths are the point. They come from this repo's own `HEAD` and from a filesystem walk of the
pulled **live theme** -- which third parties edit through the Shopify theme editor, outside any
review, and which is the entire reason that sync exists. Measured for #1637: `git ls-tree -r` and
`git diff --name-only` hand back `assets/x$(id -un).js` and `assets/z;touch owned.js` unquoted in
every `core.quotePath` setting, because git quotes control characters and high bytes and not shell
metacharacters. So the consumer running this sync against a real store is the reader who was being
handed a command to paste, built from a name they do not control.

**Score:** 3

#### Pull Request

sync-main stops printing raw file paths: a faithful display strip and a paste refusal for the conflict remedy

Plugins: dkj-policy, dkj-team-shopify

[PR #1645](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1645)

---

### DEPLOY: fix/1625-hook-in-process-check · 20260908-153515

Every SessionStart check hook in this family spawned a second `powershell.exe` to run its own check
script, on top of the interpreter the harness had already started for the hook. All **seven** now run
their check **in that same interpreter**, through one shared `Invoke-CheckScript`
([`hook-check-lib.ps1`](../scripts/lib/hook-check-lib.ps1), mirrored into `dkj-policy` and
`dkj-team-alpha`). That is **~305–443 ms** of wall-clock off every session start, resume, clear and
compact — bounded below by the slowest hook's own improvement (2161 ms → 1856 ms) and above by six
concurrent synthetic hooks differing only in the spawn. Reports are unchanged, verdict for verdict.

The figure is smaller than [#1625](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1625)
filed, and deliberately so: it assumed the hooks run sequentially and named settling that as the thing to
do first. They run in parallel — *"Claude Code runs all matching hooks in parallel"* — so the ~875 ms
sum was never on the critical path. It is also not one spawn's 219 ms, because six simultaneous process
creations contend rather than each costing what one costs. (The measurements are of the six that existed
when they were taken; the seventh arrived mid-branch and was not re-measured, which is why the range is
quoted unchanged rather than widened on an estimate.)

**Score:** 3

#### What makes this deploy extra special

The repair the issue talked itself out of turned out to be the one-liner it said was unavailable.
`exit` inside a **dot-sourced** script does take the hook with it, and so does one inside a script
**block** — but a `.ps1` **file** invoked with `&` gets its own scope, and its `exit` returns control
with `$LASTEXITCODE` set. That is why no check script had to be refactored into a lib to collect this.

What the change is careful about is the other direction: in-process invocation has three failure modes
that are all **silent**. An array splats positionally, so a flag binds to the first positional parameter
and its value is dropped; `Write-Host` never reaches the pipeline without `6>&1`, so a hook whose whole
job is to forward `[ERROR]` and hold the rest back would forward everything; and one `Write-Host` can
arrive as a single record holding several lines. All three are handled once, in one lib, rather than six
times — a seventh copy that got any of them wrong would not crash, it would quietly report the wrong
thing into the session context.

**Score:** 2

#### Pull Request

Session-start hooks run their check in-process instead of spawning a second interpreter

Plugins: dkj-policy, dkj-team-alpha

[PR #1644](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1644)

---

### DEPLOY: fix/1628-claim-readback-three-states · 20260908-152548

`claim-issue` no longer reports a read it could not make as a claim the tracker refused. The read-back
held one boolean for two opposite facts -- "gh answered and your account is not there" and "gh never
answered" -- and printed the first for both, naming a cause it had not measured ("most often an account
with no write access") and telling you to treat the issue as UNCLAIMED. Measured on the claim of #1623:
that fired, and a plain `gh issue view` on the same checkout seconds later showed the claim sitting
there. Followed literally by a second session, it inverts the duplicate-work hazard the step exists to
prevent. There are now three states. A read that answered and found your account absent still refuses,
with the same message, because that is the one state it was ever right about. A read that did not
answer prints a warning naming the exit code, says the claim most likely landed and why, hands over
`gh issue view <n> --json assignees`, and **does not block** -- a claim is the opening of the work, so a
false stop costs the whole assignment. The closing verdict says `(unconfirmed)` in that state rather
than asserting a claim it could not confirm.

**Score:** 3

#### What makes this deploy extra special

A consuming repo runs this script as its claim step, and this is the failure mode it hits: an
intermittent `gh` on an otherwise healthy checkout. Before this, that session was told its claim was
refused and to treat the issue as unclaimed -- so it either stopped, or re-claimed work it already
held. Now it is told the claim probably landed, told how to confirm it, and carries on. Nothing
tightens: a genuine refusal refuses exactly as before, with the same words and the same exit code.

**Score:** 3

#### Pull Request

claim-issue tells an unverified claim apart from a refused one

Plugins: dkj-policy

[PR #1633](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1633)

---

### DEPLOY: fix/1622-fixture-git-judged · 20260908-151234

A fixture `git` command that fails while `sync-main.tests.ps1` builds its repos is now named, with its
exit code and git's own stderr, instead of passing silently. That helper is behind all 24 fixture
mutations in the suite and discarded both, so a half-built repo produced a block of red asserts with no
cause printed anywhere -- which is what #1622 met under the 16-lane gate, and why the sighting could not
be diagnosed.

Two things follow. The run says a broken fixture **before** the verdict, because otherwise the default
reading of a red suite is that the script regressed -- and here it did not. And a run where every assert
passed but a fixture command did not now **fails**: a clean sweep over a repo that was never built proves
less than it appears to, and the failure count is the only thing that knows.

The report's own two hypotheses were checked against the tree first and neither survives: the `net:`
cases are static scans of the script's source, and fixture roots carry `$PID` as well as a GUID while
lanes are separate processes. What is genuinely different under thirty lanes is dozens of concurrent
`git` processes over one temp tree.

**Score:** 3

#### What makes this deploy extra special

N/A -- a test suite's own diagnosability. No subscriber sees it, and nothing about what the workflow
does changes.

**Score:** N/A

#### Pull Request

A fixture git command that fails is named, instead of leaving a block of red asserts with no cause

[PR #1640](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1640)

---

### DEPLOY: fix/1636-gate-keeps-red-capture · 20260908-150234

A failing test suite's captured output now survives the run that produced it. `Invoke-TestSuiteGate`
buffers each suite's stdout and stderr to `%TEMP%\test-suite-gate-<PID>\` and printed each block on
reap, then deleted the directory in its `finally` whether the run was green or red -- so the console was
the only copy, with no flag to keep it, and a pipe through `tail`, a scrollback limit or a truncated CI
log lost the evidence for a 130-140s run whose failure may not reproduce. A red run now keeps the
**failing** suites' `.out.txt`/`.err.txt`, deletes every other capture, and names the directory on the
verdict line -- the line a session copies into a branch document, a commit message or an issue. A green
run still keeps nothing, and an empty capture file is dropped rather than padding a directory the
verdict has just recommended reading. `$captureDir` already carried `$PID`, so a retained directory
cannot collide with a later run's.

**Score:** 3

The next red gate is diagnosable from a file instead of from scrollback, which is the difference between
reading the failure and paying 140s to try to reproduce it. Not higher because nothing a session does
today changes and a green run is byte-for-byte as before.

#### What makes this deploy extra special

A consumer running the `dkj-policy` workflow runs this same gate through `open-pr` and `cut-release`,
and the lib is mirrored into both `dkj-policy` and `dkj-team-shopify`, so the retention arrives with the
next release. It is not a change they have to notice or act on, though: nothing they type differs, and
the only visible difference is one extra line under a red verdict.

**Score:** N/A

#### Pull Request

the test gate keeps a failing suite output

Plugins: dkj-policy, dkj-team-shopify

[PR #1643](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1643)

---

### DEPLOY: fix/1620-ship-resume-front-door · 20260908-144854

A `ship-pr` run whose process does not survive the CI wait can be resumed from the checkout it was
interrupted in. Step 2b puts that checkout back on the trunk as soon as the PR exists (#1073), so the
re-run used to meet `You are on main; ship-pr runs from a branch` -- a refusal about the wrong problem,
in a state where the killed process has usually taken the scrollback with it. The front door now asks
whether an open PR exists whose head branch is in this checkout, and where it finds one it names the
PR, the branch and the `git checkout` that resumes the ship, instead of refusing on the general rule.
It stays best-effort: where `gh` cannot answer, the refusal is exactly the line it has always been.

**Score:** 3

#### What makes this deploy extra special

Every consumer of this workflow ships with the same script and the same step 2b, so the same
interrupted ship is recoverable there without reading the source repo's issues -- and a consumer is
where it is most expensive, because their operator has no `ship-pr.ps1` in front of them to read the
comment the diagnosis used to live in.

**Score:** 3

#### Pull Request

ship-pr names the interrupted ship's branch at the front door instead of refusing on 'You are on main'

Plugins: dkj-policy

[PR #1634](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1634)

---

### DEPLOY: fix/1623-ref-display-strip · 20260908-143357

A branch name this workflow prints in a sentence can no longer read as a different branch. `git
check-ref-format` enforces `\p{Cc}` and **accepts** `\p{Cf}`, so a branch carrying U+202E, U+200B,
U+200D or U+2066 is creatable, checkout-able and returned verbatim by `git rev-parse` -- and
thirty-two printed sentences across `ship-pr.ps1`, `sync-main.ps1`, `remote-ahead-lib.ps1` and
`worktree-lib.ps1` put that name straight into a console. `Get-DisplayRef`, one definition in
`ref-print-lib.ps1`, now replaces every control and format character with a space, collapses the
runs and trims; the words stay, because a reader standing on that branch has to recognise it. The
paste axis is unchanged and stays distinct: a command gets a placeholder, a sentence gets a strip.

Two of the thirty-two are worth naming on their own. `ship-pr.ps1`'s go-ahead line is the one line
the ship documents as safe to act on. And `sync-main.ps1`'s standing-predecessor rows print names
that came off `git ls-remote` -- text chosen by whoever pushed the branch, read by an operator
deciding which pull request to close.

The same movement retired the tree's second copy of the strip pattern: `remote-ahead-lib.ps1` had
been sanitising a commit subject and printing the branch label beside it raw, which is the sharpest
instance the report found.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here reaches a subscriber. It changes what a console prints to whoever runs the
workflow's own scripts, and only for a branch name no ordinary repo has.

**Score:** N/A

#### Pull Request

A ref name printed as prose is stripped of control and format characters

Plugins: dkj-policy, dkj-team-shopify

[PR #1631](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1631)

---

### DEPLOY: fix/1609-claude-home-pollution · 20260908-141700

A debug script wrote fixture data into the real `~/.claude` and cost three checkouts their plugin
install records, with no backup, no error and nothing that reported it -- what a session saw instead was
every plugin listed as *"not installed in this checkout"*. A new SessionStart check,
`claude-home-sessioncheck`, now reports a record whose `projectPath` sits under a scratch tree -- the one
signature no existing reader can see, since the shared reader filters to this repo's path and separately
skips a path that no longer resolves -- and names any marketplace clone the same fixture left behind. It
also snapshots `installed_plugins.json` while that file reads healthy, after the verdict and never on a
finding, so a clobber can be *restored* rather than re-installed, which is what left #1609 unrepaired at
filing. The guard the report proposed was measured and declined: nothing committed writes under
`~/.claude`, so a write-helper has no call site to be enforced at, and a command-string guard cannot see
inside the temp script that did the writing.

**Score:** 3

#### What makes this deploy extra special

It is the first SessionStart check in this family that writes anything, and the exception is stated
rather than quiet -- bounded to one file it owns, skipped on any finding, and switched off by one flag.
The rest of the interest is in what was declined: the orphan-marketplace-directory scan that would have
fired forever on ordinary residue (measured the same day on `claude-plugins-official/`), and the
heredoc-inspecting guard whose first casualty would have been the fixture that tests it.

**Score:** N/A

#### Pull Request

Detect and recover fixture pollution of the real ~/.claude

Plugins: dkj-policy, dkj-team-alpha

[PR #1626](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1626)

---

### DEPLOY: fix/1617-ref-print-display-scope-reason · 20260908-140616

`ref-print-lib.ps1` said git already closes the deceptive-character class for a ref name. It does not:
`git check-ref-format` enforces `\p{Cc}` and accepts `\p{Cf}`, so U+202E, U+200D, U+200B and U+2066 are
all legal in a branch name -- creatable, checkout-able, and returned verbatim by `git rev-parse`. Those
first two are the exact code points #1446 was filed for. The guard itself was always right; only the
sentence explaining it was wrong, and a reader who is told a class is closed cannot weigh a gap they
have been told does not exist. All four claim sites now name the two Unicode classes exactly, carry the
measurement, and say the display axis is left open knowingly. The suite moves the format characters
into its reachable half, where git's acceptance is asserted as a premise rather than assumed away.

**Score:** 3

#### What makes this deploy extra special

N/A. Nothing a subscriber can observe changes -- no guard loosens or tightens, no printed line differs,
and the four code points were refused on the paste axis before this branch and are refused after it.
The correction is to the reasoning a maintainer reads in the lib and its suite.

**Score:** N/A

#### Pull Request

Correct ref-print-lib's display-scope reasoning: git accepts format characters in a ref

Plugins: dkj-policy, dkj-team-shopify

[PR #1624](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1624)

---

### DEPLOY: fix/1612-relay-sanitise · 20260908-135612

`ship-pr` prints the sentence a failing workflow wrote about itself, and it now strips the control and
format characters out of that sentence before it reaches your terminal -- the same guard the
"N commits behind" line has always had on a commit subject. An ANSI or OSC escape in a workflow's own
`::error title=...::` can no longer repaint the console it is relayed into, and an RTL override can no
longer make the relayed line read as something other than what it says. The words are kept; only the
characters that act rather than read are removed. The 500-character cap is unchanged.

Small, because it prevents a failure that has not happened: the author of an annotation is whoever writes
the repo's own workflows, which is a high-trust surface. It is worth more than a 1 in one specific shape
that is ordinary practice -- a workflow echoing untrusted input into `::error title=...::`, such as a PR
title, a branch name or a third-party action's output -- where the relayed text stops being the author's
own.

**Score:** 2

#### What makes this deploy extra special

It closes a claim as well as a gap. A page in the tree told readers this workflow printed
externally-authored text to a console in exactly one place, so nobody had reason to look for the second
one -- and the comment beside the second one already described itself as guarded. The repair makes three
statements agree with the code instead of one, and pins the two sanitisers to each other so the next
reader inherits a checkable arrangement rather than a claim.

**Score:** N/A

#### Pull Request

Strip control and format characters from the relayed annotation, and correct the only-place claim

Plugins: dkj-policy

[PR #1621](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1621)

---

### DEPLOY: feat/1591-consumer-version-verdict · 20260908-134603

A consumer with no source checkout beside it now gets a real answer at session start instead of
`no verified workshop checkout found -- check skipped`. That machine is the ordinary case, not an
edge case: the register checks genuinely cannot run there, because `check-connectors.ps1` is
source-only and is not plugin-carried -- so the hook said nothing at all about versions, and a
session could load a plugin release behind the one on the machine with no signal of it. It now runs
the plugin-carried `plugin-versions.ps1` in a new `-Brief` mode, which reports per enabled plugin
whether the version THIS checkout installed is the one the local marketplace clone holds, and prints
the command that closes the gap.

Only an install that is BEHIND its clone is reported as a finding. A stale clone is deliberately not
one -- it is a cache this checkout does not own, and shouting about it teaches the reader to skim the
marker that matters -- and `[INFO]` lines are kept out of a clean run entirely, because a plugin from
another marketplace reports "cannot determine" forever and would become permanent session-start
noise. Every branch says the register checks did not run, so nobody reads a version answer as an
all-clear for five checks that never happened.

**Score:** 4

#### What makes this deploy extra special

Every consumer of this workflow receives it in the next release, and it closes the blind spot the
`plugin-versions` skill could only answer when someone thought to ask: a session that has quietly
loaded a plugin release behind the machine's own now says so at the start, unprompted, on the
machines where nothing was checking. The signal arrives where the cost of not having it is highest --
a consumer acting on stale agent defs, skills or hooks without knowing it.

**Score:** 4

#### Pull Request

A real version verdict on a plain consumer, instead of a session start that says nothing

Plugins: dkj-policy

[PR #1611](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1611)

---

### DEPLOY: fix/1602-step8-report-wording · 20260908-132217

`ship-pr`'s step 8 no longer reports that a check "governed the merge" after the merge has already
happened. Since #1602 that report is printed after the fold, once the non-required checks have
finally reported -- and on the laps that change is actually about, the check finishing last is the
non-required one, so the line stated the exact opposite of what occurred: the merge went minutes
earlier *because* it no longer waits for that check. The line now names which check finished last and
keeps everything else, including the excess clause that sizes the tail.

**Score:** 2

#### What makes this deploy extra special

N/A -- one sentence of `ship-pr`'s own console output, read by whoever ships a branch.

**Score:** N/A

#### Pull Request

step 8's report no longer says a check governed a merge that already happened

Plugins: dkj-policy

[PR #1619](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1619)

---

### DEPLOY: fix/1616-go-ahead-trunk-claim · 20260908-131115

`ship-pr`'s go-ahead line now says what step 2b actually did with the working tree instead of
asserting that it went home. The trunk clause was a literal, so on every run where step 2b
declined to move the tree -- a dirty tree, a lane, a trunk another worktree holds -- the line a
reader is told to act on contradicted the line four rows above it. It is
`Get-TrunkReturnGoAheadLine` in `worktree-lib.ps1` now, asserted in that lib's suite: the yes arm is
word for word what it was, and the no arm names the branch the checkout is standing on and sends the
reader to a lane, which is detached at `origin/<trunk>` and therefore unaffected either way. Both
arms keep the two clauses that are true regardless -- step 1 is over, the tree is free -- because
withdrawing those with the trunk clause would cancel the invitation the line exists to make.

**Score:** 3

#### What makes this deploy extra special

A consumer runs this same script from the plugin mirror, and the go-ahead is what tells them it is
safe to open a second terminal and carry on. Until now it told them their primary checkout was on
the trunk on runs where it was standing on the shipping branch -- the exact state #1073 exists to
prevent, reported as already handled.

**Score:** 3

#### Pull Request

State what step 2b actually decided in ship-pr's go-ahead line

Plugins: dkj-policy

[PR #1618](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1618)

---

### DEPLOY: fix/1602-merge-on-required-green · 20260908-125722

`ship-pr` no longer holds the merge behind checks the ruleset does not require. Step 3 blocks on the
required checks only; the rest are waited for and reported at a new step 8, after the fold. That
stops the trunk from voiding a valid certificate during a wait nothing was gated on -- measured at
5.1% of 99 laps, and 62.5% of the tail-governed laps on the busiest day in the sample, each one
costing a whole further CI cycle. With no required check known the wait is byte-for-byte the old
one, so a repo without a ruleset is untouched.

**Score:** 4

#### What makes this deploy extra special

N/A -- `ship-pr` is the maintainer's shipping tool. No subscriber of anything reaches it, and the
consuming repos that do run it meet it as the same command with a shorter path to the merge.

**Score:** N/A

#### Pull Request

ship-pr merges as soon as every required check is green

Plugins: dkj-policy

[PR #1614](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1614)

---

### DEPLOY: fix/1594-printed-command-ref-safety · 20260908-123649

Seven printed, paste-ready commands across `ship-pr.ps1` and `sync-main.ps1` interpolated the branch
name raw. git's ref rules admit `;`, `&`, `|`, `` ` ``, `$( )` and the apostrophe -- so a legal branch
name could carry a shell metacharacter into a line the reader, often an agent session, pastes and runs.
Quoting does not close it in either direction: command substitution runs inside double quotes in bash
and PowerShell alike, and a legal apostrophe terminates single quotes. The new shared
`Get-PasteableRef` refuses to put such a name in a command at all -- it prints `<branch>` and names the
branch beneath, outside any command context -- and `Test-BranchName` now holds the same allowlist so a
branch this workflow creates is safe by construction. Both halves exist because neither closes it
alone.

**Score:** 3

#### What makes this deploy extra special

The repair the report proposed does not work, and that is the durable part. "Quote the variable" is the
reflex, and this is a measured case where both spellings fail for different reasons -- which is why the
answer is a refusal rather than an escape, and why the reasoning is written into the lib's own header
where the next person to reach for quotes will find it.

The other half is the size. The issue reported three sites of seven, in good faith, from the outside;
the pickup check is what found the other four. A repair that had satisfied the report would have left
four live and carried a citation saying the class was closed.

**Score:** N/A

#### Pull Request

A branch name is never interpolated raw into a printed, paste-ready command

Plugins: dkj-policy, dkj-team-shopify

[PR #1615](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1615)

---

### DEPLOY: fix/1600-branch-pickup-divergence · 20260908-121846

A branch resumed from a handoff note now learns that another session is already on it -- at the moment
of pickup, and again on every turn after it.

Two sessions had run the same pre-PR review on one parked branch in full, each finding real defects the
other missed, and neither learned of the other until the push at the very end. The signal existed for
half an hour: `cycle-autopark`'s push is refused the moment the other side pushes, every turn. What was
missing was delivery. The refusal now fetches that one ref and **names the other side** -- how far
behind, and the remote tip's author and subject, which is what separates a collision from a
fast-forward of your own autopark -- where it used to say *"run park-cycle by hand for the reason
(diverged from origin?)"* and send the reader for an answer the run already held. The Stop hook carries
the child's stderr into its report, so no line park-cycle writes can be lost to the stream it chose.

And the pickup route that carries the guard is now the one the documentation prescribes: `park`'s
"picking a parked branch back up" opens with `new-branch.ps1 -Name <the parked branch>` -- idempotent,
and the only resume that counts the gap and names the tip -- instead of leaving `git checkout` as the
implied route, which is the door this incident came through three days after
[#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439) closed the other one.

**Score:** 4

#### What makes this deploy extra special

Every consumer of this workflow runs `cycle-autopark` on every turn, so this changes what their sessions
are told at the moment two of them collide -- and duplicated work is expensive in a way wasted tokens
are not: the measured pair each found defects the other missed, so either winning outright would have
shipped a bug. It arrives on a plugin update with nothing to adopt.

**Score:** 4

#### Pull Request

A resumed branch learns another session is on it, at pickup and every turn

Plugins: dkj-policy

[PR #1613](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1613)

---

### DEPLOY: docs/1597-readme-six-enabled-plugins · 20260908-115352

The `dkj-policy/` folder index no longer describes this repo as enabling two plugins. Its "Updating the
plugins" section states that `.claude/settings.json` enables every plugin in the marketplace and prints
an update command for each of the six, so an update round in another checkout of this repo no longer
leaves four plugins silently behind.

**Score:** 3

#### What makes this deploy extra special

N/A — an internal maintenance document of this repo. No consumer reads it, and nothing about the
plugins they install changes.

**Score:** N/A

#### Pull Request

Name all six enabled plugins in the dkj-policy folder index

[PR #1610](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1610)

---

### DEPLOY: fix/1601-folded-upstream-diverged-checkout · 20260908-113102

`check-unfolded-entry.ps1` told a checkout that is both ahead of and behind `origin/<trunk>` that its
unfolded entry had already been folded upstream, and sent it at a `git pull --ff-only` that cannot
fast-forward. The fold was still owed. It now asks whether the branch's entry is present in
`CHANGELOG.md` on the remote-tracking ref -- the other half of the same fold commit -- through
`Test-BranchFoldedOnRef`, a new function in `entry-scaffold-lib.ps1` that reads the changelog at that
ref via the existing `Get-FoldedEntryForBranch` rather than defining a second idea of what a folded
entry looks like. The entry's presence has exactly one cause whichever way a checkout has drifted, so
the gap gate #1585 needed is gone: it was sufficient, never necessary. Nothing changes in CI or for a
checkout that is merely behind.

**Score:** 2

#### What makes this deploy extra special

The repair is the one #1601 itself named, down to the function's place in the tree -- and the reason
#1585 named the state instead of guarding it (a second definition of a folded entry) is what shaped
it: the match stays in the lib, beside the definition it must not disagree with.

The fixture is the part worth reading. `Push-UpstreamFold` had written only the deletion half of the
fold commit, which was invisible while the check asked about that same half; the moment the check
asked the other question, the suite could no longer answer it. A fixture that models half a commit
proves nothing about the other half, and this one had been passing for exactly as long as the check
was looking the same way it was.

**Score:** 1

#### Pull Request

Read the entry on the ref, not the absent document, in check-unfolded-entry

Plugins: dkj-policy

[PR #1608](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1608)

---

### DEPLOY: feat/plugin-version-overview-v2 · 20260908-111715

A second pre-PR review pass on `plugin-versions.ps1` repairs the one defect its first pass shipped
with the trunk still carrying: where an install's recorded commit is reachable in the marketplace
clone but not an ancestor of its HEAD -- the state a history rewrite in the clone leaves behind -- the
verdict skipped the version-string tiebreaker its own sibling branch already used, and concluded
unconditionally that the install was ahead. The consequence was a wrong instruction:
`claude plugin marketplace update` printed where `claude plugin update` was the one that would have
closed the gap. Alongside it: four smaller output defects in the same script (a stray blank, a
wrongly-printed `HEAD`, a missing-sha line blaming the wrong side, and two culture-aware sorts brought
onto this project's ordinal-sort invariant), input sanitising on the sha before it reaches `git`, the
test coverage that closes the gap which let the original bug ship unnoticed, a token cut to the
skill's always-on frontmatter, and two small wording fixes.

**Score:** 3

#### What makes this deploy extra special

A consumer of the `dkj-policy` workflow whose marketplace clone has been through a history rewrite
stops being told to run the wrong command. Every consumer with `dkj-policy` enabled also pays a
slightly cheaper always-on cost for this skill, and reads clearer wording on its page. Bounded
reach: the wrong-instruction bug only fires on a clone that has actually been rebased or force-pushed
since the install was recorded, which is not the common case.

**Score:** 2

#### Pull Request

Second pre-PR review pass on plugin-versions

Plugins: dkj-policy

[PR #1604](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1604)

---

### DEPLOY: fix/1592-fold-commits-void-certificate · 20260908-105846

`ship-pr`'s stale-certificate gate no longer refuses on a **fold** commit. A commit whose entire
diff is the changelog plus the removal of a branch document is written by this workflow itself,
under an exception bounded to those two paths, and carries no script, test, manifest or agent def --
so it cannot be the case the gate was built for: a test block reaching the trunk that the shipping
branch's CI never ran. The commit's own diff decides that, never its subject line, and every
unreadable input leaves the commit counted exactly as before.

It is why detect-and-rebase can converge on a busy trunk. Shipping PR #1571 took four attempts and
about an hour; the three commits that voided its two refused certificates were all folds, and both
refusals would have passed. Folds are 42% of this trunk's first-parent commits, so the rate at which
the trunk voids a certificate roughly halves -- against a window that is about as long as CI takes
(310-461s measured, median 374s) and cannot be made much shorter.

Nothing changed at the wait. #1592 attributed the window to the non-required `claude-review` check,
reading `lint-en-tests finished in 2s` off the check table; that 2s is the aggregator job's elapsed,
and measured over 40 paired runs the non-required check governs 8 of them at a median excess of 0s
across all 40 -- reconfirming #831's own 23% at n=100 rather than overturning it.

**Score:** 4

#### What makes this deploy extra special

N/A -- no subscriber of a service notices this. It is entirely internal to how a branch reaches the
trunk in this repo and in every consumer running the workflow.

**Score:** N/A

#### Pull Request

The staleness gate no longer refuses on fold commits

Plugins: dkj-policy

[PR #1598](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1598)

---

### DEPLOY: fix/1585-unfolded-entry-stale-checkout · 20260908-104546

The skipped-fold check no longer reports a landed fold as a missing one. A checkout that is merely
behind `origin/<trunk>` now gets a `[WARN]` naming the gap and `git pull --ff-only`, instead of an
`[ERROR]` pointing at a fold that would refuse on that same stale trunk; where a fold really is owed the
report is unchanged, and now also says to pull first. The extra question costs no network and is asked
only at a non-zero gap, so CI and an offline session both behave exactly as before.

**Score:** 3

#### What makes this deploy extra special

A consumer's session start stops raising a red `[ERROR]` for the ordinary state of being a few commits
behind, and the one line it prints instead is the command that fixes it. That noise was
indistinguishable from the real skipped-fold state the check exists to catch, which is what made it
worth repairing rather than tolerating.

**Score:** 3

#### Pull Request

Tell a stale checkout apart from a skipped fold in check-unfolded-entry

Plugins: dkj-policy

[PR #1603](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1603)

---

### DEPLOY: feat/plugin-version-overview · 20260908-102335

A new `dkj-policy` skill, `plugin-versions`, answers a question nothing else in the system does: for
each enabled plugin, is the version installed IN THIS CHECKOUT the same as the one the local
marketplace clone holds, and if not, which command closes the gap? It reads only what every consumer
machine already has -- the install record keyed on this checkout's `projectPath`
(`version`, short `gitCommitSha`, `scope`), and the marketplace clone's per-plugin `plugin.json`
`version` plus its git `HEAD`. Because the clone advances only on
`claude plugin marketplace update`, the version string is cut-granular and the HEAD sha is the finer
truth, so the verdict prefers the sha (ancestor of HEAD -> `claude plugin update`; equal -> up to
date; unknown to the clone -> refresh the clone) and falls back to the version comparison when a sha
is absent. Read-only, no arguments, runs on any device; a missing clone, a missing install record, a
declarative-only enable, a moved checkout and a non-git marketplace fetch each degrade to a clear
line rather than an error. `Get-InstallRecord` in `check-report-lib.ps1` gains a `GitCommitSha` field
on its projection to feed it.

**Score:** 3

#### What makes this deploy extra special

Every consumer of the `dkj-policy` workflow receives the `plugin-versions` skill in the next release,
and with it the first per-device answer to *"is this checkout on the current plugin release, and do I
run `claude plugin update` or `claude plugin marketplace update`?"* -- a blind spot the repo slot in
`CLAUDE.md` calls out explicitly ("between two releases no version check can tell you the clone is
behind"). It is noticed the moment a consumer wonders whether a session loaded a stale plugin.

**Score:** 3

#### Pull Request

A per-device plugin-version overview: installed vs. marketplace clone, with a verdict

Plugins: dkj-policy, dkj-team-alpha

[PR #1599](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1599)

---

### DEPLOY: fix/1588-stale-ci-remedy-checkout · 20260908-100702

`ship-pr`'s stale-CI refusal now tells you to check the branch out before bringing it forward. It printed
`git fetch` and `git merge` alone, and by the time it fires the same run has already returned your tree to
the trunk -- so both commands acted on `main`, silently: the merge fast-forwarded the trunk with a diffstat
that reads exactly like the branch moving forward, the push was a no-op, and the branch was untouched. The
cost was a full CI cycle and a re-run complaining about the wrong problem, twice in five days.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service notices. This is a refusal message inside the shipping tooling;
its reader is whoever is merging a pull request.

**Score:** N/A

#### Pull Request

ship-pr's stale-CI remedy names the branch to check out first

Plugins: dkj-policy

[PR #1596](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1596)

---

### DEPLOY: fix/1584-ship-pr-conflicting-early-exit · 20260908-095109

`ship-pr` now refuses a CONFLICTING pull request the instant it starts waiting for CI, instead of
after the full 180s check-registration timeout. A conflicting PR has no `refs/pull/<n>/merge` for a
`pull_request` workflow to run against, so no check suite can ever register for it -- a state GitHub
reports the moment the PR exists, which made the wait pure cost. The refusal reuses the existing
#1247 diagnosis (resolve the conflict; a close/reopen was measured doing nothing), and where the
conflict is a branch whose changelog entry has already folded on `main`, it says the branch is spent
and the follow-up belongs on a fresh branch off the trunk -- rather than a rebase that just re-adds a
folded entry.

**Score:** 3

#### What makes this deploy extra special

N/A -- internal shipping-workflow tooling; no subscriber of a service is affected.

**Score:** N/A

#### Pull Request

Refuse a CONFLICTING PR up front instead of after the 180s check-registration wait

Plugins: dkj-policy

[PR #1595](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1595)

---

### DEPLOY: fix/1586-fold-on-merge-stale-trunk-deferral · 20260908-094224

The `Fold on merge` CI job no longer goes red when two merges land within seconds of each other. Its
checkout reads the trunk once, and the fold's trunk-freshness guard measures the same trunk again about
eleven seconds later -- so a second merge in that gap left the job refusing on an entry another actor
had already folded. The guard was right and the trunk ended correct; only the red was wrong, and it
described a state that was gone by the time anybody opened it.

That refusal now carries its own exit code -- `2`, the only thing in `fold-changelog-entry.ps1` that
returns it -- and the job stands down green on that code alone, naming the reason in the log. Every
other non-zero code still fails it, so the three real ways the job goes red are untouched. Nothing is
lost by standing down: the guard fires in a pre-pass before a single entry is folded, and the push that
moved the trunk queues its own run of the same job behind this one. The consumer template in
`adopt-merge-queue.ps1` places the same behaviour, and both workflow headers stop claiming -- as
#1543's repair did -- that `ref: <trunk>` puts that guard out of reach.

**Score:** 3

#### What makes this deploy extra special

A consumer who has adopted the CI floor gets a fold runner that stops crying wolf, and the guidance
that goes with it: a `Stood down:` line in the log is the job working rather than a fold that went
missing. `git fetch` + `--ff-only` before the fold was the obvious alternative and is declined in
writing -- it narrows the window without closing it, which leaves the guardrail red *rarely*, and a
guardrail that is wrong rarely is the one nobody reads.

**Score:** 2

#### Pull Request

fold-on-merge stands down on a trunk that moved under it, instead of going red

Plugins: dkj-policy

[PR #1593](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1593)

---

### DEPLOY: docs/1587-staleness-source-of-truth · 20260908-093101

`dkj-policy/README.md`'s staleness paragraph claimed a connector manifest "carries the version its
record was last seen on." No manifest field has ever stored a version — that bookkeeping was removed
by decision on July 20, 2026 (see [`connectors/README.md`](../connectors/README.md#the-manifest-format))
— and the actual mechanism reads the version installed on that machine from its own
`installed_plugins.json` record and compares it to the source checkout's `plugin.json`; the register's
only part in that is `localCheckout`, i.e. which machine record to read. The rewritten paragraph keeps
what was true (`connector-sessioncheck` still reports every lagging consumer at session start, and
`check-connectors.ps1` is still the deliberate full run, because the lagging checkout itself reports a
plausible version and works) and adds the case the old wording missed: with no verified source checkout
on the machine, the check is skipped outright, so silence there is not "up to date" — it is no verdict
at all. No other passage in the file rested on the same false premise.

**Score:** 2

#### What makes this deploy extra special

N/A -- this corrects one paragraph's wording about an internal maintenance mechanism (the connector
register and the staleness check). No subscriber of a service reaches this page or is affected by
whether the mechanism is described accurately.

**Score:** N/A

#### Pull Request

Describe the plugin-staleness mechanism as it actually works

[PR #1590](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1590)

---

### DEPLOY: fix/1566-truncated-plugin-links · 20260908-092431

Sixteen links in the plugin payload named a file and pointed at the repository front page. A consumer
reading `specialists-init` -- the first page a new adopter opens -- was told to read `INSTALL.md` and
landed on the repo's home page to find it themselves. All sixteen now carry the path they name, and the
six that named a section carry its anchor.

Nothing could have caught them. GitHub answers `.../blob/main/` with the repo root, so all sixteen
returned 200 and were never dead links; the dead-link scan skips absolute targets, and `[plugin-link]`
skipped them too, because its subject is a *relative* target escaping the plugin root. The defect sat
in the gap between "not dead" and "not relative".

So the check that produced the shape now holds it. `[plugin-link]`'s suggestion hands the author the
absolute form of an escaping link, anchor included; sixteen base-only links against the seventeen
repairs that suggestion was written for is close enough to name the mechanism -- the advice was right,
and nothing held the *result* of taking it. The new half reports an absolute link that is this repo's
blob/tree base with nothing after it: the one absolute shape that is provably not what the author
meant, since the link text always names something more specific. Absolute links stay otherwise out of
scope. It keys on `Get-RepoBlobUrl`, so it cannot disagree with the suggestion about which URL counts
as this repo's -- and in a repo without that seam it does not run and the coverage line says so.

That keying has one named cost: a base-only link written on the *previous* owner name is out of reach,
which is where all sixteen of these were. Widening to reach it was declined -- recognising a retired
owner path would bless a spelling the repo-citation rule is retiring -- and there is no instance left to
justify it: zero base-only links on either owner remain anywhere in the tree, and every future one comes
from the suggestion, which writes the current base. A test pins the pass, so reaching for it later has to
be a deliberate edit.

**Score:** 3

#### What makes this deploy extra special

A gate whose own advice creates a defect class it cannot see is the shape this repo keeps paying for,
and the reach is a consumer's first read rather than an internal document. Not a required migration and
nothing breaks, so it stops short of 4: a reader who never clicked those links loses nothing, and one
who did now lands where the text said.

**Score:** 3

#### Pull Request

Give the 16 truncated absolute plugin links their real paths, and gate the shape

Plugins: dkj-policy, dkj-team-alpha

[PR #1571](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1571)

---

### DEPLOY: fix/machine-local-note-review-findings · 20260908-091324

Five review findings on the machine-local note reached `main` after the change they were about. The
gate's reworded note (#1574) merged from a parked commit while the reviews on it were still running, so
the text that shipped still said to keep a swept-in edit in "that file's gitignored sibling" -- singular,
against a note whose first line lists however many paths the repo watches. A consumer with two entries
in `Get-MachineLocalPaths` read advice with no antecedent. That is corrected here, along with a seam
comment that called PR #1573 a branch whose "entire subject" was one hunk of a fifteen-file diff, and
three defects in the folded changelog entry: it credited #1557 with founding the gate where #1559 did,
used "misfires" transitively where the two neighbouring restatements do not, and switched the referent
of "it" mid-paragraph. Nothing about when the gate fires changed, and it still only warns.

**Score:** 2

#### What makes this deploy extra special

The note is printed by a shared script that travels in the plugin mirror, so its wording is what every
consumer reads at `open-pr`. The correction matters most in the repo this text was NOT written in: one
watched path is this repo's answer, and the sentence only breaks where somebody has configured two.

**Score:** 1


#### Pull Request

Land the review findings the queue merged past on the machine-local note

Plugins: dkj-policy

[PR #1589](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1589)

---

### DEPLOY: fix/1579-shopify-no-store-seam · 20260908-090100

This repo now declares that it has no Shopify store, so `dkj-team-shopify`'s floor check stops asking it
for a live theme id it cannot truthfully give. `scripts/repo-config.ps1` answers
`Get-ShopifyRepoHasNoStore` with `$true` -- the seam inbound #1570 added to the check -- and the
`CLAUDE.md` repo slot no longer describes that permanent `[ERROR]` as a gap in the check, because it is
not one any more. The "do not silence it by seeding a theme id" warning stays: a declaration says there
is no store, an id says there is one and names it, and only the first of those is true here. The
session start on a given machine goes quiet once the plugin change reaches its marketplace clone
through a release, which the slot now states rather than leaving a reader to wonder why the message
persists.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here reaches a consumer of the plugins. Both files are this repo's own layer:
`scripts/repo-config.ps1` is repo-local configuration and never ships, and `CLAUDE.md`'s repo slot is
explicitly the part a copying repo replaces. The seam it answers was shipped by #1570; this branch only
answers it.

**Score:** N/A

#### Pull Request

This repo declares it has no Shopify store, so the floor check goes quiet

[PR #1583](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1583)

---

### DEPLOY: fix/1572-lane-ship-queue-trunk-holder · 20260908-085026

`ship-pr.ps1` refused a lane ship whenever another worktree (the primary checkout) held `main`, on the
ground that "step 5 could not fold after the merge" -- but under a merge queue step 5 folds nothing:
the queue's own push to `main` runs `fold-on-merge.yml`. The refusal therefore blocked the exact
lane workflow `ship-pr` itself recommends, since step 2b (#1073) leaves the primary on the trunk on
purpose. The refusal now runs *after* the queue verdict and is gated on `-not $queueActive`, the same
shape #1506 established for the fold-push verdict; under a queue the held trunk is noted, not refused.
Where no queue is read the guard is unchanged.

**Score:** 4

The lane ship path -- the one `ship-pr` prints while waiting on CI -- was simply broken on a queued
trunk. Each occurrence was worked around by hand (moving the primary off the trunk, against the
orchestrator's "end on the trunk" rule for the duration of the ship).

#### What makes this deploy extra special

A consumer running `dkj-policy` *with a merge queue on their trunk* hits the same refusal if they
follow `ship-pr`'s own advice to ship from a lane. Bounded audience -- GitHub only offers merge queue
on private repos under Enterprise/Team -- but for those repos the lane ship was unusable.

**Score:** 3

#### Pull Request

ship-pr no longer refuses a lane ship on a queued trunk where it folds nothing

Plugins: dkj-policy

[PR #1576](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1576)

---

### DEPLOY: fix/1575-prune-merged-dirty-guard · 20260908-084930

`prune-merged.ps1` no longer refuses a dirty working tree on runs that could never move it. The
refusal's own ground is step 4c -- stepping off the branch you are standing on in order to reap it --
and that step is unreachable when HEAD is the trunk (never a reap candidate), when HEAD is detached,
and under `-DryRun` (which deletes nothing). The guard now asks exactly that reachability question, so
those runs proceed; a dirty tree they pass through is reported with the reason it was harmless, rather
than passed over in silence.

This is the command the orchestrator's lens tells a session to run mid-assignment in place of
classifying `git ls-remote` output by hand -- and mid-assignment is exactly when a checkout has
uncommitted work in it, so the guard was blocking the report in the state the advice was written for.
The two ways out it offered are the wrong price for a read: parking commits to a branch, and stashing
touches a file the session was told to leave alone.

Nothing the guard protected is given up. A dirty checkout standing on a non-trunk branch refuses
exactly as before, because that branch can be squash-merged while the work is uncommitted, and that is
the case where the step-off drags it onto the trunk. The refusal now names the branch that makes it
reachable, and offers `-DryRun` beside commit, park and stash.

That last case is why the doc half moved too. The orchestrator's lens and the consumer-facing skill page
for this script now name `-DryRun` as the route for a session standing on a branch with uncommitted
work, which is the ordinary mid-assignment shape: it deletes nothing, so it never has to step off, and
the classification it prints -- the paste-ready delete command for a merged leftover,
`Kept ... -- live work` for everything else -- is identical to the full run's. The skill page had gone
further than stale; it still described the refusal as unconditional, which is what a consumer would have
read.

The suite's own dirty case ran from the trunk, so it had been pinning the defect; it is re-pointed at a
branch, and two cases are added for the arms that now proceed.

**Score:** 3

#### What makes this deploy extra special

N/A -- this is a maintenance script in the development workflow. No subscriber of a service reaches it,
and nothing about a published artifact changes.

**Score:** N/A

#### Pull Request

prune-merged only refuses a dirty tree where the run could actually step off it

Plugins: dkj-policy

[PR #1581](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1581)

---

### DEPLOY: fix/1570-shopify-floor-no-store-seam · 20260908-084027

The Shopify floor session check gains a third state. A repo that enables `dkj-team-shopify` without a
store -- the plugin's own source repo, or any repo that turns the team on only to validate its
manifests and hooks -- can now answer `Get-ShopifyRepoHasNoStore` with `$true` in its
`scripts/repo-config.ps1`, and the check then stays silent on the half-armed live-theme finding
instead of raising a permanent `[ERROR]` it has no truthful way to clear. The silence follows a
deliberate, self-authored declaration only -- never an inference from the tree -- so no real store is
ever quieted by it, and the guard hook, every other seam and the independent duplicate-guard finding
are unchanged.

**Score:** 3

#### What makes this deploy extra special

A consumer that enables `dkj-team-shopify` purely to check that its manifests and hooks still resolve,
without owning a store, gets a clean session start instead of a standing `[ERROR]` or a faked theme
id. Store consumers -- the common case -- see nothing change.

**Score:** 2

#### Pull Request

let a repo declare it has no Shopify store, so the floor check stops the permanent [ERROR]

Plugins: dkj-team-shopify

[PR #1578](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1578)

---

### DEPLOY: fix/1574-machine-local-remedy-wording · 20260908-083227

The machine-local path gate stops giving wrong advice on the path it fires on. It warns whenever a
branch's commits touch a tracked file that usually belongs to a clone -- `.claude/settings.json` here
-- and its remedy sentence said, flatly, to drop the change from the branch because "machine-local
plugin enablement belongs in `.claude/settings.local.json`". That is right for a machine's own extra
enable, the sweep the gate was built for (#1559, measured on PR #1557), and wrong for the other case
the same file carries: a branch whose subject IS the declared, tracked set every clone inherits. Measured on PR
#1573, where the gate fired on a branch that existed to change exactly that. The note now names both
cases and prescribes the move only for the clone's own edit; the seam comment in `repo-config.ps1`
records which half of the advice belongs where, and the suite asserts it. Nothing about when the gate
fires changed, and it still only warns -- what changed is that the sentence a reader acts on is true on
both paths. The cost of leaving it was not a broken branch but a decaying reader: a warning that gives
the wrong advice on the path it fires on is one that gets scrolled past, and it is then scrolled past on
the day it is right.

**Score:** 2

#### What makes this deploy extra special

The note is emitted by a shared script that travels in the plugin mirror, so every consumer running
`open-pr` reads this text. A consumer branch that legitimately changes its own shared harness settings
now gets advice it can follow instead of being told to move the change somewhere gitignored. Small --
three sentences on a rare path -- but until now following that advice was the wrong move, and only a
reader who already distrusted it came out right.

**Score:** 2

#### Pull Request

Sharpen the machine-local gate's remedy so it names both cases

Plugins: dkj-policy

[PR #1577](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1577)

---

### DEPLOY: feat/source-enables-every-plugin · 20260908-081857

The source repo now enables **every** plugin in its own marketplace, not just the core team and the
workflow, and says why: a plugin whose agent defs, manifests and hooks are never resolved anywhere is one
whose install is only ever proven in somebody else's session. Enabling all six means a frontmatter that
stops parsing, a manifest that goes stale or a hook that stops resolving surfaces at this repo's own
session start instead of downstream. The three add-on teams and `dkj-policy-bwj` have no work here and are
not expected to, so the eleven specialists they bring get roster entries and empty `VUL-IN` lenses -- and
`CLAUDE.md` and `SPECIALISTS.md` both now say, in as many words, that those eleven lenses are the intended
end state and not a backlog. The one cost that cannot be documented away is `dkj-team-shopify`'s floor
check, which reports an `[ERROR]` every session here because it asks which theme is live and has no third
state for a repo with no store; that is named in the repo slot and filed as #1570, with an explicit
instruction not to silence it by inventing a theme id.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing under `plugins/` changed, so no released payload moves and no consumer sees anything from
this branch. It is a change to how the source repo is configured and what its own governance documents
claim.

**Score:** N/A

#### Pull Request

Enable every plugin in the source repo, with the roster catch-up it owes

[PR #1573](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1573)

---

### DEPLOY: feat/consumer-readme-update-topup · 20260908-080839

A consumer's `dkj-policy/README.md` now **gets** the UPDATE section, and gets it even if their folder was
scaffolded before the section existed. `adopt-dkj-policy` Part 1 places it on a fresh adoption and
**appends** it to a page that has none, recognised by a marker comment
(`<!-- dkj-policy:update-section -->`) — the one write this command makes into a file it did not create,
bounded to a single append at the end of a single file, in whichever folder `Get-WorkflowFolderName` says
that repo actually has. A page that already carries it is left untouched and reported as such, so a
re-run still finds nothing to do.

The section itself names that repo's **own** plugin ids, read from its settings chain, one
`claude plugin update <id> --scope project` line per enabled plugin under the marketplace refresh — with
the command's shape as the fallback, because a placeholder is honest and a wrong id is not. It carries
why both halves of the pair matter, that the marketplace clone and the install record are per-checkout
state no session reports, and the seam answer a newer version of the shared scripts can start asking for.

This closes the reach half of #1567: without it, the section landed in the source repo and in no consumer.

**Score:** 4

#### What makes this deploy extra special

Three consumers are registered against this source today, and every one of them adopted its folder
before this section existed — so this is the difference between the section existing and the section
arriving. It is also the first time this scaffold can deliver a *later* improvement to a page it already
placed, which is a shape the folder's other documents will want as well.

**Score:** 3

#### Pull Request

Let the adoption scaffold place -- and top up -- the UPDATE section in a consumer's folder README

Plugins: dkj-policy

[PR #1569](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1569)

---

### DEPLOY: fix/1564-fold-stale-offset-after-tally · 20260908-075318

`fold-changelog-entry.ps1` crashed on the first fold after every release cut -- folding into an empty
`## [Unreleased]` -- because it read byte offsets against the changelog *before* the pending-tally
rewrite replaced that string with a shorter one, then used them in the "placed above N" console line.
The crash landed between the changelog write and the commit, so `-Commit -Push` silently did neither
and left the fold uncommitted on the trunk with the entry file already deleted. The offset-dependent
counts now run before the tally rewrite, while the offsets are still valid; a regression test folds
into a freshly-cut `## [Unreleased]` and checks the fold is committed.

**Score:** 4

Every first fold after a release cut hit this; recovering it meant a hand-typed commit of the two
bounded paths, twice in one day per the issue. Not a 5 only because that recovery was known and
in-bounds.

#### What makes this deploy extra special

A consumer running the `dkj-policy` workflow hits the same crash on their first fold after their own
release cut -- a shipped script broken on a guaranteed code path, leaving their trunk in a silent
half-state (`-Commit -Push` doing neither, entry file gone so `check-unfolded-entry.ps1` sees nothing).

**Score:** 4

#### Pull Request

fold-changelog-entry.ps1 no longer crashes on the first fold after a release cut

Plugins: dkj-policy

[PR #1568](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1568)

---

### DEPLOY: docs/dkj-policy-folder-update-section · 20260908-074642

`dkj-policy/README.md` now says how to **update** the plugins, not only how the folder is arranged — a
section between the seam table and the pointer list, written for the case this repo is peculiarly
exposed to: it consumes its own marketplace, so a session here runs the installed copy and **a push does
not advance the local clone**. It carries the two commands per plugin, the session restart, and then the
three things that make an update invisible until somebody looks: between two releases no version check
can tell you the clone is behind, the install record is per-checkout and keyed on its folder path
(#1449), and the only place a lagging machine is actually visible is the connector register. It closes
on the two catch-ups an update can require — the seam function `script-contract-sessioncheck` reports,
and the roster row and lens a newly arrived specialist needs.

The same edit narrows this page's intro, which called the index **two** sections below the divider and
is now three.

**Score:** 3

#### What makes this deploy extra special

N/A — this is the source repo's own folder index, and nothing here travels to a subscriber. The
consumer-facing half of the same subject shipped in #1565, on the plugin's own page.

**Score:** N/A

#### Pull Request

Say how to update the plugins in another checkout of this repo

[PR #1567](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1567)

---

### DEPLOY: docs/dkj-policy-update-section · 20260908-072707

The `dkj-policy` plugin page now says how to **update** the plugin, not only how to enable it — a
`## Updating it` section beside `## Enabling it`. It carries the two commands, the session restart, and
the ministry's own pair; then the reason the section has to exist at all: the cached marketplace clone
and the install record are both **per-machine** state keyed on the checkout's folder path, so a version
picked up on one machine changes nothing on the next one and no session says so. It closes on what a
consumer needs afterwards: the script-contract catch-up an update can require — the shared scripts may
call a repo-owned function that checkout has never had (#147), which `script-contract-sessioncheck`
reports and `adopt-dkj-policy` Part 2 fills in — and the assurance that an update never touches the
consumer's own `dkj-policy/` folder, so work in flight cannot be lost.
No measurement is restated: the page links the family's `INSTALL.md` for those.

The same edit corrects that file's 13 `DaveKJohn/claude-code-specialists` citations to the canonical
`DKJ-Solutions/…`, under the rule that corrects them in a file being edited anyway.

**Score:** 3

#### What makes this deploy extra special

For a consumer running this workflow in more than one checkout — which is every consumer with a laptop
and a desktop — the page they read now answers the question that sends them to the wrong tree: *why is
this machine behind, and what do I run here?* The answer was only ever in the family's adoption page,
one repo away from the plugin they had just installed.

**Score:** 2

#### Pull Request

Say how to update dkj-policy on every other machine

Plugins: dkj-policy

[PR #1565](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1565)

---

### DEPLOY: fix/1562-origin-remote-redirect · 20260907-211130

The repo-citation section of `CLAUDE.md` now covers the layer it could not reach: a checkout's own
`origin` remote. A checkout cloned before the September 2, 2026 transfer still pushes to
`DaveKJohn/claude-code-specialists.git` and succeeds only because GitHub answers `remote: This
repository moved` — every push of the `v4.32.0` cut did exactly that. The note names the
one-command repoint (`git remote set-url origin
https://github.com/DKJ-Solutions/claude-code-specialists.git`) and ties the fragility to the same
condition the prose rule already carries: the redirect holds only while nothing is created at the
old path.

**Score:** 1

The failure this prevents has not happened: pushes from un-repointed checkouts still work today. It
bites the day anything is created at `DaveKJohn/claude-code-specialists` — every such checkout's
pushes then fail with no redirect to catch them, and nothing in the tree points at the cause.

#### What makes this deploy extra special

N/A — an internal documentation note. A subscriber of the service never sees a repo remote URL.

**Score:** N/A

#### Pull Request

Note the origin remote fix for checkouts still on DaveKJohn/

[PR #1563](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1563)

---

