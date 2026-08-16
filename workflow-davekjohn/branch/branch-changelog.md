## `docs/chain-route-readable` changelog

### Branch title

The chain's remaining commands become readable to the model

### Branch ID

20260816-135719

### Branch type

docs

### What does the change on this branch bring to main?

Inbound [#731](https://github.com/DaveKJohn/claude-code-specialists/issues/731), from `life-hub`. It
reported that `disable-model-invocation: true` makes the owner's explicit approval unexecutable: a
branch finished under the exception, the owner says *"merge it"*, and the assistant cannot act on the
word the whole governance rule is built around.

**The finding stands and no flag changed.** `new-branch/SKILL.md` gains one section listing the four
commands that follow it — `open-pr`, `ship-pr`, `fold-changelog-entry`, `cut-release` — with the
`${CLAUDE_PLUGIN_ROOT}` form each of their own pages already carries, plus the source-repo caveat and
an explicit statement that the list is a route and never a licence.

**Because the flag hides the instruction, not the capability.** It removes a page from the model's
context entirely; the script stays ordinary PowerShell that anyone can run. So the practical effect was
an inversion — the documented route unavailable at exactly the moment it was needed, the undocumented
one wide open. `new-branch` is the one skill in this chain deliberately left model-invocable, so a
pointer placed there is readable at precisely the moment a chain begins, costs nothing until then, and
duplicates no chain.

**Three targets were measured and rejected first, and each rejection is the reason this one is right.**
Derek's and Rendall's portable personas cannot carry the command: they are `team-alpha`, which ships
neither the scripts nor a dependency on `workflow-davekjohn`, so `${CLAUDE_PLUGIN_ROOT}` there resolves
into the wrong plugin root. `workflow-davekjohn/CLAUDE.md` is the right owner but the wrong reach —
`adopt-workflow-folder` never overwrites, so it would reach new consumers only, and the reporter
already has that folder. A settings-level opt-in, the reporter's own first preference, does not exist:
`skillOverrides` is the documented lever and its own documentation ends with *"Plugin skills are not
affected by `skillOverrides`."*

**Three of the report's own facts were wrong, and the recount is why the repair is not the one it
proposed.** It counted 6 flagged skills in `workflow-davekjohn`; there are **10** of 13, and **14** of
19 across the six shipped plugins. It described the split as *"read/scaffold open, push/merge/tag
closed"* — falsified both ways: `continue`, `lock` and `prompt` are flagged while their own
descriptions say they read only or write one gitignored file, and `adopt-config` and
`adopt-workflow-folder` are unflagged while they write into the consumer's repo. And it called the
script route undocumented, when `open-pr/SKILL.md` and `ship-pr/SKILL.md` open with exactly that
command. Its proposal — drop the flag on `open-pr` alone, since that is *"the reversible half"* —
rested on the falsified split, so following it would have changed a governance boundary on a reason
that does not hold. The fifth failure pattern in Chris's lens, for the fifth time.

`INSTALL.md` carried the same mis-attribution and is corrected in passing: it named `cut-release`,
`fold-changelog`, `open-pr` and `park` as *"team-alpha's own skills"* when all four are
`workflow-davekjohn`'s, and it now states the measured 14-of-19 instead of "several".

### Significance

#### Tier 0

The route to the rest of the chain is readable in context for the first time, so a session no longer
has to infer a script path it was never told.

**Score:** 3

#### Tier 2

The reporting consumer's blocker is gone: the owner's *"merge it"* is executable through the documented
route rather than through one nobody wrote down. No flag, gate or governance boundary moved, so nothing
must be re-approved.

**Score:** 3

### Pull Request

