# Development cycle: `feat/the-cycle-document-has-a-shape-gate-v1` · 20260826-102323

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
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

## PLAN

**Issues [#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898) and
[#899](https://github.com/DaveKJohn/claude-code-specialists/issues/899): two structural rules for
`development-cycle.md` that no gate reads.** Filed separately and built together, because they share the
gate, the suite and the one sentence in the portable page that has to change -- two branches would collide
on all three, with each other rather than with anyone else.

Both were caught by Dave, by eye, on the same afternoon, on the same document:

- **#898** -- a fifth `##` heading (`## Where this stands (August 25, 2026, late)`) above `## PLAN`.
- **#899** -- branch-specific prose in the region between the H1 and `## PLAN`, which is generic guidance
  in every branch document in every repo. **Two sessions in a row** used that region for branch state, so
  it is a shape the document invites rather than a slip.

Each issue ends by naming the decision as Dave's rather than picking one. Both were put to him on
August 26, 2026 and both answers are the option the analysis recommended:

| | decision |
| --- | --- |
| #898 | **Error, scoped to the source repo.** Heading-blindness is deliberate so a consumer may keep headings of their own -- so source-scoping is the correct reach here, not a compromise |
| #899 | **Detect the SHAPE, everywhere.** Any non-blank line in that region not starting with `>` is branch content. Translation-proof, so it needs no scoping, and it catches both measured instances |

### Verified before scoping, and one thing both issues get wrong

| check | verdict on `main` at `c0421aa` |
| --- | --- |
| subject | stands -- `scripts/lint/check-branch-entry.ps1`, `Split-DevelopmentCycle` and `StepsGuidance` are all where the reports say |
| symptom | stands -- #898 was tested rather than assumed by its reporter (byte-identical output at four and five headings), and #899's region is read by nothing |
| reasoning | stands, including the part that argues AGAINST a naive check: heading-blindness is a stated feature of the gate, not an oversight |
| proposed repair | **both name `Test-SourceRepo`, which exists nowhere in the tree.** The mechanism is real and is called `Test-IsWorkflowSourceRepo` (`scripts/lib/seam-lib.ps1`) -- a repo with `.claude-plugin/marketplace.json` is the source. Observation right, lever wrong: keep the first, replace the second |
| size | two rules, two measured instances, one document -- and the count is not the subject here, the shape is |

### What this must not break, and how each is handled

- **No second parser.** `Split-DevelopmentCycle` already hands back Head and Entry, fence-aware, and is
  the single splitter three readers share by design. Both checks read its Head rather than re-deriving
  where the entry begins.
- **The portable page currently says the opposite.** `DEVELOPMENT-portable.md`: *"The gate reads step marks
  only, so a heading of any level is invisible to it."* That stops being true for the source repo, and the
  sentence travels to consumers -- so it is rewritten to say what is now true for whom, rather than left
  as a claim the code contradicts.
- **A consumer must not be refused for a correct file.** #898's check is behind
  `Test-IsWorkflowSourceRepo`; #899's does not need scoping, and the reason is worth stating rather than
  assuming: a translated guidance block is still a blockquote, so the shape rule survives translation
  where a byte comparison would not.

## CREATE

- [ ] Dot-source `seam-lib.ps1` in `check-branch-entry.ps1` for `Test-IsWorkflowSourceRepo`
- [ ] #898: refuse a fifth `##` in the source repo, naming the extra heading and its line, and saying to demote it
- [ ] #899: refuse a non-blank, non-`>` line between the H1 and the first `##`, naming the line -- in every repo
- [ ] Rewrite the heading-blindness sentence in `plugins/workflows/workflow-davekjohn/DEVELOPMENT-portable.md`, and regenerate the mirror if the source half moves

## TEST

- [ ] Scenarios in `scripts/tests/branch-entry-gate.tests.ps1`: four headings (pass), five (error), five in a CONSUMER fixture (pass -- the scoping is the point), a `##` inside a fence (pass), guidance-only preamble (pass), a plain paragraph in the preamble (error), a translated blockquote preamble (pass)
- [ ] Each check RED before its fix and green after, verified in that order
- [ ] `check-plugin-integrity.ps1` green and the full suite green, the same set CI runs

## DEPLOY: `feat/the-cycle-document-has-a-shape-gate-v1`

**Score:**

### What makes this deploy extra special

**Score:**

### Pull Request

the branch-entry gate holds development-cycle.md to its four phases and its generic preamble

