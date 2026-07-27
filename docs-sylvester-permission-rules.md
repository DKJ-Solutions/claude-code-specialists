### Two permission rules for Sylvester: not agent-editable, never version-pinned · Docs · 2026-07-27

Processes [#196](https://github.com/DaveKJohn/davekjohns-workshop/issues/196) (inbound from
life-hub). Two additions to Sylvester #15, both about permission rules for the plugin's own scripts,
and both holding for every consuming repo — which is why life-hub deliberately placed no bridging
note in its own lens.

**1. A permissions file is never agent-editable.** The existing rule *"Read before write, always
merge — never overwrite"* silently assumed Sylvester can write to `settings.json` /
`settings.local.json`. He cannot: the auto-mode classifier refuses every write, whatever the tool
(both an Edit and a scripted rewrite were blocked). That is correct behaviour — an agent that can
widen its own permissions has stopped being a gate — but because the manual never said so,
Sylvester walked into it, got blocked, and had to improvise a recovery mid-task. Twice in two
consecutive pieces of work. The rule now says: don't attempt the edit, hand over a paste-ready block
(exact lines out, exact lines in) plus the route, then verify by *reading*.

**2. Never pin a plugin-script permission to a version.** Plugin scripts live under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/...`, so a rule containing the version
number dies at the next release — and it fails as a permission *prompt*, not an error, so it can sit
broken for releases unnoticed. In life-hub two rules had been pinned to `1.18.0` and `2.5.0` while
the plugin had moved to `2.7.3`, which made every `new-branch` and `park` run prompt. **That
friction was actively holding back adoption of the very workflow the plugin had just centralised**
— the skills worked, using them was merely annoying enough to avoid. The rule prescribes the prefix
form, for both the `Bash(...)` and `PowerShell(...)` routes.

**Written into the agent-def as well as the manual, and that is the point.** The subagent reads its
agent-def every run but the manual only "if unsure", so a rule that lives only in the manual does
not stop Sylvester from walking into the wall. Working method step 2 in `agents/05-15-agent.md` held
the exact misconception; it now has both rules beside it in compact form, with the full reasoning in
`manuals/05-15-manual.md`. The `fewer-permission-prompts` mention under "Sylvester is lazy" carries
a warning too, since the skill derives its proposals from concrete transcript paths and therefore
generates precisely the pinned form — the trap is built into the tooling, not a one-off slip.

**Checked in this repo:** no `plugins/cache` rules in its settings at all — the workshop runs its
scripts locally from `scripts/`, not from the plugin cache, so it never had the dead-rule problem.
Nothing to repair here; this is purely a core fix for the consumers.
