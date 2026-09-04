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
**GitHub issue is closed, the Asana task gets an update** saying the work is built and ready to test,
naming the pull request that closed it
-- by a small GitHub Actions workflow this plugin ships as a template for each repo to copy into its
own `.github/`. Reopening the issue posts the counterpart; a daily reconciliation sweep carries over
anything a missed event left behind, without ever saying the same thing twice.

And that same daily run carries exactly one thing the other way: the Asana task's **`Prio-Score`**
becomes one of four prio labels on the GitHub issue (`very high` / `high` / `low` / `very low`), so
the priority the business sets on the board is readable where the work actually happens. It is the
only step that moves Asana -> GitHub, and the only thing this plugin writes outside Asana.

**It never ticks the task off, and it has no code path that could** (Dave, September 1, 2026): closing
the issue says the work is *built*, and only the colleague who asked for it can say it is *good*.
**A ticket that came the other way -- filed in Asana and copied into an issue for analysis -- is
covered too:** the workflow reads the Asana link in such an issue's header row when it carries no
machine marker of its own.

**And the card moves with it.** The board's sections **are** the cycle, in order, from *a colleague put
this on your name* to *tested and good*. Two questions, deliberately kept apart: a section is
recognised by the **number its name starts with**, so the words after it belong to the team and can be
rewritten any day; what each number **means** is stated once by the repo, in `Get-AsanaStageMap`. A
board whose sections are not numbered is never written to, and a column the map does not name is left
alone rather than guessed at.

**The three middle stages are the GitHub Project's three statuses, and always in sync with them** --
`Todo` / `In Progress` / `Done` are *filed* / *being built* / *closed*, read off the project board
rather than re-derived from the issue, because GitHub's own project workflows already write that field
and deriving it twice made two writers of one fact. `Get-GithubStatusMap` is where a repo states it.

**The stage past those is reached by FEEDBACK, not by a column:** a card moves to *ready to test* once
the submitter has actually been told, which is the workflow's own close update -- and where a ticket
has no submitter that stage is skipped entirely, because there is nobody to hand it to.

The two ends stay the submitter's -- their untriaged inbox at one end and `Completed` at the other --
and the code permits the middle and nothing else, which is the same guarantee as *"it never ticks the
task off"* in the board's own currency. **And the last two sections are terminal**: once a card is in
*ready to test* or `Completed`, nothing here takes it back out, not even a reopen. Moves are otherwise
forward, with exactly two exceptions that are both a person saying something: the `needs-info` label,
which blocks a card whatever the board is doing, and an issue being reopened. Dave, September 2, 2026, closing
[#1222](https://github.com/DaveKJohn/claude-code-specialists/issues/1222); **there is exactly one such
board**, which is what makes the *"which board?"* question inbound
[#1217](https://github.com/DaveKJohn/claude-code-specialists/issues/1217) ran into moot.

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

The `report-issue` skill needs to know which Asana workspace and project a mirrored task lands in,
and the CI mechanism needs the project. That is answered by a set of functions in your repo-owned
`scripts/repo-config.ps1` -- the same file `contributing-davekjohn` already dot-sources:

- `Get-AsanaWorkspaceGid` -- the Asana workspace GID.
- `Get-AsanaStageMap` -- which numbered section of the board each stage of the cycle is, plus the
  label that drives the blocked column. **Optional**: leave it out and the built-in map is used, which
  is right only if your board happens to be numbered the same way, and the run says which map it read.
  Semantic keys rather than GIDs, so a rebuilt column costs nothing.
- `Get-GithubStatusMap` -- which **GitHub Project status** each of the three middle stages is, keyed on
  the project board's own column names, plus `SubmitterPattern`: the regex over an Asana task's notes
  that names who asked for it. **Also optional**, with one consequence worth knowing: leave the pattern
  out and *ready to test* is never entered automatically, so every closed ticket waits a column short
  for a person. That is the fail-safe default rather than a fault -- a card pushed into the submitter's
  column claims a handover that never happened -- but it is silent, so it is worth stating deliberately.
- `Get-AsanaProjectGid` -- the project a mirrored task is created in, and it has exactly one correct
  value: **the board the team reads**. Two independent constraints land on the same answer. An Asana
  custom field only becomes usable once it has been added to a project's own `custom_field_settings`
  -- workspace membership alone does not establish that -- so a project the field was never added to
  makes the prio
  labels of
  [step 5](WORKFLOW-portable.md#5-the-asana-prio-score-comes-back-as-a-github-label) reach only the
  tickets imported from the board; and the stages of
  [step 6](WORKFLOW-portable.md#6-the-boards-sections-are-the-cycle----one-card-one-column-per-stage)
  live on
  that board's sections, so a task filed anywhere else is on no pipeline and never moves a column.
  Neither failure says anything in a log.
- `Get-AsanaIssueFieldGid` and `Get-AsanaTypeFieldGid` -- the GIDs of the board's `Github Issue` and
  `Github Type` custom fields, so a mirrored task carries the issue URL and the issue type from the
  moment it is created rather than waiting for somebody to type them in. **Both optional**, and
  `$null` -- the default -- is the common answer: most boards carry neither, and `report-issue`
  skips whichever is unset without saying anything. Where a board does carry one, leaving it unset is
  the state that costs something, because the field is then filled by hand or not at all.

`adopt-bwj-asana` **proposes** these, it never places them: they state what your repo *is*, and the
project may differ per brand. The CI half reads the project from the repo variable
`ASANA_PROJECT_GID` and its token from the secret `ASANA_PAT` -- it addresses every task by GID, so
it needs no workspace of its own.

## Enabling it

An ordinary plugin change: enable `bwj-codex` in `.claude/settings.json` alongside `team-alpha`
and `contributing-davekjohn`, then run [`adopt-bwj-asana`](skills/adopt-bwj-asana/SKILL.md) once.
Disabling it removes nothing it already wrote to your repo -- the CI workflow and the config stay;
the skill that reads them stops.
