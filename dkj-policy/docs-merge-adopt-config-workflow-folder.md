## docs/merge-adopt-config-workflow-folder

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

Skill-level merge only (Dave's explicit scope decision): one new SKILL.md, adopt-dkj-policy, replaces both adopt-config and adopt-workflow-folder as two named parts of one page. The two underlying scripts (adopt-config.ps1, adopt-workflow-folder.ps1), their own tests, and their registry Name fields are UNCHANGED -- only each script's Skill field in shared-scripts-lib.ps1 now points at adopt-dkj-policy. Every doc cross-reference, the printed session-hook remediation message in check-script-contract.ps1 (root+mirror), the check-roster-sync.ps1 comment describing that message, the generated masthead text adopt-workflow-folder.ps1 writes into a consumer's scaffolded README, and the check-plugin-integrity.ps1 comments citing the old message as their own worked example, all updated to match. One test assertion (script-contract.tests.ps1) that checked the literal old skill name in printed output was updated to the new name. Consistent with the same-day precedent: adopt-bwj-asana was renamed to adopt-dkj-policy-bwj earlier today for the identical reason (a name naming one plugin should not leave a sibling operation for that plugin looking unrelated).

### CREATE

- [x] Wrote `plugins/workflows/dkj-policy/skills/adopt-dkj-policy/SKILL.md`: one page, two named parts
      (Part 1 = the former `adopt-workflow-folder` content, Part 2 = the former `adopt-config`
      content), an intro explaining the two run independently and in either order, and every internal
      cross-reference between the two ("Part 2 below explains the marker", "the same rule Part 2
      follows") repointed from the old skill names. Every word of substantive content from both source
      pages carried over -- headings demoted one level (`##` to `###`) since they now nest under the
      two `## Part N` sections, nothing else changed.
- [x] `git rm -r` the two old skill directories (`skills/adopt-config/`, `skills/adopt-workflow-folder/`).
- [x] `shared-scripts-lib.ps1`: both scripts' registry entries keep their own `Name` (`adopt-config`,
      `adopt-workflow-folder` -- unchanged, they still identify the SCRIPT) but now share
      `Skill = 'adopt-dkj-policy'`. This many-scripts-one-skill shape already existed
      (`verify-resolved-issues` has shared `ship-pr`'s page since before this merge) and check 18
      (skill-param) already supports it.
- [x] The one PRINTED, USER-FACING instruction that named a skill by name: `check-script-contract.ps1`'s
      "workflow folder does not exist" finding said `Run the 'adopt-workflow-folder' skill to scaffold
      it`; now says `adopt-dkj-policy`. Fixed in both the root copy and the `dkj-policy` plugin mirror.
      Its own explaining comment two lines up (about why this imperative is safe to print bare) and
      `check-roster-sync.ps1`'s comment describing the same printed line were updated to match, in both
      copies of each.
- [x] The masthead text `adopt-workflow-folder.ps1` writes into a consumer's scaffolded
      `dkj-policy/README.md` ("Scaffolded by the `adopt-workflow-folder` skill...") now reads
      "`adopt-dkj-policy` skill (Part 1)" -- root and mirror. No test asserts this exact string
      (checked), so nothing else needed updating for it.
- [x] `check-plugin-integrity.ps1`'s own three comments/notes that cite `check-script-contract`'s
      printed line as the worked example justifying "frontmatter-driven, not a phrasing rule" (the
      barred-skill check's design rationale) -- updated to cite the new name, since the OLD name no
      longer appears anywhere in the tree as that example.
- [x] Doc cross-references updated across the active tree: `dkj-policy/README.md`,
      `plugins/workflows/dkj-policy/README.md` (three spots, including merging two `<!-- skills:plugin
      -->` table rows into one), `plugins/workflows/dkj-policy/scripts/README.md` (two script rows, one
      shared skill link, each annotated "(Part 1)"/"(Part 2)"), `plugins/workflows/dkj-policy/
      CONTRIBUTING-portable.md`, `plugins/workflows/dkj-policy/RELEASES-portable.md`,
      `plugins/workflows/dkj-policy/skills/check-branch-entry/SKILL.md`, `plugins/workflows/README.md`,
      `plugins/ADOPTION.md` (merged the two table rows into one, fixed the "two of the three append to
      repo-config.ps1" sentence -- both remaining items append, so the count no longer parsed after the
      merge either way), `INSTALL.md`, root `README.md` (four spots, including both `<!-- skills:all
      -->` marker spans), `.claude/skills/triage-inbound/SKILL.md`, and two specialist lenses
      (`05-06-extension.md`, `06-16-extension.md`).
- [x] `scripts/tests/script-contract.tests.ps1` asserted the literal OLD skill name in the printed
      finding's text (`Assert-Match 'adopt-workflow-folder' $r.Out ...`) -- this would have failed the
      moment the printed message changed, and did fail locally before the fix. Updated to
      `'adopt-dkj-policy'`. Two other test files (`bootstrap-drift.tests.ps1`,
      `check-plugin-integrity-commands.tests.ps1`) carried descriptive comments (not assertions)
      naming the old skill as their real-tree example; updated for accuracy, no behaviour change.
- [x] Left untouched, deliberately: every mention of `adopt-config`/`adopt-workflow-folder` that names
      the SCRIPT rather than the skill page (e.g. `script-contract-lib.ps1`'s many "adopt-config places
      this text VERBATIM" behavioural comments, `repo-config.ps1`'s comments, `adopt-shopify-floor.ps1`'s
      comparisons to "the same default adopt-config and adopt-workflow-folder use") -- the two scripts
      keep their names, so these are still correct as written. Also left: historical citations of a
      past measured incident under the old name (`check-plugin-integrity.ps1`'s and
      `check-plugin-integrity-docs.tests.ps1`'s "adopt-config/SKILL.md shipped with EF BB BF in 4.1.0"),
      and `dkj-policy/CHANGELOG.md`'s still-pending `fix/1454-releases-readme-folder-name` entry, which
      quotes what a NOW-FIXED bug used to say a page claimed -- changing the quoted old name would
      misrepresent the bug it describes. `config-blueprint.json` needed no hand-edit: it is a generated
      artefact copied verbatim from `repo-config.ps1`'s own comments, none of which changed.
- [~] `scripts/maintenance/baselines/skill-cost.json` still carries two stale keys
      (`dkj-policy/adopt-config`, `dkj-policy/adopt-workflow-folder`) and no `adopt-dkj-policy` entry.
      Not fixed here: `measure-skill -UpdateBaseline` drives live `claude plugin details` calls against
      the INSTALLED marketplace clone, which will not see this branch's renamed skill until it is
      merged and the clone is refreshed -- measuring now would either fail or record a number against
      a name that will not exist in the release this lands in. Filed as
      [#1469](https://github.com/DaveKJohn/claude-code-specialists/issues/1469) rather than guessed at.
- [~] `plugins/teams/team-alpha/skills/specialists-init/SKILL.md`'s sentence "The two SessionStart
      hooks, `adopt-config.ps1` and `orchestrator/SKILL.md` name the command and the actor for that
      reason" does not parse cleanly against anything this branch touched (neither file is a
      SessionStart hook, and no printed message anywhere names `adopt-config` with an imperative this
      sentence could be about) -- a pre-existing confusion unrelated to this rename, out of scope to
      guess-fix here. Filed as
      [#1470](https://github.com/DaveKJohn/claude-code-specialists/issues/1470).

### TEST

- Lint gate (`scripts\lint\check-plugin-integrity.ps1`): 0 errors, run twice (once before the three
  check-plugin-integrity.ps1 self-references were fixed -- still 0, since those are prose rather than
  something the gate validates against itself -- and once after).
- Full local test gate (`Invoke-TestSuiteGate`, all 70 suites, 32 lanes): **all 70 suites passed in
  144s**, after fixing `script-contract.tests.ps1`'s assertion (it failed on the literal old name
  before that fix, confirming the assertion was real and would have caught this on CI otherwise).
- `scripts/sync/build-shared-scripts.ps1`: 0 mirrors needed updating -- every root/mirror pair was
  hand-edited identically, and the generator confirmed byte-for-byte agreement rather than silently
  fixing a drift.
- Manual grep sweep of the whole tree for `adopt-config` and `adopt-workflow-folder`: every remaining
  hit is one of the four deliberately-untouched categories named in CREATE above (script-behaviour
  comment, historical citation, the still-pending CHANGELOG entry quoting a bug's own wrong claim, or
  this branch's own document).

### DEPLOY: docs/merge-adopt-config-workflow-folder

`adopt-config` and `adopt-workflow-folder` were two separately-named skills for the same plugin,
`dkj-policy` -- one placing the config seam, one scaffolding the workflow folder. Renaming
`adopt-bwj-asana` to `adopt-dkj-policy-bwj` earlier the same day, for a sibling plugin that had grown a
second chapter under a name naming only the first, raised the same question here from the other
direction: two *separate* skills for one plugin, neither named after it.

Merged into one skill, `adopt-dkj-policy`, in two independent parts that can run in either order or
alone -- no behaviour change to either underlying script, only the page that documents them. A reader
enabling `dkj-policy` now finds one name to ask for, covering everything the plugin needs placed in
their repo, rather than having to already know there are two.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal skill name in this repo's own workflow plugin. No consumer-facing behaviour changed;
the two scripts a consumer actually runs are byte-for-byte what they were.

**Score:** N/A

#### Pull Request

adopt-config and adopt-workflow-folder merged into one skill, adopt-dkj-policy

