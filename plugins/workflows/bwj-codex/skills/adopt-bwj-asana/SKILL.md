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

Add these functions to the repo-owned `scripts/repo-config.ps1` (the same file `contributing-davekjohn`
dot-sources). **Propose** them -- do not place them -- because the values state what this repo *is*:

```powershell
function Get-AsanaWorkspaceGid { '<your Asana workspace GID>' }
function Get-AsanaProjectGid   { '<the Asana project a mirrored task lands in>' }

# Which numbered section of that board each stage of the cycle IS. Optional -- omit it and the
# built-in map is used, which is right only if your board is numbered the same way.
function Get-AsanaStageMap {
    return @{
        Requests       = 1   # the submitter's inbox -- never a target, though cards do leave it
        NeedsInfo      = 2   # blocked on the submitter -- driven by the label below
        Filed          = 3   # project status Todo -- tracked on GitHub, nothing linked yet
        InDevelopment  = 4   # project status In Progress -- a pull request is linked
        InReview       = 5   # project status Done -- the issue is closed
        ReadyToTest    = 6   # the submitter has been TOLD -- their turn; never moved OUT of
        Completed      = 7   # the submitter says it is good -- never a target, never moved OUT of
        NeedsInfoLabel = 'needs-info'
    }
}

# Which GitHub Project status each of the three MIDDLE stages is. Also optional, and the two maps
# answer to two different boards -- this one is keyed on GitHub's own column names.
function Get-GithubStatusMap {
    return @{
        FieldName        = 'Status'
        Statuses         = @{
            'Todo'        = 'Filed'
            'In Progress' = 'InDevelopment'
            'Done'        = 'InReview'
        }
        # A regex over the Asana task's notes whose group 1 is the submitter's name -- the intake
        # form's own line. '' means stage 6 is never entered automatically; see below.
        SubmitterPattern = ''
    }
}

# The GID of the board's 'Github Issue' text custom field (Asana Field settings -> the field's own
# page shows its GID in the URL), so report-issue can set it at task creation with the full issue
# URL. Optional: $null (the default) means the board carries no such field and the step is skipped.
function Get-AsanaIssueFieldGid { $null }

# The GID of the board's 'Github Type' select custom field, so report-issue can set it at task
# creation from the issue type step 1 already chose. Optional in the same way: $null (the default)
# means the board carries no such field. The field's OPTION GIDs are not configured -- report-issue
# resolves Bug/Feature/Task by name from the project itself.
function Get-AsanaTypeFieldGid { $null }
```

**`SubmitterPattern` is the one value here that decides whether a whole column is used.** Stage 6 is
entered only once the submitter has been told, so a repo that names no pattern never enters it: every
closed ticket waits in `InReview` for a person. That is a working configuration and the safe default,
but it is *silent* -- so if the team expects an acceptance column to fill itself, this is the value
that makes it. Propose it against the wording the repo's intake form actually writes, and do not guess
it from `created_by`: measured on the BWJ board, the form creates every card as its own owner, so
`created_by` reads identically whether a colleague asked for it or a session filed it.

**Propose the stage map against the board you actually read in step 5, not against the example.** The
keys are the cycle and are fixed; the numbers are that board's and nothing else can supply them. Say
plainly that a wrong map is *silent*: every card lands a column early or late, on a board whose whole
job is telling somebody where their request is. It is a `.ps1` in the repo, so it goes through that
repo's ordinary branch and review route like any other change.

**Propose one value and say why it is the only one: `Get-AsanaProjectGid` is the board the team
reads.** That used to be an open BWJ decision -- one shared project or one per store -- and it is not
any more (Dave, September 2, 2026): there is exactly one board, and two independent constraints both
land on it.

