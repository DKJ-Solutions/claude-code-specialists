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
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](contributing-davekjohn/CONTRIBUTING.md).

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

### DEPLOY: `docs/change-contributing-title-v1` · 20260826-170138

The one page in `contributing-davekjohn/` opens under a new H1 -- **`Contributing as DaveKJohn`**, where it
read **`Contributing -- the contributing-davekjohn layer`**. The old heading described where the file SITS:
a layer over the two root documents. That is true, and it is the answer to a question a reader arrives with
only once they already know the page exists. The new one names the subject instead -- this is how work is
contributed in DaveKJohn's repos -- which is what the folder, the plugin and the page have each been about
since the folder's two pages merged into one on August 26, 2026
([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886)). The layering itself is not lost:
the page states it in its own opening paragraph, where it is prose a reader meets in context rather than a
heading standing in for a title.

**Nothing links to the old anchor**, checked across every `.md`, `.ps1` and `.json` in the tree, so the
rename strands no reference and needs no follow-up edit anywhere -- which is what makes a heading safe to
change at all in a repo whose lint gate scans for dead links.

**Score:** 1

#### What makes this deploy extra special

This page is the repo's own adopted copy, not plugin payload: the shipped document is
`plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md`, and it is untouched. No consumer
receives this heading, in this release or any other.

**Score:** N/A

#### Pull Request

the contributing layer's page is titled Contributing as DaveKJohn

