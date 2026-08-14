# Adoption — connecting your repo to the specialists

**This page is the work that is yours no matter how the plugins reached you.** Installing them is a
separate matter and may already have been done for you: if your organisation publishes this family
through a marketplace of its own, the registration and the install happened once, centrally, and you
should not repeat them. If you came here to install it yourself, that half is
[INSTALL.md](../INSTALL.md) and you do it first.

What is on *this* page is the same in both cases. The plugins give you a team; connecting it to your
repo — the bootstrap, the roster, the lenses — is what turns that team into one that knows where it
is. **An unfilled lens does nothing.** That sentence is the reason this page exists as its own
document rather than as the back half of an install manual.

**Why the procedure is what it is** — which step was added when, and what was measured to justify it —
is not on this page. It lives in the release record:
[`releases/README.md`](../workflow-davekjohn/releases/README.md) indexes every version with the changes
behind it. This page tells you what to do; that one tells you why it changed.

> **Budget most of the time for the last step.** The bootstrap places the whole seam in seconds. Step 3
> — writing your roster and filling your lenses — is writing, and on a repo of ordinary size it is
> closer to half a day than to a command. That is not a warning about this page being slow; it is where
> the value is.

## Before you begin

Three things have to be true, and only the first one might not be:

1. **The plugins are installed and enabled for this repo.** If you installed them yourself, that is
   [INSTALL.md](../INSTALL.md). If they arrived through your organisation, this is already done — the
   specialists appear in your session as `@team-alpha:<name>` subagents.
2. **You have restarted the session since that happened.** A skill that ships inside a plugin only
   becomes available once the session has loaded the plugin.
3. **`specialists-init` is in your slash list.** That is the check for both of the above at once: if it
   is not there, nothing below will work and the problem is upstream of this page.

## What this gives you

Instead of one generic Claude, you work with a **team of specialized Claudes under one Chief of
Staff (Chris)**: every assignment is classified and delivered to the specialist with the right
playbook — a DevOps engineer for branches and PRs, a technical writer for docs, a copy editor
and code/security reviewers for the independent final pass before a PR or merge. Your repo stays in
charge: the governance (your `CLAUDE.md`, your safety rules) remains yours; the plugins only supply
the team and its playbooks.

The system consists of **teams and a workflow**: the repo-neutral core team `team-alpha` (always
enable it), three optional add-on teams, and exactly one **way-of-working** plugin, chosen from the two
the marketplace offers. Which specialists live in which plugin and who they are meant for is covered in
the [root README](../README.md).

**The workflow slot is different in kind, so decide about it deliberately rather than by habit — and
decide is the right word, because leaving it empty is no longer the default it once was.** Two plugins
answer "how does work move through this repo," and exactly one may be enabled: `workflow-default`, which
imposes nothing and asks the specialists to read what your repo already states about its own
conventions, and `workflow-davekjohn`, which carries no specialists at all but is DaveKJohn's own branch,
changelog and release method as skills plus scripts (`new-branch`, `open-pr`, `ship-pr`,
`fold-changelog`, `cut-release`, `park`, `fix-mojibake`). **`workflow-default` is the one this page's
default settings block enables, and it is the one to leave enabled** unless you deliberately want
`workflow-davekjohn`'s method instead. Two consequences worth knowing before you switch to it:

- **Switching onto it later is a plain enable + re-run of `specialists-init`**, which then adds the
  config it needs. Nothing has to be undone first.
- **Enabling it makes your repo owe it two files** — `scripts/repo-config.ps1` (repo name, lint gate)
  and `scripts/lib/branch-info.ps1` (your branch-prefix table). `specialists-init` scaffolds both, and a
  session check tells you if a function is missing. On `workflow-default` you are asked for neither —
  it reads your repo instead of asking you to configure it.


## The three steps

