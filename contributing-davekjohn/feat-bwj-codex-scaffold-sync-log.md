## feat/bwj-codex-scaffold-sync-log

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

Dave asked for `bwj-codex`'s sync-log folder to be scaffolded at adopt time instead of appearing only
on the first sync branch, with an empty file ready and waiting. This reverses the "nothing scaffolds
it, deliberately" reasoning `SYNC-LOG-portable.md` shipped on September 1, 2026 -- but that reasoning's
own premise (an empty file is ambiguous between "no sync yet" and "adoption never happened") stops
holding once scaffolding becomes an unconditional part of adoption rather than an optional extra.

### CREATE

- [x] Add a step to `adopt-bwj-asana/SKILL.md` that creates `bwj-codex/SYNC-LOG.md` with a masthead
      (no entries), leaving an existing file untouched -- the same non-destructive spirit as step 1's
      "stop and diff" rule, though a masthead-only file needs no diff, just "leave it alone"
- [x] Update `SYNC-LOG-portable.md` ("Where the record lives", "Adopting it in a repo") to state the
      new behaviour and why the reversal is safe rather than a re-introduction of the old ambiguity
- [x] Update `bwj-codex/README.md`'s "Enabling it" section, which claimed chapter two needed no adopt
      step and no skill

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors (link-scan, skill-param and skill-command
      checks all read the touched skill/doc pages)
- [x] Confirmed no other file in the tree repeats the retired "nothing scaffolds it, deliberately" or
      "no adopt step of its own" wording (`grep` over the repo)
- [x] Parallel review -- Victor (code review), Edith (copy edit), Sebastian (security, since a skill
      changed): Sebastian found nothing; Victor and Edith both independently caught the same leftover
      contradictory sentence in `bwj-codex/README.md` (the retired ambiguity argument sitting right
      next to the new behaviour it contradicts) -- fixed; Victor also flagged a tangled conditional in
      step 7 and an overstated "mirrors step 1" claim in this dossier -- both fixed
- [x] Lint + tests green, then PR + merge + fold

### DEPLOY: feat/bwj-codex-scaffold-sync-log

`bwj-codex`'s `adopt-bwj-asana` skill now scaffolds `bwj-codex/SYNC-LOG.md` (masthead only, no
entries) the moment the plugin is adopted, instead of leaving the file to appear on the first `sync/`
branch. `SYNC-LOG-portable.md` and the plugin `README.md` are updated to match, including why the
reversal removes the ambiguity the original design was written to avoid rather than reintroducing it.

**Score:** 2 -- a documented behaviour change in one workflow plugin's adopt step; noticed by anyone
who re-reads `SYNC-LOG-portable.md` or `adopt-bwj-asana`, nothing else in this repo depends on it.

#### What makes this deploy extra special

A BWJ store repo (`smartwatchbanden` or `xoxowildhearts`) that runs `adopt-bwj-asana` after this ships
gets `bwj-codex/SYNC-LOG.md` immediately, ready for the first sync branch, instead of only after it.
Reaches exactly the two repos this plugin targets, and only at (re-)adopt time.

**Score:** 2 -- small and non-breaking; a repo that already has the file (from a prior sync) sees no
change at all, since the new step never overwrites an existing file.

#### Pull Request

bwj-codex scaffolds an empty SYNC-LOG.md at adopt time

