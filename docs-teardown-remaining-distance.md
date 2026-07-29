### Record what a teardown leaves behind, honestly · Docs · 2026-07-29

A hand measurement in `davekokbwj/smartwatchbanden` (July 29, 2026) established how far a torn-down
consumer really is from "no reference to the plugin anywhere", and one of the findings contradicted
what the family README claimed. Both docs now state it.

**The finding that matters: a runtime dependency, not clutter.** The plugin is the single source of
truth for the operational scripts (`new-branch.ps1`, `park-branch.ps1`, `new-changelog-entry.ps1`,
`open-pr.ps1`, `fold-changelog-entry.ps1`; #81), and a consumer reaches them through a resolver of its
own that locates the marketplace cache and **throws** once that cache is gone — in the measured
consumer `scripts/lib/plugin-paths.ps1`, dot-sourced by `start-task.ps1`, `open-pr.ps1`, and
`fold-changelog-entry.ps1`. So after a teardown plus `claude plugin uninstall` the repo does not merely
carry leftovers: its daily git workflow stops working. The teardown gap table in the family README
listed the shared scripts as "gone cleanly — plugin-owned", which is true of the plugin's side of the
boundary only; that row is now qualified, and the target shape gains the missing requirement (the
resolver degrades to an actionable failure, or the consumer keeps local copies — decided at adoption,
because no teardown can decide it afterwards).

**Two further leftovers named in [`specialists-teardown`](claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md).**
The authored text the script refuses to touch is now quantified rather than described — roughly 43
lines across some 6 sections of `CLAUDE.md` (the 22-row roster table, the work-division block, the
loading-strategy paragraph, the safety cross-references), plus loose mentions in `README.md` (5),
`research/plugin-sharing/README.md` (14), `releases/README.md` (1) and
`.github/pull_request_template.md` (1). And the orchestrator's lens survives as an **orphan**: it is
authored, so it is kept, while the `@`-import that loaded it is knowably bootstrap-written and is
removed — a `[KEEP]` line that reads as "still working" when it only means "still there".

The skill also now says plainly that its dry run warns about none of this: it reports what it would
remove and what it keeps, not what breaks afterwards. Making it warn is a script change, deliberately
not folded into this documentation pass.