**Step 1 — run the bootstrap skill.** In the new session, invoke `specialists-init`. It sets up —
purely additively, without overwriting anything — the **lens-only** persona lenses (including
Chris) + an empty repo-lens scaffold per specialist in **the seam**
(`.claude/specialists/lenses/`), one `@`-import at the bottom of your `CLAUDE.md` pointing at that
seam (which in turn imports Chris's portable body from the plugin install + his repo lens), and a
proposal for safety settings (`settings.suggested.jsonc`, for your own
review). The details of this path are in the
[root README › Adoption](../README.md#adoption-the-bootstrap-path) — which counts the install as
"step 0" and this one as "step 1", because it numbers from before the point where this page starts.

**What it should report, so you can check it rather than trust it** (inbound
[#337](https://github.com/DaveKJohn/claude-code-specialists/issues/337)). With only the core `team-alpha`
plugin enabled, the closing line reads:

```
Done: 4 persona-lens(es) created, 0 already present; 15 lens-scaffold(s) created, 0 already present;
2 script-scaffold(s) created, 0 already present.
```

**4 personas + 15 subagent scaffolds = 19 lens files** in `.claude/specialists/lenses/`, plus 2 script
scaffolds and 1 `@`-import. Those figures used to appear only in the skill's own `SKILL.md`, which a reader
sees *after* invoking it — i.e. after the moment they would have needed them. This page is meticulous about
counting everywhere else (*"the count is part of the check, not a detail"*, as the install page puts it), and this was the
one step where the script prints numbers with nothing to compare them against.

**Read each pair as `created + already present`, not as a fixed number.** The sum is what this page
promises; the split depends on what your repo already had. A **fresh** repo — this step's own audience —
gets everything under `created`, which is the sample above. A repo that already had, say,
`scripts/repo-config.ps1` sees that one move to `already present` instead. So a figure that is *higher*
than the sample is not an error, and neither is one that is lower: what matters is that each pair adds up
and that the skill names anything it skipped. If you enabled an add-on team as well, expect its
specialists on top of these. `workflow-default`, on the other hand, changes nothing here: it carries no
specialists and needs no script scaffold, so this sample's numbers hold whether or not it is enabled
alongside `team-alpha`.

> The sample above was itself the finding: until August 2, 2026 it showed `0 script-scaffold(s) created,
> 2 already present` — captured in a repo that already had them, and therefore inverted for exactly the
> fresh-repo reader this section was written for (inbound
> [#358](https://github.com/DaveKJohn/claude-code-specialists/issues/358)). The guidance covered only the
> "lower than this" direction, so the one number that could not match had no explanation.

**And one thing it does that no document mentioned:** every file it writes uses **LF** line endings and
`CLAUDE.md` gets **no trailing newline**, on Windows too. Harmless while nothing is committed, but on a repo
whose files are CRLF this is the same class of lasting diff that
[INSTALL.md](../INSTALL.md) warns about for `claude plugin install` — and the missing final newline turns any
later hand-edit of `CLAUDE.md` into a two-line diff. If your repo cares, normalise once after the
bootstrap.

**Step 2 — restart and verify.** Start again and check that Chris takes the floor. What that looks
like: the turn **names the specialist the work belongs to, and why**, before doing it — Chris's ritual
step is *"This one is for \<name\> — \<reason\>."* So on an ordinary request you should see something
like:

```text
**This one is for Rebecca (Research Specialist)** — "what's in this repo" is internal repo
exploration, her domain.
```

**Check for the invariant, not for a fixed string** (inbound
[#361](https://github.com/DaveKJohn/claude-code-specialists/issues/361)). A named owner with a stated reason
is what the persona guarantees and what proves the orchestrator loaded; the exact shape is not fixed.
Some repos add a house style on top — a fixed header line per turn, emoji and all — but that is a rule
those repos write into their own `CLAUDE.md`, not something this plugin ships. Until August 2, 2026 this
step told you to look for `🧭 Chris — intake & routing`, which no bootstrapped repo emits: a
verification a fresh consumer could not pass, on the step that exists to prove the install worked.

**Step 3 — write the roster and fill the lenses.** This is the step where the system starts being
useful, and it is by a wide margin the largest one. The two steps above give you a team that knows its craft
and nothing about your repo; the lenses in the seam (`.claude/specialists/lenses/`) are where you say
what each specialist serves *here*. An unfilled lens does nothing — it is a scaffold with a `VUL-IN`
slot, not a default.

**The honest cost: budget half a day's worth of writing, not a command.** Concretely, on a repo of
ordinary size (measured during the August 3, 2026 adoption that produced inbound
[#408](https://github.com/DaveKJohn/claude-code-specialists/issues/408)):

- Chris's lens first — the roster and the routing table. Everything else refers back to it.
- Then the specialists that actually have work in your repo. In that measurement, 20 of the 25
  placed lenses got repo-specific content; the rest stayed `VUL-IN` on purpose.
- **A lens may stay empty, and that is a state rather than a backlog item.** Fill it on the day that
  specialist first has work.

Two things reliably surface in this step and are not caused by it, so plan for them rather than
diagnose them: a `.gitignore` that excludes `.claude/` and therefore the whole seam — check that
before you write anything, because every gate stays green while your lenses are untracked — and a
`scripts/repo-config.ps1` older than the current script contract (`Get-RosterPath`,
`Get-RosterIgnoredIds`), which `scripts/sync/check-script-contract.ps1` reports for you.

The worker specialists can be invoked directly as `@team-alpha:<name>` from the moment Step 2 is
done — with an empty lens they simply answer out of their portable playbook.

> **Do not attribute this half hour to the installer.** `specialists-init` places the seam, 25 lens
> files, the roster scaffold, the settings proposal and the `@`-import in **seconds**. The time here is
> yours, spent writing — which is why it is a numbered step rather than a closing remark.


## Undoing it — the half that is yours

Adoption is reversible by design, and the reversal is **two** removals that do not do each other's job:
taking the family out of *your repo*, and taking the plugin off *the machine*. The first is this page's
mirror image and is yours whatever channel you are on. The second is an install, so it belongs to
whoever did the installing — if that was your organisation, it is not yours to undo.

**Out of your repo** is the `specialists-teardown` skill: it removes the seam
(`.claude/specialists/`), the `@`-import in your `CLAUDE.md`, the settings proposal and the scaffolds
you never filled in. It is a **dry run by default**, because a script that deletes things in somebody's
repo should have to be asked twice — and the preview doubles as the inventory you say yes to. It
classifies before it removes: a lens still carrying its `VUL-IN` marker is generated and goes, a lens
**you filled in is yours** and is reported rather than touched. Read the `[remove]` and `[KEEP]` lines
rather than what is left on disk; a `[KEEP]` means *still there*, not *still working*.

The full procedure, including the machine half and the states it can fail in, is
[UNINSTALL.md](../UNINSTALL.md).

**What stays behind is not debt, mostly.** Your history stays — a changelog that mentions specialists
is an accurate record of something that happened. Lenses you wrote stay, as files nothing reads any
more. Roster rows and specialist names in your own prose stay, because no rule a script could apply
safely knows where a roster row ends and your writing begins.

**One leftover keeps talking, and it is the one to act on.** If the bootstrap created your `CLAUDE.md`,
two of its lines are its own — and `CLAUDE.md` is loaded into every session as project instructions. So
that file goes on telling every future session, in the channel that outranks its defaults, that this
repo is governed by a system that is no longer installed. The teardown reports those lines instead of
deleting them, deliberately: an `@`-import *loads* something, so removing it is safe and necessary, but
cutting sentences out of somebody's governance file to satisfy a counter is the wrong side of that
boundary. Delete them yourself, and the repo is genuinely free.

## Reporting back or improving something

- **An improvement to the shared core** (an agent def, playbook, persona, or skill): don't rework it
  locally, but report it as an issue on the source repo with the label `inbound` — an
  [issue template](../.github/ISSUE_TEMPLATE/inbound-improvement.md) is ready for that. It is processed
  through that repo's own chain, and the improvement comes back to every consumer via a release.
- **Repo-specific additions** belong in your own repo lenses in the seam
  (`.claude/specialists/lenses/`) — those are yours and do not travel with the plugin.
