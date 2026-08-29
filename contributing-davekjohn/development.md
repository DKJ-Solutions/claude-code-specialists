## Development: `fix/lint-barred-skill-imperatives-v1` · 20260829-195407

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

Build the regression guard offered by inbound #1093 and filed as **#1104**: a frontmatter-driven lint
check that a printed message never names a `disable-model-invocation` skill with a bare imperative, and
repair the sites it finds.

#### The report asked for three things to be decided first, and all three were measured

The issue named its own preconditions rather than proposing a rule, so each was answered with a number
before anything was written.

**The contrast case has to pass.** `check-script-contract.ps1` names `adopt-workflow-folder` with a bare
imperative and is *correct* to -- that skill carries no flag, so its page is in context and a session can
invoke it. Confirmed in the tree, and it is why the check reads frontmatter rather than phrasing. A grep
for the wording would have been born with that false finding.

**Scope: output only, or shipped markdown too?** Both, and the measurement decides it: printed output
carries **6** of the 7 real sites and `INSTALL.md` carries the **seventh**. Output-only would have shipped
a check that passes over the one instance a consumer actually reads.

**Measure the candidate before landing it, and count how many findings are correct.** Two candidates were
run over the whole tree:

| Rule | Hits | Unique sites | Correct |
|---|---|---|---|
| imperative + a barred name | 18 | 8 | 4 of 8 |
| ...and the word `skill` after the name | 11 | 7 | **7 of 7** |

The naive rule's four false findings are worth naming, because they are what the discriminator is for:
three name the **script** rather than the skill (`run scripts/maintenance/fix-mojibake.ps1 to repair`,
`then run ship-pr again`, `run park-cycle by hand`) and one is prose offering a choice rather than issuing
an instruction. `park-cycle` is the sharpest of them -- `\bpark\b` matches inside it, because a hyphen is a
non-word character, so the check's boundary is `(?![\w-])` rather than `\b`.

That is the same mention-versus-use separation check 11 makes with its `@`-target, and it is what makes a
generic scan viable here where check 10 had to be opt-in. **The stale-path check was declined at 124
findings all false; this one lands at 11 findings all true.**

#### Two of the seven sites are also repaired by PR #1105, which is open and red

