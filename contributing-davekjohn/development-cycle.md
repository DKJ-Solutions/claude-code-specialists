## Development cycle: `docs/inbound-sixth-pattern-mirror-in-the-reporters-tree-v1` · 20260827-135715

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.


### PLAN

#### Where this branch came from

Inbound [#954](https://github.com/DaveKJohn/claude-code-specialists/issues/954) was picked up, verified
against the tree, and closed without a line of repair: the two dead links it reported are real and live,
and they are in the reporter's own checkout. The report was not wrong about the symptom, the 404, or the
horizontal rule -- it was wrong about **whose tree** the file is in, and it reasoned its way there from a
mirror the source had retired thirteen days earlier.

That is a failure mode the triage guidance did not have. Five patterns were written down; this is a sixth,
and it is the only one where the defect survives verification in full and still is not ours to fix. The
constitution's rule that a lesson is secured in the docs rather than in memory is what makes writing it
part of that assignment rather than a follow-up.

#### The layer question, answered before writing

By [the source-is-the-default rule](CLAUDE.md#claude-code-specialistss-safety-implementation): the
**evidence** goes in the `triage-inbound` skill, read only during a triage, and the **rule** goes in the
always-on layer. The rule half is portable -- a report that attributes a defect to the tree you are
standing in can arrive in any repo -- so it belongs in the persona body in the plugin source, not in the
repo lens. The lens keeps only its one-sentence form, whose count this branch necessarily invalidated.

### CREATE

- [x] `triage-inbound/SKILL.md`: the sixth pattern added, with the two commits that emptied the source
      (`94476de6`, `8797f7a5`), the two greps that measure it, and the three line numbers in the
      reporter's copy that date the mirror. Frontmatter description, intro sentence and section heading
      moved from five to six.
- [x] `lenses/01-01-extension.md`: the rule sentence gains the **repo** check and `#954`; "five" becomes
      "six" in both places it is counted.
- [x] `personas/01-01-persona.md` (plugin source, always-on): two paragraphs after the subject check --
      the which-tree check, and the mirror tell that dates a stale copy.
- [x] The always-on cost measured and cut rather than accepted: the first draft added 1,528 B to a body
      every consumer session loads, tightened to **1,143 B** (~285 tokens) with the substance intact.
- [~] No script, test or manifest touched -- dropped because there is nothing to enforce here. A gate that
      could tell a correctly-attributed report from a misattributed one would have to resolve paths in a
      tree it cannot see.

### TEST

- [x] `check-plugin-integrity.ps1` green, including the dead-link scan over the three changed documents
      and the `[script-ascii]` check that this branch's em dashes must not reach a `.ps1`.
- [x] All suites green via `open-pr`'s gate, unchanged in count.
- [x] The claim the sixth pattern rests on re-measured after the edits:
      `grep -rn "plugins/workflows/workflow-davekjohn" .` still returns zero live hits, and
      `grep -c '^---' releases/README.md` still returns 0.

### DEPLOY: `docs/inbound-sixth-pattern-mirror-in-the-reporters-tree-v1`

Triaging an inbound item now checks six things instead of five, and the sixth is **which tree the symptom
is in**. Every earlier check holds the report against the tree you are standing in and quietly assumes
the defect is there too; a reporter measuring from another repo can be right about the symptom, the
reason, the line number and the 404, and wrong about whose file it is. The rule half lands in Chris's
always-on body -- resolve the path in your own tree before accepting the attribution, and where it
resolves to nothing the finding has neither collapsed nor been repaired -- and the measurement lands in
the `triage-inbound` skill.

The instance is [#954](https://github.com/DaveKJohn/claude-code-specialists/issues/954), closed
August 27, 2026. It reported two dead `plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md`
blob URLs above the horizontal rule in `releases/README.md`, verified 404 against the new path's 200.
Every fact was true, and none of it was here: the tree returns **zero** live hits for that path, and that
page has no horizontal rule at all. `94476de6` (August 13, inbound #646) moved the mirrored process half
out of the file and into `RELEASES-portable.md`, taking both URLs with it; `8797f7a5` (August 26, #886)
corrected the path in its new home. The links are in the reporter's
`contributing-davekjohn/releases/README.md` -- a different path than the report names, whose own
`releases/README.md` returns 404 -- at lines 196 and 289, above the rule at 336.

**What made it invisible is the report's own justification**, which is the half worth distrusting: *"the
content above the rule is a verbatim mirror of the source's page, so a local fix would just restart
drift."* Sound reasoning from an identity the two trees had stopped sharing thirteen days earlier, ended
by the very change that ended the mirroring. Being identical is a mirror's whole design, so its content
can never tell you which side you are reading -- date it instead. Line 482 of their copy still describes
`RELEASES-portable.md` as a proposal, which pins the mirror to before #646 landed. And a mirror retired
upstream makes the proposed fix the wrong fix: repointing two URLs preserves a ~4,000-word hand-maintained
copy of a process half that no longer exists, which is the exact cost #646 was filed to end.

For somebody maintaining this repo the gain is one grep at intake and a closure that tells a reporter
something they could not have worked out themselves. It is a 2 rather than higher because the check was
already run in the triage that produced it -- what lands is the written form, and it is noticed on the next
inbound rather than today.

**Score:** 2

#### What makes this deploy extra special

Chris's body is loaded in every session of every repo that enables `team-alpha`, so this arrives on a
plugin update whether or not anyone asked for it -- which is the reason its size was measured rather than
estimated. The first draft cost **1,528 B**; what ships is **1,143 B**, about 285 tokens per session, and
the trim took out the generic restatement rather than the tell.

The check reaches a consumer in the direction they actually meet it. They do not receive inbound from
consumers of their own, but they do receive reports -- from a session, a teammate, their own earlier
notes -- about content they mirror from here, and the whole family of `*-portable.md` pages plus the
above-the-rule half of the workflow folder's pages is mirrored content by design. #954 is what that looks
like from the other side: a careful reporter, correct measurements, and an attribution built on a sharing
relationship that had already been dissolved upstream. The paragraph that helps them most is the one
saying a stale mirror can be dated from inside itself.

**Score:** 2

#### Pull Request

the triage skill carries a sixth inbound pattern: the symptom is real and it is in the reporter's tree
