# bwj-codex -- BWJ's shared ticket workflow, packaged so two repos cannot drift on it

**This is the one way BWJ's two Shopify stores -- `BWJ-ecommerce/smartwatchbanden` and
`BWJ-ecommerce/xoxowildhearts` -- handle a discovered issue.** The two repos are identical in
behaviour and differ only in brand, and the connector register already flags them as the pair most
at risk of quietly diverging. This plugin is the thing that holds them together on one point: what
happens between spotting a problem and it being tracked where every BWJ colleague can see it.

## It is an add-on, not a replacement

`bwj-codex` **layers on top of `contributing-davekjohn`** -- it does not stand in for it. It
extends exactly one seam of that workflow: *ticket-work, the layer before the branch*. It says
**nothing** about how a branch is named, what a change owes before it can open a PR, or what a
release is -- those are still `contributing-davekjohn`'s answers, unchanged. So the two do not hand
the specialists two contradicting answers to the same question; they answer different questions.

That is the deliberate reading of the "second workflow" note left in
[the workflows README](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/README.md)
and the root README after
[#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886): a second workflow plugin is
safe here **because it is additive and non-overlapping**, not because the old guard was wrong.

**It carries no specialists.** A workflow changes how the existing ones work, not who they are.
Enabling this without `team-alpha` gives you a skill with nobody to invoke it; it also expects
`contributing-davekjohn` to be enabled, because its rule begins where that workflow's ticket-work
step begins.

## The rule, in one paragraph

A discovered issue is **created on GitHub first** -- GitHub is the source of truth, full technical
detail, the normal `team-alpha` filing bar unchanged. It is **classified in the same breath**: an issue
type (Bug / Feature / Task), plus the `tier-1` label where management and the commissioner would notice
it, both set at creation so nobody has to classify a tracker by hand a second time. It is then
**mirrored to Asana** as a colleague-friendly variant: plain language, outcome-framed, no code or
repo jargon, so any BWJ colleague can read it. The two are **cross-linked both ways**. When the
**GitHub issue is closed, the Asana task is resolved automatically** -- by a small GitHub Actions
workflow this plugin ships as a template for each repo to copy into its own `.github/`. Reopening
the issue un-resolves the task; a daily reconciliation sweep repairs anything a missed event left
behind.

The whole rule, with the field-by-field shape of the Asana variant and the cross-link markers, is in
[`WORKFLOW-portable.md`](WORKFLOW-portable.md) -- that is the page to read, and the page to point BWJ
colleagues at.

## What is in this folder

| what | what it holds |
|---|---|
| [`WORKFLOW-portable.md`](WORKFLOW-portable.md) | the rule in prose -- the human-facing page, read alongside your repo's own Asana config |
| [`skills/`](skills/) | the skills a specialist invokes |
| [`templates/`](templates/) | the CI mechanism to **copy** into each repo's `.github/` -- GitHub only runs workflows from a repo's own `.github/`, so what ships here is the reference to copy and diff against, the same pattern as `contributing-davekjohn/templates/pull_request_template.md` |

**No `agents/`, no `manuals/`, no `hooks/`, no `blueprint/`.** Agents and manuals belong to a team.
The hooks and blueprint a workflow carries "only where it needs them" -- this one needs neither.

## The skills

<!-- skills:plugin -->

| skill | when |
|---|---|
| [`report-issue`](skills/report-issue/SKILL.md) | a real issue has been found in a BWJ store repo -- files it on GitHub with its type and reach label, mirrors it to Asana as the colleague-facing variant, and writes the cross-links |
| [`adopt-bwj-asana`](skills/adopt-bwj-asana/SKILL.md) | one-time setup in a store repo -- copies the CI mechanism into `.github/`, proposes the Asana config seam, and prints the secret/variable setup |

<!-- /skills:plugin -->

## What it expects from your repo -- the seam

The `report-issue` skill and the CI mechanism need to know which Asana workspace and project a
mirrored task lands in. That is answered by two functions in your repo-owned
`scripts/repo-config.ps1` -- the same file `contributing-davekjohn` already dot-sources:

- `Get-AsanaWorkspaceGid` -- the Asana workspace GID.
- `Get-AsanaProjectGid` -- the project a mirrored task is created in.

`adopt-bwj-asana` **proposes** these, it never places them: they state what your repo *is*, and the
project may differ per brand. The CI half reads the same two values from repo variables
(`ASANA_WORKSPACE_GID`, `ASANA_PROJECT_GID`) plus the secret `ASANA_PAT`.

## Enabling it

An ordinary plugin change: enable `bwj-codex` in `.claude/settings.json` alongside `team-alpha`
and `contributing-davekjohn`, then run [`adopt-bwj-asana`](skills/adopt-bwj-asana/SKILL.md) once.
Disabling it removes nothing it already wrote to your repo -- the CI workflow and the config stay;
the skill that reads them stops.
