## Development: `fix/a-plugin-link-must-stay-inside-its-plugin-v1` · 20260829-110609

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

Verified inbound #1066: 17 live escapes, not zero. Next: build check 30 in check-plugin-integrity.ps1, repair the 17, add the suite.

#### What the verification changed about the assignment

The report filed a **gap** and argued explicitly against building anything: *"today's expected answer is
zero findings, which is itself the reason not to build it yet."* Two of its load-bearing facts did not
survive being held against the tree, and both moved in the same direction.

- **Its boundary was wrong.** It proposed *"a relative link under `plugins/` must resolve to a target
  also under `plugins/`, because that is the subtree the plugin cache contains."* The cache contains no
  such subtree: every `installPath` in `installed_plugins.json` is
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`, so the plugin's own directory is the
  root and a sibling plugin is a separate versioned directory rather than a neighbour.
- **Its count was wrong, and so was "it never shipped."** The rule at the correct boundary finds **17**
  escapes in 5 files, all passing check 4 -- and resolved inside the installed copies (`team-alpha`
  4.21.0, `contributing-davekjohn` 4.22.0) rather than in this tree, **all 17 are dead**. Among them is
  the very link the report cites as *"1, correct -- that target travels"*: `cut-release/SKILL.md:123`.
  The manual it names does travel; it simply never travels to that path.

So the standing no-pre-emptive-fixes rule stopped applying -- the failure mode had bitten, 17 times, in
released payload -- and the assignment became build-and-repair rather than file-and-wait.

### CREATE

- [x] Verify the inbound report against the tree: resolve the link in the real plugin cache, not in the marketplace clone (which is a full checkout of this repo and resolves everything, teaching the wrong lesson)
- [x] Recount at the correct boundary -- the plugin root rather than `plugins/` -- over every `*.md` under the five published plugin roots
- [x] Build lint check 30 in [`scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1): resolve each relative link from where it sits, hold it against its own plugin's root, and hand over the absolute form in the finding
- [x] Repair the 17, per the convention `DEVELOPMENT-portable.md` already states -- `blob/main/` for files, `tree/main/` for the two directory targets
- [x] Write the convention out in full in [`DEVELOPMENT-portable.md`](../plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md) (portable half) and the measurement in [Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md) (local half, where `CLAUDE.md` sends a reader for why a check has its shape)

### TEST

- [x] Six scenarios in [`check-plugin-integrity-links.tests.ps1`](../scripts/tests/check-plugin-integrity-links.tests.ps1), including scenario 37 -- a link into a sibling plugin, which the report's own proposed boundary would have passed
- [x] Full lint gate green (0 findings, `[plugin-link] checked 81 ... 0 escaping`)
- [x] All suites green

### DEPLOY: `fix/a-plugin-link-must-stay-inside-its-plugin-v1`

The lint gate could not see the one class of dead link that reaches consumers. Check 4 resolves every
link against the tree it runs in, and for a plugin-shipped file that is this repo -- the single tree
where the link is guaranteed to work. A consumer reads the same file from
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`, where the `plugins/` level, the family
level and every sibling plugin are gone, so a relative link that walks out of the plugin root resolves
here and lands on nothing there.

**Check 30 closes it**, and the boundary is the **plugin root** rather than `plugins/` -- the difference
is the whole check, because the weaker rule passes a link into a sibling plugin, which is equally dead.
It reads every `*.md` under each published plugin root, masks fences, inline code and HTML comments
without shifting line numbers, and hands the author the absolute URL to paste (`tree/main/` for a
directory, anchors carried along). Personas are excluded for check 4's reason; `${...}`, `~/` and
absolute targets are passed over.

**Measured on arrival: 17 escapes in 5 files, all repaired here** -- against the report's expected zero,
and resolved inside the installed copies rather than this tree, all 17 were already dead. The convention
itself was not new; it was stated on one portable page for that page and enforced nowhere. It is now
written out with its mechanism and held by a gate.

**Score:** 3

#### What makes this deploy extra special

All seventeen repaired links sit in payload a consumer reads -- the `specialists-init` and
`specialists-teardown` skills, the workflow's README and scripts README, and the `cut-release` skill --
and all seventeen are dead in the copies installed today. Resolved inside
`~/.claude/plugins/cache/`, `specialists-init` alone had 8 of its 9 relative links landing on nothing.
They work from the next release onward. `DEVELOPMENT-portable.md` gains the mechanism behind the
convention, so a consumer authoring their own plugin payload can see why the rule exists rather than
inheriting it as a habit.

**Score:** 3

#### Pull Request

A plugin-shipped relative link must resolve inside its own plugin

