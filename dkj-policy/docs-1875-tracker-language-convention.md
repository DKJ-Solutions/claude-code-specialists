## docs/1875-tracker-language-convention

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

Issue #1875: a GitHub issue Claude files in a consuming repo must be written in English, like every
other artefact this workflow produces. Dave's one carve-out is an Asana ticket a person wrote
themselves, because nobody controls how a colleague phrases their own request.

**The gap is real and the rule was never stated anywhere a filing session reads.** The language
convention lives in the technical writer's portable manual, and every layer it names is a *file in the
tree* -- a manual, a persona body, the script layer, a script-generated document. A session filing a
finding is writing somewhere else entirely, so it can follow that rule to the letter and still leave a
Dutch tracker behind. `dkj-policy`'s step 1 states the whole filing bar without naming a language, and
`dkj-policy-bwj` names the two audiences -- the GitHub issue and the Asana card -- without saying which
language either takes.

**Symptom verified before anything was written.** Of the fifteen most recent issues in
`bwj-development/smartwatchbanden`, three carry Dutch titles: `559`, `554` and `547`. The issue's own
title says "still in English" where the tree says Dutch; the body is unambiguous about which way round
it is, so the title is read as the slip.

#### Where it lands, and why four places rather than one

- the **portable manual** is the canonical home of the convention -- `CLAUDE.md` names it as such -- so
  the scope correction belongs there and travels to every consumer through a release;
- **`dkj-policy`'s step 1** is where a session filing an issue actually reads, and that plugin does not
  depend on `dkj-subagents-alpha`, so a consumer can run this cycle with the manual nowhere in context;
- **`dkj-policy-bwj`** is where the two audiences sit side by side, and therefore the only place the
  carve-out can be stated as the boundary it is rather than as an aside;
- **`report-issue`** is the procedure a BWJ session executes, one line per step, pointing at both.

#### What is deliberately NOT done here

- **No backfill.** The three Dutch issues are not retitled. An issue records what was reported and
  when; rewriting the backlog buys a tidy list and loses that, and the rule is about what is filed from
  here on. Written into the BWJ page so the next reader does not take it as an oversight.
- **No gate.** Nothing checks the language of an issue title, and nothing here proposes one -- a
  language check is a guess about prose, and this repo has declined checks on weaker grounds.
- **Not in `CLAUDE.md`.** Its language section already delegates to the manual for the system-wide
  norm, so the correction arrives there without an always-on edit.

### CREATE

- [x] Verify the symptom in the consuming tracker, and the gap in all three portable layers
- [x] Portable manual: the tracker is in scope, and a person's own words are not a fourth exception
- [x] `dkj-policy` step 1: one answer per repo, English in this family, with the row in the answers table
- [x] `dkj-policy-bwj` step 1: English, title as much as body, and no backfill
- [x] `dkj-policy-bwj` step 2: the one place the language turns over, and the Asana carve-out
- [x] `report-issue`: one line in step 1 and one in step 2, pointing at the rule rather than restating it

### TEST

- [x] `check-plugin-integrity.ps1` -- frontmatter, manifests and every new anchor (four added links)
- [x] The full suite set, exactly as CI runs it
- [x] Both BWJ pages verified still pure ASCII, which is their convention

### DEPLOY: docs/1875-tracker-language-convention

A GitHub issue a session files is now stated to be English -- title as much as body -- in the four
portable places a filing session reads: the technical writer's manual, which is the canonical home of
the language convention and until now named only files in the tree; `dkj-policy`'s step 1, which states
the filing bar for every consumer whether or not the specialists plugin is installed; and
`dkj-policy-bwj`'s workflow page plus its `report-issue` steps, where the GitHub issue and the Asana
card sit side by side. The carve-out is a person's own words: a ticket a colleague wrote, and the
message going back to them, stay in their language and are quoted rather than translated -- so one
finding legitimately reads English on GitHub and the colleague's language on the board, which is the
translation step 2 is named for rather than drift. The session-reply language is untouched.

**Score:** 3

#### What makes this deploy extra special

N/A -- a writing convention for the two plugins' own tracker artefacts. No subscriber of any service
reaches it; the readers are the sessions filing issues in the consuming repos and the colleagues who
later search that tracker.

Worth recording for the next reader: the rule that failed here was not being broken. It was written for
a scope -- files in the tree -- that a tracker is not in, so every session following it exactly still
produced the state Dave reported. A convention stated by enumerating layers goes stale the moment the
system writes somewhere the enumeration never named.

**Score:** N/A

#### Pull Request

State the tracker language convention: an issue a session files is English
