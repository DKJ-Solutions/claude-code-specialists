## Development: `fix/the-guard-refusal-does-not-teach-forgery-v1` · 20260828-164145

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Repair inbound #1032: `guard-live-theme` blocks AUTHORING a file that contains a theme delete, and its
refusal text advises adding the delete marker to a command that writes a file.

#### The report's reason was verified first, and it is not the reason

The report attributes the Bash/PowerShell asymmetry to `Get-LeadingCommand` seeing a variable
assignment, and proposes exempting a segment led by `Out-File`/`Set-Content`/`Add-Content`. Measured
against the loaded guard, that repair does not fix the reported command. The segment split is on
**newlines**, so an unstripped here-string body becomes one segment per line: the segment that matches
is the body line beginning `shopify`, and the `Out-File` that would have earned the exemption is a
segment away. The actual cause is that `Remove-HeredocBodies` knows only the POSIX `<<TERM` syntax and
nothing strips a PowerShell `@' … '@` body.

Measured with a fixture consumer (both markers answered) before any edit: the reported command blocked,
`Out-File`/`Set-Content` as a *leading* command blocked too, and the Bash twin passed. So the repair is
the reporter's (1) and (2) plus the stripping their (2) needed to work — stated here because it goes
**further than the report asked**, and the reporter planned their own follow-up on the narrower reading.

### CREATE

- [x] `Remove-HereStringBodies` in the guard — the PowerShell twin of `Remove-HeredocBodies`, gated on
      `-not $executesText` so the exemption carries its own override rather than borrowing one
- [x] `$executesText` gains the PowerShell execution vectors — `Invoke-Expression`, `iex`,
      `[scriptblock]::Create` — which is what makes that stripping safe to have, and which also
      disables the text-tool exemption as the existing `eval`/`xargs` members do
- [x] `$TEXT_TOOLS` gains the PowerShell half of its own list — `Out-File`, `Set-Content`,
      `Add-Content`, `Get-Content`, `Select-String`, `Tee-Object`, `Write-Output`, `Write-Host`,
      `Out-String`
- [x] `$AUTHORING_NOTE` on **every** refusal, written once rather than into the four Deny calls: a
      marker authorises a command, never a file write. This is the half that removes the hazardous
      advice, and it changes no behaviour
- [x] an unclosed here-string body is put **back** rather than dropped — found by its own counter-case
      on the first draft, where an opener with no closer stripped to the end of the command
- [x] the guard header, and the README's *"Mentioning a rule is not performing it"* section, state the
      two new exemptions, the asymmetry and the refusal note

### TEST

- [x] group 7 in `scripts/tests/guard-live-theme.tests.ps1` — groups 2 and 3 again in the other shell:
      7 authoring cases that must pass, 7 counter-cases that must still block, 3 asserts on the refusal
      wording via a new `Get-GuardRefusal` helper
- [x] the counter-cases are the point, and one of them found a real hole (the unclosed body above):
      a here-string fed to `Invoke-Expression`, to `iex` and to `[scriptblock]::Create`; a real command
      after a closed body; an unterminated opener; a write cmdlet beside a real command; and a delete
      marker written **into** a file failing to authorise a real delete
- [x] `guard-live-theme.tests.ps1`: 102 passed, 0 failed
- [x] the README's assert count was `69` against a suite that already had 85 before this branch —
      corrected to 102 in the same sentence rather than left to drift further
- [x] the full gate — `check-plugin-integrity.ps1` plus every suite — green

### DEPLOY: `fix/the-guard-refusal-does-not-teach-forgery-v1`

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

