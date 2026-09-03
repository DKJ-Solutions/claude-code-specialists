## feat/branch-document-name-and-headings

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

#### What #1335 asks for

Three cosmetic changes to the branch development document, and each one removes a delimiter that
machinery was reading:

1. the filename loses its `development-` prefix -- `contributing-davekjohn/<branch-slug>.md`;
2. the document's own heading becomes bare -- `## feat/x`, no title word, no backticks, no creation stamp;
3. the DEPLOY heading loses its backticks -- `### DEPLOY: feat/x`.

#### The concern, stated once and then built anyway

The backticks and the title word were this format's only delimiters, and four readers used them:
`Get-BranchFileDeclaredBranch` (the idempotency and resolution test), `Get-DevelopmentEntryPattern`
(the splitter), `Get-EntryDeclaredType` (the change type, read off the branch prefix) and
`Get-FoldedEntryForBranch` (the duplicate-fold guard). The filename prefix was the only thing that
made `development-*.md` a safe glob inside a folder that also holds `README.md`, `CONTRIBUTING.md`
and `CHANGELOG.md`. So the work is not the three edits -- it is replacing each delimiter with one at
least as narrow, and proving it with tests.

### CREATE

- [x] Filename: `Get-BranchFilePaths` writes `<slug>.md`, reads `development-<slug>.md` as the prior
      per-branch name, and gains a reserved-name list so the widened glob cannot sweep the folder's
      own pages
- [x] One sweep for four call sites: `Get-PerBranchDocumentRels`, used by the resolver, the
      unfolded-entry gate and the two lint sweeps
- [x] Headings: `Format-BranchFileHeadingLine` drops the backticks; the document heading drops its
      title and its creation stamp, retiring `ProgressTitle` and `-Id` with them
- [x] Readers: the four above accept the bare shapes and keep reading every backticked one
- [x] The scripts around the lib: `new-branch.ps1`, `check-unfolded-entry.ps1`,
      `check-plugin-integrity.ps1`
- [x] The docs that name the path or the heading, and the plugin mirror

### TEST

- [x] `branch-document-path.tests.ps1`, `entry-scaffold.tests.ps1`, `new-branch.tests.ps1` and
      `unfolded-entry-gate.tests.ps1` cover the new shapes and every legacy one
- [x] A test that the widened glob does NOT read `CHANGELOG.md`, `README.md` or `CONTRIBUTING.md` as
      a branch document -- the destructive direction of this change
- [x] Full gate: `check-plugin-integrity.ps1` plus every suite

### DEPLOY: feat/branch-document-name-and-headings

The branch's development document is named after the branch and nothing else, and both of its headings
lost their decoration. Where a branch got `contributing-davekjohn/development-feat-thing-v1.md`, headed
`` ## Development: `feat/thing-v1` · 20260903-152650 ``, it now gets
`contributing-davekjohn/feat-thing-v1.md`, headed `## feat/thing-v1`. The entry heading keeps its title
word and loses the backticks:
`### DEPLOY: feat/thing-v1`. Asked for in
[#1335](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1335).

**Everything removed was load-bearing, which is where the work actually was.** The backticks were this
format's only delimiter and four readers used them to find where the branch name starts and ends -- the
idempotency and resolution test, the splitter that finds the DEPLOY heading, the reader that takes the
change type off the branch prefix, and the duplicate-fold guard. Each now reads the bare shape with a
narrower anchor than "a word in backticks somewhere on the line": the entry's heading by its title word
and colon, the document's by the heading being nothing but a branch-shaped token. And the `development-`
prefix was quietly making `development-*.md` a glob that could not reach this folder's own pages, so that
narrowing is now stated -- `ReservedNames` excludes `CHANGELOG.md`, `README.md` and `CONTRIBUTING.md` from
one shared sweep, `Get-PerBranchDocumentRels`, which four call sites read instead of repeating the glob.
`CHANGELOG.md` is the one that makes it load-bearing: it is full of folded DEPLOY headings, so it declares
a branch by every test in the lib, and the fold moves a document into the changelog and then deletes it.

Every earlier shape is still read, exactly as at the six renames before this one: a branch open across
this change keeps its prefixed filename, its backticked headings and its creation stamp, and folds
normally.

**Score:** 3

#### What makes this deploy extra special

A consumer's open branches are untouched -- they keep the old name and the old headings, and the readers
still recognise both -- so the update arrives without a migration. New branches get the shorter name and
the plainer headings. The creation stamp is gone from the document heading and is not replaced: nothing
ever read it back, and the stamp the changelog orders by is the merge stamp, which is unchanged.

**Score:** 2

#### Pull Request

Development document: bare branch-name filename and headings
