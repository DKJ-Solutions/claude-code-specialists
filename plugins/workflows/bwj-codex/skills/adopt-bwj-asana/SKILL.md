---
name: adopt-bwj-asana
description: >-
  One-time setup of bwj-codex in a BWJ store repo (smartwatchbanden or xoxowildhearts): copy the
  asana-mirror CI mechanism into .github/, propose the Asana config seam for scripts/repo-config.ps1,
  and print the repo secret and variables the CI needs. Strictly additive and dry-run by default; it
  never overwrites an existing file. Run this right after enabling the plugin, or when report-issue
  reports the Asana config seam missing.
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

Whether both BWJ stores mirror into one shared project or one project each is a BWJ decision; the
function returns whatever this repo sets. The two repos must make the same *kind* of choice.

## 3 -- print the CI secret and variables (the maintainer sets these)

The CI workflow needs, on the repo (Settings -> Secrets and variables -> Actions):

- **Secret** `ASANA_PAT` -- an Asana personal access token with write access to the project.
- **Variable** `ASANA_WORKSPACE_GID` -- same value as `Get-AsanaWorkspaceGid`.
- **Variable** `ASANA_PROJECT_GID` -- same value as `Get-AsanaProjectGid`.

Print these as a checklist. This skill does not set secrets.

## 4 -- point the repo's governance at the rule

Add a line to the repo's `CLAUDE.md` (or a repo lens) pointing at
`~/.claude/plugins/marketplaces/claude-code-specialists/plugins/workflows/bwj-codex/WORKFLOW-portable.md`
so a session reads the BWJ ticket rule the same way it reads the other portable pages.

## What this skill does not do

- It does not enable the plugin -- that is a `.claude/settings.json` change you make first.
- It does not create the Asana project or token.
- It does not register this repo in the source repo's `connectors/` register -- that happens in the
  source repo after this repo's settings change has merged.
