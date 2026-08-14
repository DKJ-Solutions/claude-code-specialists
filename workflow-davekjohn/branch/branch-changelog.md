## `feat/claude-code-workflows` changelog

### Branch title

Claude Code review and mention workflows, hardened before they land

### Branch ID

20260814-152819

### Branch type

feat

### What does the change on this branch bring to main?

Two GitHub Actions workflows now sit beside `ci.yml`: `claude.yml`, which answers an `@claude` mention
in a comment, and `claude-code-review.yml`, which reviews every pull request. They landed through
[PR #658](https://github.com/DaveKJohn/claude-code-specialists/pull/658) (merge `3a79e3c`).

**This entry exists because that merge could not write one.** PR #658 was opened by the GitHub App
installation flow rather than by `new-branch`, so it carried no changelog entry, no step list, and a
branch name (`add-claude-github-actions-1786697157488`) that `Test-BranchName` refuses outright. Nothing
was wrong with the change; the route simply bypassed the machinery that records it, and without this
branch the repo would have gained a CI layer that `CHANGELOG.md` and the release documents never mention.
The three documents that describe that layer are corrected here for the same reason: `README.md`'s repo
layout still enumerated `.github/` as holding one workflow, Sylvester's lens owned only `ci.yml`, and
`workflow-davekjohn/CONTRIBUTING.md` left a contributor unable to tell which of the two checks on their
PR blocks the merge. The root `CONTRIBUTING.md` is deliberately left alone: it names `lint-en-tests` as
the required check, which stays exactly true, and that page is the thin standard-workflow layer.

**Four hardening changes went in before the merge, out of a security review of the diff.** They are
recorded here rather than only in the files, because three of them are decisions that read as arbitrary
to whoever finds them later:

- **Both actions are pinned by commit SHA** instead of the moving `v4`/`v1` tags. This repo is a public
  plugin source, so anyone able to move a tag reaches every consumer through its CI.
- **`claude.yml` runs on a read-only tool allowlist.** Upstream's own configuration doc states the
  default set covers *"reading, committing, editing files"* — so without this, an `@claude` mention could
  produce a branch and a commit that passed none of this repo's gates. The three `mcp__github_ci__*`
  tools are named explicitly, because the `actions: read` permission in that file exists to enable
  exactly them and an allowlist omitting them would switch that capability off in silence. The
  consequence is stated in the file so nobody debugs it as a fault: `@claude fix this` now answers with
  what it would change, and does not change it.
- **The `issues: [opened, assigned]` trigger is gone**, so an outsider's issue body cannot start a run at
  the moment it is filed. The action's write-access gate governs *who triggers*, not *who wrote the text
  that is then read* — and this repo publishes an `inbound` issue template, which makes external prose a
  designed-for input rather than an edge case. Upstream states its sanitisation is best-effort and
  recommends reviewing raw external input first.
- **Both files now record that their `permissions:` block is not the boundary.** `id-token: write` lets
  the action mint a GitHub App token documented as Contents, Pull Requests and Issues at read **and**
  write; the read-only scopes in the workflow bound `GITHUB_TOKEN` only. A reader auditing either file
  would otherwise conclude the opposite of what is true.

**The plugin marketplace is deliberately left unpinned, and that is the half worth keeping.** The obvious
fifth change was to pin `code-review@claude-code-plugins` too. Both inputs were read in the action's own
`action.yml` before anything was written: `plugin_marketplaces` takes *"Git URLs to install from"* and
`plugins` takes plugin names, and neither those descriptions nor `docs/usage.md` documents a ref, tag or
commit syntax. So no syntax was invented — this repo has already paid for a proposal that named a
mechanism which did not exist ([#566](https://github.com/DaveKJohn/claude-code-specialists/issues/566)),
and a comment in the file states the real remedy instead: drop the plugin and write the review prompt
inline, if the dependency does not earn its place.

**One question could not be answered from here and is recorded rather than guessed.** Whether the Claude
GitHub App sits in the `main-ci-gate` ruleset's bypass list decides whether the App token can reach the
trunk past the required check. Three endpoints refused to return `bypass_actors`, so it needs a look at
Settings → Rules.

### Significance

#### Tier 0

Every pull request now carries a second check, and an automated review lands on the diff before a person
opens it. The hardening is the part that matters longer: the read-only allowlist is what keeps a
`@claude` mention from producing a commit that skipped the branch prefix, the changelog entry, the step
list and the `open-pr` gates — the whole apparatus this repo runs on.

**Score:** 3

#### Tier 2

These are this repo's own `.github/` files. They are not plugin payload, so a consumer receives nothing
through a plugin update and nothing changes in any tree but this one. The reasoning above is portable if
a consumer installs the same action, but it reaches them as prose in a changelog they can read, not as
something that arrives and takes effect.

**Score:** N/A

### Pull Request
