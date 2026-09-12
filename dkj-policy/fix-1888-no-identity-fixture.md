## fix/1888-no-identity-fixture

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

Issue #1888: the `no identity` fixture that inbound #1867 added to `scripts/tests/new-branch.tests.ps1`
is vacuous on this machine. It suppresses the identity in every place it knows about -- local config
unset, `GIT_CONFIG_GLOBAL` pointed at `NUL`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_AUTHOR_*`/`GIT_COMMITTER_*`
cleared -- and git still names an author, so its own sanity assert goes red and takes the seven asserts
below it with it. The whole local test gate fails on it, which is why the branch before this one shipped
with `-SkipTests`.

- [x] Verify the report's six axes before repairing, not just its symptom: symptom, reason, proposed
      repair, size, subject, repo. All six stand -- see TEST.
- [~] Consider a machine-local workaround (setting a global identity, or exempting the suite). Dropped:
      the fixture asserts the ABSENCE of a usable identity, and a fixture asserting an absence has to pin
      it. Anything that repairs the machine instead leaves the next machine to rediscover this.

### CREATE

- [x] `scripts/tests/new-branch.tests.ps1`: point `GIT_CONFIG_GLOBAL` at a real config file carrying
      `user.useConfigOnly = true`, written as a SIBLING of the fixture rather than inside it -- the
      fixture repo is the one `new-branch.ps1` reads `git status` on, and an untracked config file in
      its root would put a second subject into every assert. Registered in `$script:fixtures`, so the
      existing teardown removes it.
- [x] Replace the `NUL`-versus-`/dev/null` comment, whose reasoning is sound about reading a missing
      file and simply does not reach this cause, with the measurement that does.
- [x] Correct the block above the fixture, which claimed the suppression covered "all three places git
      reads" and named the last one as the `username@hostname` guess.
- [x] `scripts/lib/git-identity-lib.ps1`: correct `Test-GitCanCommit`'s docstring, which cited
      "exit 128 under `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`" as measured on this same
      machine. Corrected rather than deleted, because the false premise is the trap.
- [x] Mirror the lib to `plugins/dkj-policy/scripts/lib/` via `scripts/sync/build-shared-scripts.ps1`.
- [~] Add a regression test for the fixture itself. Dropped: the fixture's own sanity assert
      (`Assert-Equal 128 $identProbe.Code`) IS that guard, it is why this was found rather than passing
      vacuously, and a second assert on the same probe would only restate it.

### TEST

- [x] Reproduce the reported cause in a throwaway repo: with local config unset, `GIT_CONFIG_NOSYSTEM=1`
      and `GIT_CONFIG_GLOBAL` pointed at nothing, `git config --show-origin --get user.email` exits 1
      while `git var GIT_AUTHOR_IDENT` exits 0 with a real name and address. Config has nothing and git
      still answers. Confirmed for both `NUL` and `/dev/null`. `git 2.55.0.windows.5`.
- [x] Verify the proposed repair before building it: with `user.useConfigOnly = true` in the file
      `GIT_CONFIG_GLOBAL` names, the same probe exits 128 with "no email was given and auto-detection is
      disabled", and `git commit` refuses identically.
- [x] `scripts/tests/new-branch.tests.ps1`: all 265 asserts pass, including the 8 that were red and the
      two `healthy identity` asserts that prove the suppression is scoped and restored.
- [x] `scripts/lint/check-plugin-integrity.ps1`: 0 errors, script-ascii check included.
- [x] Check whether any other fixture rests on the same premise, which the issue asked for. Two other
      sites touch this ground and neither does: `git-identity-gate.tests.ps1` passes the probe's answer
      in as `-CanCommitOverride` rather than constructing the state, deliberately, so it never suppresses
      anything; `publish-to-business.tests.ps1` forces a `GIT_CONFIG_GLOBAL` file to turn commit signing
      ON, which is the opposite direction and asserts no absence.
- [x] Full suite pool via the PR gate.

### DEPLOY: fix/1888-no-identity-fixture

The `no identity` fixture in `new-branch.tests.ps1` now pins the state it asserts, instead of assuming
that an empty config produces it. Emptying every config scope does not stop Git for Windows naming an
author: its last source is the OS account rather than a config file, and what it returns is a real
display name and a real address rather than the `username@hostname` guess git then refuses -- so the
probe exited 0, the fixture's own sanity assert went red, and the seven asserts below it measured a
checkout that could commit perfectly well. `GIT_CONFIG_GLOBAL` now points at a real file carrying
`user.useConfigOnly = true`, which is the switch that disables the fallback. The whole local test gate
failed on this, so every pull request from such a machine needed `-SkipTests` to get out.

`Test-GitCanCommit`'s docstring carried the same false premise, citing a measurement that does not
reproduce on the machine it names; it is corrected rather than deleted, because the trap is worth
keeping written down.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing here changes what any shipped script does. The corrected docstring travels to consumers
in the `dkj-policy` mirror, but it is a comment, and the state it describes is one a consumer's own
developer would only meet while writing a fixture of their own.

**Score:** N/A

#### Pull Request

Pin the no-identity fixture against Git for Windows' identity auto-detection