- **The prio labels.** `Prio-Score` only reaches a task once it has actually been added to that task's
  project, via the project's own `custom_field_settings` -- sitting in the same workspace as the board
  is not enough to guarantee that -- so a task created in a project that does not carry the field can
  never carry a `Prio-Score`, and the sweep of
  [step 5](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/bwj-codex/WORKFLOW-portable.md#5-the-asana-prio-score-comes-back-as-a-github-label)
  then reaches only the tickets *imported from* the board
  ([#1213](https://github.com/DaveKJohn/claude-code-specialists/issues/1213),
  [#1386](https://github.com/DaveKJohn/claude-code-specialists/issues/1386)).
- **The stages.** They live on that board's own sections, so a task filed anywhere else sits on no
  pipeline and never moves a column -- see step 5 below.

**A provisional GID is where both costs land at once**, and neither says anything in a log: such a
ticket carries no prio label and never advances a stage. So if the real project is not known yet,
record that both are incomplete until it is.

**`Get-AsanaIssueFieldGid` is addressed by GID rather than by name, and that is worth flagging
because it breaks the pattern step 5's `Prio-Score` reading sets.** The reconcile sweep of step 5
looks that field up by *name*, because it is **reading** a task back and the Asana API hands back a
custom field's name alongside its value -- no GID needed. Creating a task and setting one of its
custom fields in the same call is the opposite direction: the `create task` call addresses a custom
field by its GID, which Asana Field settings shows on the field's own page, in the URL. **The same
per-project constraint
[step 5](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/bwj-codex/WORKFLOW-portable.md#5-the-asana-prio-score-comes-back-as-a-github-label)
already states for `Prio-Score` applies here too** -- an Asana custom field only becomes usable once it
has been *added to* a project via that project's own `custom_field_settings`, and definition in the
right workspace is not enough to guarantee that, so this GID has to come from a field that is actually
on `Get-AsanaProjectGid`'s own project. And it is **plainly optional**: `$null`, the default, means
the board carries no `Github Issue` field, and `report-issue` skips the write silently -- a repo
without the field loses nothing by leaving it unset.

**`Get-AsanaTypeFieldGid` carries every one of those properties and is not restated here** -- same
reason for a GID rather than a name, same silent-skip default, same constraint on where the field has
to live. **What differs is one level of indirection, and it is the whole reason this seam is only
half a seam.** A text field takes the value you send it; a select field takes the GID of one of its
own **options**, so writing `Task` means finding out what `Task` is called in GIDs first.

**Those option GIDs are deliberately not configured.** Three more values per repo, each pinning a
name somebody can rename or rebuild in the Asana UI without anything failing -- and unlike the field
GID they do not have to be pinned, because they are resolvable at run time from the project
`Get-AsanaProjectGid` already names. So this seam answers *which field*, and `report-issue` answers
*which option*, on a call it is already making. The one thing to tell the maintainer is what that
buys: rebuild an option and nothing breaks; **rename** one away from `Bug`, `Feature` or `Task` and
the write is skipped with a note rather than guessing, because an unmatched name on a board that
reads as authoritative is worse than a blank.

## 3 -- print the CI secret and variables (the maintainer sets these)

The CI workflow needs, on the repo (Settings -> Secrets and variables -> Actions):

- **Secret** `ASANA_PAT` -- an Asana personal access token with write access to the project.
- **Secret** `GH_PROJECT_TOKEN` -- a GitHub PAT that can **read the organization's Projects v2**.
- **Variable** `ASANA_PROJECT_GID` -- same value as `Get-AsanaProjectGid`.

Print these as a checklist. This skill does not set secrets.

**`GH_PROJECT_TOKEN` is not optional if you want the stage sweep**, and it is worth saying why rather
than listing it. The three middle stages are read off the project board's `Status` field, and
`GITHUB_TOKEN` -- the token the workflow gets for free -- **cannot see an organization's Projects v2 at
all**. There is no `permissions:` key that grants it; it is not a scope this workflow can ask for.

Without the secret the workflow still runs and the close update still goes out: the query retries once
without the project field, and the log says the status could not be read. **So the symptom is cards that
never move, with the reason in the run log** -- which is the right failure, but only if somebody reads
it. Say that plainly when you report, because "the mirror works" and "the board moves" are two claims
here and the first can be true while the second is not.

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

**And the `needs-info` label**, which is the entire mechanism for the board's blocked column: while it
is on an issue the card sits in `NeedsInfo` whatever the branch and the pull request are doing, and
taking it off returns the card to wherever the work actually is. Name it in
`Get-AsanaStageMap`'s `NeedsInfoLabel` if the repo prefers another word; set that to `''` and the
column is switched off, which is a real answer for a board without one.

```bash
gh label create needs-info --repo <owner>/<repo> --color d4c5f9 \
  --description "Blocked on the person who filed it -- parks the Asana card in the blocked column"
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
[step 6](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/workflows/bwj-codex/WORKFLOW-portable.md#6-the-boards-sections-are-the-cycle----one-card-one-column-per-stage)
reads a card's stage off the **number its section's name starts with**, and takes the *meaning* of
each number from `Get-AsanaStageMap`. **This step is where both halves are established, and it comes
before step 2's proposal can be written** -- read the sections of the project and report them:

```text
<N>. <anything>   ->  which stage of the cycle this column is
```

The words after each number belong to the team; only the number is read. **Report what you find and
change nothing** -- a board is a shared surface, and renaming somebody's column is not an adoption
step. Then map the columns you found onto the seven cycle stages and put *that* in the step 2
proposal. Four cases are worth naming explicitly when you report:

- **No numbered sections at all.** Nothing is ever moved on that board. That is the safe default, and
  it is *silent* -- so a board meant to be a pipeline and not numbered looks exactly like one that
  works. Say so plainly.
- **A gap in the middle** (say, no `4.`). Cards simply stop at the stage below it and the log says
  which section was missing. Nothing is created.
- **More columns than stages.** A board may have columns this cycle has no stage for. Leave them out
  of the map: an unnamed column is a **hold** -- not a target and not a source -- so cards parked
  there stay put. That is the intended way to keep a column out of the pipeline.
- **A board numbered differently from the example.** Then the example map is wrong for this repo and
  `Get-AsanaStageMap` is not optional. The board this model was first written against gained a column
  the same afternoon it shipped, which moved every stage above it by one -- so treat "the default
  happens to fit" as a claim to verify here, not to assume.

### And read the GitHub side of the same question

The three middle stages come from the **project board's `Status` field**, so that field is the other
half of this step. Read its options and report them beside the Asana columns:

```bash
gh api graphql -f query='
query { organization(login: "<org>") { projectV2(number: <n>) {
  fields(first: 30) { nodes { ... on ProjectV2SingleSelectField { name options { name } } } } } } }'
```

Three cases to name when you report:

- **The three defaults** (`Todo` / `In Progress` / `Done`). The built-in status map fits, and
  `Get-GithubStatusMap` is optional.
- **Renamed or translated columns.** Then the map is **not** optional -- the status names are its keys,
  and an unmapped column derives no stage, so cards simply stop moving.
- **A fourth column** (a `Blocked`, a `Icebox`). Leave it out of the map: an unmapped status is a
  **hold**, which is the intended way to park a card outside the pipeline.

**Also report which of the project's built-in workflows are enabled**, because they are what writes
that field: `Item added to project`, `Pull request linked to issue` and `Item closed` are the three
that matter. A board where those are off has a `Status` nobody maintains, and then this whole half of
the model reads a stale column -- which looks exactly like a board that works.

## 6 -- point the repo's governance at the rule

Add a line to the repo's `CLAUDE.md` (or a repo lens) pointing at
`~/.claude/plugins/marketplaces/claude-code-specialists/plugins/workflows/bwj-codex/WORKFLOW-portable.md`
so a session reads the BWJ ticket rule the same way it reads the other portable pages.

## What this skill does not do

- It does not enable the plugin -- that is a `.claude/settings.json` change you make first.
- It does not create the Asana project or token.
- It does not register this repo in the source repo's `connectors/` register -- that happens in the
  source repo after this repo's settings change has merged.
