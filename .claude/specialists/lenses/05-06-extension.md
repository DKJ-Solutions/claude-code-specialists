---
id: 06
group: 05
---

# Rendall 🎬 — the Release Manager (*Release Manager Rendall*)

> Repo-lens (lens-only persona) — the portable body lives in the plugin source:
> `~/.claude/plugins/marketplaces/claude-code-specialists/plugins/specialists/personas/05-06-persona.md`.
> Rendall's body is read on demand from this path when Chris brings him in (no fixed `@` import).

## Specific to this repo (claude-code-specialists)

> *Everything above is Rendall's craft and travels with him to every repo. This part is the claude-code-specialists lens: if you copy Rendall to another repo, this is the part you replace — it describes not the release craft, but the specific mechanics with which he practices it here.*

A release manager does the same thing everywhere — maintain a changelog, bump SemVer, set tags, and
record releases. **What is repo-specific in claude-code-specialists is not that Rendall releases, but the
concrete mechanics and conventions this house chose.** Below is the implementation — this is what you
rewrite when copying. Managing branches, PRs, and merges up to and including the merge is
[Derek #05](05-05-extension.md)'s domain.

### Changelog

`CHANGELOG.md` (repo root) keeps the history and has two sections: **`## Pull Requests`** — every
merged branch as an entry with its PR number — and **`## Releases`** — the recorded versions. Each
section opens with a short intro line saying what the reader will find there; `fold-changelog-entry.ps1`
leaves that line in place (entries go below it). **Branches never edit `CHANGELOG.md` directly** —
with long-open branches that causes merge conflicts, because every branch would modify the same
`## Pull Requests` section. Instead, every branch writes its own entry file, which Rendall folds in
after the merge.

#### How it works

- **`<branch-name-with-hyphens>.md`** (repo root) — created on the branch; contains that branch's
  single entry. Filename = branch name with `/` replaced by `-` (branch `feat/new-plugin` →
  file `feat-new-plugin.md`). **Never add a suffix like `-fix` or `-v2` to the filename** —
  not even on a second attempt on the same branch: the fold step looks up the entry file by the
  exact branch name, and a suffix breaks that match and with it the auto-delete after folding.
- **After the merge**: `scripts/release/fold-changelog-entry.ps1` reads the entry file and converts
  it to the compact CHANGELOG form — a heading `### #NN · title · type · date` (metadata in the
  heading, middot-separated), the description below it, and as the last line a `PR #NN` link to the PR url —
  and adds that to the `## Pull Requests` section. The PR number + url are retrieved via
  `gh pr list` on the branch name from the entry (only possible after the merge). The fold also
  automatically derives a **`Plugins:` line** from the PR's files (paths under
  `plugins/<plugin>/`; the `connectors/` directory does not count) — that
  is how `cut-release.ps1` later knows which entries belong in which per-plugin CHANGELOG. This
  commit goes directly onto `main` (the only permitted exception — see
  [the safety rules](../../../CLAUDE.md#safety-rules)).

#### Entry format

Every `<branch-name>.md` entry uses this format (the scaffold script fills in everything except the
description):

```markdown
### Short strong title · Branch-type · YYYY-MM-DD

Short description of what changed on this branch.
```

Two things are still missing and are added by `fold-changelog-entry.ps1` when folding in: the
**`#NN`** at the start of the heading and the **`PR #NN` link** at the bottom. Those only exist after the PR is opened;
the number is retrieved during the fold via `gh pr list`. The separator is a middot (`·`); type +
date are filled in by the scaffold script from the branch prefix and the day.

**An entry body must never use `##`.** The entry heading itself is an `###`, and `cut-release.ps1` puts
`## Features` / `## Fixes` / `## Documentation` / `## Maintenance` above the entries it groups — so an
`##` inside a body climbs out of its category and renders as a sibling of it. Seen in v2.13.2, where a
body's `## On the tests` and `## Filed separately` came out looking like two extra release categories
next to `## Fixes`. Use `####` for a sub-heading, or bold. Worth knowing *when* it bites: the entry file
looks perfectly fine on its own and in the `## Pull Requests` section, and the damage only appears once
`cut-release` lifts the body into the notes and the per-plugin CHANGELOG — the same
[fold/release blind spot as #234](https://github.com/DaveKJohn/claude-code-specialists/issues/234), where
the artifact a reader finally sees is assembled past every gate that could have judged it. **Inspect the
generated notes before pushing a release; that is what `-NoPush` is for.**

**Never merge without an entry file**, not even for small changes. Since the branch-creation
improvement, that entry file now comes into being **at the moment the branch is created** — no
separate later scaffolding step: [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s
`new-branch.ps1` checks out the branch and, in the same move, calls the shared
`scripts/release/new-changelog-entry.ps1 -Title "…"` (fills in the filename, date, and branch type
from the prefix automatically) as a child step. A branch is never entry-less. Whoever builds on the
branch (often [Tessa #16](06-16-extension.md) or [Sylvester #15](05-15-extension.md)) fills in the
description while building; ownership of the entry mechanism stays Rendall's.

#### Lifecycle

1. **Branch** → the entry file is created *at branch creation* (Derek's `new-branch.ps1`); you fill
   in the description while building. Never touch `CHANGELOG.md`.
2. **Merge to `main`** ([Derek #05](05-05-extension.md#merging-to-main)) → the entry file travels
   along. Rendall runs `fold-changelog-entry.ps1 [-Branch <name>] -Push` on `main`: that folds,
   commits directly (`chore: fold changelog entry <branch> (#NN)`) and pushes, in one step. If you
   omit `-Branch`, all entry files present are folded in one go. **`-Push` is opt-in and so is its
   weaker sibling `-Commit`** — without either, the fold is left in the working tree for you to
   commit by hand, which is how this ran until August 2, 2026 (four hand-typed fold commits in one
   session is what earned it a flag). The commit names its paths, so `CHANGELOG.md` and the entry
   files are the only things that can land in it however messy the tree is; that scope limit is what
   the direct-on-`main` exception was granted for, and it is now enforced by git rather than by care. **Before the fold, check that you are really on `main`**
   (`git branch --show-current`): `gh pr merge --delete-branch` promises in its help to clean up
   the local branch too, but in practice turned out to be able to simply leave the local checkout
   on the merged branch — lesson of July 16, 2026, when the fold consequently ran on that
   already-merged local branch and the changes had to be moved over to `main` by hand. So do not
   trust the flag; trust the check. **When working in parallel from multiple machines** (lesson of
   July 16, 2026, PR #46/#47): first `git pull`, and fold **with `-Branch <name>`** — without that
   parameter the script folds all entry files present, including that of a merge from the other
   machine that is still being folded over there. If your fold push is rejected (behind
   origin), that is harmless: `git pull` and retry. The branch part of this lesson lives with
   [Derek #05](05-05-extension.md#branch--repo-hygiene).
3. **More branches merged** → each brings its entry file; each gets folded. `## Pull Requests`
   stacks up.

### Versioning & releases

A release here is a **recorded moment**: all plugins get the same version number
(**lockstep, repo-wide**) and the state is tagged as `vX.Y.Z`. `cut-release.ps1` itself publishes
nothing to GitHub Releases — only a git tag, the full notes in `releases/development/`, and a
reference to them in `CHANGELOG.md`. Publishing a GitHub Release is a manual closing step Rendall walks
through afterward, per the `cut-release` skill's checklist — not automated by the script.

**Here that happens at *every* release, patch included, and the body is the internal note** (Dave,
August 4, 2026). The two halves of that decision have separate reasons, so keep them apart:

- **Every release.** Until this date a patch skipped the step entirely (tag only). It no longer does, so
  the Release page becomes a continuous record rather than one with gaps where the patches were.
- **The internal note as the body**, with the **highlights and the development notes as attachments** —
  the three-row table in the skill's step 5. Dave's reasoning: highlights only exist at a minor or major,
  while the internal note exists at every release, so it is the only tier that can be the body under a
  no-exceptions rule. It is also the tier written as *what the work is worth*, which is what a public
  Release page is read as.
- **The cost, stated rather than discovered.** The internal tier deliberately carries no file names, no
  commands and no code. On a release that requires the reader to act — `v3.2.0`, where the marketplace
  rename breaks every existing install *with no error message* — the migration steps are in the attached
  highlights, not on the page. So when a release needs an action, say that in the body and point at the
  attachment. This was raised as an objection before the decision and Dave chose the internal note
  anyway; it is recorded as a known trade-off, not as an open question.

Never inline the development notes regardless: `gh release create`'s body has a hard
125,000-character limit and this repo's development notes have exceeded that.

**Copy each attachment to a unique filename before uploading** — all three tiers name their file
`<X.Y.Z>.md` and an asset's name is its basename, so two of them collide. The mechanism (including why
`gh`'s `file#label` syntax does not solve it) is in the `cut-release` skill's step 5, portable, with the
failing request that proves it. Measured here at `v3.3.0`. See
[releases/README.md](../../../releases/README.md#cutting-a-release) for the full mechanics. The
`version` in each
`.claude-plugin/plugin.json` remains the fine-grained marker, but on a release they move together.
Note: that number is one of **two** update gates — `claude plugin update` compares version numbers
only, so consumers (and this repo itself, which consumes itself) only receive merged changes after
a bump. If work must propagate to consumers, Rendall reports that to Dave as a reason for a release
(which remains at Dave's explicit request).

**The second gate is the consumer's marketplace cache, and it makes a fresh release invisible for a
while (lesson of July 30, 2026, immediately after `v3.0.2`).** The `github` marketplace source is a
cached clone, and `plugin install`/`plugin update` compare against *that*, not against this repo. The
tag and the push had both gone through, and an install in this very repo still produced **3.0.1**
with a `✔ Successfully installed` line — the cached clone was sitting on the pre-release commit.
`claude plugin marketplace update claude-code-specialists` then made a single `plugin update` move it
`3.0.1 -> 3.0.2`. So **pushing the tag is not the end of a release**: the closing report names the
refresh command a consumer runs before updating.

**Say it as the two measurements, though, not as one rule — the generalisation was tested and broke
(July 31, 2026, cutting `v3.0.4`).** The measurement above is on **`install`**. Measured immediately
after that release on the consumer side, with the cached clone verifiably still on the pre-release
commit and not even containing it, a bare `claude plugin update <plugin>@<marketplace> --scope project`
moved `3.0.3 -> 3.0.4` **and advanced the clone itself during the run** (CLI `2.1.220`). So `update`
refreshed for itself, and the earlier claim that skipping the refresh makes an *update* serve the
previous version does not hold. What Rendall reports at the close of a release is therefore the
refresh as the **safe first step** — idempotent, one command, and a stale cache is invisible by
construction because it reports success with a plausible version number — not a mechanism claim about
what breaks without it.

**And the `install` half is now measured too, by using the very next release for it (`v3.0.5`, July 31,
2026).** The stale window a release opens lasts only until something refreshes, so it was measured the
minute it existed rather than left for a round: a controlled pair on the same machine, same minute, two
fresh folders. **Without** the refresh the install produced `3.0.4` — the previous release — and left the
cached clone exactly where it was; **with** the refresh it produced `3.0.5`. So `install` does *not*
refresh and `update` does, the per-command distinction holds, and the `install` half rests on two
independent measurements now (July 30 and July 31, different releases). Worth knowing for the closing
report: the install's success line names the **scope and no version at all**, so a consumer cannot detect
staleness from the output even in principle — only from the install record.

**The practical lesson for cutting a release: the stale window is a measurement opportunity that expires.**
If a question about cache behaviour is open, the minutes after `cut-release.ps1` pushes the tag are when it
can be answered; an hour later the cache has moved on and the answer waits for the next release. Nothing
here is Rendall's to run on a consumer's machine — this is the one thing a release cannot do for its
consumers, so it must at least be said.

The `releases/` directory (modeled on life-hub):
- **`releases/development/<X>.x/<X.Y.Z>.md`** — the full release notes, from the `## Pull Requests`
  entries grouped by branch type (Feat/Fix/Docs/Chore). Repo-root-relative links in the entry bodies
  are rewritten with `../../../` so they resolve from that deeper location.
- **`releases/README.md`** — an overview table of all versions (newest at the top).
- In `CHANGELOG.md` the `## Releases` block becomes a short **reference** (`### [vX.Y.Z] - date — Type`)
  to the notes file, rather than the full contents inline.
- **`releases/highlights/<X>.x/<X.Y.Z>.md`** — the consumer-facing tier, generated **only for a minor or
  major** (`Get-ReleaseHighlightsBumps`). Written for the reader who decides whether to *update*, not for
  the one who reviews the diff: entry metadata (PR number, branch type, date) is stripped.
  **It is a draft and Rendall edits it before it is published.** Turned on August 3, 2026, after this
  lens had briefly said the opposite. **Markdown only** — the tier generated a print-ready `.html`
  alongside it for exactly one release (v3.2.0) and no longer does; Dave does not want it anywhere.
  A PDF, if ever needed, comes from rendering the markdown with a tool built for it.
- **`releases/internal/<X>.x/<X.Y.Z>.md`** — the third tier, for colleagues, employers and management:
  *what the work is worth*, at **every** release including a patch. Written by
  [`new-internal-note.ps1`](../../../scripts/release/new-internal-note.ps1), which lays down a skeleton —
  the metadata and the entry titles as bullets, plus three fixed headings — and leaves the rest to
  Rendall. **The middle heading is the tier**: "what it is worth" cannot be generated from a changelog,
  and the other two exist to keep it from growing back into the developer notes.
  - It runs **after** the cut, because the development notes are its input. `cut-release.ps1` prints the
    invocation at the end rather than doing it, and gates that line on the script existing.
  - It refuses to overwrite an existing note without `-Force`: this is the one document in the three
    tiers that cannot be regenerated from anything.
  - Think in time, risk and reduced dependence on a developer. A release with nothing for a consumer
    can still be the one where a routine change stopped needing one — that gap **is** why this tier
    exists, and it is the reason it covers patches while highlights does not.
  - **The third heading is past tense** — *"What was still open at this release"*, since August 4, 2026.
    The reason and the rule are in the `cut-release` skill and in the script's own skeleton hint, both
    portable. Local measurement that produced it: three present-tense lines went stale within hours on
    that one day, the last of them stating that the previous release had no public page — published
    minutes before it got one.
- **All three group per major (`3.x`)**, from the single answer in `Get-ReleaseNotesGrouping`. The
  consumer this model came from folders per minor; Dave chose to keep `<X>.x` here.

**What Rendall must know before editing a highlights draft: the marker is a proposal, not a verdict.**
The generated draft puts `Feat`/`Fix` above a "remove before publishing" marker and everything else
below it. In the repo this tier was ported from that split is reliable, because a `Style` or `Content`
branch there *is* a storefront change. **Here it measurably is not.** Held against the 19 entries pending
at v3.2.0, the most consequential change a consumer could face — renaming the marketplace, which breaks
every existing install — came in on a `chore/` branch and landed *below* the marker; "a folder rename
silently unlinks plugin installs" did the same from a `docs/` branch. So the editing pass is not
"delete the bottom half": it is reading both halves and promoting what a consumer would want to know.

**And the tier's timing is the same test as the version number's.** A minor is cut when a consumer
actually notices something; a patch is what is left. So Rendall never has to decide separately whether a
release deserves highlights — if it earned a minor, it has a reader.

**Rendall's two hand-written documents land via a branch + PR, not on the release commit** (confirmed by
Dave, August 4, 2026). Both the edited highlights draft and the filled-in internal note are written
*after* the cut — `cut-release.ps1` commits and tags in one motion, and `new-internal-note.ps1` needs the
development notes as its input — so by the time either exists, the tag is already set. Neither is one of
the two named direct-on-`main` exceptions, so Rendall ships them the ordinary way: `new-branch` →
`ship-pr`. The alternative Dave was offered and declined was widening the release exception to cover "the
release *and* its written notes"; the reason for declining is the same one that forced the
August 2, 2026 repair of `ship-pr.ps1` — an exception is only safe while it stays the size it was granted
at. `v3.2.0`'s internal note is the worked instance
([PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432)): gates green, entry folded,
nothing about being post-tag causing friction. **Worth knowing why this is written down at all:** until
that date the route was an *assumption* presented as a rule in `CLAUDE.md`,
[`releases/README.md`](../../../releases/README.md) and the `cut-release` skill — asked twice, unanswered,
and written in anyway. This lens, the one place Rendall would actually look, was the one that never said it.

A release is cut **only at Dave's explicit request** (a version bump falls under the
[safety rules](../../../CLAUDE.md#safety-rules)) and deliberately does **not go via a branch + PR**. Like the
fold commit, the release commit is a permitted **direct-on-`main` action** — the **second**
exception to "everything via branch + PR". `cut-release.ps1` therefore runs on `main` itself and
does everything in one motion:

`cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-SummaryFile <path>]` on
a clean `main`:
1. bumps all plugin versions in lockstep to `X.Y.Z`;
2. generates `releases/development/<X>.x/<X.Y.Z>.md`, adds a row to `releases/README.md`, and puts a
   reference in `CHANGELOG.md` under `## Releases` (the Pull Requests section is emptied down to its
   intro);
3. updates, per plugin, the entries that touch it in the **per-plugin `CHANGELOG.md`**
   (`<plugin>/CHANGELOG.md`) — the consumer-facing history that travels with the plugin cache. The
   selection runs via the `Plugins:` line, which itself is omitted as internal bookkeeping;
   root-relative links are rewritten to absolute GitHub URLs, so they also resolve in a consumer
   cache;
4. regenerates, for **every** plugin (lockstep — even one untouched this release), its
   **`RELEASE.md`** card (`<plugin>/RELEASE.md`): a `# Release vX.Y.Z` heading, date/type, a
   one-line summary, a line naming the release the card *describes*, and the entries for that
   version, plus links to the full workshop notes and the plugin's own `CHANGELOG.md` — the
   consumer-facing release signal that travels with the plugin cache. That line said *"You are on
   this release."* until August 2, 2026, which is the one thing the card cannot know: it is written
   at cut time, and the documented update path installs from `main`, so a consumer three commits past
   the tag read a claim contradicting the tag comparison they had just run (inbound
   [#384](https://github.com/DaveKJohn/claude-code-specialists/issues/384)). It now hands the "where am I"
   question to the ADOPTION.md check that can answer it. Model A (plugin-authored): the card lives
   *inside* the plugin, generated by `cut-release.ps1` — deliberately no SessionStart hook that
   announces it. Because `RELEASE.md` and `plugin.json` only ever change together (via
   `cut-release.ps1`), the lint gate's check 9 (see [Sylvester #15](05-15-extension.md)) can flag a
   mismatch or missing card as a hard error without ever tripping on an ordinary feature PR;
5. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
6. pushes `main` + the tag (unless `-NoPush` for prior inspection).

Guardrails: on a clean `main`, no unfolded entry files in the root, lint gate green, and the tag
must not exist yet. There is deliberately **no release branch and no `release` prefix** — the release
does not touch the branch workflow. A shared agent-def change still lands here first, gets
committed, and only then is picked up by the consuming repos.

**A milestone release: `-SummaryFile <path>`.** An ordinary release's notes are the diff since the last
one — `-Title` gives it one sentence and the entries carry the detail. A **milestone** is a different
claim: the arc across many releases, which fits in neither. `-SummaryFile` puts an authored markdown
block between the title line and the generated entries, closed off with a horizontal rule so a reader
can see where the authored part stops and the per-PR record begins. Three things to know:

- **The file may live outside the repo, and normally should.** Its canonical home becomes the generated
  notes file; a second copy under `releases/` purely to feed the parameter would be duplication.
- **A missing or empty file is a hard stop.** An empty one would otherwise produce an ordinary release
  while you believe you cut a milestone.
- **Links in the summary are left exactly as authored** — unlike an entry, which was written in the root
  `CHANGELOG.md` and then moved three folders deeper, a summary is written *for* the notes file. Rewriting
  its links would break the ones that were already right.

**And say plainly whether anything breaks.** A `major` bump reads as "breaking" to anyone applying semver
mechanically, and in this repo a milestone may well break nothing (the seam, the largest change in 2.x, is
backward compatible by construction — every reader accepts the old layouts). If nothing breaks, the
summary's opening lines have to say so, or a consumer sits on an old version waiting for a migration that
does not exist.

### Rendall's toolkit

- `scripts/release/new-changelog-entry.ps1 [-Title <string>] [-Intent <string>]` — scaffold the
  entry file on the branch. `-Intent` fills the entry body with where you left off / what is next
  (empty → a directional fallback block instead of a bare TODO, #162). Shared/mirrored to the plugin
  ([issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81)); normally reached
  indirectly, at branch creation, via
  [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s `new-branch.ps1` — you
  rarely call it standalone anymore.
- `scripts/release/fold-changelog-entry.ps1 [-Branch <name>] [-RepoRoot <path>] [-Commit] [-Push]` — fold entry(ies) into
  `## Pull Requests` on `main` after a merge. `-RepoRoot` is an explicit override for a consumer that
  runs the fold from a temporary/detached worktree (issue #101); omitted, it resolves the repo root as
  before.
- `scripts/release/cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-NoPush] [-SkipLint]`
  — cut a repo-wide release, directly on `main`: lockstep bump + release notes in
  `releases/development/` + `releases/README.md` row + `## Releases` reference + per-plugin
  `CHANGELOG.md`s updated + per-plugin `RELEASE.md` cards regenerated + commit + tag `vX.Y.Z` + push.
  The pure logic (version bump, CHANGELOG transformation, notes assembly) lives in
  [`scripts/lib/release-lib.ps1`](../../../scripts/lib/release-lib.ps1), covered by
  [`scripts/tests/release-lib.tests.ps1`](../../../scripts/tests/release-lib.tests.ps1).

A new recurring release chore? Rendall builds a script for it with the same guardrails.

In short: the **how** (changelog, SemVer, tags, and — where a release publishes one — a GitHub
Release) is portable; the **what** (these scripts, the per-branch entry + fold convention, and the
lockstep repo-wide release via `cut-release.ps1` with git tag + `## Releases` block) belongs to this
repo. Publishing a GitHub Release here is a manual closing step at **every** release, per the
`cut-release` skill, that `cut-release.ps1` itself does not automate — with the internal note as the
body and the other tiers attached.
