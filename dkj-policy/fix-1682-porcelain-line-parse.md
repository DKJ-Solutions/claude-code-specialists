## fix/1682-porcelain-line-parse

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

Extract `ConvertFrom-GitPorcelainLine` into a shared lib; `park-lib` keeps its exclusion and count,
`fanout-lib` keeps its map.

#### The repair went one layer up from the one #1682 proposed, deliberately

The issue proposed extracting the **parse**. Two of the three lessons it names are properties of the
**command** — `--untracked-files=all` and `core.quotePath=true` — so extracting only the parse would
have left both flags, and the reasons for them, duplicated in both callers. So the lib owns the read
as well: `Get-GitPorcelainStatus` runs the command, `ConvertFrom-GitPorcelainLine` reads one line, and
`ConvertTo-GitPorcelainPath` settles one path half. The two callers keep exactly what the issue said
they keep.

### CREATE

- [x] Read both sites before touching either: the parse is verbatim across them, and `park-lib`
      discards the rename's old path where `fanout-lib` keeps it. The issue's account holds.
- [x] `scripts/lib/git-porcelain-lib.ps1` — the command with its two flags, the line parse, and all
      four lessons documented once.
- [x] `park-lib.ps1`: the porcelain block becomes a call; its docstring keeps the `core.quotePath`
      paragraph because THIS function still spawns the `git diff` half itself, and its comment keeps
      the half the lib cannot state — why `--untracked-files=all` matters to the *exclusion*
      specifically, which is that the very first park of a branch has the excluded path inside a new
      untracked directory.
- [x] `fanout-lib.ps1`: the porcelain block becomes a call; the map is still built here, and still
      with only the three fields the baseline round trip carries, so
      `Get-WorkingCopySnapshotFormat` does not have to answer for a fourth.
- [x] Registered as a mirror in `shared-scripts-lib.ps1` and listed in the plugin's
      `scripts/README.md` row set — both callers are mirrored, so a consumer whose `park-cycle` Stop
      hook dot-sourced a file the mirror did not carry would fail on every turn.
- [x] File the third handling of the same quirk as
      [#1689](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1689): `Convert-GitQuotedPath`
      in `sync-rules.ps1` already DECODES these escapes correctly. Not folded in here — calling it
      would make a porcelain parse dot-source the Shopify sync rules, and moving it changes what a
      live theme sync compares paths against.

#### The defect the extraction exposed, which is lesson 4

Writing the suite turned up a real defect **both original copies carried**: `-replace '\', '/'` ran
over every path unconditionally, including the ones `core.quotePath` exists to produce. A quoted path
escapes a high byte as `\303\251`, so `"caf\303\251.txt"` came back as `caf/303/251.txt` — a path with
two directories in it that exists nowhere.

It was **latent in both callers**, which is how it survived two implementations: a count still counts
the mangled entry, and a comparison still matches because both readings mangle it identically. What it
would break is the first caller that takes one of these paths and goes looking for the file — and
`park-lib` already compares its paths against an exclusion the caller supplies, so the near miss is
real. Repaired in the lib, which fixes both callers at once; that is the extraction paying for itself
before it ships.

### TEST

- [x] `scripts/tests/git-porcelain-lib.tests.ps1` — 50 asserts, table-driven over the parse (status
      halves, renames, copies, quoting, separators, the lines that carry no path), plus both callers'
      own uses of the result, plus the read's success and failure paths.
- [x] It uses **no fixture repo and no temp directory**: the parse needs none, and the two read cases
      are read-only (this repo, and a directory that is not a repository). That keeps it out of the
      predictable-temp-path class [#1664](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1664)
      is closing on another branch right now, instead of adding a 109th path to it.
- [x] A structural half asserts each caller dot-sources the lib, calls it, and no longer carries its
      own porcelain command or rename split — the assert that would catch the duplication coming back.
- [x] The four suites #1682 named must stay green: `park-branch` (31), `park-commit` (28),
      `new-branch` (255), `fanout-lib` (86). All four pass unchanged.
- [x] The lint gate and every suite, via `open-pr.ps1`.
- [x] Code review (Victor) and copy edit (Edith) on the diff. Victor found no correctness defect --
      behavioural equivalence at both call sites, lesson 4 safe for the exclusion and for the baseline
      round trip, the dot-source chain reachable from all five entry points, and no PS 5.1 pitfall.
      Edith found one: the header and
      [#1689](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1689) both said
      `sync-main` calls `Convert-GitQuotedPath` at five sites; three of the six occurrences are
      comments, so it is three. Corrected in the lib, the mirror and the issue body.

- [x] The test gate caught a regression the review round did not: `park-cycle.tests.ps1`, 10 of 91
      asserts red. Five fixture suites hand-list the libs they copy into a fixture tree, and
      `git-porcelain-lib.ps1` was in none of them, so `park-lib`'s **guarded** dot-source found
      nothing and `Get-GitParkBacking` answered without a backing note. Added to all five
      (`park-cycle` 91, `park-branch` 31, `new-branch` 255, `entry-scaffold` 796, `worktree-lane` 35 --
      all green). Filed the general gap as
      [#1693](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1693).

#### What that regression says about the guard, since this branch wrote the guard

`park-lib` and `fanout-lib` dot-source the new lib **guarded** — `Test-Path` first — and the registry
entry states the reason: a consumer whose mirror predates this entry must not crash on load. That is
right for a consumer and it is exactly what made this failure quiet. In a fixture the file is absent
for a different reason (nobody listed it), and the guard turns "this lib is missing" into "the backing
note is empty", which is a wrong answer rather than a refusal.

The two suites #1682 named that exercise `park-lib` — `park-branch` and `park-commit` — stayed green
throughout, because neither asserts the backing note. Only `park-cycle` does, and #1682 did not name
it. So the four-suite list in the issue was one short, and the gate is what said so.

The four other fixtures were repaired **before** they went red, on the same reasoning: each copies
`park-lib`, so each is one new assert away from the same failure.

#### A dispatched subagent moved this checkout off the branch, mid-review

While the two reviewers ran, something switched the primary checkout from this branch to `main` --
`checkout: moving from fix/1682-porcelain-line-parse to main` in the reflog, asked for by nothing in
the session. **Nothing was lost, by luck rather than by a guard**: the work had been committed four
minutes earlier, so one `git checkout` recovered the whole tree. Twenty minutes sooner it would have
been 892 uncommitted lines across ten files.

It is the hazard [#1669](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1669) is
open about, with a symptom that issue does not yet name -- a bare `git checkout <branch>` discards
nothing and is still the same violation, so a guard written against #1665's `git stash` /
`git checkout HEAD --` pair would have passed it. Recorded as a comment there rather than as a new
issue, because it argues for exactly what #1669 already asks for, and #1669 is assigned to another
session. What found it was a harness system-reminder showing two files reverted to their pre-branch
content; no gate, hook or session check reported anything, and `git status` was clean throughout.

### DEPLOY: fix/1682-porcelain-line-parse

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
