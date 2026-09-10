## fix/1764-agents-manifest-file-list

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Repair 2 chosen by Dave: keep subagents/, list every .md in each plugin's agents key, plus a lint check
holding each list to the directory's actual contents. Measured: agents accepts string|string[] of .md
file paths only -- no directory, no glob (claude plugin validate 2.1.267).

#### What was verified before any of it was built

The report (#1764) named a symptom, a cause and two candidate repairs, and all three were held against
the tree rather than taken on trust:

- **Symptom, still standing.** `claude plugin install dkj-subagents-lifehub@claude-code-specialists
  --scope project` answers `Validation errors: agents: Invalid input`, verbatim as reported.
- **Cause, confirmed structurally.** `git show 2ef95c42^:plugins/dkj-teams/dkj-team-alpha/.claude-plugin/plugin.json`
  carries no `agents` key at all -- the directory was `agents/` and Claude Code found it by convention.
  #1698 renamed it to `subagents/` and added `"agents": "./subagents/"` to point at it.
- **The reasoning behind #1698's key, EXPIRED.** Its point 3 reads *"it is permitted by the plugin
  format: the reference documents an `agents` key in `plugin.json` (string or array) that replaces the
  default directory."* The premise is false for a directory, so the repair is not a reversal of a sound
  decision but the repair of one built on an unrun sentence.
- **The accepted shape, measured rather than read**, with `claude plugin validate` (read-only, no
  install) on Claude Code 2.1.267 -- two findings the report did not have:
  - **no glob**: `["./subagents/*.md"]` fails with `Path not found`, so a self-maintaining list is not
    available. That is what makes the gate below load-bearing rather than tidy.
  - **the reference is wrong, and `commands` is the control.** The plugins reference lists `agents`
    among the fields that replace their default directory and prints `["./agents/",
    "./custom-agents/reviewer.md"]` as the way to keep the default and add more -- rejected at element
    0. `"commands": ["./subagents/"]` passes on the same manifest. Upstream, not ours to repair;
    queued as Claude Code feedback in this session.

### CREATE

- [x] the four `plugin.json` manifests: `"agents"` as an array of every `.md` in that plugin's
      `subagents/`, generated from the directory rather than typed. 15 + 3 + 5 + 3 = 26 entries.
- [x] `claude plugin validate` passes on all four plugins and on the marketplace.
- [x] `scripts/lint/check-plugin-integrity.ps1` check 38 `[agents-key]`, in both directions -- the
      installer's accepted shape, and every `*-agent.md` a plugin ships held to the list that has to
      name it. Plus the third shape: no key at all with defs outside `agents/`.
- [x] its entry in that script's own `checks:list` span, which check 37 holds it to.
- [x] `INSTALL.md`'s #1698 migration section, which stated the key as `"agents": "./subagents/"` --
      the broken form, documented as the design. The repair created that contradiction, so it is
      repaired here rather than filed: same sentence, same key. It now also tells a consumer who met
      the refusal on `v4.33.0` what it was and that nothing on their side caused it.

### TEST

- [x] eleven scenarios in `check-plugin-integrity-docs.tests.ps1`, scenario 1 being the manifest
      v4.33.0 actually shipped -- so the suite proves the check fires on the defect and not only that
      the repair passes.
- [x] the full lint gate green on this tree, with `[agents-key] checked 6 -- ... 26 'agents' entry(s)`.
- [x] all suites green.

### DEPLOY: fix/1764-agents-manifest-file-list

The four team plugins can be installed again. Every one of them shipped `v4.33.0` with
`"agents": "./subagents/"`, which the installer refuses outright -- `agents: Invalid input` -- so four
of the six plugins in this marketplace could not be installed by anybody for a whole release, while
this repo's own lint gate and CI both reported `0 error(s)` over them. Each manifest now lists its
subagent files, which is the only shape the field accepts, and check 38 holds the class shut at both
ends: an entry that is not an existing `.md` file inside the plugin (what #1764 measured) and a def on
disk that no entry names (what a hand-maintained list of 26 paths is exposed to next).

**Score:** 5

#### What makes this deploy extra special

A consumer on `v4.33.0` cannot install four of the six plugins at all, and the failure is a validation
error rather than a missing feature -- so there is no partial state to work around. After a
`claude plugin marketplace update` the installs succeed again. Nothing else about the plugins changes:
the `subagents/` directory keeps its name, every specialist keeps its id, and no consumer has to edit
anything of their own.

**Score:** 5

#### Pull Request

The four team plugins install again -- the agents key lists its subagent files, and the gate holds it to the directory

