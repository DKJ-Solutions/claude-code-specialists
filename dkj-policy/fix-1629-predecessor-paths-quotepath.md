## fix/1629-predecessor-paths-quotepath

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

#### The report's symptom stands; two of its claims did not, and one of those decided the repair

[#1629](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1629) reports that
`Write-SyncPredecessorVerdict` prints another branch's file paths raw, two lines under a row #1623
stripped, and that the `git diff` producing those paths sets no `core.quotePath`. Both halves of the
symptom stand. Two things in the reasoning did not:

**Its quoted code did not exist when this was verified.** The report shows
`$branchRow = Get-DisplayRef -Ref ([string]$r.Branch)   # stripped` and argues from the inconsistency
between that row and the raw paths beneath it. #1623 was still **open** at that moment and
`Get-DisplayRef` was nowhere in the tree -- the row above the paths was raw too, so there was no
inconsistency to point at. #1623 landed mid-branch as #1631, which made the report's premise true. It
is recorded here because the report was written against a tree that did not yet exist, and the same
reasoning would have been wrong had #1623 gone another way.

**Its stated hazard does not reach the terminal, and measuring that changed the repair.** The report
says git allows a control character in a path, so these are "externally-authored strings printed
straight to a console". Measured, git 2.55.0.windows.5, on a tree built with `git mktree` so the paths
need not be createable on NTFS:

```text
A) default (quotePath on)      "assets/ev\033[2Kil.js"     "assets/caf\303\251.js"
B) -c core.quotepath=false      "assets/ev\033[2Kil.js"     assets/cafM-CM-).js
D) core.quotepath=false in config  "assets/ev\033[2Kil.js"  assets/cafM-CM-).js
```

`diff --name-only` **C-quotes `\p{Cc}` in every setting** -- the ESC survives as four ASCII characters
whatever the config says -- so git was closing the control half by accident. `\p{Cf}` is quoted only
with the flag on: U+202E came back as `"assets/sj.\342\200\256gpj.js"` with it and as raw bytes without
it, so half the deceptive class was already reaching the loop in a consumer who had turned it off.

#### So the `core.quotePath` question is the real defect, and it is a wrong ANSWER rather than a display one

The report asks whether the missing flag is "a second defect in the same statement" and says it needs
measuring. It is the first one. These paths are not display-only: `Get-SyncPredecessorReport` compares
them against this run's take set, whose paths come off the mirror walk and `Convert-GitQuotedPath` as
real .NET strings. So an accented path the predecessor captured arrived quoted, matched nothing, and the
branch reported as **independent** when this run covers it exactly -- the `.claude/rules/language-layers.md`
class from inbound #821, at the one read that never got the pair.

That direction is the expensive one: `all of them in this run` tells the operator to close the redundant
PR, `NOT in this run` tells them both branches are needed. The defect kept a superseded sync PR alive
while naming a path that **is** in the run.

**And fixing it is what makes the strip load-bearing.** `Convert-GitQuotedPath` unpacks `\033` back into
a live ESC byte -- correct for comparing, a repaint surface when printed. So the repair is two lines, as
the report suspected, and they are not independent: the second exists because of the first.

- [x] Verify both halves of the symptom against the tree
- [x] Measure git's own quoting of `\p{Cc}` and `\p{Cf}` in `diff --name-only` under three configs
- [x] Trace the take set's provenance, to establish the comparison is decoded-vs-raw and not display-only
- [x] Confirm `Invoke-SyncGitQuiet` passes `-c` correctly -- native-command binding flattens the array, as line 960's existing call already relies on

### CREATE

- [x] `-c core.quotePath=true` on the predecessor `git diff`, plus `Convert-GitQuotedPath` -- the pair #821 prescribes and the neighbouring `ls-tree`/`check-ignore` reads already use
- [x] `Get-DisplayPath` on the printed paths, since the unpacker now hands the printer live escape bytes
- [x] `Get-DisplayPath` and NOT `Get-DisplayRef`, which is the decision #1629 left open: it asked whether stripping was even right for a path, given that a stripped path no longer names a file. #1637/#1638 landed mid-branch and answered it in the tree -- a path-shaped strip that neither collapses runs nor trims, because git, NTFS and Shopify asset names all accept a space
- [x] So the fidelity cost this branch was going to have to accept does not arise: these rows survive being read off the screen and typed back
- [x] Mirror into `plugins/dkj-teams/dkj-team-shopify/scripts/task/sync-main.ps1` -- held byte-identical

### TEST

- [x] `sync-main.tests.ps1`: an end-to-end case where the predecessor captured an **accented** path this run takes -- asserts the superseded verdict, the absence of `NOT in this run`, and that no `\303\251` octal escape is printed anywhere
- [x] Its own accented name rather than the existing pin's, so the case does not depend on that block's order
- [x] `ref-print-lib.tests.ps1`: the paths asserted to go through `Get-DisplayPath` BY NAME, the raw interpolation asserted absent, and `Get-DisplayRef` asserted absent at that site -- the ref-shaped strip there would be a quiet regression rather than a visible one
- [x] Verified it by reverting: with the fix stashed, all FOUR guard/quotepath asserts fail (`FAILED: 4 of 135`); restored, all four pass. The defect is reproducible end to end, not read off the code
- [x] Full local suites for both files, and the lint gate

### DEPLOY: fix/1629-predecessor-paths-quotepath

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
