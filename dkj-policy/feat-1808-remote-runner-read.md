## feat/1808-remote-runner-read

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Give check 6 an opt-in network read so a consumer whose checkout is not on this machine is judged rather than skipped -- and states that it was not checked where it cannot be.

#### What the report got right, and the one thing it under-specified

Verified against the tree before anything was written. The subject is real and the limit stands exactly
as filed: `check-connectors.ps1` check 6 reads the consumer's local checkout, so it inherits check 1,
and an absent consumer is `[SKIP]` with nothing about its runners read. Both reasons the report gives
for having declined the network read are still good, and both are honoured rather than argued with --
the switch is off by default because this script runs from `connector-sessioncheck.ps1` at every
session start, and a repository the credential cannot read gets a third verdict of its own.

**What the report under-specified is the REST shape it proposed.** `gh api
repos/<repo>/contents/.github/workflows` needs a second call per file to get any content, and -- worse
-- its listing answers *a repository this token cannot see* and *a repository with no workflows
directory* with the same HTTP 404. That conflation is exactly the distinction the third state exists to
make, so the proposed reader could not have produced the behaviour the same issue asks for. One GraphQL
call answers both structurally (a null `repository` is no access, a null `object` is no such tree) and
returns the blob text with it. So this follows the report's intent rather than its mechanism.

**And the branch that filed it was still open when it was picked up.** #1805 was parked with no PR, so
check 6 did not exist on the trunk; it merged as #1809 while this branch's own gates were running.
Nothing about the work changes with it -- recorded because a reader retracing the two issues would
otherwise find #1808's subject landing after the branch it is a follow-up to.

### CREATE

- [x] `check-connectors.ps1`: `-RemoteRunners`, plus the once-per-run answer to whether the read can be
      made at all (no `gh`, no credential) -- asked once because both are properties of the machine
      rather than of a connector, and said out loud because the switch was typed on purpose.
- [x] `Write-RunnerPathFinding` -- check 6's judgement extracted from its local loop, so both transports
      reach the same three outcomes and the wording cannot drift apart. The caller supplies only a
      clause naming where the text came from.
- [x] `Get-RemoteConsumerWorkflow` -- one `gh api graphql` call per absent consumer returning name +
      text per workflow, with the slug guarded to GitHub's own shape before it becomes an owner and a
      name, and the body parsed BEFORE the exit code is looked at.
- [x] `connectors/README.md` -- the switch, why it is the only opt-IN one on that page, and the measured
      blind spot it closes. The check list above it gained check 6, which #1805 had not added to it.

### TEST

- [x] `connectors.tests.ps1` scenario 13 (a-k), driven against a fake `gh` on PATH that logs every call:
      the switch off makes no call at all, a stale path over the network is the same `[ERROR]` with the
      branch named, a current path is silent, an unreadable repository is a stated `[INFO]` quoting the
      API, no workflows directory is silence, a text-less blob is its own nothing while its sibling is
      still judged, both refusal doors say so, a malformed `repo` slug never reaches a call, and
      `-OnlyConsumer` spawns nothing at all. 314 pass, 0 fail (268 before this branch).
- [x] The real register, both ways. **Default path unchanged, measured rather than asserted**: the
      output of `-SkipDrift -SkipVersions` at this branch and at `origin/main` is byte-identical apart
      from the commit stamp it prints (0 errors, 6 infos, 5,363 characters both times). Run by swapping
      the one file in and out of the same checkout, because a `git worktree` is NOT a valid A/B here --
      `localCheckout` is relative to the repo root, so a worktree in a temp directory makes the two BWJ
      consumers read as absent and produces a difference the change had nothing to do with.
      With `-RemoteRunners`: the two consumers #1805 reported as red come back as the third state --
      this credential cannot see either -- and `DaveKJohn/djcylow-react` is read and reported clean,
      verified by hand to be the truth rather than a silent failure (one workflow, `ci.yml`, naming no
      checkout of this repository).
