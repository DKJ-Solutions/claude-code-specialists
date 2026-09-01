---
name: report-issue
description: >-
  File a discovered issue the BWJ way -- GitHub first (the source of truth), then a colleague-facing
  Asana task, cross-linked both ways. Use this in BWJ-ecommerce/smartwatchbanden or
  BWJ-ecommerce/xoxowildhearts whenever a real finding needs tracking: a bug, a broken customer-facing
  behaviour, a stale doc, a decision that is not yours to make. The GitHub issue always gets created
  even if Asana is unreachable, so the source-of-truth guarantee holds. It does NOT resolve tickets --
  closing the GitHub issue does that, via the asana-mirror CI workflow.
---

# report-issue -- the BWJ GitHub-first, Asana-mirrored filing procedure

This skill has **no script of its own** -- it is a procedure over `gh` and the Asana MCP, because the
colleague-facing translation is a judgement call, not a transform. The full rule it implements is in
[`WORKFLOW-portable.md`](../../WORKFLOW-portable.md); this page is the steps.

## Before you start

- Confirm you are in a BWJ store repo (`BWJ-ecommerce/smartwatchbanden` or
  `BWJ-ecommerce/xoxowildhearts`). This procedure applies nowhere else.
- Confirm `gh auth status` is clean.
- Read `Get-AsanaWorkspaceGid` and `Get-AsanaProjectGid` from the repo's `scripts/repo-config.ps1`.
  If either is missing, run [`adopt-bwj-asana`](../adopt-bwj-asana/SKILL.md) first.
- Confirm the Asana MCP tools are available in this session. If they are not, you still do step 1 and
  then stop with a clear note -- never skip the GitHub issue.

## Step 1 -- the GitHub issue (always)

Apply the `team-alpha` filing bar in full: verify the finding still stands by reading the code, doc
or output behind it; search the tracker for a duplicate; one subject per issue; state what you
measured versus inferred. Then:

```bash
gh issue create --repo <owner>/<repo> --title "<precise technical title>" --body "<full detail>"
```

Note the issue number and URL. If the finding collapses on verification, stop here and say so -- do
not file a weakened version, and do not create an Asana task for a non-issue.

## Step 2 -- the Asana task (a translation, not a copy)

Compose the task body from the fixed skeleton -- plain language, outcome-framed, no code or repo
jargon:

```text
What is wrong:   <one or two plain sentences -- what a visitor or colleague sees>
Where:           <which store, and which page or flow>
How urgent:      <blocking a sale / visible but not blocking / cosmetic / not customer-facing>
Tracked on GitHub: <issue URL>
```

Create it in the project `Get-AsanaProjectGid` names, in the workspace `Get-AsanaWorkspaceGid`
names, via the Asana MCP `create task` tool. Note the task GID and URL.

If Asana is unreachable: report the GitHub issue URL, say the mirror did not happen and why, and
stop. The issue can be mirrored later by re-running this skill's steps 2-3.

## Step 3 -- cross-link both ways

- **GitHub issue** -- append to the body (keep everything already there):

  ```text
  Asana: <task URL>
  <!-- asana-task: <numeric task GID> -->
  ```

  The marker holds the bare numeric GID only. `gh issue edit <n> --repo <owner>/<repo> --body "<full new body>"`.

- **Asana task** -- the `Tracked on GitHub:` line already carries the issue URL, so nothing more is
  needed unless you created the task before you had the issue URL; in that case edit the task notes
  to add it.

## Step 4 -- report

Give both URLs and stop. Do not resolve anything: when the GitHub issue is closed, the
`asana-mirror` CI workflow completes the Asana task on its own.
