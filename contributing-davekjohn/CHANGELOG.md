# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `docs/v4-22-0-note-correction-v1` · 20260828-210436

The published `v4.22.0` note stops telling its readers that the test suites cost 443s, and stops
attributing a red gate run to who invoked it.

Both statements were falsified hours after publication, by the verification of the inbound report the
release's own gate trouble produced ([#1033](https://github.com/DaveKJohn/claude-code-specialists/issues/1033)),
and [#1038](https://github.com/DaveKJohn/claude-code-specialists/issues/1038) filed them rather than
repairing them -- correctly, since that was not #1033's assignment. It framed the repair as an open policy
question: correct in place, annotate, or leave standing.

**It is not an open question, and the answer splits the note's claims rather than covering them all.**
`RELEASES-portable.md` already gives the test -- *not whether the line is wrong now, but whether it was
wrong when it was typed*. The table row `54 suites at 443s` was true when typed: that leg took that
long, and recording elapsed time is the row's whole job, so it is **frozen and untouched**. The two
sentences built on top of it were false when typed --
the gate costs about 200s on that tree, and `cut-release.ps1:262,275` dot-source `repo-config.ps1` and
`native-capture-lib.ps1` before calling it, so no caller axis ever existed -- and those are **corrected**,
each marked *(Corrected -- see below.)*. The form is PR #694's, which corrected the `v4.11.0` note the same
way.

One thing was measured rather than assumed, and it is the part a reader cannot get anywhere else: the two
halves reached readers differently. The frozen attachment `v4.22.0-notes-for-users.md` carries the 443s
claim, and does **not** contain the caller attribution at all -- that sentence was written into the repo
copy afterwards, in the release-notes commit, so the asset still ends its timing section at *"the total is
added in a second pass"*. The new `## Correction to this page` section says exactly that, alongside what
each line first said and what the five re-runs measured.

**Score:** 2

#### What makes this deploy extra special

A published record was corrected without being rewritten, and the seam between those two things is now
demonstrated rather than merely stated. The published-record rule's own distinction -- protect what was
true, correct what was false -- had only ever been exercised on a line that was plainly false on the day.
Here it had to be applied *within a single paragraph*, separating a clock reading that stands from the
argument built on it that does not, which is the harder and far more common shape.

**Score:** 1

#### Pull Request

The v4.22.0 note's falsified gate cost and caller attribution, corrected

[PR #1040](https://github.com/DaveKJohn/claude-code-specialists/pull/1040)

---

### DEPLOY: `fix/park-cycle-resurrects-shipped-branch-v1` · 20260828-203741

The Stop hook no longer puts a shipped branch back on `origin`. `park-cycle.ps1`'s PR bound asked
`gh pr list --state open`, so it lifted the moment a PR merged -- and on the machine that merged, a
pruned remote-tracking ref then read as "a local commit nobody can see", and the hook pushed the branch
back seconds after `deleteBranchOnMerge` had removed it. Measured on PR #1027: merged 12:56:25, deleted
12:56:27, re-created 13:05:30, at the PR's own head OID with nothing on it `main` did not already have.

That quietly undid the one setting cleaning the remote up, and it poisoned the read it collided with:
`git ls-remote --heads origin` is how a parked branch is found, since a parked branch has no PR by
design -- so the signal for real parked work started reporting shipped branches, each carrying a `park:`
commit whose `Backing:` line read *2 of 2 steps resolved*. A branch that reads as finished work waiting
to be picked up, hours after it landed.

The bound now asks `--state all`: the question it was always protecting is *has this branch been
published?*, not *is a PR open right now?*. The refusal names which state stopped it and points at
`park-branch.ps1` for a branch whose work genuinely resumed -- that judgement belongs to the deliberate
park, never the automatic one. It also covers the closed-unmerged head #992 left behind, which
`prune-merged.ps1` cannot see by design. The other candidate repair, refusing when `HEAD` is an ancestor
of the trunk, would not have: that branch sat 96 files divergent from `main`.

**Score:** 4

#### What makes this deploy extra special

N/A -- `park-cycle.ps1` ships to every consumer of the `contributing-davekjohn` workflow plugin, so the
resurrection stops there too, but this repo is not a subscribed service and has no such reader.

**Score:** N/A

#### Pull Request

park-cycle no longer resurrects a branch whose PR already shipped

Plugins: contributing-davekjohn

[PR #1037](https://github.com/DaveKJohn/claude-code-specialists/pull/1037)

---

### DEPLOY: `docs/the-gate-red-was-load-not-its-caller-v1` · 20260828-203405

The test gate's verdict does not depend on who calls it, and the release figure that said the suites cost
443s was measuring the machine.

Inbound [#1033](https://github.com/DaveKJohn/claude-code-specialists/issues/1033) came out of the
`v4.22.0` cut, where the same tree answered green in 443s inside `cut-release.ps1` and **11 of 54 failed
in 626s** when the gate was driven from the session afterwards — with one of the eleven passing alone in a
fresh process. It read that as the gate depending on whether its caller had dot-sourced the libs, and
concluded that CI is on the failing side. The two files it names say otherwise: `cut-release.ps1`
dot-sources `repo-config.ps1` and `native-capture-lib.ps1` before it calls the gate, so both runs had
identical state, and CI's `ProcessorCount` is **four** on its runner against the eighteen lanes the red
run used.

Re-measured across every axis the report did name — 16 and 18 lanes, console CP 850 and 65001, idle and
under a second identical gate — **five full runs, all 54/54 green**: 194s, 216s, 203s, 421s, 419s. The
last pair is the one that pays: two gates side by side reproduce the release's own *green* 443s to within
5%, which retires that number as a cost figure. This gate costs about **200s** on that tree; 443s was a
reading of what else the machine was doing, and 626s was more of the same.

What is left is real but older than the report. Red under the gate and green alone, on these same suites,
has now been seen three times — the `Start-Job` fan-out of August 12, the two post-split reds of August
16, and these eleven — and none of the three reproduces. Six of the eleven scan the live tree and five do
not, so the known collision covers part of it and nothing covers the rest. So it is named where it fires:
`Invoke-TestSuiteGate`'s docstring now carries the converse of its own inbound-#821 rule, pointing at the
two lenses that already held the standing response — *re-run the red suite alone before believing its
assert*. Not reaching those two pages is what cost that release 22 minutes, not the flake.

**Score:** 2

#### What makes this deploy extra special

The docstring half travels: `native-capture-lib.ps1` is mirrored into `workflow-davekjohn`'s
`contributing-davekjohn` plugin, so a consumer running that workflow gets the same warning above their own
gate on their next update. The measurements stay here, in the two lenses, because they are this machine's.

**Score:** 1

#### Pull Request

the gate's red was the machine, not who called it

Plugins: contributing-davekjohn

[PR #1036](https://github.com/DaveKJohn/claude-code-specialists/pull/1036)

---

### DEPLOY: `fix/the-guard-refusal-does-not-teach-forgery-v1` · 20260828-182455

`guard-live-theme` stops teaching the one habit it exists to prevent, and authoring the rule it enforces
no longer depends on which shell your platform uses.

The refusal a consumer met while moving a printed `shopify theme delete` out of a `Write-Host` format
string told them to *"add the marker `# …-THEME-DELETE-AUTHORIZED` to this exact command"*. On a command
that writes a **file** that advice works, because the marker is matched over the whole command string —
so a reader doing as they were told marks a non-delete as an authorised delete. The guard's own header
already argued that a guard making its own rule impossible to write down gets switched off; this was the
sharper version, one that made the rule *hazardous* to write down. Every refusal now carries one line
saying a marker authorises a **command**, never a file write, and the suite asserts that line is present.

The matching half was an asymmetry nobody chose. The matcher has read both the Bash and the PowerShell
tool since day one — that breadth is what closes the wrapper vector — while both exemptions knew only
the POSIX spellings. A PowerShell `@' … '@` body is now stripped exactly as a heredoc body is, gated on
the same execution test, and the write cmdlets join `$TEXT_TOOLS` beside their POSIX twins. The
here-string half is the one that mattered: the segment split is on newlines, so an unstripped body
matches on its own body line, a segment away from the cmdlet consuming it.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches a service subscriber — this is a plugin-carried hook, and it reaches Shopify consumers
of `team-shopify` on their next update.

**Score:** N/A

#### Pull Request

The live-theme guard stops teaching marker forgery, and PowerShell authoring is exempt like Bash

Plugins: team-shopify

[PR #1034](https://github.com/DaveKJohn/claude-code-specialists/pull/1034)

---