`check-roster-sync.ps1`'s `[BOOTSTRAP]` line and `adopt-config.ps1`'s `[STOP]` line are repaired by
`fix/adoption-handover-and-jsonc-caveat-v1` (#1105), still open and failing `lint-en-tests` on an
unrelated assert (`quotepath: a path with a non-ASCII byte is compared, not read as a new file`).

**This branch repairs them anyway, because a check cannot ship red** -- and it uses #1105's exact wording,
so the overlap resolves to identical text rather than to a decision. The five sites #1105 does not touch
are this branch's alone: both `roster-sessioncheck.ps1` hooks, `check-roster-sync.ps1`'s stale-header line,
`adopt-shopify-floor.ps1`, and `INSTALL.md`.

### CREATE

- [x] **Check 30** in `check-plugin-integrity.ps1`, documented in the numbered inventory. Reads the
      `disable-model-invocation` flag from the frontmatter **block** rather than the file, because
      `new-branch/SKILL.md` quotes that string in its prose to explain the mechanism -- a whole-file match
      reads that page as barred, and a false entry there does not produce one wrong line, it turns every
      correct instruction naming that skill into a finding.
- [x] Printed output is found through the **PowerShell parser**, so a comment explaining the rule -- the
      check's own included -- is not a subject. Markdown is matched per line.
- [x] `Add-BarredSkillFinding` sits beside `Add-Error`, where that function's own comment says a finding
      must go, so the two scan loops cannot drift on what they tell an author to do.
- [x] Not skippable: `-SkipCheck` is the three checks the gate's own suites need, and the comment on
      `$script:SkippableChecks` says a fourth is a deliberate act.
- [x] **Seven sites repaired**, each naming the command and who types it. Plugin mirrors regenerated
      through `build-shared-scripts.ps1`, not hand-edited.

### TEST

- [x] Seven scenarios (42-48) in `check-plugin-integrity-commands.tests.ps1`, the suite that already owns
      "printed things must hold". The fixture's `skill-beta` gains the flag and `skill-alpha` deliberately
      does not, so the same sentence about the two must come out differently -- that pair is what every
      scenario turns on.
- [x] Both directions, and the four the measurement says matter: the barred name fails (42), the
      **unflagged** name passes (43), the script-not-skill wording passes (44), a hyphenated continuation
      is a different name (45), a comment is not output (46), markdown is a subject (47), and the repaired
      wording passes (48) -- so the check and the repair cannot drift apart.
- [x] Two more (49, 50) for the exclusions the gate itself forced -- see below.
- [x] All four gate suites green (55 / 95 / 78 / 108 asserts); the fixture change disturbs none of them.
- [x] The gate itself: 0 findings, where it reported 11 before the repairs.

#### The check refused to let this branch describe it, which is how it got its last two rules

The first shape of check 30 scanned every markdown line. It then refused to push this branch: **the PLAN
section above quotes the forbidden wording in order to explain what the check forbids.** A rule that
cannot be written down in the document introducing it is a rule nobody can explain, and the finding was
correct on its own terms -- the line really does say it.

Both neighbouring checks had already solved it, so the fix is theirs rather than a new idea:

- **Fences are masked** (`Get-FenceMaskedText`, as checks 10 and 11 do). A fenced example is an
  illustration a reader compares against, not an instruction they follow.
- **The markdown set is check 11's `$lifecycleFiles`**, borrowed whole rather than rebuilt, which brings
  its two exclusions with their reasoning intact: history (`CHANGELOG.md`, `releases/**`, `RELEASE.md`)
  records what was true then and is never rewritten, and the branch document is history in the making --
  its DEPLOY text is pasted into `CHANGELOG.md` at the fold, so a finding there would follow it into the
  changelog permanently.

Scenario 50 asserts the history exclusion rather than trusting it, because the set is borrowed: a later
narrowing of check 11's set would otherwise move this check in silence.

#### The gate caught two defects in this branch's own work, and one got past it

Worth recording, because the second is a hole rather than a lesson.

**Caught:** check 27 rejected a literal `U+FEFF` written into the new check's regex -- the script layer is
pure ASCII, so it is written as the escape `\uFEFF` now.

**Not caught, and filed:** `Set-Content -Encoding utf8` writes a **BOM** on Windows PowerShell 5.1, and
check 27 reads its files with `[System.Text.Encoding]::UTF8`, which strips the BOM while decoding. So the
one character check 27's own error message warns about (*"Do NOT add a BOM"*) is the one character it
cannot see. Check 26 reads bytes but only covers frontmatter-bearing shipped documents, so a `.ps1` falls
between the two. Measured the hard way: PR #1108 shipped a BOM into `scripts/tests/internal-note.tests.ps1`
with both gates green.

### DEPLOY: `fix/lint-barred-skill-imperatives-v1`

The lint gate now refuses a printed instruction that tells its reader to run a skill that reader cannot
invoke. A skill whose frontmatter carries `disable-model-invocation: true` has its page removed from the
model's context entirely, so a session told to `run the 'cut-release' skill` is refused by the harness and
cannot even read the page that would explain the route -- while the reader who *can* run it, the person at
the keyboard, is never told the line is theirs to type. Check 30 holds every printed script message and
every shipped markdown line to naming the command and the actor instead.

**Seven sites were named with a bare imperative and are repaired**: both `roster-sessioncheck` hooks,
two lines in `check-roster-sync.ps1`, `adopt-config.ps1`, `adopt-shopify-floor.ps1` and `INSTALL.md`.
Two of those are repaired by PR #1105 as well, in its exact wording, so the overlap resolves to identical
text.

The rule is frontmatter-driven rather than a phrasing convention, which is what lets
`check-script-contract.ps1` go on naming the unflagged `adopt-workflow-folder` with the same bare
imperative. Offered as optional by #1093 and deliberately not built there, under this repo's rule that a
risk which has not bitten gets named rather than repaired -- built now because it bit twice a month apart
(#731 -> #734, then #1093/#1096 rediscovered from scratch when a consumer adoption stopped on it) with
nothing connecting the two.

**Score:** 3

#### What makes this deploy extra special

Every rule this repo adds to a gate has to be measured over the tree first, and this one shows why: the
obvious version of the check -- an imperative verb plus a barred skill name -- is **half wrong**, four of
its eight findings false. The discriminator that fixes it is one word, and the sharpest false finding it
removes is `run park-cycle by hand`, where `\bpark\b` matches inside a longer name because a hyphen is not
a word character. Shipped as measured: 11 findings, 7 sites, none of them false.

**Score:** 2

#### Pull Request

The lint gate refuses a printed instruction that names a skill the model cannot invoke

