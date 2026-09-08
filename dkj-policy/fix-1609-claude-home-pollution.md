## fix/1609-claude-home-pollution

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

A throwaway diagnostic script wrote fixture data into the real `~/.claude` while #1591 was being
worked: it never redirected `$env:USERPROFILE`, so it overwrote
`~/.claude/plugins/installed_plugins.json` with two fixture records and left a fixture marketplace
clone behind. Every real per-checkout install record was lost -- this checkout and both registered
consumers -- with no backup and no error.

#### What #1609 asked for, and why the shape changed

The report proposed a helper that refuses to write under `~/.claude` unless the resolved home is a
scratch path, and named the systemic half rather than the instance as the thing worth fixing. Verified
against the tree before anything was built, and the proposed mechanism does not fit:

- **Nothing in the committed tree writes under `~/.claude`** -- every reference in `scripts/` is a
  reader. The helper would ship with no in-tree caller, enforced only by a one-off script's author
  remembering it: the same unenforced instruction #1609 criticises the docstring for being. The lint
  gate cannot hold anyone to it either, there being no committed writes to check.
- **A command-string guard cannot see it.** The `guard-live-theme` `PreToolUse` shape reads the command
  about to run; here that was `powershell -File <temp>/dbg.ps1`, and the write lived inside the file.

So the harness is the only thing that reaches a throwaway script, and it reaches it twice: detect, and
recover. Dave chose detect-and-recover on those two measurements, September 8, 2026. The declined guard
is recorded with them in Sylvester's lens rather than left as folklore.

#### The instance was already repaired before pickup

The install records are back (18 records; `dkj-policy` and `dkj-team-alpha` at 4.32.0) and
`marketplaces/ccs-fixture/` is gone. Verified at pickup, so this branch builds only the systemic half.

### CREATE

- [x] `Get-InstallRecord` gains an `AllRecords` field -- every record in the file, whatever path it
      names. The three existing fields are all filtered, so a fixture record is dropped twice over:
      once for the path mismatch, again because a deleted fixture root no longer resolves (#301). A
      field rather than a second reader, per that lib's own one-reader rule.
- [x] `scripts/lint/check-claude-home.ps1` -- the check. One signature: a record whose `projectPath`
      sits under a scratch tree. Reports the polluted records, and whether the marketplace they name
      also has a clone sitting in the real tree.
- [x] The snapshot: on a healthy read only, after the verdict, and only on a difference -- so a
      polluted file can never become the snapshot, and restoring it puts the previous records *back*
      where re-installing writes new ones.
- [x] `plugins/dkj-policy/hooks/claude-home-sessioncheck.ps1` + its `hooks.json` entry -- soft, exit 0
      always, `[OK]`/`[SKIP]` silent at session start.
- [x] Registered in `shared-scripts-lib.ps1` (no skill, no `MeasureArgs` -- the no-argument form reads
      the real administration) and mirrored via `build-shared-scripts.ps1`.
- [x] Root resolved dual-context through the shared `Resolve-CheckRoot`, even though this check reads
      only the unfiltered field and never uses the repo-scoped answer. The `shared-scripts` suite
      caught the shortcut, and it was right to: a script exempted because "this one does not need a
      root" is how that invariant erodes.

#### What the review round changed

Four reviewers ran on the diff in parallel. Three findings were real and are repaired here:

- **Every value printed out of the JSON was raw** (#309/#414's vector). The hook forwards the whole
  output into session context and counts `[ERROR]` over it, so a record id carrying a bracket could be
  *counted* and one carrying a newline could forge a line -- in the one check whose premise is that the
  file may hold whatever a stray script wrote. `Id` now goes through `Format-SuspectToken`,
  `ProjectPath` and the clone directory through `Format-SafePathToken`, and `$record.Error` through
  `Format-SafeProseToken`. That last one was missed by the reviewer who found the class and is the
  widest of the three: `ConvertFrom-Json`'s message **embeds the offending document**, so on an
  unparseable administration it carried the file's whole raw text.
- **`Test-PluginMarketplaceSlug` was missing** before the id's marketplace part became a path segment
  -- the lib's own stated rule, already honoured at this seam by `check-roster-sync` and
  `check-policy-drift`. A part spelled `..` would have had `Test-Path` probe, and on a hit report as a
  leftover clone, a directory nowhere near `marketplaces/`.
- **Two always-on documents still called the hooks read-only** -- `README.md` and
  `.claude/specialists/SPECIALISTS.md`, the second loaded into every session. My change falsified both;
  both now state the one exception.

And one finding was wrong in a way worth keeping: the docstring said *"its four siblings all state that
they change nothing"*, two reviewers returned two different numbers, and **both were wrong** -- eight
hook files across three plugins carry that line. Counting was the defect; the siblings are now named,
which is the answer the plugin README's own hooks cell already reached after its count went stale twice
in two days.

Deliberately **not** done here, with the reason:

- **The double process spawn** every hook in the family pays (~125 ms x 7 per session start) is filed as
  [#1625](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1625). It predates this branch
  by six hooks; this one added the seventh instance of an established pattern, and the repair needs each
  check's `exit` calls refactored into a lib -- a cross-cutting change to every consumer's session start,
  which does not belong behind a review about `~/.claude`.
- **The `suite-durations.json` row** for the new suite waits for this branch's first CI run.
  `record-suite-durations.ps1` takes CI run ids on purpose: a workstation figure read as a CI one is the
  exact defect it exists to prevent (#1358). A missing row is charged the maximum and self-corrects on
  the next refresh, so this costs packing accuracy for one run and nothing else.
- **The snapshot re-reads a file `Get-InstallRecord` already read.** Declared in the code rather than
  repaired: the alternative is an `-IncludeRaw` switch on a lib five other scripts call, which is more
  shared API surface than a few-KB re-read costs.

### TEST

- [x] `scripts/tests/claude-home-gate.tests.ps1` -- 36 asserts. Every case passes `-HomeOverride` into
      a fixture tree and `-NoSnapshot` unless the case is about the snapshot: a suite for this check
      that used the real home would be the defect under test, committed.
- [x] Covered: the finding and its record naming, the leftover clone in both directions, the
      prefix boundary (a sibling whose name merely begins the same way), clean / no-records / fresh /
      unreadable, the snapshot written once and not rewritten, **the snapshot untouched on a finding**,
      a missing administration with a snapshot beside it, the hook's four branches, and mirror parity.
- [x] Added after review, each closing a branch a regression could have walked back through: the
      **plural verb** (the singular case cannot tell a correct agreement from a hard-coded `names`),
      a **forged `[ERROR]` in a record id** and **in the parse message** -- both asserted on the marker
      COUNT in the output rather than on the sanitizer call, so a refactor that moves the call still
      has to keep the property -- the **`..` marketplace part** refused by the slug guard, and the
      unreadable-with-a-snapshot line that was otherwise unreachable.
- [x] Lint gate green (it caught a missing `shared-scripts:mirror` row, now added). The eleven suites
      the change could touch all pass, including `check-report-lib` (206), `roster-sync` (349) and
      `shared-scripts` (600).
- [~] The machine's own scratch resolution (`$env:TEMP`, a literal `\temp\` segment) is **not**
      asserted -- a named test gap, not an omission: a suite asserting on it would be asserting about
      the machine it runs on. The boundary logic those roots feed is pinned instead.
- [x] Run against this machine: `[OK] ... 18 records, none naming a scratch tree`, and the first
      snapshot now exists -- the recovery baseline the incident did not have.

### DEPLOY: fix/1609-claude-home-pollution

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
