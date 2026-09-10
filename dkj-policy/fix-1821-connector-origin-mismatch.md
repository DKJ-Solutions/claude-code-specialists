## fix/1821-connector-origin-mismatch

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

Issue [#1821](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1821): `check-connectors.ps1`
follows a record's `localCheckout` **by path**, and a path says nothing about which repository is in
the folder. Reproduced on this machine before any edit: the record for
`BWJ-Development/smartwatchbanden` resolves to a clone whose `origin` is
`BWJ-ecommerce/smartwatchbanden` -- two distinct repositories, not a redirect -- and the check printed
five confident `[ERROR]` lines about a repository it never opened.

The repair is check **1b**: read the checkout's `origin`, compare it with the record's `repo`, and
where they disagree say so instead of reading that disk on the named repo's behalf.

#### The arm that makes it safe to ship

A naive comparison was measured against every record on this machine first, and it fires falsely on
the source repo's **own** connector: `connectors/dkj-claude-plugins.json` names
`DKJ-Solutions/dkj-claude-plugins` while this checkout's `origin` is still
`DKJ-Solutions/claude-code-specialists` -- the #1769 rename, landing on a transfer redirect. So the
check reads its own rename history (`Get-RepoName` + `Get-RetiredRepoNames`, the seams the file
already loads for check 6) and stays quiet there, rather than crying wolf about itself at every
session start.

### CREATE

- [x] `scripts/sync/check-connectors.ps1`: check 1b -- four arms (agree / this repo's own retired
      spelling / disagree / question could not be asked), placed after the checkout resolves and
      before anything reads its settings, with the `.DESCRIPTION` list updated to match.

### TEST

- [x] `scripts/tests/connectors.tests.ps1`: cover the three arms that can be fixtured -- a checkout
      whose `origin` disagrees (the finding fires and the plugin verdicts are withheld), one that
      agrees (unchanged), and one that cannot be asked (unchanged).
- [x] The existing suites stay green -- `connectors.tests.ps1` and `connector-sessioncheck.tests.ps1`.
- [ ] Review round on the diff: code review, copy edit, security.

### DEPLOY: fix/1821-connector-origin-mismatch

`check-connectors.ps1` followed a record's `localCheckout` by path and never asked which repository
the folder actually was. Measured on two machines: the record for `BWJ-Development/smartwatchbanden`
resolves to a clone of the archived `BWJ-ecommerce/smartwatchbanden` -- two distinct repositories that
merely share a name half -- and the check printed five confident `[ERROR]` lines about a repository it
had never opened. That is worse than silence, because it invites somebody to repair a consumer that is
already correct.

Check **1b** now reads the checkout's own `origin` before anything reads that disk on the named repo's
behalf, and says what it measured rather than what it guessed. Agreement is silent. A mismatch is one
`[ERROR]` naming both slugs, stating that nothing about the named repository was checked, and giving
the two things it can be -- a clone of a different repository, or a `localCheckout` pointing at the
wrong folder here -- with the command for each; every verdict below is withheld rather than printed
against a repo that was never read. It does not claim more than a local read can support: without a
network call this run cannot tell a different repository from an old spelling still answering a
transfer redirect, and the finding says so.

The arm that makes it safe to ship is the one the issue did not anticipate. A plain comparison fires
falsely on the source repo's **own** connector -- `connectors/dkj-claude-plugins.json` names
`DKJ-Solutions/dkj-claude-plugins` while this checkout's `origin` is still
`DKJ-Solutions/claude-code-specialists`, the #1769 rename landing on a transfer redirect. So a mismatch
that this repo's own rename history explains is a dim `[SKIP]` naming the one command that ends it, and
the run proceeds untouched. Without it the check would have cried wolf about itself at every session
start, in the repo that ships it.

**Score:** 3

#### What makes this deploy extra special

A consumer's own session runs this check too, scoped to its own manifest, so a consumer whose checkout
was cloned before a rename or an org move stops being told that five plugins are not enabled and is
told the one true thing instead: the folder being read is not the repository the register names. It
only fires where that is actually the case, which is why it is not higher.

**Score:** 2

#### Pull Request

check-connectors names the repository a checkout actually is