## fix/1622-fixture-git-judged

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

#### The report's two hypotheses were checked first, and neither survives

#1622 offers two, both explicitly unmeasured. Read against the tree:

| the report's hypothesis | what the code says |
|---|---|
| **Lane contention** -- "asserts labelled `net:` and `net/ls-remote:`, so at least part of it reaches the network" | The `net:` cases are **static scans of `sync-main.ps1`'s source text** -- call counts, bare-`& git` bans, EAP-bracket bans. The one case that runs anything, `net/ls-remote:`, first points origin at a local `no-such-origin.git`. The suite reaches no network at all. |
| **A shared path between fixtures** | Fixture roots are `syncmain-$PID-<label>-<six hex of a GUID>`, and gate lanes are separate `Start-Process` children. The PIDs differ before the GUID is consulted. |

A third candidate the suite's own header records -- #1117, where a random hex suffix spelled the needle `caf` and failed an assert about a file nothing touched, one run in 517 -- is closed here: all 24 `-notmatch` needles in this suite now carry a path prefix. Checked.

#### What does explain it

`Invoke-Git`, the helper behind **every fixture mutation in the suite** -- init, config, checkout, add, commit, remote add, push, 24 call sites -- was one line:

```powershell
try { $ErrorActionPreference = 'Continue'; & git @args 2>$null | Out-Null } finally { ... }
```

Stderr discarded, exit code never read. A git command that **failed** was indistinguishable from one that worked, so a fixture half-built and the cases reading the run's output failed in a block while the ones reading the disk stayed green -- with no error text anywhere. That is #1622's shape exactly, including "no evidence left to read".

It is the outlier of the three `Invoke-Git`s in this tree: `worktree-lane.tests.ps1`'s returns `@{ Code = $LASTEXITCODE; Out = ... }`, `fold-changelog.tests.ps1`'s is a read helper that returns output.

And what is different under 30 lanes is not the network but **dozens of concurrent `git` processes over one temp tree**, where a transient `index.lock` sharing violation, a scanner holding a file, or disk pressure is ordinary rather than rare.

#### The reporter's disclaimer is half right, and the other half is filed

> *"That is my error and NOT a gate defect -- recorded here so the next reader does not go looking for a diagnosability gap that is not there."*

The gate does print the block. It then **deletes the capture file** in its `finally`, so the console is the only copy -- which is what makes a pipe, a scrollback limit or a truncated CI log fatal rather than unlucky. Different file, different subject: **#1636**.

### CREATE

- [x] `Invoke-Git` judges `$LASTEXITCODE`, prints `[FIXTURE GIT FAILED] exit <n> -- git <args>` with git's
      own stderr beneath it, and counts the failure. It does **not** throw: a suite that dies at the
      first fixture hiccup reports less than one that runs on and names what broke.
- [x] `2>&1` instead of `2>$null`, the same call `worktree-lane.tests.ps1` already makes. Under Windows
      PowerShell 5.1 that wraps each stderr line in an ErrorRecord, which is harmless at `EAP=Continue`
      and is why the redirect stays inside the `try`. `$LASTEXITCODE` is unaffected -- it is `$?` that
      the wrapping disturbs, and nothing here reads `$?`.
- [x] the summary says it **before** the verdict and changes what the verdict means: every assert below
      a failed git command measured a repo that was never built, and "the script regressed" is the
      conclusion a reader reaches by default.
- [x] and a clean sweep of asserts over a broken fixture **fails the run**. Nothing else would catch it:
      the count is the only thing that knows, so it decides the exit code rather than letting a green
      run certify a suite that never ran what it claims to.

### TEST

- [x] the suite is green unchanged: 126 of 126.
- [x] both new paths verified by injecting a failing `git checkout refs/heads/no-such-branch-probe` into
      the fixture builder, then reverting: **22** named `[FIXTURE GIT FAILED]` lines, each with its exit
      code and full command; the `FIXTURE:` summary block; and -- the case that matters -- **every assert
      still passed and the run exited 1**. Without that last arm the probe would have been reported as a
      clean pass over twenty-two broken repos.
- [x] full lint + test gate green

### DEPLOY: fix/1622-fixture-git-judged

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

