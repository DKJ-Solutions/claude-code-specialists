---
name: adopt-bwj-asana
description: >-
  One-time setup of bwj-codex in a BWJ store repo (smartwatchbanden or xoxowildhearts): copy the
  asana-mirror CI mechanism into .github/, propose the Asana config seam for scripts/repo-config.ps1,
  print the repo secret and variables the CI needs, check that the classification labels exist, and
  report whether the board's sections are numbered so the stage model can read them. Strictly additive and dry-run by default; it
  never overwrites an existing file, and it renames nothing on the board. Run this right after
  enabling the plugin, or when report-issue reports the Asana config seam missing.
---

# adopt-bwj-asana -- place the CI mechanism and the config seam

An install writes nothing into your repo. This command places the two things `bwj-codex` needs on
your side: the CI workflow that resolves Asana tasks, and the config functions the skill and the CI
both read.

## 1 -- copy the CI mechanism into `.github/`

GitHub only runs a workflow from a repo's own `.github/`, so these are copied, not imported:

| from this plugin | to your repo |
|---|---|
| `templates/asana-mirror.yml` | `.github/workflows/asana-mirror.yml` |
| `templates/asana-mirror.ps1` | `.github/scripts/asana-mirror.ps1` |

Copy them verbatim. If a file already exists at the target, **stop and diff** rather than
overwriting -- report the difference and let the maintainer decide.

## 2 -- propose the config seam for `scripts/repo-config.ps1`

Add two functions to the repo-owned `scripts/repo-config.ps1` (the same file `contributing-davekjohn`
dot-sources). **Propose** them -- do not place them -- because the values state what this repo *is*:

```powershell
function Get-AsanaWorkspaceGid { '<your Asana workspace GID>' }
function Get-AsanaProjectGid   { '<the Asana project a mirrored task lands in>' }
```

**Propose one value and say why it is the only one: `Get-AsanaProjectGid` is the board the team
reads.** That used to be an open BWJ decision -- one shared project or one per store -- and it is not
any more (Dave, September 2, 2026): there is exactly one board, and two independent constraints both
land on it.

- **The prio labels.** An Asana custom field does not cross workspaces, so a task created in a project
  of some *other* workspace can never carry a `Prio-Score`, and the sweep of
  [step 5](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/bwj-codex/WORKFLOW-portable.md#5-the-asana-prio-score-comes-back-as-a-github-label)
  then reaches only the tickets *imported from* the board
  ([#1213](https://github.com/DaveKJohn/claude-code-specialists/issues/1213)).
- **The stages.** They live on that board's own sections, so a task filed anywhere else sits on no
  pipeline and never moves a column -- see step 5 below.

**A provisional GID is where both costs land at once**, and neither says anything in a log: such a
ticket carries no prio label and never advances a stage. So if the real project is not known yet,
record that both are incomplete until it is.

## 3 -- print the CI secret and variables (the maintainer sets these)

The CI workflow needs, on the repo (Settings -> Secrets and variables -> Actions):

- **Secret** `ASANA_PAT` -- an Asana personal access token with write access to the project.
- **Variable** `ASANA_PROJECT_GID` -- same value as `Get-AsanaProjectGid`.

Print these as a checklist. This skill does not set secrets.

**There is deliberately no workspace variable here**, and do not add one back: the CI half addresses
every task and project by GID, so it never needs the workspace. `Get-AsanaWorkspaceGid` from step 2
stays -- `report-issue` reads it session-side, where it CREATES a task and the API does want a
workspace.

## 4 -- make sure the classification labels exist

[`report-issue`](../report-issue/SKILL.md) files every issue with an issue type and, where it reaches
that far, the `tier-1` label. **`gh issue create` fails outright on a label the repo does not have**, so
check for it and create it if it is missing:

```bash
gh label list --repo <owner>/<repo> | grep -E '^(tier-1|documentation)\b'
gh label create tier-1 --repo <owner>/<repo> --color fbca04 \
  --description "Reaches the business: management and the commissioner notice it"
```

**And the four prio labels**, which the reconcile sweep needs: it sets one of them on every open
issue from its Asana task's `Prio-Score`, and `gh issue edit` fails on a label the repo does not have
exactly as `gh issue create` does.

```bash
gh label create "very high" --repo <owner>/<repo> --color b60205 \
  --description "Asana Prio-Score 4.00-5.00"
gh label create "high"      --repo <owner>/<repo> --color d93f0b \
  --description "Asana Prio-Score 3.00-3.99"
gh label create "low"       --repo <owner>/<repo> --color 0e8a16 \
  --description "Asana Prio-Score 2.00-2.99"
gh label create "very low"  --repo <owner>/<repo> --color c2e0c6 \
  --description "Asana Prio-Score 1.00-1.99"
```

Four buckets and deliberately no `medium` (Dave, September 2, 2026). **Exactly one of them sits on an
issue at a time** -- the sweep removes the other three as it sets one, so a ticket rescored from 2.5
to 4.2 loses `low` as it gains `very high`. A task with **no** score, or a score outside 1.00-5.00,
gets no prio label at all rather than a guessed one; on the BWJ board the day this shipped that was
28 of 96 open tasks, so it is the common case and not an edge one.

The three issue **types** (Task / Bug / Feature) are org-wide, not per repo, so there is nothing to
create for them -- confirm in the org settings that they are enabled and stop there. Do **not** create
`bug` or `enhancement` labels: the type carries both, and they were deliberately deleted from the
existing BWJ repos.

## 5 -- check the board's sections are numbered

The stage model of
[step 6](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/bwj-codex/WORKFLOW-portable.md#6-the-boards-sections-are-the-cycle----one-card-six-stages)
reads a card's stage off the **number its section's name starts with**. Read the sections of the
project from step 2 and report which stages the board actually offers:

```text
1. <anything>   the requester's untriaged inbox   never written by this workflow
2. <anything>   tracked on GitHub now
3. <anything>   somebody is building it
4. <anything>   merged, and the issue is not closed yet
5. <anything>   ready to test
6. <anything>   the requester says it is good     never written by this workflow
```

The words after each number belong to the team; only the number is read. **Report what you find and
change nothing** -- a board is a shared surface and renaming somebody's column is not an adoption
step. Two cases are worth naming explicitly when you report:

- **No numbered sections at all.** Nothing is ever moved on that board. That is the safe default, and
  it is *silent* -- so a board meant to be a pipeline and not numbered looks exactly like one that
  works. Say so plainly.
- **A gap in the middle** (say, no `4.`). Cards simply stop at the stage below it and the log says
  which section was missing. Nothing is created.

## 6 -- point the repo's governance at the rule

Add a line to the repo's `CLAUDE.md` (or a repo lens) pointing at
`~/.claude/plugins/marketplaces/claude-code-specialists/plugins/workflows/bwj-codex/WORKFLOW-portable.md`
so a session reads the BWJ ticket rule the same way it reads the other portable pages.

## What this skill does not do

- It does not enable the plugin -- that is a `.claude/settings.json` change you make first.
- It does not create the Asana project or token.
- It does not register this repo in the source repo's `connectors/` register -- that happens in the
  source repo after this repo's settings change has merged.
