## Development: `docs/orchestrator-skill-is-the-pre-bootstrap-door-v1` · 20260829-193825

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

Inbound [#1107](https://github.com/DaveKJohn/claude-code-specialists/issues/1107), split out of
[#1094](https://github.com/DaveKJohn/claude-code-specialists/issues/1094): a pre-bootstrap consumer
session has none of the orchestrator's filing and verification rules, and the issue asks which of three
channels should carry them. It names option 1 (the `orchestrator` skill page), option 2 (the
`[BOOTSTRAP]` SessionStart line) and option 3 (`ADOPTION.md`, which #1094 already writes).

#### The answer is option 1, and it moves one layer up inside that option

**Option 1 as the issue states it does not reach the session, and that is the finding.** It proposes a
sentence on the skill *page* — the body, which is read only once the skill has been invoked. The whole
job of that page is `Read the persona and adopt it`, so by the time a session reads the added sentence
it has already been handed all three rules verbatim in `01-01-persona.md`. A sentence there is a copy of
something the next paragraph delivers in full.

**What is genuinely always in context, pre-bootstrap included, is the skill's `description`** — and
today that description excludes exactly the case #1107 is about. It offers three situations, and a
consuming repo that has not run the bootstrap is in none of them as written: it *has* a repo, it *has* a
`CLAUDE.md` (one that simply does not carry the `@`-import), and its specialists did not arrive "in an
app". The closing sentence contrasts only against a repo that *has* run `specialists-init`, so the
inverse is implied and never said. So the one channel a pre-bootstrap session already pays for was
telling it this skill is for somebody else.

**That is why the repair is the door and not a hand-picked sentence.** #1094's own fourth comment
frames the question as *"which of Chris's rules does a session need before it has Chris"*, and the
honest answer from three measured failures is *all of them*: the third one — a `disable-model-invocation`
refusal read as settled policy — defeated a session that was already filing well in the first two, so
which rule goes missing next is not predictable from the three that did. A description that admits the
un-adopted repo routes the session to a page that loads the whole body, which no selected sentence can.

#### What was checked before any of that was written

- **The symptom still stands.** No shipped file puts those rules in a pre-bootstrap main loop.
- **The collision #1107 defers on still stands too.** PR
  [#1105](https://github.com/DaveKJohn/claude-code-specialists/pull/1105) is open (CI red) and rewrites
  both candidate homes — the `[BOOTSTRAP]` message in `check-roster-sync.ps1` *and* the
  `Where this is the wrong tool` section of `orchestrator/SKILL.md`. This branch therefore touches
  **neither**: the frontmatter is untouched by that PR, and the new body section is appended after the
  last section it edits. Both hunks merge cleanly in either order.
- **Option 3 is not on the trunk.** #1107 says #1094 "already implements it"; that repair sits on
  `docs/filing-rules-before-the-bootstrap-v1`, parked with no PR. It is real work and it is not in a
  consumer's hands, so this branch does not lean on it and does not touch `ADOPTION.md` either — which
  would have conflicted with the parked branch for no gain.
- **Option 2's cost, honestly stated, because the issue raises it and it is the closer call than it
  looks.** The `[BOOTSTRAP]` line prints only while a repo is un-adopted, so it is targeted at exactly
  the right population and self-extinguishes at the bootstrap — better targeting than the description,
  which every consumer pays for forever. It loses on two other counts: it is the string #1105 is
  rewriting right now, and a hook whose subject is *"you have not been set up yet"* would be carrying
  governance prose it cannot deliver in full anyway. It remains available if the description proves too
  quiet, and #1107 is the place that argument is written down.

#### The cost, measured

The `description` grows 511 → 666 characters, **+155 characters ≈ 39 tokens per session**, paid by every
consumer with `team-alpha` enabled whether or not it is adopted. That is the whole always-on price. The
body grows 4,244 → 6,603 characters (~590 tokens) and is paid only on invocation, by the session that
asked for it.

### CREATE

- [x] `orchestrator/SKILL.md` frontmatter: the `description` names the un-adopted repo as a case this
      skill covers, and says in one clause what is missing before the bootstrap
- [x] `orchestrator/SKILL.md` body: a closing section stating that this page is the pre-bootstrap door
      and is *not* a way around the `specialists-init` handover, with the three measured rule-gaps from
      #1094 in a table
- [~] The `[BOOTSTRAP]` SessionStart line — deliberately not touched, per the collision above; it stays
      the fallback #1107 records rather than a second copy of the same prose
- [~] `plugins/ADOPTION.md` — deliberately not touched: option 3 is #1094's parked branch, and editing
      the same page from here would conflict with it

### TEST

- [x] `check-plugin-integrity.ps1`: 0 findings across all 33 checks, including the dead-link scan over
      the two new issue links, `[frontmatter-bom]` and `[skill-command]` over the changed skill page
- [x] `orchestrator-skill.tests.ps1`: its `disable-model-invocation` assert read the **whole page**, so
      it went red the first time that page *discussed* the flag — a false failure on correct prose, and
      the same bare-mention-versus-declaration distinction the `[lifecycle]` integrity check already
      draws. Narrowed to the frontmatter block, where the key would actually take effect; the intent it
      guards is unchanged and one assert was added for the block itself. **No assert was added pinning
      that the body keeps discussing the flag** — that would pin wording nobody decided on
- [x] The suites, via `open-pr`'s own gate — not pre-run here, which would measure the same thing twice
      and credit nothing
- [~] No new assert, and this is a stated test gap rather than an oversight. What would have to be
      pinned is a `description`'s *wording* — the shape this repo measured and declined once already
      (the stale-path check, 124 findings all false). A regression here is somebody rewriting the
      sentence, which no cheap assert can tell apart from an intended rewrite

### DEPLOY: `docs/orchestrator-skill-is-the-pre-bootstrap-door-v1`

A consumer's session can now find the orchestrator during the adoption itself, instead of one restart
after the moment it needed him.

The `orchestrator` skill has always been the route to Chris where the `@`-import cannot reach — but its
description offered three situations, and a repo mid-adoption was in none of them: it has a repo, it has
a `CLAUDE.md`, and its specialists did not arrive in an app. So the one channel that is always in
context before the bootstrap was telling the one session that needs this skill that it is for somebody
else. The description now names that repo, and says in one clause what is missing until the bootstrap
runs: the rules for filing what you find and for verifying a refusal before you obey it.

The page itself gained a closing section for the same reader. It states that the handover to
`/team-alpha:specialists-init` is still the whole move — the bootstrap writes the owner's `CLAUDE.md`
and is theirs to authorise — and that loading a persona into one conversation is a different act, not a
way around it. The three rule-gaps measured in a single pre-bootstrap run are tabled there with what
each one cost, because the third of them defeated a session that was already filing well: which rule
goes missing next is not predictable, which is why the repair is the door rather than a selected
sentence.

**Score:** 2

#### What makes this deploy extra special

Everything a consumer's session finds while adopting — the moment it is least equipped and has the most
worth reporting — reaches this repo only if that session knows filing needs nobody's permission. It
costs 39 tokens a session to say where that rule lives, and the alternative is measured: two findings
held back for an authorisation nobody was going to ask for, and one refusal read as policy and never
filed at all.

**Score:** 3

#### Pull Request

the orchestrator skill names the un-adopted repo, so a session without Chris can still reach him
