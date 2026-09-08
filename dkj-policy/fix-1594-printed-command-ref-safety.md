## fix/1594-printed-command-ref-safety

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

Resolves [#1594](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1594).

#### What the issue reported, and what the pickup check changed about it

The report stands, and four of the six pickup checks came back clean: the symptom is still present,
the reasoning holds, the subject exists, and the repo is the right one. Two did not, and both changed
the work:

- **The SIZE was under-measured -- seven sites, not three.** The issue names
  `ship-pr.ps1` twice and `sync-main.ps1` once. Four more printed, paste-ready commands carry the same
  unquoted value: `ship-pr.ps1`'s under-a-queue fold line, its two fold-by-hand remedies, and
  `sync-main.ps1`'s `gh pr create` hand-over line. Repairing the reported three would have left both
  files internally inconsistent in exactly the way the issue's own Scope note wanted to avoid.
- **Two of the seven are NOT attacker-reachable, and the issue's framing implies they are.**
  `sync-main.ps1` composes its own branch name from a date stamp and `Get-ShopifySyncBranchPrefix`'s
  answer, so nothing hostile arrives through `git rev-parse` there. That prefix is a string a consumer
  authors, so the sites are not fixed either -- they are the same defect with a different reach, and
  they get the same repair for the reason #1194 measured: two hand-typed copies of one security
  predicate drifted within a day.

The issue's central claim was verified rather than taken on trust, because the whole repair turns on
it: **quoting does not close this.** `$( )` runs inside double quotes in bash *and* in PowerShell, and
`fix/it's-fine` is a legal branch name, so the value can terminate its own single quoting. Confirmed
with `git check-ref-format --branch`.

#### And one measurement the issue left open, because a candidate depended on it

The issue lists restricting the character set at creation as candidate 3, unmeasured. Measured here:
all **994** pull-request head refs in this repo's history match `^[A-Za-z0-9][A-Za-z0-9._/-]*$`, so
that rule refuses nothing anybody has ever wanted. It is adopted -- as the *second* half, not the
first, for the reason the issue itself gives: a branch cloned, fetched or created by hand never meets
it.

### CREATE

- [x] `scripts/lib/ref-print-lib.ps1` -- the new mirrored lib. `Get-PasteableRef` returns one object
      carrying the token to print, the verdict, and the line that names the real branch outside any
      command. One call rather than two functions, so a caller cannot take the placeholder and forget
      the sentence that explains it.
- [x] Registered **twice** in `scripts/lib/shared-scripts-lib.ps1` -- `dkj-policy` for `ship-pr.ps1`
      and `dkj-team-shopify` for `sync-main.ps1`, on the `native-capture-lib-shopify` precedent. The two
      plugins are separately versioned and separately installed, so reaching into the other's cache
      would be a dependency a version mismatch breaks silently.
- [x] All **seven** sites repaired -- five in `ship-pr.ps1`, two in `sync-main.ps1`. The ref is judged
      **once** per script, beside the read or the composition that produced it, so two verdicts cannot
      drift.
- [x] The three here-string remedies share one `$branchPasteNoteBlock`, which carries its own leading
      blank line. A safe name is the overwhelming common case, so those refusals stay byte-identical to
      what #1588 settled and only the refused path grows.
- [x] The creation-side half: the same allowlist in `Test-BranchName`
      (`scripts/lib/branch-info.ps1`), with its docstring's hard-reject list updated to match.
- [x] `plugins/dkj-policy/scripts/README.md` -- the mirror table's row for the new lib, and the
      regenerated `config-blueprint.json`. Both were gate findings, not guesses.

#### What was deliberately left alone

Prose that merely **quotes** the branch name inside a sentence -- `ship-pr.ps1`'s "this checkout is
still on '<name>'" lines. Those are not commands, and git already rejects the control and format
characters that would make prose deceptive; `remote-ahead-lib.ps1` owns that half of the wall. Widening
this branch to cover them would have replaced a measured subject with a tree-wide sweep.

### TEST

- [x] `scripts/tests/ref-print-lib.tests.ps1` -- new suite, **232 pass, 0 fail**. Every hostile name is
      first put through `git check-ref-format` as an explicit premise, and the cases are split on that
      measurement: 17 names git ACCEPTS (these carry the finding) against 7 it rejects (defence in
      depth, asserted because `sync-main` hands the guard a name git has never seen). All seven call
      sites are asserted structurally, plus a scan for any raw interpolation left behind -- which is the
      assert that would catch the eighth site, the failure mode this issue itself demonstrated.
- [x] `scripts/tests/pr-issues.tests.ps1` -- the existing `IndexOf('  git checkout $branch')` assert
      moved to the token. The ORDER it exists to pin (#1588) is unchanged; only the located string moved.
- [x] The lint gate: `check-plugin-integrity.ps1`, **0 errors** over all 40 checks.
- [x] Full suite run, as CI runs it.

#### Two defects the new suite found in itself on its first run, both recorded because they are traps

- `-like` is not a substring test. In a `-like` pattern the backtick is the escape character and `*`,
  `?` and `[` are wildcards, so `"*$bad*"` silently stopped matching for exactly the names the suite
  exists to cover -- it passed every case except the backtick one, and the lib was right all along.
  `.Contains()` throughout.
- `^`, `*`, `~`, `:`, `[`, `\` and `?` are **not** legal in a git ref. The premise assert caught that
  claim before it shipped, which is what a premise assert is for; those names moved into the
  defence-in-depth block instead of being asserted as reachable.

### DEPLOY: fix/1594-printed-command-ref-safety

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
