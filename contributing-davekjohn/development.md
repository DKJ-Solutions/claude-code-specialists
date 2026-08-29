## Development: `fix/suggested-settings-ship-an-allow-half-v1` · 20260829-143653

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

`bootstrap.ps1` writes `.claude/settings.suggested.jsonc` with exactly one permissions half --
`deny` -- so a consumer who follows the adoption to the letter ends up with a repo that forbids the
five things the workflow must never do and permits nothing it must do. The one person who can widen
a permissions file is the human, and today nothing hands them anything to paste (inbound #1075).

#### The report's proposed repair does not survive contact with the tree

It asks for the rules to carry "the resolved plugin root". They cannot: `CLAUDE_PLUGIN_ROOT`
resolves to the **version-pinned** install path -- `installed_plugins.json` records
`...\plugins\cache\claude-code-specialists\contributing-davekjohn\4.22.0` -- so a rule naming that
path stops matching at the next plugin update, silently and with no warning. A permission rule that
expires is worse than none: it reads as covered.

The shape that does hold puts a wildcard where the machine-specific and version-specific parts sit.
Verified against the permission reference: a `*` matches at any position in a Bash rule, and
"PowerShell permission rules use the same shape as Bash rules". The literal tokens before the first
`*` are what limit the rule, so `powershell -NoProfile -File` stays written out and only the path is
wildcarded -- which also keeps the rule clear of the startup warning that fires when an allow rule
wildcards the program or the subcommand.

### CREATE

- [x] `bootstrap.ps1`: emit a `permissions.allow` half beside the existing `deny`, filled only when
      the workflow plugin is enabled -- the three documented entry points (`new-branch`, `open-pr`,
      `ship-pr`) in both tool shapes, plus `gh repo edit --delete-branch-on-merge`
- [x] Name the two deliberate exclusions in the emitted comment: `cut-release.ps1` (it cuts a
      release -- that one is worth a prompt) and `gh repo delete` / `gh repo archive`
- [x] Next-step 3 stops saying the permissions block is "ready to use as-is" without qualification:
      say what the allow half covers, and what a repo with no workflow plugin gets instead
- [x] `bootstrap-drift.tests.ps1`: assert the allow half in the workflow-enabled fixture, that
      `cut-release` is not in it, and that the core-only fixture says why its allow half is empty

### TEST

`bootstrap-drift.tests.ps1`: 140 asserts green, 11 of them new. The core-only fixture asserts the
allow half exists, is empty, and **says why** -- the difference between "nothing to permit" and "we
forgot". The workflow-enabled fixture asserts each of the three entry points in both tool shapes,
the one `gh repo edit` form, and that `cut-release` is absent from the RULES rather than from the
file: the comment above them names that exclusion on purpose, and a whole-file match read that
sentence as the very thing it warns against -- which is how the first version of the assert failed.

Full gate: `check-plugin-integrity.ps1` 0 errors, all 60 suites green.

Eyeballed the generated file for both shapes, because a permission rule that never matches is
invisible to every assert above.

### DEPLOY: `fix/suggested-settings-ship-an-allow-half-v1`

`specialists-init`'s settings proposal now ships **both** permission halves. It carried `deny`
alone, so a consumer who followed the adoption to the letter ended up with a repo that forbids the
five things the workflow must never do and permits nothing it must do -- and the one person who may
widen a permissions file is the human, who was handed nothing to paste. The `allow` half is filled
with that workflow's three entry points (`new-branch`, `open-pr`, `ship-pr`, both tool shapes) plus
the single `gh repo edit --delete-branch-on-merge` the workflow assumes; `cut-release` is
deliberately absent, because a release is worth a prompt. Enable no workflow and the half is emitted
**empty and says why**, which is a state rather than an omission.

The paths in those rules are wildcarded, and that is the repair rather than a shortcut: the report
asked for the resolved plugin root, and `${CLAUDE_PLUGIN_ROOT}` is version-pinned
(`.../cache/<marketplace>/<plugin>/<version>/`), so a rule carrying today's path would stop matching
at the consumer's next plugin update -- silently, while still reading as covered.

**Score:** 3

#### What makes this deploy extra special

Every consumer meets this file on their first day, and it is the one artifact a session structurally
cannot repair for them: a permissions file is never agent-editable, so whatever the adoption prints
is what they get. The reported symptom -- six classifier denials in a day -- was measured on one
repo and did **not** reproduce on the virgin testrun, so this is not a guaranteed wall; what is
certain is that the block permitted nothing, and which of the two a consumer gets is not something
the adoption can predict for them.

**Score:** 3

#### Pull Request

the settings proposal hands the human an allow half, not only a deny half

