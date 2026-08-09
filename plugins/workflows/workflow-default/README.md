# workflow-default -- the workflow a repo gets when it has not chosen one

**This is what a repo gets when it has not chosen a workflow.** Enabling it changes nothing about how
work moves through your repo, because it is not a method at all -- it is the deliberate absence of one,
packaged so that absence is a real, enabled plugin rather than a gap nobody filled in. Where
[`workflow-davekjohn`](../workflow-davekjohn/) is DaveKJohn's own branch-and-entry model, named after its
author because it is *his* way of working rather than a standard, `workflow-default` carries no method
of its own to impose. It is the one to enable by default, and the one a repo keeps unless it deliberately
decides otherwise.

## The specialists follow your repo, not this plugin

The Claude Specialists already carry this rule in every agent def, verbatim, via the shared block
[`plugins/agent-shared/repo-way-of-working.md`](../../agent-shared/repo-way-of-working.md): the repo's own
way of working comes first, and a specialist reads what is already there -- the `CLAUDE.md`, a
contribution guide, the git history, the CI workflows, the scripts the repo already has -- before it
proposes anything about process. That rule is *why* `workflow-default` can be this thin: the working
method the specialists follow was never going to live in a plugin, because a plugin is the same file in
every repo and a way of working is specific to one. See
[The plugin serves the consumer's repo](../../../README.md#the-plugin-serves-the-consumers-repo) in the
root README for the fuller argument, and the test question it hands every future addition to a plugin:

> Does this describe a *craft*, or a *way of working*?

`workflow-default` fails that test on purpose, in the safe direction: it adds no way of working at all,
so there is nothing here for the test to catch.

## The half that matters most: a `SILENT` answer is an answer

Reading the repo is only useful if not-finding-something is treated as information rather than as
license to reach for a habit from elsewhere. That is the second half of the shared rule linked above --
where the repo is genuinely silent, a specialist says so and picks the most conventional option for the
stack while naming that it is a pick, never importing a convention from a different repo and presenting
it as this one's standard. `workflow-default` exists to make that half concrete rather than merely
stated: its one skill, `discover-workflow` (below), reads the repo once and writes down, question by
question, which answers came from the repo itself and which came back `SILENT` -- so a specialist arrives
at that distinction already made, instead of re-deriving it from scratch at the start of every session,
and a `SILENT` answer stays visibly a gap rather than quietly turning into somebody else's default.

## Exactly one workflow, never two

**Enable at most one workflow plugin.** A workflow answers one question -- how does work move through
this repo -- and two workflows enabled together would hand the specialists two different answers to that
same question with no way to tell which one is the repo's. That is not a hypothetical: `workflow-davekjohn`
and `workflow-default` genuinely disagree, by design, about things as basic as whether a branch owes an
entry file and a step list before it can open a PR. A team plugin can stack with as many other team
plugins as a repo's domain calls for, because each one adds specialists rather than an answer to a shared
question; a workflow plugin cannot, for the same reason two people cannot both hold the floor on "what do
we call this branch". See
[Teams and workflows -- what's the difference?](../../../README.md#teams-and-workflows--whats-the-difference)
in the root README for the full split between the two kinds of plugin.

## Switching to another workflow

Moving from `workflow-default` to `workflow-davekjohn` (or back) is an ordinary plugin swap, not a
migration: disable the one you have and enable the other in `enabledPlugins`, refresh the marketplace,
install the new plugin at `--scope project`, and restart the session -- the same acts any plugin change
needs. The two directions are not quite symmetric, though, and it is worth knowing which way you are
going:

- **Onto `workflow-davekjohn`.** That plugin's shared scripts dot-source two repo-owned files,
  `scripts/repo-config.ps1` and `scripts/lib/branch-info.ps1`; `specialists-init` scaffolds both on its
  next run, and the `adopt-config` skill offers the source's own answers for the parts of that config
  that state a shared way of working rather than something specific to your repo.
- **Onto `workflow-default`.** Nothing to scaffold. The plugin reads what is already there and, the
  first time a specialist runs `discover-workflow`, writes one document. Disabling `workflow-davekjohn`
  does not remove anything it already wrote to your repo (its entry files, its config); it stops the
  skills and scripts that read and write them.

See [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) for the plugin's own one-paragraph
statement of this doctrine, and
[`skills/discover-workflow/SKILL.md`](skills/discover-workflow/SKILL.md) for the one skill it ships.
