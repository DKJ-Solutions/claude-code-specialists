## fix/1439-parked-branch-remote-head

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

Issue #1439: on the local-branch resume path, count `refs/heads/<name>..refs/remotes/origin/<name>` off
the fetch `-FetchAllRefs` has already done, and warn with the remote tip's subject and author. Warn,
never refuse.

#### The report was verified before it was built on, and one half of it improved

All six checks stand -- symptom, reason, repair, size, subject, repo. The repair is **cheaper** than the
report inferred: it proposed fetching the branch's own head, and `Get-TrunkGap -FetchAllRefs` already
fetches every ref two blocks earlier (load-bearing since #1139), so `refs/remotes/origin/<name>` is on
disk and fresh. The check adds a `rev-list` and no network call at all.

The report's own caveat -- *"nothing forces a session through `new-branch.ps1` when the branch already
exists locally"* -- is true and is left standing. It is the one command both sessions in the measured
incident ran, and it is the documented resume tool; a second reader of the same ref is a separate
question from this one.

### CREATE

- [x] `new-branch.ps1`: measure `refs/heads/<name>..refs/remotes/origin/<name>` on the local-resume
      route, and warn with the count plus the remote tip's author and subject.
- [x] Say it twice, as the two neighbouring checks do -- and from **both** ends of the run, which is
      what the suite forced (below).
- [x] Mirror to `plugins/workflows/contributing-davekjohn/scripts/task/new-branch.ps1`, byte-identical.
- [x] The shipped skill page: the fourth resume shape, the table of why every existing guard misses it,
      and the sample output.
- [x] Sanitize and cap the remote tip line before printing it (Sebastian's review). `%an`/`%s` are free
      text chosen by whoever pushed the commit, and this is the first place in the repo that prints
      externally-authored text to a console -- which an agent session also reads.

#### What the suite changed about the design

The first draft put the repeat above `exit 0`, matching the two checks beside it. The suite failed it:
a resume of a divergent branch **cannot push** -- the creation push is a non-fast-forward and the script
exits 1, which is the measured incident's own ending. So the second copy printed zero times in exactly
the case it was written for. It is a function called from both ends now, and from the failed-push branch
it is the diagnosis rather than a repeat: git says the push was rejected, this says whose work is on the
other side of it.

### TEST

- [x] `new-branch.tests.ps1` (y1): the reported state -- a local ref at the older tip, origin advanced by
      another identity with the incident's verbatim park subject. Asserts the count, the author, the
      subject, both copies, that the checkout still happened, and that HEAD is **not** fast-forwarded
      behind your back.
- [x] (y2): `-NoPush` reaches the other call site, so neither end of the run is untested.
- [x] (y3) the negative half: a resume whose remote head has not moved says nothing -- this fires on
      every second run of an idempotent script, so silence has to be silence.
- [x] (y4): the `$branchOnOrigin` route carries no gap, because it is created at the remote tip.
- [x] New fixture helper `Add-OriginBranchCommits` -- the other session finishing and parking, with the
      author and subject as parameters because they are what the check prints.
- [x] (y5)/(y6): an adversarial remote tip (ANSI escape, RTL override, zero-width joiner) is stripped
      and a 400-character subject capped -- with the payload asserted PRESENT on the remote first, so
      the strip asserts cannot pass vacuously.
- [x] Suite green: 254 asserts.
- [x] Lint gate green (0 errors) and all suites green.

### DEPLOY: fix/1439-parked-branch-remote-head

`new-branch.ps1` now compares the branch you are resuming against its own remote head, and warns when
`origin` is ahead -- naming the count and the remote tip's **author and subject**, which is what
separates another session's collision from a fast-forward of your own autopark.

Three sessions have now built the same work twice here. The first two (#1282, #1409) were about an
**issue** worked twice and both need an issue number; #1409 closed by naming the gap this fills -- *"that
leaves the case where no issue number is passed, which is most branches"*. The signal nothing read is the
remote head of the branch under your feet: `git status` prints the same line for "in sync" as for "never
fetched", `prune-merged -IncludeRemote` is for branches you are *not* on, and `cycle-autopark` makes the
collision more likely rather than less, because it is what puts the other session's work on the shared
ref. The last one cost two full gate runs, a 508-line script and a new test suite, all built blind.

The tip line is stripped of control and format characters and capped at 120 before it is printed: it is
the one piece of text this script emits that somebody else wrote, and an escape sequence in a commit
subject repaints the terminal it lands in. The neighbouring adversarial case points the other way on
purpose -- a malicious `-Title` must land fully and unchanged, because that goes into a file.

It costs no network call -- the base measurement already fetches every ref -- and it warns rather than
refusing, because the legitimate divergence (your own autopark from another device) sits on the intended
happy path.

**Score:** 4

#### What makes this deploy extra special

Every consumer runs this script from the plugin mirror, and the cross-device handoff it guards is the
workflow's own: `new-branch` pushes by default and `cycle-autopark` keeps the branch current on `origin`,
so a consumer working from two machines meets this exact state without doing anything unusual. They now
learn at the checkout instead of at the push.

**Score:** 3

#### Pull Request

new-branch warns when the branch you resume is behind its own remote head
