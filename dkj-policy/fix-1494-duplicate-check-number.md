## fix/1494-duplicate-check-number

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

#### The decision the issue deliberately parked

[#1494](https://github.com/DaveKJohn/claude-code-specialists/issues/1494) listed three options and
declined to pick, because the archived release notes are history and are not rewritten -- so whichever
check gives up the number leaves a published sentence pointing at the wrong one. Dave chose the
specialist's recommendation (September 6, 2026): renumber, and add the machine check, so the class ends
rather than just this instance.

**Renumbering over disambiguating in prose.** Writing ``check 30 (`[barred-skill]`)`` everywhere was the
cheaper option and the one the report leaned to. It answers the grep and leaves two sections numbered 30,
so the next hand-assigned number can collide again and the disambiguation has to be remembered at every
new citation.

**And ascending order rather than uniqueness alone**, because uniqueness is what broke but ascending is
what prevents it: a uniqueness check still permits inserting a section anywhere and hand-picking its
number, which is the act that produced the duplicate.

#### Two corrections to the report, both found on verification

- It says check 31's header form is the odd one out. It is not -- **four** headers read
  `# --- Check <n>: ` (12, 18, 20 and 31) where the other twenty-nine read `# --- <n>. `. Size
  mis-measured, so the "adjacent, same cause" half is four instances rather than one.
- Unremarked in the report: 9, 17 and 19 are unused gaps. Two carry a retirement note where the check
  stood, which is what makes them legal rather than a defect -- so the new check had to permit gaps.

### CREATE

- [x] Renumber the `[barred-skill]` check from 30 to 33 in `../scripts/lint/check-plugin-integrity.ps1`,
      and move its block below check 32 so the numbers ascend again
- [x] Sweep every LIVE reference to the barred-skill "check 30" -- the gate's own four internal
      cross-references, the `roster-sessioncheck` hook, `check-roster-sync.ps1` and its plugin mirror,
      `roster-sync.tests.ps1`, and the nine scenario names plus the fixture in the commands suite
- [x] Leave the `[plugin-link]` check at 30, and leave the archived notes under `releases/changelog/`
      untouched -- history is not rewritten
- [x] Normalise the four `# --- Check <n>: ` headers (12, 18, 20, 31) to the `# --- <n>. ` form
- [x] Add check 34 (`[section-number]`): every column-0 numbered section header is unique, strictly
      ascending, and in one form -- repo-wide, since 19 scripts share the convention
- [x] Record the shape and the declined options in
      `../.claude/specialists/lenses/05-15-extension.md`, beside check 32's entry

### TEST

- [x] Five scenarios (53-57) in `../scripts/tests/check-plugin-integrity-commands.tests.ps1`: the
      duplicate, the descent, the second spelling, the legal gap + lettered sub-sections, and the
      indented header that is not a subject -- 69 asserts green
- [x] Born green: 19 files, 123 numbered headers before this check's own, 0 findings, 0 exemptions
- [x] Demonstrably firing: run against the pre-repair file the same reader reports 5 -- the one
      duplicate and the four headers in the other spelling
- [x] Full lint gate green (0 errors) and every suite green, as CI runs them
- [x] Cost measured: +~110 ms on a full gate run (10.03 s vs 9.91 s, three reps each, 205-file set) --
      1.2%. Two savings measured and DECLINED, with the reasons recorded in the lens: making the check
      skippable (worth ~3.6 s off the slowest CI lane, but widens `$SkippableChecks` past the three the
      gate holds it at) and sharing check 27's read (does not clear a tenth of #1358's own bar)

### DEPLOY: fix/1494-duplicate-check-number

Two unrelated checks in `../scripts/lint/check-plugin-integrity.ps1` both carried the number **30** --
`[plugin-link]` and `[barred-skill]` -- and both numbers were already load-bearing in published release
notes pointing at *different* checks, so a reader who grepped for the number a finding came from got two
answers. The barred-skill check is now **33** and sits below 32; every live reference moved with it, and
the archived notes stay as they are, because history is not rewritten.

The number itself is no longer prose. **Check 34 (`[section-number]`)** holds every column-0
`# --- <n>. ` section header in the repo's scripts to three rules: unique, strictly ascending, and in one
spelling. Ascending is the load-bearing one -- it leaves a new check exactly one legal number, the one
after the last header in the file, so the number stops being a choice and a second collision cannot be
hand-assigned. Gaps stay legal, since a retired check's number must not be reused. Born green over 19
files and 123 headers; run against the pre-repair file it reports the five findings it was written for.

**Score:** 3

#### What makes this deploy extra special

N/A. Nothing here reaches a subscriber: the lint gate is this repo's own maintenance tooling and ships in
no plugin. The two published release notes that cite "check 30" are deliberately left standing.

**Score:** N/A

#### Pull Request

Renumber the duplicated lint check 30 and guard the numbering by machine
