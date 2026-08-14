## `fix/skills-cannot-self-trigger` changelog

### Branch title

the three team-alpha skills stop being model-invocable, and name their PowerShell dependency

### Branch ID

20260814-194728

### Branch type

fix

### What does the change on this branch bring to main?

Item **B2** of inbound [#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669), the
assessment made from a Cowork session with **no repo at all**. `specialists-init`,
`specialists-teardown` and `sync-roster` are `.ps1` wrappers that were present in the main
conversation's skill list, so *"set this specialist system up for me"* could start a bootstrap that
ends on a command the machine does not have. They now carry `disable-model-invocation: true` — a user
can still ask for them by name, the model can no longer reach for them on its own — and each names its
PowerShell dependency **before** the procedure rather than at the end of it.

**Verified before building, and one of the report's facts had expired.** #669 argued B2 partly from
*"only `start-task` carries the flag — the only SKILL.md across all four plugins with it"*. That was
true when it was written and is not true now: **nine** of the sixteen shipped skills carry it today.
What still stood is the part that matters — the three team-alpha skills did not — so the finding
survives its own supporting fact. Same discipline as the two items split out of this report earlier:
the symptom is checked, and then the reasoning is checked separately.

**The check is at the front because the script is at the back.** The script cannot half-run — without
`powershell` it never starts — so nothing it writes is left half-written. What runs halfway is the
*page*: marketplace registration, a plugin install over the CLI, and up to two session restarts all sit
above the call. Arriving at an impossible command after all of that is the failure, and nothing before
it gives a signal. Each of the three states its own consequence rather than sharing one sentence: init
stops before step 0, sync-roster leaves the drift standing and names the manual recovery, teardown
notes that nothing was removed but that the reversibility this page promises is not available here.

**`pwsh` is deliberately not offered as the way out.** These scripts target Windows PowerShell 5.1,
which is why this repo's own CI runs them on `shell: powershell` and not on `pwsh` — pointing a reader
at it would trade a loud failure for a quiet one.

**Named and deliberately not built:** four more model-invocable `.ps1` wrappers exist —
`adopt-config`, `adopt-workflow-folder`, `new-branch` (workflow-davekjohn) and `discover-workflow`
(workflow-default). They carry the same shape, #669 did not measure them, and `new-branch` in
particular is one a model reaching for it is arguably *right* about inside a repo. Switching that off
is a decision about the workflow, not a repair of this defect.

### Significance

#### Tier 0

Nothing changes on this machine: the maintainer invokes these three by name anyway, and the lint, the
tests and the gates are untouched.

**Score:** 1

#### Tier 2

A consumer — especially one outside a developer's setup — can no longer have a bootstrap started for
them that cannot finish, and if they run one of the three somewhere without PowerShell they are told at
the front instead of at exit 127. They receive it through a plugin update rather than by choosing to,
and nothing they wrote changes.

**Score:** 3

### Pull Request

