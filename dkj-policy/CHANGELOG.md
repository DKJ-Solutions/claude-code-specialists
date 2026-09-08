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

**21 / 42 minor entries** <!-- pending-tally -->

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

