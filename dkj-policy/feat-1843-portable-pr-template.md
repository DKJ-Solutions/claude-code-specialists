## feat/1843-portable-pr-template

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

The plugin ships templates/pull_request_template.md as a reference, but nothing ever copies it into a consumer's .github/. GitHub reads a PR template only from the consumer's own repo, and open-pr builds no body at all when the file is absent -- silently, since its only warning covers a placeholder that does not match rather than a file that is not there. adopt-workflow-folder already places one file outside the workflow folder (.github/workflows/branch-entry.yml), so this adds the template to that same strictly-additive lane, read from the shipped reference rather than retyped.

#### What this branch is, within #1843

#1843 asks two things: that every `dkj-policy` consumer follow the same GitHub workflow, and that the
label sets agree. The issue carries an assessment and a red-team of that assessment, and **this branch
builds the one step that survived the red-team unchanged** -- the PR template placement. The rest of
#1843 needs decisions rather than code, and the issue stays open for them.

Verified against the tree before building, rather than taken from the report:

- The plugin ships `templates/pull_request_template.md` and **nothing copies it**. Confirmed: no
  `gh`-side, script-side or skill-side copier exists; `adopt-dkj-policy/SKILL.md` did not so much as
  mention the file.
- **The report said `open-pr` "warns when it is missing." It does not.** `open-pr.ps1` wraps the whole
  body-building block in `if (Test-Path $templatePath)` with **no `else`**, so a consumer without the
  file gets a PR with no body at all and no warning. The warning that block carries fires when a
  placeholder does not *match* -- a different state. The symptom is worse than reported, and silent.

### CREATE

- [x] `adopt-workflow-folder.ps1` places `.github/pull_request_template.md`, read from the shipped
      reference rather than retyped, on the same strictly-additive lane as the branch-entry gate.
- [x] Reference resolution covers both locations the byte-identical copies live in -- the released
      plugin mirror and this repo's own `scripts/task/`. Both candidates hang off `$PSScriptRoot`.
- [x] The root mirror re-synced and both copies parse.
- [x] `CONTRIBUTING-portable.md`, the `open-pr` skill, the plugin README and the `adopt-dkj-policy`
      skill (body and frontmatter) no longer describe the copy as a person's job, and each names the
      silent-absence failure that made it worth automating.

### TEST

- [x] Five asserts added to `adopt-workflow-folder.tests.ps1`: the dry run lists it and writes nothing,
      `-Apply` places it, what lands is byte-identical to the shipped reference, it carries a line
      `open-pr` actually recognises, and a consumer's own template survives a re-run byte for byte.
- [x] **Neither content assert restates the template**, for the reason the gate asserts were rewritten
      in #1805: a literal would compare the scaffolder's output against the test file rather than
      against the thing it has to agree with, and stay green when that thing moves. One reads the
      reference off disk; the other reads `Get-PrDescriptionPlaceholderDefaults` out of `pr-body-lib`.
- [x] `adopt-workflow-folder.tests.ps1`: 125 asserts pass.
- [x] The wrong first fallback was **caught by these tests, not by reasoning** -- it resolved against
      `$repoRoot`, which is the consuming repo being scaffolded and by definition does not ship this
      plugin, so the template was never placed at all. Written down in the script beside the repair.
- [x] End-to-end run against a scratch consumer: six files created, the placed template byte-identical
      to the reference.
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite.

### DEPLOY: feat/1843-portable-pr-template

`adopt-dkj-policy` Part 1 now places `.github/pull_request_template.md` in a consuming repo, copied from
the plugin's own reference and never overwriting one that is already there. It was the last file in the
adoption a person had to copy by hand, and the only one whose absence was silent: `open-pr` builds a PR
body only when that path exists, so a repo that skipped the copy got pull requests with **no body at
all** -- no description, no form -- and no warning saying why. The warning that block does carry fires
on a placeholder that does not *match*, which is the other failure and the loud one.

The content is read from the shipped reference rather than retyped into the scaffolder. The interface is
a single line -- the placeholder `open-pr` matches verbatim -- and a literal copy of it in the adopter
would have been a second definition free to drift from the first, which is the same argument the
branch-entry gate makes for calling a shipped script instead of hand-writing its check in shell. Where
the reference cannot be read, nothing is placed and the run says so; there is deliberately no fallback
string, because a fallback is that second definition wearing an emergency jacket and it is the copy that
ships in the one case nobody is watching.

This is one step of [#1843](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1843), which asks
for more than this and stays open: a portable `repo-settings.yml`, a CI skeleton, and the label question.
Each of those needs a decision first, and the issue carries the assessment and the red-team of it.

**Score:** 3

#### What makes this deploy extra special

The defect it closes was invisible from both ends. A consumer never saw a warning, because there is no
`else` on that path test; the source never saw it either, because every doc describing the copy was
written as an instruction to a person, and an instruction nobody follows leaves no trace. What made it
fixable was checking the reported reason instead of the reported symptom -- the report said `open-pr`
warns on a missing template, and reading the code showed it does not.

**Score:** 2

#### Pull Request

Place the PR template in a consumer's .github during adoption
