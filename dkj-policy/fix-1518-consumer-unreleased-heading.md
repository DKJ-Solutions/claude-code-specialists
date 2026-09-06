## fix/1518-consumer-unreleased-heading

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

#### The choice the issue left open was not a preference — it was already decided

#1518 named three readings and called it the owner's call: write the heading into the scaffold, or
declare the heading this repo's own and correct the lib's comment, or make it the consumer's choice and
have the scaffolder report which shape it wrote. Read against the tree, only the first survives.

`plugins/dkj-policy/DEVELOPMENT-portable.md` travels to **every** consumer with the plugin, and
instructs them without condition: *"before you write that a behaviour changed, grep `[Unreleased]` for
what it used to be."* In a repo `adopt-workflow-folder.ps1` scaffolded, that grep matched nothing at
all — the string was not in their changelog. A portable page cannot direct a consumer at a heading only
the source repo has, which rules out reading 2; and reading 3 would make a page that instructs
unconditionally depend on a per-repo answer.

**#1517 landed on the trunk while this branch was building, and it points the same way.** It retired the
sentence I had first cited here — the label was described as a seam *"because a consumer may translate
it"* — on the ground that nothing in the code ever agreed. What replaced it is a better argument for this
change than the one it removed: the label is a single constant *because "nothing migrates the document"*,
the heading being *"already committed in this repo's `CHANGELOG.md` and in every consumer's"*. That second
half was not true when it was written. It is now.

- [x] Read both files the issue cites and confirm the symptom still stands — it does: `$changelogIntro`
      carried no pending heading, and `Get-ChangelogUnreleasedHeading`'s only callers were the pattern
      builder and a refusal message.
- [x] Establish which of the three the mechanism forces, rather than asking — the portable page above.

### CREATE

- [x] `adopt-workflow-folder.ps1`: write the pending heading into `$changelogIntro`, composed from
      `Get-ChangelogUnreleasedHeading` rather than typed — the same rule `$entryHashes` already follows
      three lines up, so a repo that translated the label or repointed the entry level gets its own.
- [x] Place it **last**, and repoint the intro prose at it: the first fold into an entry-less document
      appends at the end of the content, so anything below the heading would collect its entries above it.
- [x] `entry-scaffold-lib.ps1`: the pending-section block said the heading is the one *"every"* un-cut
      entry sits under. Now true of a fresh adoption, still not of an older one — the scaffolder is
      additive and never revisits a repo. Say so where the word is, rather than leaving the next reader to
      treat a flat document as broken.
- [x] `Set-ChangelogPendingSummary`: its third anchor was justified by *"a consumer scaffolded by
      adopt-workflow-folder.ps1 has NO pending heading"*. The anchor stays — it is the only route to every
      repo already adopted — but the sentence is dated to before this change.

### TEST

- [x] `adopt-workflow-folder.tests.ps1`: four asserts on the scaffolded document — it carries the heading,
      the intro points at it, it is the **last line** (the fold's insert point), and
      `Get-PreFlatChangelogRefusal` reads it as clean. All against `Get-ChangelogUnreleasedHeading`, never
      a literal, for the reason inbound #1098 gives one assert above.
- [x] `entry-scaffold.tests.ps1`: the anchor-3 test keeps its fixture and gains the date — it is the
      pre-#1518 consumer shape now, not the shape the scaffolder writes.
- [x] Smoke-run the scaffolder into a throwaway fixture and read the document back through the parsers:
      pre-flat refusal empty, zero entry blocks, and the fold's `$listStart` resolving to the end of the
      content directly beneath the heading.
- [x] Full local gate: `check-plugin-integrity.ps1` + every suite, via `open-pr.ps1`.

### DEPLOY: fix/1518-consumer-unreleased-heading

A repo adopting this workflow now gets a `CHANGELOG.md` with `## [Unreleased]` in it. Until today
`adopt-workflow-folder.ps1` scaffolded the intro and stopped, so an adopting repo's entries sat directly
under the prose — the flat shape this workflow left behind on August 26, 2026 — while
`DEVELOPMENT-portable.md`, which travels to every consumer, tells them to grep `[Unreleased]` for what a
behaviour used to be. That grep matched nothing in their tree.

Nothing was broken and nothing is repaired in that sense: the fold inserts at the first entry heading or,
where there is none, at the end of the content, and the cut writes the head back whatever is in it, so
both shapes fold and cut correctly and no gate had anything to say. What was wrong is that one shape was
documented and a different one shipped.

The heading is composed from `Get-ChangelogUnreleasedHeading` rather than typed — a repo that translated
the label or repointed the entry level gets its own — and it is written **last**, because the first fold
into an entry-less document appends at the end of the content and anything below the heading would
collect its entries above it.

**An adoption older than today keeps the flat shape**, and that is left alone deliberately: the
scaffolder is strictly additive and never revisits a repo it has scaffolded. The tally's third anchor
exists for exactly those repos and is untouched; what changed there is the sentence justifying it, which
described the scaffolder's present tense.

**Score:** 3

#### What makes this deploy extra special

N/A. The audience here is this repo's own developers and the consumers of `dkj-policy`, which is tier 0
and tier 1 — nobody subscribes to a service that changes. A consumer maintainer adopting the workflow
today gets a changelog that matches the page they are told to read, which is worth a 3 there; it is
invisible to anyone else.

**Score:** N/A

#### Pull Request

The scaffolded consumer changelog carries the pending heading
