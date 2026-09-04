## fix/readme-keys-install-claim

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

Issue #1371 reports that `INSTALL.md`/`README.md` claim an install record is required while this repo
loads both plugins with no record at all. Both of its load-bearing measurements were checked against
this machine and **neither holds** -- but the line it cites is genuinely stale, and that is what this
branch repairs.

#### What #1371 claimed, and what was measured here (2026-09-04)

| the report | measured |
|---|---|
| the register holds *exactly one* record, `shopify-ai-toolkit@claude-plugins-official` | that plugin appears **nowhere** in `installed_plugins.json`; five plugin families do |
| no record for `team-alpha` or `contributing-davekjohn`, at any scope | both carry a `scope: project` record for **this exact path**, `4.29.0`, sha `f4a36ab` |
| `claude plugin list` lists only that shopify plugin | it lists both, plus `bwj-codex`, `team-ecomm` and `team-shopify` |
| `claude plugin update <plugin> --scope project` -> `✘ Plugin ... is not installed` | exit **0**, *"already at the latest version (4.29.0)"* -- both plugins, register byte-identical afterwards |

Both records carry `installedAt: 2026-09-01T11:42:31.028Z`, three days **before** the report was
filed, and by #389's key-order fingerprint their `projectPath` sits at position 2 -- the signature of a
genuine `claude plugin install --scope project` rather than a session-written record. A later write can
refresh `lastUpdated`; it cannot invent a September 1 `installedAt` for a record it has just created.
So the record was present at the moment the report said it was absent, and the symptom is not routable.

#### The defect it did surface

`README.md` still stated *"the two settings keys plus a restart produce **no** install and no error"* --
the exact absolute `INSTALL.md` retired after inbound #327, where it now says in so many words *"this
page no longer claims they do nothing"*. `README.md` referenced #327 nowhere at all. The sweep found the
claim in **two** places, not the one the report cites: the `#274` blockquote and the compressed form in
the *Consumption* section.

### CREATE

- [x] Sweep the retired claim across every non-archived `.md` -- two live hits, both in `README.md`
- [x] `README.md` `#274` block: state that the keys give no *working* install, and add the `#327`/`#355`
      nuance -- a session start can write a full project-scoped record whose session loads nothing, and
      whose `installPath` may name a directory that does not exist
- [x] `README.md` *Consumption*: "the settings keys alone install nothing" -> "leave you without a
      working install", reflowed to the page's wrap
- [x] Point both at `INSTALL.md#connecting--the-install-step`, the anchor that already carries the
      mechanics (verified live, used five times in `INSTALL.md` itself)
- [~] Change `INSTALL.md` -- dropped: it is already correct and already carries the #327/#355 nuance in
      full. It was `README.md` that lagged it.
- [~] Change the `--scope project` update guidance -- dropped: measured working with the flag, and the
      existing #359 block already covers the scopeless refusal the report confused it with.

### TEST

- [x] `check-plugin-integrity.ps1` -- green, 0 findings across all 34 checks, including the dead-link
      scan over the new `INSTALL.md#connecting--the-install-step` anchor
- [x] No line above the page's ~100-char wrap introduced by either edit -- the only over-length lines
      in `README.md` are pre-existing table rows
- [~] A separate run of the 65 suites under `scripts/tests/` -- dropped, and deliberately: `open-pr`
      runs them as its own gate, and a copy started ahead of it proves nothing that gate would not
      catch while charging the same measurement twice. The gate's run is the credited one.
- [~] A new or changed test -- dropped: the change is prose in `README.md`, and no suite asserts on
      that text. `check-plugin-integrity`'s link and wrap checks are the coverage it has.

### DEPLOY: fix/readme-keys-install-claim

`README.md` no longer claims the two settings keys produce no install at all. That absolute was retired
in `INSTALL.md` after inbound #327 and survived here in two places, so the repo's own front page
contradicted its install manual -- and the contradiction was load-bearing enough to generate a false
report (#1371) whose author read the README, measured the register, and concluded the documents were
wrong rather than one of them stale. Both statements now say the keys leave you without a *working*
install, name what they do produce -- a full project-scoped record written after the load phase, by a
session that loads nothing, sometimes pointing at a payload that does not exist -- and send the reader to
`INSTALL.md`'s install step for the mechanics.

**Score:** 3

#### What makes this deploy extra special

The state this repairs is the one a consumer cannot diagnose: a record that says *installed, project
scope, correct sha* while the session is completely inert, with every check that reads the record
agreeing. `README.md` is the first page an adopter opens, and it was the one page that said that state
could not arise -- so an adopter who hit it had been told to look for an absent record instead of an
inert session. The corrected block names the surface to verify instead (is the bootstrap skill in the
slash list, did the session hooks print, does Chris open the turn), which is the check that works when
the administration lies.

**Score:** 3

#### Pull Request

README stops claiming the settings keys produce no install at all

