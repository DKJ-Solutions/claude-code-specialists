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

