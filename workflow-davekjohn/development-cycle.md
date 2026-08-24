# Development cycle: `feat/the-pr-starts-with-its-answer-v1` · 20260824-141413

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
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
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

Issue #865 asks two things, and both were verified against the tree before this plan was written.

**One — the PR template's `#` header goes.** `.github/pull_request_template.md` is two lines: an H1
`# What does the change on this branch deploy to main?` and the placeholder comment. Since August 23,
2026 the DEPLOY section it mirrors carries **no** heading over that answer -- the text sits directly
under `## DEPLOY: <branch>` -- so the template is the last place still naming a question the
document stopped asking. That is the inconsistency the issue names, and it is real.

**The header is load-bearing in three places**, which is what makes this more than deleting a line:

1. `open-pr.ps1 -RefreshBody` anchors on it. It reads the FIRST heading of the template and hands it to
   `Update-PrBodySection -Heading`. No heading, no anchor -- and `Update-PrBodySection` returns the body
   untouched when the level parses to 0, so the switch would degrade to its warning branch on every run:
   a silent loss of the whole feature, reported as "the description was left as it is".
2. `Get-PrTemplateReference` ships it as line 1 of the reference a consumer copies, and its docstring
   says so out loud: *"TWO LINES, AND THE SECOND ONE IS THE CONTRACT... a first heading (any level --
   that is the one -RefreshBody replaces the description under)"*.
3. Lint check 24 refuses a `.github/pull_request_template.md` that *carries no heading*, naming exactly
   that degradation as the reason.