- [x] `check-plugin-integrity.ps1` and the full suite gate, via `open-pr.ps1`.
- [x] Review round (Victor, Sebastian, Edith in parallel on the diff) -- **three findings, two repaired
      with their own regression scenarios and one filed**:
      - *Victor 1.* The `gh` call passes `-TimeoutSeconds`, which routes it through the Start-Process
        arm -- and that arm can answer exit 0 with a capture a grandchild was still writing, which does
        not parse. Folded into the generic parse failure it printed the sentence a repository nobody can
        read gets, sending the reader after their credential for something a re-run settles. `ShortRead`
        now separates the two, as `claim-issue.ps1` and `verify-resolved-issues.ps1` already do at their
        own `gh` calls. Scenario 13k pins the separation.
      - *Victor 2.* The once-per-run capability probe ran before `-OnlyConsumer` was consulted, so a
        session-start run with both switches spawned `gh auth status` for an answer nothing downstream
        could reach. 13j now asserts the whole call log is empty rather than only that no `graphql` call
        was made -- checking for `graphql` alone is what let the spawn through.
      - *Sebastian.* No blocking findings. His advisory about `Format-SafeProseToken`'s docstring was
        verified before it was repaired and **his reason does not hold**: the claim ("today's one
        caller... has already split the document into lines") was already false for two existing callers,
        and `check-claude-home.ps1`'s own comment records having measured one that sends it a whole file.
        Not caused here, so filed as
        [#1813](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1813) rather than
        repaired on a branch whose subject is elsewhere -- the file is mirrored twice, so a one-line
        comment fix carries a generator run with it.
      - *Edith.* One measured figure in this document was wrong: the default-run bullet said "0 errors"
        without naming the flags, and a bare no-argument run gives 4 -- the machine-record check on two
        consumers whose plugin version is behind, which has nothing to do with this branch. Corrected
        above by stating the flags and re-measuring properly.
- [~] A verification against the two red consumers themselves -- dropped for the same reason #1805
      dropped it, and now for a reason the tooling states rather than a session asserting it: the read
      was attempted and the API answered that neither repository is visible to this credential. That is
      the third state working, not a gap in it.

#### The defect the first run had, worth keeping

The query was first written with the tree expression inline --
`object(expression:"HEAD:.github/workflows")` -- and Windows PowerShell 5.1 does not pass double quotes
through to a native command intact. gh received `expression:HEAD:.github/workflows` and answered
`Expected NAME, actual: COLON (":") at [1, 118]`, identically for all three absent connectors. **A
transport fault that is total is indistinguishable from a register full of unreadable repositories**, so
it would have been reported as the third state for every consumer and believed. The expression is a
GraphQL variable now, so the query string carries no quote at all.

### DEPLOY: feat/1808-remote-runner-read

Check 6 asks whether a consumer's CI runners still name paths that exist in this tree -- and it could
only ask it about a consumer checked out on the machine running it. That is the register's standing
behaviour and right for every other check there, but it lands badly on this one: those runners name a
path *into this tree*, written once at adoption into a file this tree cannot reach, so the consumer most
likely to carry a stale one is the one nobody visits -- which is the one least likely to be checked out
where you happen to be. Measured here: of six registered connectors, three were `[SKIP]`, including both
of the two whose runners were red.

`-RemoteRunners` closes that from the other end. An absent consumer's workflow files are read from its
default branch in one `gh api graphql` call and judged by the same function the local half calls, so the
finding, the repair suggestion and the escaping-path refusal are identical -- with the branch named,
because a reader who cannot open the file needs to know which revision was judged. It stays **off by
default**: this script is what `connector-sessioncheck.ps1` runs at every session start, and the suite
asserts that with the switch off not one `gh` call is made. And where the read cannot be made it says so
and quotes what the API answered, per connector, rather than falling through to a silence that on this
particular check would read as an all-clear.

**Score:** 3

#### What makes this deploy extra special

Nothing changes for anybody who does not type the switch, and that is asserted rather than claimed. What
the switch buys is the one question about an absent consumer that can honestly be answered from
anywhere, and the one this register most wants answered: a stale runner path is a required check red on
every pull request in a repository nobody is visiting, which is precisely why nobody has noticed.

**Score:** 2

#### Pull Request

check-connectors can judge the CI runners of a consumer that is not checked out here, on request

