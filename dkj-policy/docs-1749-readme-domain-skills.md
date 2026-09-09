## docs/1749-readme-domain-skills

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

Repairs [#1749](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1749): the root
`README.md` sentence naming which add-on teams may carry domain skills enumerated two of three teams
and pointed at one that ships none.

Verified before repairing, rather than taken from the report: `plugins/dkj-subagents/*/skills/` holds
nothing under `dkj-subagents-ecomm` and `dkj-subagents-lifehub`, and four skills under `dkj-subagents-shopify`
(`adopt-shopify-floor`, `push-preview`, `start-task`, `sync-main`). The symptom, the reason and the
proposed repair all still stand.


#### The rename that landed mid-branch

`feat/1698-rename-to-dkj-subagents` (#1747) merged to `main` while this branch was open, taking
`plugins/dkj-teams/` → `plugins/dkj-subagents/` and every `dkj-team-*` id to `dkj-subagents-*`. All
three defects survived it verbatim under the new names, so the repair is unchanged in substance:
`main` was merged in, its names taken on every conflicting line, and the three edits re-applied on
top. The one wording change the rename forced is in the new paragraph's historical clause — it now
says *"the lifehub and Shopify teams"* rather than quoting ids that were renamed the same day, which
would have read as a claim about the current ones.

#### The call the issue left open

It offered two honest versions — keep the possibility and fix the enumeration to three, or name the
one team that does. Named the one: the second defect *is* a stale enumeration, so re-enumerating
invites the same failure a third time. A statement about the single team that ships skills goes stale
only when a second one starts to.

#### And it moved, because in place it broke the sentence after it

The sentence sat welded to the end of the `cycle-autopark` paragraph with no blank line, between that
paragraph and **"Those last two moved out of the core"** — whose referent is the two *hooks* named
further up. Read in order, "those last two" landed on the two add-on teams the intruding sentence had
just named. Repairing the sentence in place would have shipped a correct sentence that still misleads
the reader of the next one, so the new paragraph closes the thread instead, after the hooks are done
with.

#### Two more statements of the same fact, both stale, both in scope

Not swept in from elsewhere — the same claim, in the file being edited and in the plugin-source README
one level down, and leaving either would have made the repaired sentence contradict its own neighbours:

- `README.md`'s plugin table said `dkj-subagents-shopify` carries "the domain skill `start-task`" — one,
  where it ships four.
- `plugins/dkj-subagents/README.md` said it "ships one domain skill".

#### Deliberately not touched

- `README.md`'s line about which teams describe *what kind* of repo it is. It names the same two teams
  and is correct — `dkj-subagents-ecomm` is orthogonal, which its own next clause states. #1749 says so too.
- The 43 `DaveKJohn/claude-code-specialists` citations in `README.md`. `CLAUDE.md` says these are
  corrected when a file is edited for other reasons and **not swept**; 43 rewrites under a one-sentence
  prio-1 repair is the sweep that rule refuses, and it would bury the diff a reviewer has to read.

### CREATE

- [x] Rewrite the sentence and move it below the hooks thread (`README.md`)
- [x] Correct the plugin table's skill count (`README.md`)
- [x] Correct the same count in `plugins/dkj-subagents/README.md`
- [x] Merge `main` after the #1698 rename landed and re-apply all three edits under the new names

### TEST

- [~] Lint gate + all suites -- dropped as a step: `open-pr.ps1` runs both itself at the push, so a box here can only be ticked for work the gate has not done yet
- [x] Copy edit on the diff (Edith) -- referent tightened, the duplicated "only team" claim kept to one place

### DEPLOY: docs/1749-readme-domain-skills

The root `README.md` no longer points a reader at the wrong plugin when they go looking for a domain
skill. The sentence about which add-on teams may carry one named two of the three teams — from before
`dkj-subagents-ecomm` existed — and attributed skills to `dkj-subagents-lifehub`, which ships none. It now names
`dkj-subagents-shopify`, the only add-on team that ships any, and sits below the session-hook thread instead
of wedged inside it, where it had been stealing the referent of the sentence after it. The same stale
count is corrected in the plugin table and in `plugins/dkj-subagents/README.md`.

**Score:** 2

#### What makes this deploy extra special

N/A — a documentation correction in this repo's own README. No consumer behaviour, no plugin payload
and no script changes; a reader of the marketplace README gets a correct pointer, which is not a
release note for a subscriber.

**Score:** N/A

#### Pull Request

Name the add-on team that actually ships domain skills