So the header cannot simply be deleted -- the mechanism that needed it has to learn the other shape.
The answer is a **leading section**: with no heading, the description occupies the body from the top to
the first heading the FORM carries (`-StopAtHeading`, which `open-pr` already reads from the template
for inbound #598), and to the end of the body where the form carries none. That is what this repo's own
template now is, so a refresh here replaces the whole body -- byte-identical in effect to what the H1
anchor did, since nothing followed it. A consumer whose template keeps its own sections is bounded by
them exactly as before.

**A legacy body needs no new legacy string, and that is measured rather than assumed.** A PR opened
under the old H1 and refreshed after this change takes the leading path, where the boundary is the first
FORM heading -- the old H1 is above it and is replaced with everything else. `open-pr`'s legacy-heading
list is only reached when the template still HAS a heading, in which case that heading is the anchor.
So nothing is added to it (this repo's "no pre-emptive fixes" rule); the reasoning is left in the code
where the next reader of that list will look.

**Two — `What makes this deploy extra special` becomes `What makes this PR extra special`.** One live
referent: `$script:EntryTierHigherHeading` in `scripts/lib/entry-scaffold-lib.ps1`. The rename uses the
mechanism already there -- **recognise every wording, write one** -- so the old string joins
`$script:EntryTierHigherRetiredHeadings` beside `What makes this change extra special` and
`Higher than tier 0?`. Every entry pending in `CHANGELOG.md` and every branch in flight here and in a
consumer keeps folding, which is the direction that matters: a parser that forgot a heading reads its
entries as tier 0 alone and silently empties a release.

**Named, because the issue does not name it and Dave owns the call:** this heading also lands in
`CHANGELOG.md` and in the release documents, where a reader is not looking at a PR. It is the fourth
wording this section has carried, and the August 23 rename went the other way for the mirror-image
reason ("the document says 'deploy' throughout"). The tension is genuine and one word wide; it is
reported rather than resolved here, because the issue asks for this wording explicitly.

## CREATE

- [x] `Get-PrTemplateReference`: drop the heading line, and retext the docstring -- the contract is
      now ONE line, the placeholder, and the reference must say why a heading is no longer part of it
- [x] `.github/pull_request_template.md` and `plugins/workflows/workflow-davekjohn/templates/pull_request_template.md`:
      the placeholder line alone (the second is held byte for byte to the function above)
- [x] `Update-PrBodySection`: an empty `-Heading` addresses the body's LEADING section -- start at the
      top, emit no heading line, and take the boundary from `-StopAtHeading` alone, since a section
      with no heading has no level for the level rule to compare against
- [x] `open-pr.ps1 -RefreshBody`: take the leading path when the template exists and carries no
      heading; keep today's warning for a template that is MISSING, which is a different situation and
      still has nothing to anchor on
- [x] Lint check 24: retire the "carries no heading" error, keep the placeholder rule, and retext the
      coverage note -- the contract it reports is what open-pr actually relies on now
- [x] `entry-scaffold-lib.ps1`: `$script:EntryTierHigherHeading` -> `What makes this PR extra special`,
      with `What makes this deploy extra special` appended to the retired list and the comment block
      above it carrying the date, the reason and how long the old wording was live
- [x] `scripts/sync/build-shared-scripts.ps1`: regenerate the plugin mirror of every changed lib

## TEST

- [x] `scripts/tests/pr-body.tests.ps1`: the two asserts that require a heading in the reference
      template are replaced by their opposite (one recognised placeholder, no heading needed), the
      merged-format fixtures carry the new section wording, and the leading-section behaviour of
      `Update-PrBodySection` is covered -- including that a form heading still bounds it
- [x] `scripts/tests/entry-scaffold.tests.ps1`: the written heading is the new one and EVERY retired
      wording is still read -- the assert read `[0]` of that list, so it was measuring one member of a
      list that grows; it loops now
- [x] `scripts/tests/check-plugin-integrity-docs.tests.ps1`: check 24's scenarios, now that a
      heading-less template is correct rather than an error
- [x] Docs follow the behaviour: `CHANGELOG.md`'s intro, `CONTRIBUTING-portable.md`,
      `DEVELOPMENT-CYCLE-portable.md`, `RELEASES-portable.md` and this repo's own
      `workflow-davekjohn/CONTRIBUTING.md`
- [~] The four skill pages and Rendall's lens `05-06-extension.md`: DROPPED here and filed as
      [#870](https://github.com/DaveKJohn/claude-code-specialists/issues/870). They do not carry a
      stale WORDING, they carry the whole pre-August-23 entry shape -- `` ## `feat/x` deployment ``
      with a `### What does the change...` heading and the audience tier nested at `####`. Repairing
      that is rewriting the format example on five pages, which is a documentation change with its own
      review; renaming one string inside a block whose other two facts are wrong would have made it
      look tended to. Nothing is broken at runtime: every retired wording is still read
- [x] `check-plugin-integrity.ps1` + every suite green, and a copy-edit pass on the diff

## DEPLOY: `feat/the-pr-starts-with-its-answer-v1`

**A PR body now opens with the answer instead of with a question the document stopped asking.** The PR
template's `# What does the change on this branch deploy to main?` is gone, and the audience tier's
heading reads `What makes this PR extra special`. Both come from
[#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865), and both are the same
correction: on August 23 the entry became the DEPLOY section of `workflow-davekjohn/development-cycle.md`
and tier 0's answer lost its heading — the text sits straight under `## DEPLOY:` — so the template was
the last place in the system still asking a question nothing else asked.

**The header was load-bearing, and that is the whole change.** `-RefreshBody` replaced the description
under the template's first heading; a template with none would have degraded to its warning branch on
every run — the switch silently lost, reported as *"the description was left as it is"*, which reads like
a decision. `Update-PrBodySection` therefore learned the **leading section**: an empty `-Heading` starts
at the top of the body, writes no heading line back, and takes its boundary from `-StopAtHeading` alone,
since nothing is shallower than no heading. That is the mirror image of inbound #598, where nothing was
shallower than an H1.

**And `open-pr` stopped reading "the first heading" at all — it reads where the PLACEHOLDER sits.**
Headings above it are the description's, headings below it are the form's boundaries, and a placeholder
that comes first means the leading section. That was always the real rule; it was simply never the one
being read, and under a heading-less template the old shortcut is wrong in the direction that costs
something: in a template of `<placeholder>` + `## Checklist` it would have named the checklist as the
description and overwritten it on every refresh.

**No legacy heading was added anywhere, and that was measured rather than assumed.** A PR opened under
the retired H1 keeps it in its published body, above the first form heading — so the leading section
covers it and it is replaced along with everything else. Lint check 24's contract lost its second half
for the same reason: a heading-less template is now the shape `open-pr` expects, so a gate refusing one
would refuse the template this repo ships.

**The rename uses the mechanism already there — recognise every wording, write one.**
`What makes this deploy extra special` joins the retired list after **one day**, the shortest life any of
the four has had, which changes nothing: a single day is enough for a branch to be in flight, and
`CHANGELOG.md` was still holding entries written under it. Every wording is still read, so nothing
pending stops folding. The suite that guarded this asserted only `[0]` of that list, so it had been
measuring exactly one member while the list grew; it loops now.

**Named because the issue does not name it:** this heading also lands in `CHANGELOG.md` and in the
release documents, where nobody is looking at a PR. Dave asked for this wording explicitly and the
reasoning is recorded beside the constant, so the next person to reopen the question learns it was not
overlooked.

**Score:** 3

### What makes this PR extra special

A consumer's own `.github/pull_request_template.md` is **their** file and nothing here rewrites it, so
nothing breaks on the update and there is no migration. What arrives is a choice: the shipped reference
under `${CLAUDE_PLUGIN_ROOT}/templates/` is now one line, so a consumer who diffs against it can drop
their own header and get a PR body that leads with the answer. Two things arrive whether or not they do —
`new-branch` writes the new audience-tier heading, and their gate stops requiring a template heading. A
template that keeps its heading behaves exactly as before, and one that keeps its own sections is still
bounded by them; what is new is that a heading below the placeholder is now read as the form's rather
than as the description's, which is a repair for anyone whose template had two headings above it.

**Score:** 3

### Pull Request

A PR body starts with its answer, and its second section names the PR
