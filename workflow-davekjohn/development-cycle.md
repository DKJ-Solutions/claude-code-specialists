# Development cycle: `docs/entry-shape-examples-follow-the-merged-document-v1` · 20260824-150444

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

Issue [#870](https://github.com/DaveKJohn/claude-code-specialists/issues/870): the August 23, 2026
merged-document shape never reached four skill pages and the release lens, so each of them teaches a
retired entry shape. Nothing is broken at runtime — every retired wording is still read — so this is a
documentation repair only, with no script and no test change.

The current shape, established from the code and from a rendered scaffold rather than from the issue:

- the entry's heading is `` ## DEPLOY: `<branch>` `` (`Format-EntryBlock`, `ChangelogTitle` = `DEPLOY`)
- tier 0 has **no heading of its own** — its text sits directly under that heading
- the audience tier is `### What makes this PR extra special`, at `###` (`Get-EntryTierSubLevel` = 3)
  and retexted by [#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865)
- `### Pull Request` closes the entry

## CREATE

- [x] `new-branch/SKILL.md` — three example blocks (the annotated skeleton, the empty tier pair, the
      finished pair) plus the prose that calls tier 0 "the opening question"
- [x] `fold-changelog/SKILL.md` — the folded-entry example and the prose naming the audience heading
- [x] `open-pr/SKILL.md` — the impact-gate example and the `####` reference in the prose under it
- [x] `cut-release/SKILL.md` — the `-SkipSignificanceGate` example
- [x] `.claude/specialists/lenses/05-06-extension.md` — three places: the changelog-shape paragraph,
      the six-sections-to-two paragraph, and the significance example
- [x] `CONTRIBUTING-portable.md` — a sixth document the issue listed as having FOLLOWED the change; the
      heading "two questions in one section" and the sentence under it, plus the one inbound anchor link
      in `DEVELOPMENT-CYCLE-portable.md`
- [x] Re-sweep MULTILINE for the retired facts — a line-based grep cannot see a phrase broken by a line
      wrap, which is exactly how the sixth document hid; only history still carries them

## TEST

- [x] `check-plugin-integrity.ps1` green (dead links, frontmatter, manifests)
- [x] All suites in `scripts/tests/` green

## DEPLOY: `docs/entry-shape-examples-follow-the-merged-document-v1`

**The pages that teach the entry format now teach the one the scaffolder writes.** On August 23, 2026 the
branch entry became the DEPLOY section of `workflow-davekjohn/development-cycle.md` — the heading became
`` ## DEPLOY: `<branch>` ``, tier 0's answer lost its own heading and moved directly under it, and the
audience tier's sub-heading rose to `###`. The code, the two portable documents and `CHANGELOG.md`'s intro
followed. Six documents did not, and each one presented the retired shape as current:
the `new-branch`, `fold-changelog`, `open-pr` and `cut-release` skill pages, the release lens
`.claude/specialists/lenses/05-06-extension.md`, and `CONTRIBUTING-portable.md`. Nine example blocks and the
prose around them now match a rendered scaffold rather than a shape retired a day earlier. From
[#870](https://github.com/DaveKJohn/claude-code-specialists/issues/870).

**The shape was taken from the code, not from the report, and that is what caught the third fact.**
[#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865) had retexted the audience heading
to `What makes this PR extra special` between the issue being written and being picked up, so a repair
scoped to the issue's own bullets would have corrected the nesting and kept the retired wording — a
citation on a wrong answer. `Format-EntryBlock` was rendered directly and the newest folded entry in
`CHANGELOG.md` read alongside it; both agree, and every example here is now that output.

**Two of the report's measurements did not survive the recount, and one of them widened the job.** The
issue said all five documents showed `` ## `feat/x` deployment ``; two did. It said two of three facts were
wrong; all three were, the third in two independent ways. And it named `CONTRIBUTING-portable.md` among the
documents that *followed* the change — it had not. That sixth document stayed hidden through two
line-based sweeps because the phrase wraps across a line break, so the full-string grep could not match it;
a multiline re-sweep is what surfaced it, and is what now backs the claim that nothing instructional is
left. `fold-changelog/SKILL.md` also carried an unreported fourth fact, the merge stamp still on
`### Pull Request` where it moved to the DEPLOY heading in the same movement — that page stated the new
placement forty lines below the example contradicting it.

**Nothing changed at runtime, and the reason is the standing rule.** Every retired wording is still read —
`Get-EntrySectionBody`, `Get-EntryTierHigherRetiredHeadings` and `Get-EntryTierSubLevelRange` recognise all
of them — so an entry written from a stale example still folds, and no entry in flight or already in
`CHANGELOG.md` is affected. No script and no test changed. `CHANGELOG.md`'s folded entries and the published
release documents keep the shape that was current at their version: they are the record, not instruction.

**Score:** 3

### What makes this PR extra special

Four of the six repaired documents are plugin payload — the `new-branch`, `fold-changelog`, `open-pr` and
`cut-release` skill pages — and `CONTRIBUTING-portable.md` is a fifth. These are what a consumer reads to
learn the entry format, and until now they described a shape their own `new-branch` had stopped writing, in
nine separate examples. A consumer following them wrote an entry that still folded, so nothing failed
loudly; what they got was a document that did not match the file in front of them, with no way to tell
which was right. The correction arrives with the next release and needs no action: no consumer file is
rewritten, and every retired wording stays readable.

**Score:** 3

### Pull Request

The entry-shape examples follow the merged development-cycle document
