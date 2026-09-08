## fix/1574-machine-local-remedy-wording

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

Option 1 from the issue: sharpen the wording in open-pr.ps1's note and the seam comment in repo-config.ps1, plus the plugin mirror. Do not narrow the test.

#### What the issue got right, and the one thing it did not

The symptom, the quoted gate text and the quoted seam comment all still stand -- read against
`scripts/repo-config.ps1` and against the run on PR #1573. The **reason** is ahead of the tree: #1573
is still an OPEN pull request, so "since #1573 this repo's `enabledPlugins` is a declared, tracked
governance fact" describes a state `main` does not carry yet. The finding does not need it. What makes
the remedy wrong is that `.claude/settings.json` is a **shared, tracked** file in any repo that watches
it, so a branch deliberately changing what it declares is legitimate -- and the gate fires on exactly
that branch. So this is written on the observed firing rather than on #1573's fate, and lands correctly
whether that PR merges or is abandoned.

### CREATE

- [x] `scripts/release/open-pr.ps1`: the note's remedy paragraph now names BOTH cases, and scopes the
      `.claude/settings.local.json` move to the clone's own edit instead of prescribing it for the file
- [x] `plugins/dkj-policy/scripts/release/open-pr.ps1`: mirror kept byte-identical -- this note ships
      to every consumer, which is why the wording is the deliverable and not a comment
- [x] `scripts/repo-config.ps1`: the seam comment says the watched file is not itself machine-local,
      names the case each half of the advice belongs to, and records #1573 as the measured firing
- [~] the narrowed test from the issue's second option (fire only when `enabledPlugins` changes without
      a matching repo-slot change) -- dropped: more machinery than the finding is worth, by the issue's
      own reading, and it would put a second thing to keep in step behind an advisory note

### TEST

- [x] `scripts/tests/machine-local-gate.tests.ps1`: five new asserts -- three on the note (states both
      cases, scopes the move, the retired blanket remedy is gone) and two on the seam comment. 42/42
      green. The wording is the whole subject of this branch, so it is now a regression guard rather
      than a convention
- [x] Victor on the diff, Edith on the wording

### DEPLOY: fix/1574-machine-local-remedy-wording

The machine-local path gate stops giving wrong advice on the path it fires on. It warns whenever a
branch's commits touch a tracked file whose edits usually belong to a clone -- `.claude/settings.json`
here -- and its remedy sentence said, flatly, to drop the change from the branch because "machine-local
plugin enablement belongs in `.claude/settings.local.json`". That is right for a machine's own extra
enable, the sweep the gate was built for (#1559, measured on PR #1557), and wrong for the other case
the same file carries: a branch whose subject IS the declared, tracked set every clone inherits. Seen
on PR #1573, a branch that existed to make exactly that change. The note now names both cases and
prescribes the move only for the clone's own edit; the seam comment in `repo-config.ps1` records which
half of the advice belongs where, and the suite asserts both halves. Nothing about when the gate fires
changed and it still only warns -- what changed is that the sentence a reader acts on is true on both
paths. The cost of leaving it was not a broken branch but a decaying reader: a warning that gives the
wrong advice on the path it fires on is one that gets scrolled past, and it is then scrolled past on
the day it is right.

**Score:** 2

#### What makes this deploy extra special

The note is emitted by a shared script that travels in the plugin mirror, so every consumer running
`open-pr` reads this text. A consumer branch that legitimately changes its own shared harness settings
now gets advice it can follow, instead of being told to move the change somewhere gitignored. Small --
three sentences on a rare path -- but until now following that advice was the wrong move, and only a
reader who already distrusted it came out right.

**Score:** 2

#### Pull Request

Sharpen the machine-local gate's remedy so it names both cases

