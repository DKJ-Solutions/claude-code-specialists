---
name: report-issue
description: >-
  File a discovered issue the BWJ way -- GitHub first (the source of truth, classified at creation with
  its issue type and the `tier-1` reach label), then a colleague-facing Asana task, cross-linked both
  ways. Use this in BWJ-ecommerce/smartwatchbanden or BWJ-ecommerce/xoxowildhearts whenever a real
  finding needs tracking: a bug, a broken customer-facing behaviour, a stale doc, a decision that is
  not yours to make. The GitHub issue always gets created
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
measured versus inferred. Then file it **classified** -- the type and the labels are set at creation,
never left for a later pass:

```bash
gh issue create --repo <owner>/<repo> --title "<precise technical title>" --body "<full detail>" \
  --type <Task|Bug|Feature> [--label tier-1] [--label documentation]
```

| what to set | how to decide it |
|---|---|
| `--type` | **Bug** for a defect in behaviour that already exists, **Feature** for a capability the store does not have yet, **Task** for everything else -- which is most of it, doc findings included. Always one of the three; the `BWJ-ecommerce` org has no others |
| `--label tier-1` | **only** where management or the commissioner would notice it. The test is whether that reader notices the **defect**, not whether the file renders to them: a customer-facing template with a developer-only defect is tier 0, and a build script whose breakage stops a release the business is waiting on is not. **In doubt, leave it off** |
| `--label documentation` | on a doc finding, on top of its type -- the one content distinction the three types cannot express here |

**Do not add `bug` or `enhancement`.** Both labels were deleted from both repos on September 1, 2026
because the issue type already carries them. The reasoning behind all three fields is in
[`WORKFLOW-portable.md`](../../WORKFLOW-portable.md#classify-it-as-you-file-it----three-fields-all-set-at-creation).

Note the issue number and URL. If the finding collapses on verification, stop here and say so -- do
not file a weakened version, and do not create an Asana task for a non-issue.

**On an issue that is already filed** -- yours from an earlier run, or somebody else's -- the same two
fields are set afterwards:

```bash
gh api --method PATCH repos/<owner>/<repo>/issues/<n> -f type=Bug
gh issue edit <n> --repo <owner>/<repo> --add-label tier-1
```

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

**Name the type and the tier you chose, and why.** You infer both rather than asking for them -- the
reach question is answerable from the finding itself, and the whole backfill of 135 issues was
classified from the issue text alone. Naming the call here is what makes it correctable: it puts the
answer in front of the person who knows the store, at no extra turn, beside the one line that changes
it (`gh issue edit <n> --repo <owner>/<repo> --add-label tier-1`, or `--remove-label`).