[PR #933](https://github.com/DaveKJohn/claude-code-specialists/pull/933)

---

### DEPLOY: `fix/intent-placement-in-the-skill-page-v1` · 20260826-163806

The `new-branch` skill page and the DevOps lens now name where `-Intent` actually writes: the opening
paragraph of `PLAN`, without a heading. Both still described the pre-#908 placement at the top of the
document. The skill page is the only documentation a consumer has for that parameter, so it also tells
anyone holding a branch scaffolded before August 26, 2026 what to move and where.

**Score:** 3

#### What makes this deploy extra special

A consumer reading the skill page would have been told to expect the intent somewhere the scaffolder no
longer writes it, and -- worse -- would have had no way to connect a refused branch document to the
parameter that caused it. The page now carries both the correct placement and the one-line repair for a
branch already in flight.

**Score:** 3

#### Pull Request

the new-branch skill page and Derek's lens name the intent's real place

Plugins: contributing-davekjohn

[PR #932](https://github.com/DaveKJohn/claude-code-specialists/pull/932)

---

### DEPLOY: `fix/refresh-body-drops-the-resolves-block-v1` · 20260826-162404

`open-pr.ps1` now refreshes the PR description **before** it appends the closing block, instead of after
([#919](https://github.com/DaveKJohn/claude-code-specialists/issues/919)). The two edits on the
existing-PR path run sequentially on one variable, so the second consumed the first: with the block
appended first, `-RefreshBody` replaced it and the run published a body that closes nothing. It printed a
lost-section warning and exited 0, which is why it read as a success -- measured on PR #916, where #913
stopped being a closing reference and was reinstated by hand.

The reason a refresh can reach that far is a **heading-less PR template**, which is what this repo and the
shipped reference both carry: with no heading above the placeholder the description is the body's leading
section, and with no heading below it there is no stop, so the leading section is the whole body. Both
halves are `Update-PrBodySection`'s documented behaviour. Nothing about them changes here.

`Add-ResolvesBlock` is idempotent per issue, so appending **last** is a no-op where the block survived and
restores it where it did not -- no new knowledge of stops or heading levels is needed. The comparison moved
with it: the append is now measured against the body as it went in, so a run that only refreshes no longer
announces a closing keyword it never added. And the lost-section warning stops firing for
`### Resolved issues` on its own, because the block is back before that check runs.

**The guard is the half that makes this stick.** `pr-issues.tests.ps1` gains a `#919` section asserting
the composition in both directions -- append-then-refresh loses the keyword, refresh-then-append keeps it --
plus a source-order assert that reads `open-pr.ps1` and requires the append to sit after the refresh. This
suite exists for the #341-#343 failure, where three PRs repaired issues and left eight of them open; #919
is that same failure reached through the door built to prevent it, and nothing asserted that the block
still arrived.

**Score:** 3

#### What makes this deploy extra special

`open-pr.ps1` ships with the `contributing-davekjohn` workflow, and so does the reference
`pull_request_template.md` -- which carries **no headings**, exactly the shape that makes the description
the whole body. So a consumer running `-Resolves` together with `-RefreshBody` met this on their own PRs,
in the tooling rather than in anything they wrote, and met it silently: the run warns, exits 0, and the
issue simply stays open after the merge. They notice the first time they look for a closed issue and find
it open, which may be long after the merge that should have closed it. Nothing they already do changes,
and no template of theirs needs editing.

**Score:** 3

#### Pull Request

open-pr refreshes the body before it adds the Resolved issues block

Plugins: contributing-davekjohn

[PR #931](https://github.com/DaveKJohn/claude-code-specialists/pull/931)

---

### DEPLOY: `fix/new-branch-intent-lands-in-plan-v1` · 20260826-161931

`new-branch.ps1 -Intent` now writes its parking note as the opening paragraph of the document's first
phase (`PLAN`) instead of above the phases. The region between the title and the first phase heading is
generic guidance, and `check-branch-entry.ps1` refuses branch content there -- so a branch scaffolded
with `-Intent` was rejected by CI as soon as its entry was written, which is at the PR. The parameter,
its pass-through from `worktree-lane.ps1` and its place in the document are otherwise unchanged; it
still keeps no heading of its own and still never touches the DEPLOY section.

**Score:** 4

#### What makes this deploy extra special

The scaffolder stated a rule and broke it in the same file, and the half that made it expensive was not
the contradiction but the gate: `-Intent` produced a branch a consumer's CI would not let through, and
the failure was invisible until the entry was written. Anyone who has a branch in flight carrying an
intent above the phases can move that paragraph under `PLAN` by hand; nothing else about the document
changes.

**Score:** 4

#### Pull Request

new-branch -Intent writes into PLAN instead of above it

Plugins: contributing-davekjohn

[PR #929](https://github.com/DaveKJohn/claude-code-specialists/pull/929)

---

### DEPLOY: `fix/scaffold-guidance-concat-v1` · 20260826-155456

`check-branch-entry.ps1` now prints the heading level it actually read in its **findings**, not only in its
`[OK]` line ([#924](https://github.com/DaveKJohn/claude-code-specialists/issues/924)). The gate derives that
level from the document's own title -- deliberately, so a shape change needs no era flag -- and one line
quoted the derivation while six typed `##` or `###`. When the format shifted one level down on August 26,
2026, every refusal therefore described the shape the document no longer had: it named `'##'` headings in a
`###` document, misquoted the stray heading it had just found, and told the reader to demote a `###` to a
`###`. The success path was level-aware and the failure path was not, which is the worse way round -- the
failure message is the one somebody reads while they cannot yet see what is wrong.

The six now quote one composed pair, `$phaseMark` and `$subMark`, built beside the `$phaseLevel` the checks
already use, so there is a single source rather than a literal per message. Two live comments naming a level
were rewritten to name the thing instead; the three that narrate a past measured defect keep theirs, because
that history really did happen at `##`.

**The guard is what makes this more than a rewording.** `branch-entry-gate.tests.ps1` gains scenario 9: the
same defect fed through the same code path at two levels, asserting that a current-level document is told
`###`/`####` and a legacy-level one `##`. Both new asserts were confirmed red against the literals before
being trusted -- and the legacy assert stays *green* under the defect, which is the reason one level on its
own proves nothing.

**This branch was opened for something else and that is the more useful half of its story.** It was meant
to repair the comma-versus-`+` defect in the guidance array; `#921` had already landed that against `#915`
twenty minutes before the report was written, including the regression test the report proposed. The report
was filed from a checkout one commit behind and never fetched -- the first of the five inbound patterns,
applied to a report this house wrote itself. What made it convincing is worth naming: a lane is based on
`origin/main`, but its dossier is scaffolded by the **primary** checkout's scripts, so the lane held a fixed
source tree and a broken document at the same time.

Nothing changes about what the gate accepts or refuses. What changes is that a refusal now describes the
document in front of the reader.

**Score:** 2

#### What makes this deploy extra special

`check-branch-entry.ps1` ships with the plugin, and it is the gate a consumer meets in CI rather than one
they run by hand -- so a consumer who is refused reads this message with no context and no repo history to
fall back on. Being told to demote a heading to the level it already has is worse there than here: a
maintainer of this repo knows the format shifted, and a consumer taking the workflow does not. They notice
the first time a branch of theirs is refused; nothing they already do changes.

**Score:** 3

#### Pull Request

The gate's findings name the heading level they actually read

Plugins: contributing-davekjohn

[PR #926](https://github.com/DaveKJohn/claude-code-specialists/pull/926)

---

### DEPLOY: `docs/plugin-readme-skill-table-v1` · 20260826-153911

The workflow plugin's own skill table lists all **16** skills it ships and no longer says how many
([#873](https://github.com/DaveKJohn/claude-code-specialists/issues/873)). `measure-skill` and
`worktree-lane` had each arrived without a row; the heading read *"The twelve skills"* above 14 of them,
and the layout table's `skills/` row said twelve as well. Both counts are gone rather than corrected --
the third time this table has drifted, and every time a number is what made the gap look like a decision.

**The half that prevents recurrence got a verified answer, which is what the report actually asked for.**
It proposed a lint-checked enumeration span, the mechanism check 10 already enforces on the root `README.md`.
Held against `scripts/lint/check-plugin-integrity.ps1`, that span cannot carry this table: its canonical
set is built from *every* published plugin's `skills/` (24 skills today, so a 16-name span would report the
team plugins' as missing), and every backtick-quoted token inside a span counts as a claimed name, which a
two-column table with backticked paths in its second column cannot honour. Both constraints are now written
into the section's own note, replacing the *"nothing here is machine-checked"* sentence that recorded only
the risk. The variant that *would* fit -- scoped to one plugin, reading each row's link target instead of
its backticks -- is [#920](https://github.com/DaveKJohn/claude-code-specialists/issues/920), with the
measurement for why it must stay opt-in: `team-alpha` and `team-shopify` enumerate none of their skills, so
a generic rule starts life with an 8-finding exemption list.

**One instance of the same defect class was found and deliberately not repaired here.** `INSTALL.md` tells
a reader that *"14 of the 19 skills across the six shipped plugins"* carry `disable-model-invocation`;
measured today that is 16 of 24 across five. It is a consumer-facing document making four separate claims,
one of them needing a rewrite rather than a new number, so it is
[#922](https://github.com/DaveKJohn/claude-code-specialists/issues/922).

Nothing about the workflow changes and no script moved. What changes is that the page now agrees with the
directory beside it, and that a reader who wonders why it is not machine-checked gets the reason instead of
a warning.

**Score:** 2

#### What makes this deploy extra special

This README ships with the plugin, so it is the page a consumer reads when adopting the workflow -- and for
`worktree-lane` it is the *only* discovery route, since that skill carries
`disable-model-invocation: true` and therefore never appears in a slash list. A consumer who read this table
to find out what the workflow gives them was missing two of sixteen skills, one of them invisible everywhere
else. They notice the moment they open the page; nothing they already do changes.

**Score:** 3

#### Pull Request

The workflow plugin's README lists every skill it ships, and stops counting them

Plugins: contributing-davekjohn

[PR #923](https://github.com/DaveKJohn/claude-code-specialists/pull/923)

---

### DEPLOY: `fix/the-guidance-array-parenthesises-its-levels-v1` · 20260826-152509

`new-branch.ps1` writes a usable `development-cycle.md` again. Four lines of `$script:BranchFileDefaults.StepsGuidance`
composed their heading levels as `'opening text' + $script:BranchCyclePhaseHashes + 'closing text'` inside a
comma-separated array literal -- and in PowerShell `,` binds tighter than `+`, so that is not string
concatenation at all. It parses as *array* concatenation of the neighbouring elements --
`('previous', 'opening text') + '###' + ('closing text', 'next')` -- turning one element into three. The array held **38
elements where 30 are written**, four of them a naked `###` or `####` alone on a line. `check-branch-entry.ps1`
read those four as branch-specific content in the region that must be generic and exited 1 -- so the
scaffolder wrote a document the gate refuses, and `open-pr.ps1` would not push it. That blocked **every**
branch, here and in every consumer taking the workflow plugin; the branch that hit it first was unblocked by
repairing its own document by hand, which left the generator untouched. Introduced by
[#911](https://github.com/DaveKJohn/claude-code-specialists/pull/911), reported as
[#915](https://github.com/DaveKJohn/claude-code-specialists/issues/915), and reproduced here by creating this
branch before touching anything.

**The repair is four pairs of parentheses, and the comment beside them is the durable half.** `+` is settled
before `,` ever sees it. The same edit lands in the byte-identical plugin mirror
`plugins/workflows/contributing-davekjohn/scripts/lib/entry-scaffold-lib.ps1`, because that is the copy a
consumer actually runs. What the note above the lines now records is that the parentheses are load-bearing --
without it they read as redundant grouping, and the next editor tidying them away reproduces the defect
exactly.

**Why it shipped green is the part worth keeping.** The composition fails into *well-formed* output: a
document that renders, with four markers merely orphaned onto lines of their own. Nothing read the array
back. Two guards now do. `entry-scaffold.tests.ps1` asserts that every element of the block opens the
blockquote -- a **shape**, deliberately not a count, because a pinned count goes red on every legitimate
wording edit and gets raised rather than read. And `branch-entry-gate.tests.ps1` gains scenario 8, which feeds
the gate the preamble `Format-DevelopmentCycle` actually produces. That is the real gap: the suite's own
header states that entry states come from the real formatters and never from a literal, and the seven shape
scenarios were the documented exception -- they spell their head out by hand, for a stated reason. That
exemption is why a generator writing a broken preamble passed a suite whose whole subject is that preamble.
Both guards were confirmed to fail against the defect before being trusted.

**Score:** 4

#### What makes this deploy extra special

`entry-scaffold-lib.ps1` is plugin payload: the `contributing-davekjohn` workflow ships it, so a consumer that
takes this plugin gets a scaffolder writing a document its own CI gate refuses -- every new branch, with no
way past it, since neither `open-pr.ps1` nor the gate has a `-Force`. The failure arrives at branch creation,
before any work is done, and the visible symptom is a document that looks fine. Nothing needs migrating: the
next branch after the update is written correctly, and a document already repaired by hand stays valid.

**Score:** 4

#### Pull Request

the scaffolded cycle document composes its heading levels without splitting the guidance array

Plugins: contributing-davekjohn

[PR #921](https://github.com/DaveKJohn/claude-code-specialists/pull/921)

---

### DEPLOY: `docs/contributing-numbered-steps-v1` · 20260826-150053

`contributing-davekjohn/CONTRIBUTING.md` now carries the step numbering
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894) asks for: four numbered `##` sections,
their substeps as `###`, and the four gates as `####` under the step where they fire. The letters are gone --
`1A`-`1H`, `2A`-`2E`, `3A`-`3G`, `4A` became `1.1`-`1.5`, `2.1`-`2.6`, `3.1`-`3.7` and `4.1` -- and every
in-text reference to a step or a gate moved with them.

**Four `##` *in total*, which needed more than a renumber.** The seam table and the pointer list sat between
the title and step 1 as `##` sections that were not steps, so the page read as six. Both moved to
[`contributing-davekjohn/README.md`](contributing-davekjohn/README.md), the folder index they always were.

**One new section, and it is the only content here that is not a renaming:** `2.3`, the merge queue
([#912](https://github.com/DaveKJohn/claude-code-specialists/issues/912)). Two PRs must not merge at once,
because every branch's fold writes into the same place in `CHANGELOG.md` -- the top of `## [Unreleased]` --
and it writes there after the merge, on `main`. Two folds racing break in the gap between the merge and the
fold, which is the state nothing reports: the later run's fold push is rejected as non-fast-forward, or
`ship-pr.ps1` step 5 aborts on its ff-only merge before folding at all. Either way the PR is merged, the entry
has not landed, and every gate stays green until a release trips over it. **No gate enforces the queue**,
which the section says out loud rather than leaving a reader to assume a script is watching.

**The sync in `2.3.3` is written as hygiene rather than as ordering, deliberately.** The fold inserts at the
top of `## [Unreleased]` on whatever `main` it is standing on, so the order entries end up in follows merge
order and not branch freshness -- syncing a stale branch does not move its entry up. The queue is what keeps
the order; the sync keeps a branch from merging a tree it was never tested against. Both claims were checked
against `ship-pr.ps1` step 5 rather than inferred from the shape of the problem.

**Two stale statements were corrected on the way, both of which had gone stale within the last two days.**
The fold paragraph said "2C and 2D are one command" while pointing at `2D` and `2E` -- it had been left behind
when "Open the PR" became its own step. And section 3 opened by explaining that its letters differed from #894
by one, because the issue asked for a release-note step this page did not have; the August 26 edit dropped
that step, so the two now agree and the paragraph was describing a gap that had closed. The subject itself did
not go away with it and is now [#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914).

It changes how the page reads for anyone following the cycle here -- every step reference in it is a different
string than it was -- but the cycle it describes is unchanged, and the one genuinely new step is a convention
rather than a mechanism. A reader notices the moment they open the page; nobody has to do anything differently
except queue behind an in-flight merge.

**Score:** 2

#### What makes this deploy extra special

Nothing here reaches a consumer. This page is this repo's own set of answers; the portable half that ships
with the plugin is untouched.

**Score:** N/A

#### Pull Request

CONTRIBUTING.md's four steps become numbered ## sections with dotted substeps, and the PR gains a merge queue

[PR #917](https://github.com/DaveKJohn/claude-code-specialists/pull/917)

---

### DEPLOY: `fix/the-review-failure-names-its-reason-v1` · 20260826-144804

When `claude-review` goes red, the log now names the reason. A failure-only step in
`.github/workflows/claude-code-review.yml` reads the execution file the action leaves behind and prints the
result message's `subtype`, `is_error`, `api_error_status`, `stop_reason`, turn count, duration, cost and
denial count, plus its `result` string truncated to 2,000 characters. On PR #911 -- inbound
[#913](https://github.com/DaveKJohn/claude-code-specialists/issues/913) -- the check failed twice and said
nothing but `is_error:true`, which left a guess about the credential as the only available hypothesis.

**The guess was half wrong, and the numbers already in the log say so.** #913 inferred an expired or
rate-limited OAuth token from the empty `ANTHROPIC_API_KEY:` line. Attempt 1 reports `num_turns: 12` and
`total_cost_usd: 1.03208985` across 69 seconds, so the token authenticated and did real work; an expired
credential cannot spend a dollar over twelve turns. Attempt 2 reports `num_turns: 1` and `total_cost_usd: 0`
in 470ms, a different failure entirely. A rate limit is consistent with both and an expiry with neither --
which is as far as the log can be read, and exactly why the reason has to be printed rather than reconstructed.
The other candidate the numbers offer is refuted outright: the three runs that PASSED that day carry
`permission_denials_count` of 6, 10 and 16, against the failing run's 1.

**The silence had a located cause, not a mysterious one.** `sanitizeSdkOutput` in the action's
`base-action/src/run-claude-sdk.ts`, read at the pinned SHA `e63208c`, emits seven fields of the result message
and suppresses every other message type. The SDK's own `SDKResultSuccess` type carries two more that name a
reason -- `result` and `api_error_status`, the latter holding 429 for a rate limit and 529 for an overload --
and neither is among the seven. So nothing was missing upstream that could be asked for; what was missing was a
reader for the file it already writes.

**Three mechanisms were read rather than assumed, because a workflow that leans on the wrong one fails only
when it is needed.** `execution_file` survives the failure, because `src/entrypoints/run.ts` calls
`setExecutionFileOutputIfPresent()` from its catch block. The file is an array whose last element is the
result, which is how upstream reads it in `update-comment-link.ts`. And `show_full_output: true` was rejected
rather than overlooked: it is the only switch on offer, it dumps every message including tool results into a
public log, and its own description warns it may carry secrets. Reading the file keeps the disclosure to the
fields that name the failure -- which is also why the step runs on failure only, where `result` holds an error
instead of review prose about the diff.

**And the branch found a second thing, which only the changelog can keep:** a PR that edits this workflow is
reviewed by nobody. `claude-review` skipped itself on this very PR -- 10 seconds against the 1m0s-7m2s of the
runs that reviewed something -- reporting `Action skipped due to workflow validation error ... expected ... on
PRs with workflow changes`. It reports that as **success**, not as skipped, so the green means the opposite of
what a green means on any other PR. Nothing here changes that, and it is written down rather than repaired:
the class it silently excuses is the one where a reviewer is most wanted.

`claude.yml` has the identical blindness and is deliberately left alone: it answers a human who typed
`@claude` and is already reading the thread when it breaks. This check runs unattended on every PR, which is
what makes its silence expensive.

**Score:** 2

#### What makes this deploy extra special

N/A -- `.github/workflows/claude-code-review.yml` is this repo's own CI. It is not plugin payload, it ships
in no release, and no consumer of the specialists plugins ever reads it. The mechanism generalises to any repo
running `claude-code-action`, but nothing here delivers it to one.

**Score:** N/A

#### Pull Request

The claude-review failure names its own reason

[PR #916](https://github.com/DaveKJohn/claude-code-specialists/pull/916)

---

### DEPLOY: `feat/the-workflow-shifts-one-level-down-v1` · 20260826-135636

The development cycle document and `CHANGELOG.md` each move one heading level deeper, and
`contributing-davekjohn/CONTRIBUTING.md` moves one shallower -- the shape Dave asked for in the edited
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894), which PR #905 could not have built
because the edits landed 21 minutes before its commit and after its plan was written. A branch document is now
`## Development cycle` with `### PLAN`, `### CREATE`, `### TEST`, `### DEPLOY`; `CHANGELOG.md` gained a real
`## [Unreleased]` section with `###` entries under it; and CONTRIBUTING's four steps became its top level, with
section 1 split into 1A-1H, section 2 gaining "open the PR" as its own 2A, section 3 gaining an optional 3H
wait for a `SHIP MAIN` / `PUSH LIVE` command, and section 4 reduced to the single act that command releases.

**`## [Unreleased]` is what makes the rest cost nothing, and it reverses a decision on purpose.** The flat
changelog -- an intro followed directly by one entry per change -- was Dave's own answer of August 5, 2026. He
reversed it here, and the mechanical argument is that the pending heading takes H2, which is what lets an entry
nest at H3 and therefore land at exactly the level the cycle document's DEPLOY phase carries. That equality is
what makes the fold a verbatim paste instead of a re-level, and it now has an assert in both libs -- it had
none before, having held only by the two pairs happening to agree.

**Nothing was pinned that could be composed.** Sixty assertions across six suites failed on the shift, and
almost none of them were about the level they named: they were structural claims written with a literal `##`
that had drifted into being a second definition of the format. Every one now reads its level from the lib, so
the next re-level does not reproduce this afternoon.

**A seventh suite held nine more, and three of them had gone GREEN.** `release-lib.tests.ps1` was not in the
sweep above and was caught by the pre-PR gate instead, where it did not report nine failures but zero of
anything: one fixture still built a pre-format entry at a literal `##`, `Split-Changelog` found no entry in it
and threw, and an uncaught throw ends the run with neither a PASS count nor a FAIL count -- the exact reading
error the TEST phase above says to watch for, met by the phase that wrote it. Six of the nine were ordinary red
literals. The other three are the ones worth keeping: they passed `-EntryLevel 3` to `Set-EntryHeadingLevel` to
mean *one deeper than canonical*, and once canonical WAS 3 the call became a no-op -- so "a canonical block
still renders deeper" asserted that a block which had not moved looked like a block which had not moved. A
literal level does not merely go stale; it goes stale in the direction that hides itself, which is why the
repair composes both ends of every shift rather than typing the new numbers in.

**And two of those pins were in the SCRIPTS, where the same drift is silent instead of red.** Both were found
by a suite rather than by reading, and neither would have raised anything at runtime:

- **`Get-EntryInsertOffset`'s `$EntryPattern` default was the literal `'(?m)^## '`.** A parameter default
  cannot call a function, so the level had been typed -- and once it was stale, every caller relying on the
  default saw a changelog with no entries in it. The fold then ranked each new entry against an empty list
  and appended it, which silently reverses the order the list is supposed to hold. It is resolved in the
  function body now. The fixture that caught it carries a comment describing this exact failure from the
  *previous* level move, three weeks earlier -- it had been repaired by typing the new number rather than by
  composing it, which is why it broke a second time.
- **`session-status.ps1` walked the changelog on `'^##\s'`.** Two things went wrong at once and only one was
  loud: entries at H3 stopped being counted, so the status block would have reported "none pending" on a
  changelog holding nine -- and `## [Unreleased]`, which sits at exactly the level that pattern wanted, would
  have been printed *as* a pending change. It reads the level from the lib now and skips the pending heading;
  the no-library fallback accepts both levels, because that branch cannot ask.

**This section is pure ASCII, and by the time it merged it no longer had to be.** It was flattened while
[#907](https://github.com/DaveKJohn/claude-code-specialists/issues/907) was open -- the DEPLOY lock compares
the section against the PR body, `ship-pr` read that body through a non-UTF-8 decode, and any non-ASCII
character therefore made a clean document mismatch a mojibake copy of itself. Three em-dashes went to `--` to
get this merged, exactly as [#906](https://github.com/DaveKJohn/claude-code-specialists/pull/906) had done the
day before. [#910](https://github.com/DaveKJohn/claude-code-specialists/pull/910) closed that hole while this
branch was still open, and it landed on `main` between this PR opening and its merge -- so the flattening is
left standing here as the last instance of a workaround that is already gone, not as a convention. Write the
next one normally.

**Score:** 4

#### What makes this deploy extra special

**A consumer's `CHANGELOG.md` needs migrating, and the fold and the cut now say so instead of doing something
quiet.** Their document's entries sit at the level the pending heading occupies, so without a migration
`Split-Changelog` finds no entries and a cut would describe nothing. That path was already guarded; the guard
had to be widened, because with an entry one level deeper a leftover heading falls into the HEAD where neither
loop was looking. Widening it turned up a second gap the same guard already had: a leftover heading BELOW the
first entry -- exactly the shape of the consumer document this guard was built from, which has two of them with
a real entry between -- was never reported at all, and the assert demanding both had been passing on the
example list inside the refusal's own message rather than on a finding.

**What does not need migrating is anything in flight.** Every reader accepts both level pairs, so a branch open
when the plugin updates keeps folding, and this branch is the proof: its own document was scaffolded before the
shift and is read by the merged code.

**Score:** 5

#### Pull Request

The cycle document and CONTRIBUTING shift one heading level down

Plugins: contributing-davekjohn

[PR #911](https://github.com/DaveKJohn/claude-code-specialists/pull/911)

---

### DEPLOY: `fix/native-capture-utf8-read-v1` · 20260826-132946

The DEPLOY lock refused correct work. `ship-pr` read the PR body back through the console decoder while
reading the branch document as explicit UTF-8, so on a non-UTF-8 console the two sides of one comparison
were decoded differently: `gh`'s em-dash `e2 80 94` arrived as `c3 94 c3 87 c3 b6`, and the lock refused a
PR whose body was intact, naming a line that reads as correct — in a gate with no `-Force`.

**The boundary #907 declined to guess is the console code page, and nothing about the PR.** The report was
right that the trigger is narrower than "any em-dash" and right not to guess: PR #905 passed and #906 failed
because `[Console]::OutputEncoding` differed between the runs, not because their entries did. Measured by
putting the report's own bytes through the real helper -- identical on cp65001, mangled on cp850 and cp437.

**This entry deliberately carries em-dashes, where the previous one had to be flattened to ASCII.** That
flattening was option 3 from the report applied by hand, and it said so itself so nobody would copy it as a
house style. Writing this one normally is the proof that the reason for it is gone — and it was held
against the real PR body on a cp850 console before the merge, not only in the suite.

**The repair is the one the language rule already prescribes, and the report's own option 1 named half of
it.** `Invoke-NativeCapture` gains an opt-in `-Utf8` that redirects the child's output to a file and decodes
it as UTF-8 explicitly. The bracketed alternative in that option -- setting `[Console]::OutputEncoding`
around the call -- is forbidden in writing: that setter is console-wide, and the test gate runs every suite
on one console. Option 2 was declined for the reason the report gave against itself, and option 3 is what
the previous entry had to do by hand.

**Four call sites, not one.** The report named `ship-pr`; the subject is every read that pulls prose through
this decoder, and there are four. The CI gate's copy of the same lock is one of them -- it never bit because
CI runs UTF-8, which is exactly the shape of defect that waits for a local run.

**Score:** 3

#### What makes this deploy extra special

N/A -- these scripts ship in the workflow plugin, so a consumer does receive the fix. But it repairs a gate
refusing correct work rather than changing anything they do: a consumer on a UTF-8 console never saw it, and
one on cp850 gets a lock that stops lying. Nothing to learn and nothing to adopt.

**Score:** N/A

#### Pull Request

the PR-body read no longer depends on the console code page

Plugins: contributing-davekjohn

[PR #910](https://github.com/DaveKJohn/claude-code-specialists/pull/910)

---

### DEPLOY: `fix/settings-json-trailing-newline-v1` · 20260826-123558

`.claude/settings.json` did not end with a newline. Installing `contributing-davekjohn` into this checkout
rewrote the file and added one, which is the only reason anybody noticed: it surfaced as a one-line diff on
`main` that nobody had authored.

**The newline is kept rather than reverted, and that is the whole change.** A text file ending without one
is the defect: any tool that appends to it, and any diff that touches its last line, reports a change to a
line nobody edited. Reverting would have restored a file that produces a phantom diff the next time a
plugin is installed here -- and this repo consumes its own plugins, so that is a recurring event rather
than a hypothetical one.

**Score:** 1

#### What makes this deploy extra special

N/A -- `.claude/settings.json` is this checkout's own harness config. It is not plugin payload, it ships in
no release, and no consumer of the specialists plugins ever reads it.

**Score:** N/A

#### Pull Request

settings.json ends with a newline

[PR #909](https://github.com/DaveKJohn/claude-code-specialists/pull/909)

---

### DEPLOY: `fix/the-changelog-intro-names-the-current-folder-v1` · 20260826-114730

`CHANGELOG.md`'s intro named `workflow-davekjohn/CONTRIBUTING.md` in the text of a link already pointing at
`contributing-davekjohn/CONTRIBUTING.md`. One line, and the intro is the one part of that file which is live
prose rather than history -- every release cut copies it through verbatim, so it would have shipped a dead
path into the next release notes.

**What it corrects is the reach of a rule, not a typo.** #905 renamed a folder that published notes link
into, and followed the doctrine those notes carry: repoint targets, never rewrite prose. Applied across
`CHANGELOG.md` that is right for the entries and wrong for the intro, which this repo separately documents
as a live statement rather than a record. Measured after the fix: one instance in the live layers, now zero,
and the two in history left as the testimony they are.

**This entry is written in ASCII on purpose, and it is not a house style.** The DEPLOY lock refused to merge
it while it carried em-dashes -- not because the section had changed, but because `ship-pr` reads the PR body
through a non-UTF-8 decode, so a clean document was being compared against a mojibake body
([#907](https://github.com/DaveKJohn/claude-code-specialists/issues/907), filed with the byte proof). The
dashes were flattened to get one line of documentation merged, and the underlying defect is somebody's own
branch rather than a convention anybody should copy.

**Score:** 2

#### What makes this deploy extra special

N/A -- the changelog intro is read by whoever opens this repo's changelog, not by a consumer of the plugins.
A reader who clicked the link landed in the right place either way; only the label was wrong.

**Score:** N/A

#### Pull Request

Fix the changelog intro so its link text names the folder that exists

[PR #906](https://github.com/DaveKJohn/claude-code-specialists/pull/906)

---

### DEPLOY: `feat/rename-workflow-to-contributing-davekjohn-v1` · 20260826-111226

`workflow-davekjohn` is now `contributing-davekjohn` -- the plugin, its directory, and its root folder in the
repo -- and `workflow-default` is gone along with the "exactly one workflow" guard that only existed because
there were two. The plugin's name now says what it does: it serves one owner's contributing rules, not a
workflow among several. Its folder carries **one** page instead of two, arranged as the four steps work
actually moves through, and the folder's `CLAUDE.md` is merged into it.

**Nothing is renamed without the old name still being read.** That is this repo's own precedent rather than a
new idea: `Get-BranchFilePaths` already kept four legacy filenames readable, on the argument that a consumer
meets a rename through a plugin update rather than by choosing to, and that a half-finished branch must not be
stranded. So seven document names resolve where one is written, both folder names satisfy the isolation guard
and the script-contract check, the bootstrap recognises either plugin id, and the seam defaults prefer whichever
folder actually exists. Two of those would have failed **loudly** in an unmigrated consumer if they had been
swept: the isolation guard refuses with `exit 1`, and the contract check is forwarded by a SessionStart hook as
`[ERROR]`.

**Two rules Dave stated mid-branch are now written down and shipped**, after he caught both by eye in this
branch's own document: `development-cycle.md` has four `##` headings and never a fifth, and nothing
branch-specific sits above `## PLAN`. Neither is enforced by anything -- measured, not assumed -- so both went
into the portable page and into the scaffolder's preamble, where every future branch document in every repo
will carry them. The gate question is [#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898)
and [#899](https://github.com/DaveKJohn/claude-code-specialists/issues/899).

**A record's prose and its links were treated differently, deliberately.** Renaming twice made 61 links in
published release notes dead. Measured before deciding: of 29 occurrences of the old plugin path in history, 22
were link targets and 7 were prose in backticks. The link targets followed the move -- which the folder's own
doctrine explicitly permits -- and every prose mention stayed exactly as written. The same split applied to the
`skill-cost.json` baseline: its 13 keys are addresses and moved, its values and their `Version` fields are the
measurement and did not.

**Score:** 5

#### What makes this deploy extra special

**Every consumer of this marketplace has to act, and nothing will tell them so.** Their
`.claude/settings.json` names `workflow-davekjohn@claude-code-specialists`, which resolves to nothing at their
next `claude plugin marketplace update` -- and the hook that would have had an opinion about their workflow
keys is the one this change retired. That breakage is accepted rather than avoided: Dave answered decision B
with *"I accept the breakage. I'm the only consumer so it's something I can fix easily myself."*

What softens it is that **only the install line is urgent.** Everything a consumer already has on disk keeps
working: their `workflow-davekjohn/` folder is still read, their branch documents still resolve, their seams
still pass the isolation guard, and their `CLAUDE.md` in that folder is untouched because the scaffold never
overwrites. So the migration is `claude plugin install contributing-davekjohn@claude-code-specialists --scope
project` plus one settings line, and the folder rename can wait for a quiet moment. This repo consumes itself,
so it is the first consumer to need exactly that -- `check-connectors.ps1` already says so.

**And a `workflow-default` install, if anybody has one, simply stops resolving.** No consumer in the register
had it enabled -- re-verified across all four connector records -- so the measured population of that breakage
is zero.

**Score:** 4

#### Pull Request

Rename workflow-davekjohn to contributing-davekjohn, and remove workflow-default

Plugins: contributing-davekjohn, team-alpha, team-shopify

[PR #905](https://github.com/DaveKJohn/claude-code-specialists/pull/905)

---

### DEPLOY: `feat/the-cycle-document-has-a-shape-gate-v1` · 20260826-105312

`check-branch-entry.ps1` now reads the SHAPE of `development-cycle.md`, not only its step marks. Two rules
that were enforced by Dave reading the file, on a document a session writes, with nothing in between:

- **Four `##` headings, never a fifth** ([#898](https://github.com/DaveKJohn/claude-code-specialists/issues/898)).
  Anything else is a `###` under one of the four.
- **Nothing but guidance above the first `##`** ([#899](https://github.com/DaveKJohn/claude-code-specialists/issues/899)).
  That region is identical in every branch document in every repo.

Both were broken on the same document within one afternoon, and #899's had been broken by **two sessions
in a row in the same position** -- which is what makes it a shape the document invites rather than a slip.
The harm is worth naming, because "wrong place" understates it: the stray paragraph sat flush under the
guidance with no heading between them, so it *read* as guidance. A reader who finds one branch's status
inside a generic block learns to distrust the whole block, including the rules that do apply everywhere.

**The two rules are scoped differently, and that asymmetry is the design.** The heading count runs only in
the repo that maintains this workflow, behind `Test-IsWorkflowSourceRepo`: heading-blindness is a stated
feature of this gate precisely so a repo that adopted the document may keep headings of its own, and a
check refusing those would refuse correct files elsewhere. The preamble rule holds everywhere, because it
reads the shape and not the text -- guidance is blockquoted whatever language it has been translated into,
so it survives the case a byte comparison against the scaffolder could not (inbound #562 is the consumer
who translated that block).

Neither check re-derives where the entry begins: both read `Split-DevelopmentCycle`, the one splitter three
readers already share, and both are fence-aware, because a document explaining this format quotes its own
headings.

**One correction the tests forced, kept here because it is the useful part.** The first draft reported
"every heading past the fourth" -- which named `## DEPLOY` as the extra the moment the stray sat *above*
`## PLAN`, which is exactly where both measured instances sat. A count cannot say which heading does not
belong. The phases are now read by name from `Get-BranchFileWording`, the same source the scaffolder writes
them from, so a repo that renames a phase is judged by its own names.

**Score:** 3

#### What makes this deploy extra special

N/A. One of the two rules reaches a consumer -- the preamble check, which refuses only content that would
misread as generic guidance in their own document -- and the heading rule deliberately does not. The
portable page states which is which, so an adopter can see the boundary rather than infer it. Nothing they
have written today starts failing.

**Score:** N/A

#### Pull Request

the branch-entry gate holds development-cycle.md to its four phases and its generic preamble

Plugins: workflow-davekjohn

[PR #904](https://github.com/DaveKJohn/claude-code-specialists/pull/904)

---

### DEPLOY: `fix/the-guard-covers-every-entry-point-v1` · 20260826-102307

`scripts/maintenance/measure-always-on.ps1` now carries the source-repo guard, and
[`scripts/README.md`](scripts/README.md) states the rule instead of counting it.

**The gap, and why nothing saw it.** The guard refuses a shared script that is running from a released
copy inside the repo that maintains it -- the mechanism behind
[#897](https://github.com/DaveKJohn/claude-code-specialists/issues/897)'s subject. `measure-always-on.ps1`
joined the shared registry on August 25 without it, while `scripts/README.md` claimed every shared entry
point but two carried it. Both named exceptions are sound: they are invoked from the plugin by a
SessionStart hook, so refusing there would fail every session start here. This one is no hook -- its own
skill page prints `${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-always-on.ps1` and then says to run
the local copy instead, which is precisely what the guard exists to enforce rather than request.

It was invisible because **the guard's suite tested whether the guard decides correctly and never whether
it is called.** That half is now asserted off the registry, so the next entry point is held to the rule on
the day it is registered rather than on the day somebody re-counts. Two supporting asserts keep the assert
itself honest: the entry-point set must be non-empty, and an exemption must name a file that exists and is
registered -- a licence cannot outlive what it excuses.

**A stale measurement tool is the worst place for this gap**, which is why it is repaired rather than
exempted. A stale copy of a measuring script does not fail; it reports. That file's own docstring is the
record of what a plausible wrong number costs here: the chars-per-token factor was inherited unexamined
through three hand measurements and was ~19% too generous, so every derived figure was under-stated while
looking precise.

**The page stops counting, and that is the durable half.** Its two tallies were both wrong, and re-typing
them would have been wrong again twice over: the registry holds **43** pairs today and **42** the moment
#886 removes `workflow-default`, because `check-report-lib` is deliberately registered to two other
plugins as well. So the counts are gone -- the registry is named as the authority, and the entry-point
claim is a rule with two named exceptions held by a test. Same resolution the root `CLAUDE.md` reached
about counting a name inside the document that carries it.

**Score:** 3

#### What makes this deploy extra special

N/A. A consumer receives the mirrored `measure-always-on.ps1` with the guard in it, and the guard is a
no-op for them by construction -- it refuses only where the repo being operated on holds its own copy of
the running script, which a consumer never does. The README and the test are source-side. No consumer
behaviour changes.

**Score:** N/A

#### Pull Request

every shared entry point carries the source-repo guard, and scripts/README.md stops counting

Plugins: workflow-davekjohn

[PR #902](https://github.com/DaveKJohn/claude-code-specialists/pull/902)

---

### DEPLOY: `feat/gate-validates-import-targets-v1` · 20260826-093433

The lint gate now resolves every `@`-import target it can see, and refuses a dead one whose target is
in the tree. Check 4 has validated `[text](target)` links since the beginning; an `@`-import is a
different syntax and matched none of it, so no gate in this repo had ever resolved one --
[issue #874](https://github.com/DaveKJohn/claude-code-specialists/issues/874).

**Why this class is not just another dead link.** A dead link costs a reader one click. A dead import
costs the **session the whole document**: Claude Code drops one it cannot resolve without erroring, so
nothing fails and the instructions simply are not there. This repo's always-on path is assembled out of
exactly three imports, and two of them are not repo-relative -- so the layer that vanishes is the one
carrying the safety rules or the roster, and the only symptom is a session behaving as if it had never
read them.

Check 28 reuses the parser in `scripts/lib/measure-context-lib.ps1` rather than restating the three
resolution rules, so the gate and `scripts/maintenance/measure-always-on.ps1` cannot drift on what an
import means or where it resolves from. Two discriminators keep it honest, both measured before it was
written: a fenced `@(...)` is PowerShell, and a target containing whitespace is prose -- seven and one of
the twelve column-0 `@` lines in the tree respectively. A target outside the repo is counted and named,
never refused, because a `~/`-relative import points into the plugin marketplace clone and CI is a
machine without one.

**Born green**, this repo's standing bar for a new check: 294 files scanned, 2 resolving in-tree imports,
1 outside the repo, 1 line read as prose, 0 findings and 0 exemptions.

**Score:** 3

#### What makes this deploy extra special

N/A. The check itself lives in `scripts/lint/`, which is this repo's own gate and does not travel to a
consumer. What does travel is the plugin mirror of `measure-always-on.ps1`, and only its wording changed
there -- the sentence saying no gate covers this class was true when it was written and is not any more.
No consumer behaviour changes.

**Score:** N/A

#### Pull Request

the lint gate validates every '@'-import target

Plugins: workflow-davekjohn

[PR #901](https://github.com/DaveKJohn/claude-code-specialists/pull/901)

---

### DEPLOY: `fix/the-deploy-section-is-locked-at-the-pr-v1` · 20260825-234507

The DEPLOY section is now **one text in all four places it lands** -- the branch's own
`development-cycle.md`, the PR body, `CHANGELOG.md`, and the developer release notes -- and it is **fixed
at the moment the PR opens**. `ship-pr` refuses to merge when the document has since diverged from what
the PR published, and the branch-entry check in CI refuses the same thing for a PR merged from the GitHub
UI. Neither has a `-Force`, like the step-list gate beside them. What that closes is a window that used to
shut invisibly: an edit made after the review landed in the changelog and from there in the release notes
having been seen by nobody, and because the fold *removes* the document at the merge, the place a reviewer
would compare the two was the one place it no longer existed.

Two changes had to happen for that to be checkable at all, and both are reversals recorded rather than
quietly made. The heading says **`What makes this deploy extra special`** again -- `deploy` was written
August 23, `PR` replaced it August 24 ([#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865)),
and #884 puts it back, because two of the section's four readers are not looking at a PR and the two that
come last are the ones a release is read from. And `Get-PrDescription` now carries the `## DEPLOY:` heading
**verbatim**, promoting nothing, which reverses the August 9, 2026 heading promotion **on today's shape
only**: while body and document were two renderings of one section, a comparison would have had to
reproduce the transform to make sense of them. The legacy `What does the change...` path keeps promoting,
because there the H2 genuinely stays behind, and consumers have such branches in flight.

**Score:** 3

#### What makes this deploy extra special

A consumer meets three things at their next plugin update. Their PR bodies start carrying the
`## DEPLOY:` heading and the section's own levels, instead of a level-shifted copy with the heading
dropped -- so a PR body and the changelog entry it becomes now read as the same document. Their scaffolder
writes `deploy` rather than `PR`, and every wording it has ever written is still **read**, so branches in
flight fold unharmed. And a merge is refused where it used to go through: edit the DEPLOY section after
opening the PR and `ship-pr` stops, naming the first line the PR body does not have, with two ways out --
put it back, or republish deliberately with `open-pr.ps1 -RefreshBody` so the change is reviewable where
the review happens.

The one action a consumer may have to take is a permission line: reading a PR body needs
`pull-requests: read` on the branch-entry workflow, on top of the `contents: read` it has today. Without
it the lock reports that it could not read the body and merges anyway -- deliberately, because `gh`
failing says something about the token rather than about the section -- so nothing breaks, it simply does
not fire.

**Score:** 4

#### Pull Request

The DEPLOY section is locked once the PR opens, and says deploy everywhere

Plugins: workflow-davekjohn

[PR #895](https://github.com/DaveKJohn/claude-code-specialists/pull/895)

---

### DEPLOY: `docs/development-portable-rename-v1` · 20260825-222427

Renamed `DEVELOPMENT-CYCLE-portable.md` to `DEVELOPMENT-portable.md` and repointed every reference
to it repo-wide, so the manual's name no longer contradicts the working file it describes
(`development-cycle.md`, not `development-cycle-cycle`).

**Score:** 1 — cosmetic naming cleanup; no behavior, script contract, or consumer-facing change.

#### What makes this PR extra special

N/A — an internal doc rename, nothing a subscriber of the service would ever see.

**Score:** N/A

#### Pull Request

Rename DEVELOPMENT-CYCLE-portable.md to DEVELOPMENT-portable.md and update every reference

Plugins: workflow-davekjohn

[PR #893](https://github.com/DaveKJohn/claude-code-specialists/pull/893)

---

### DEPLOY: `feat/isolate-workflow-from-consumer-root-v1` · 20260825-204036

Nothing changes for this repo's own release runs today — the computed defaults exempt the source repo
outright, so `CHANGELOG.md` and `releases/` keep resolving to the exact root paths they always did. What
a developer here meets is the plumbing underneath: the two duplicate `Get-SeamValue` copies collapse into
one shared `seam-lib.ps1`, which also carries the four isolate-by-default seams and the new
`Assert-WorkflowIsolatedSeamPath` provenance preflight, backed by its own dedicated suite
(`seam-lib.tests.ps1`, 8 asserts) among the eleven suites this branch touched. Noticed the next time
somebody works in a release script, not before.

**Score:** 2

#### What makes this PR extra special

A consumer no longer risks the plugin reaching into their repo root: the changelog, the three release-note
roots (`releases/development/`, `releases/github/`, `releases/internal/`) and the release-history index
all default inside `workflow-davekjohn/` now, and the provenance preflight refuses outright if a
consumer's own explicit override still resolves outside that folder. This closes a hazard that was
measured rather than theoretical — the root `*.md` sweep could misread a consumer's own permanent doc as a
stray, unfolded changelog entry, and two portable pages (`TICKETWORK-portable.md`,
`CONTRIBUTING-portable.md`) carried hand-written workarounds telling consumers how to dodge it; both are
gone now because the sweep itself no longer needs them — it reads content, not a name list. An
already-adopted consumer does have to notice this on their next fold or cut: entries land in
`workflow-davekjohn/CHANGELOG.md` rather than their root file from here on, and a pending entry already
sitting in their old root `CHANGELOG.md` is not picked up automatically — the re-adoption migration note
this branch added documents exactly that. The same split reaches `releases/README.md`: an already-adopted
consumer's release history moves to `workflow-davekjohn/releases/history.md` from here on (named
`history.md`, not `README.md`, because that folder already uses `README.md` for its own hand-written
seam-answers page) — old rows stay at the root file, new rows land in the folder, the same accepted-cost
duplication as the changelog rather than a silent redirect.

**Score:** 5

#### Pull Request

Isolate the workflow from the consumer's repo root

Plugins: workflow-davekjohn

[PR #890](https://github.com/DaveKJohn/claude-code-specialists/pull/890)

---

### DEPLOY: `fix/remove-prompt-inbox-v1` · 20260825-155219

Removed the prompt-inbox mechanism entirely (issue #882, Dave): the `workflow-davekjohn/prompts/`
folder, the `prompt` skill, its two scripts (`prompt-inbox.ps1` + `prompt-inbox-lib.ps1`, root and
plugin mirror), the `prompt-sessioncheck` SessionStart hook, and every doc that named any of it — the
plugin's own README and scripts README, this repo's `workflow-davekjohn/CLAUDE.md` and
`workflow-davekjohn/README.md`, the root README's two skill-list spans, `SPECIALISTS.md`,
`connectors/README.md`, and a stale cost baseline. No replacement: Dave now hands assignments over as
GitHub issues instead.

Tier 1 — this repo's own contributors notice one fewer skill and, once merged, one fewer SessionStart
hook line; nothing in how a branch, PR or release works changes.

**Score:** 3

#### What makes this PR extra special

N/A — nothing here reaches a service subscriber; the prompt inbox was a workflow-authoring convenience
inside this repo and its consumers, never anything an end user of a published product could see.

**Score:** N/A

#### Pull Request

Remove the prompt inbox from workflow-davekjohn

Plugins: workflow-davekjohn

[PR #889](https://github.com/DaveKJohn/claude-code-specialists/pull/889)

---

### DEPLOY: `fix/release-notes-at-the-changelogs-own-level-v1` · 20260825-125958

**The generated developer release notes now render at `CHANGELOG.md`'s own heading levels.** Entries sit at
`##` and their sections at `###`, exactly where the fold wrote them, so an entry copied out of the record
into a hand-written note pastes at the level it was written at instead of needing a manual shift.
`Build-ReleaseNotes` no longer opens each tier group with `## Tier <n> - <audience>` — measured at `v4.19.0`
in [#881](https://github.com/DaveKJohn/claude-code-specialists/issues/881), that wrapper put all 35 entries
at `###` where their source had them at `##`, a pure one-level shift of every heading in the file. The tier
still decides the order (highest first, ranked inside a tier); it no longer prints a heading to say so,
because where a change reached is a claim about attribution and this document is the record of what changed.
Each entry states its own reach, so nothing is lost with the heading.

**The heading was machine-read, and that is the half the report did not see.** `new-internal-note.ps1`
filtered tier 0 out of the internal note by walking those `## Tier <n>` headings, with a documented
fallback — no tier headings means take everything — that would have carried all 11 tier-0 entries of a
release into the one document tier 0 exists to stay out of: no error, plausible output, a document written
for colleagues listing repo-internal housekeeping. `releases/development/4.x/4.8.0.md` had recorded this
dependency in so many words when it left the wording alone. The filter now reads each entry's **own**
declaration through `Resolve-EntryImpact` — the same reader `Get-PullRequestEntriesByTier` groups on, so
the two cannot disagree — and keeps the container heading as the fallback, because it is the only tier
information an archived note carries whose entries pre-date the declaration entirely, and this script takes
a version: it can be run against any release ever cut.

**`v4.19.0`'s own notes were regenerated rather than edited.** The 35 entries were read back out of
`CHANGELOG.md` at `9983299`, the commit before the cut, and re-rendered by the new generator; the
normalised diff against the published file is exactly the two tier headings gone plus one `---` at the
seam, and the heading profile now matches the pre-cut changelog's 35/70/7 line for line.
`Get-ReleaseTierHeading` and the `Heading` field are kept and documented as unrendered, for the reason
v4.8.0 already gave for this same heading: they are the single source of that wording, every note ever cut
carries it, and removing a published field of that contract is a decision of its own.

**Score:** 2

#### What makes this PR extra special

A consumer's cut writes this document too, so the level correction and the repaired tier filter both
arrive with the plugin — including the failure the filter prevents, which a consumer would have met as
repo-internal entries appearing in the note they hand to colleagues. `RELEASES-portable.md` states the new
shape, so the page describing the document and the generator writing it agree.

**Score:** 3

#### Pull Request

Developer release notes render at CHANGELOG.md's own heading levels

Plugins: workflow-davekjohn

[PR #883](https://github.com/DaveKJohn/claude-code-specialists/pull/883)

---

