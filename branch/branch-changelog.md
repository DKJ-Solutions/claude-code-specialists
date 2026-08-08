## `docs/the-plugin-serves-the-consumer` changelog

### Branch title

The plugin serves the consumer's repo

### Branch ID

20260808-094102

### Branch type

docs

### What does the change on this branch bring to main?

`README.md` states what the plugins promise a repo that installs them: **a consuming repo is unique and
has its own way of working, and the specialists adapt to it.** This repo's branch-and-entry model, tier
ladder, fold and cut are its own answer, not a standard a consumer inherits — with one named exception,
the author, who runs the plugins across several of his own repos and deliberately keeps one way of
working across them. His way of working therefore has to be available as something switched on per repo
rather than as what a stranger receives by default.

From that follows one test question for everything added to a plugin from here on: **does this describe
a craft, or a way of working?** A craft is portable and adapts; a way of working belongs to whoever
authored it and is opt-in.

The section carries the measurement that made writing it necessary, because the core did not pass its
own test: of the 1,973,691 bytes `specialists` shipped on August 8, 2026, the personas, agent defs and
manuals were 175,672 — **9%** — while the shared scripts, the seven workflow skills and the session
hooks came to 923,277, or **47%**. It also locates the leak rather than only naming it. The persona
layer was already clean (no file under `personas/`, `manuals/` or `agents/` names `CHANGELOG.md`,
`branch/`, `open-pr`, `ship-pr` or `cut-release`), so how a specialist is described was never the
problem; what shipped alongside them was.

And it names the instance that reads as compliance, which is the one worth recording: `repo-config.ps1`
looks like the seam that makes the workflow adaptable, but its 19 functions tune *parameters* of a
single changelog model that `entry-scaffold-lib.ps1` fixes. `check-script-contract.ps1` then enforces
that a consumer supplies those functions — so a repo that worked differently was not adapted to, it was
told at every session start that it was misconfigured.

This branch changes documentation only. It sets the measuring stick that the following branches are
held against; it does not itself move anything out of the core.

### Significance

#### Tier 0

The test question is now a written rule with a measurement behind it, so the next addition to a plugin
is judged against something instead of against whoever is in the room. This is the branch every
following one in this movement cites.

**Score:** 3

Is there a tier 1?

#### Tier 1

The doctrine is the yardstick for the split that follows. Without it, moving scripts between plugins is
a reorganisation somebody can undo on taste; with it, the destination of every file has a stated reason.

**Score:** 3

Is there a tier 2?

#### Tier 2

*"Will this force its workflow on my repo?"* is the first question anyone evaluating an agent plugin
asks, and the landing page now answers it in its own words instead of leaving it to be inferred. Held
to 2 rather than higher on purpose: this branch makes the promise explicit, it does not yet change what
a consumer receives — the machinery behind it lands in the branches that follow.

**Score:** 2

### Pull Request

