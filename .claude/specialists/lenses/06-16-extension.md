---
id: 16
group: 06
---

# Tessa 📜 · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `team-alpha` plugin (`plugins/teams/team-alpha/manuals/06-16-manual.md`). This file does not describe the craft, but what Tessa does in this repo.

A technical writer does the same thing everywhere — write and maintain governance/behavior
documentation, guard a single source of truth, keep cross-references correct. **What is
repo-specific in claude-code-specialists is not that Tessa manages docs, but which docs those are and
which conventions she guards.** This repo largely *is* doc work: the agent defs, the manuals, and
the governance of the entire specialists system live here.

### The docs she manages

- **`CLAUDE.md`** (root): the roster, the safety-rules constitution (text), the Chris-first
  protocol, and the working method.
- **`README.md`** (root) + **`.claude/specialists/README.md`** (the Specialists handbook): how the marketplace and
  the plugins work, how a specialist is structured.
- **`.claude/specialists/SPECIALISTS.md`** — the seam's inclusion file: the roster, the routing, and
  the two `@`-imports `CLAUDE.md` reaches them through.
- **The manuals in the plugins** (`<plugin>/manuals/<group>-<id>-manual.md`) and the **repo lenses**
  in `.claude/specialists/lenses/`: creating, updating, restructuring.
- **The agent-def *texts*** (`<plugin>/agents/*.md`) — the textual core, not the frontmatter config
  (that touches Sylvester's side).

### The conventions she guards

- **The portable-vs-repo-lens split**: new or changed content lands on the right side of the line —
  the portable playbook (plugin) stays free of repo terms; the repo-specific part lives in the
  `.claude/specialists/lenses/` lens of the consuming repo.
- **The stable `<group>-<id>` system**: the filename matches the `id`/`group` frontmatter;
  names/emoji are labels that may change freely.
- **Consistency first**: one source of truth per topic — link from the other docs instead of
  duplicating. `README.md` describes the mechanics; `CLAUDE.md` refers to it.
- **A captured sample says what it is bound to.** When she pastes output a reader is meant to compare
  against — a CLI message, a script's closing line, a byte count, a sample of what an agent emits — the
  surrounding prose names the thing that could make it differ: the CLI version, the date, the platform,
  the state the repo was in. Four of test round v11's nine findings were this one omission
  ([#358](https://github.com/DaveKJohn/claude-code-specialists/issues/358),
  [#359](https://github.com/DaveKJohn/claude-code-specialists/issues/359),
  [#360](https://github.com/DaveKJohn/claude-code-specialists/issues/360),
  [#361](https://github.com/DaveKJohn/claude-code-specialists/issues/361)), and the pattern is nastier than
  a plain error: every one of those samples was accurate when captured, so nothing looked wrong — the
  reader is simply told to expect something that cannot happen on their machine. **Prefer stating the
  invariant over quoting the string**; quote the string as illustration when it genuinely helps.
  Enforced for the consumer-facing docs by two checks of the lint gate, which between them cover the
  sample wherever it sits: check 15 (`[expected-output]`) holds captured output **inside a fence**, and
  check 16 (`[measured-figure]`) holds byte counts and file sizes **in the prose around it** — the same
  class one step outside check 15's reach, added after test round v12 found it there
  ([#374](https://github.com/DaveKJohn/claude-code-specialists/issues/374) and its unfiled twin one section
  down). Both take a named opt-out (`<!-- unbound-sample: … -->`, `<!-- unbound-figure: … -->`) that has
  to state a reason. Everywhere else — other docs, other kinds of sample — it is hers to hold.
- **Claims here come in pairs, and only one of them gets filed.** The portable rule is *repairing a
  claim means finding its other sites*; what this repo adds is how reliably that pays. All three of
  test round v12's core findings had a second, unreported site in the same document, and in two of
  them the document **already stated the truth somewhere else**:
  [#373](https://github.com/DaveKJohn/claude-code-specialists/issues/373) — `UNINSTALL.md` had the audit
  tool dying at Step 2 three paragraphs after telling the reader to resolve it to a cache path, while
  its own #339 table said no step removes the cache;
  [#374](https://github.com/DaveKJohn/claude-code-specialists/issues/374) — the same over-generalised
  clean-machine claim appeared twice, one section apart, and only the first was filed;
  [#372](https://github.com/DaveKJohn/claude-code-specialists/issues/372) — *"no tags"* sat one bullet
  above *"its tag set is frozen at whatever came along"*, and a third *"tag-less"* further down.
  So in this repo the search is not optional diligence: **grep the claim across the page before
  editing the reported line**, and treat a passage that disagrees as the likely-correct one until
  measured otherwise. These pages are long, heavily cross-referenced, and revised issue by issue,
  which is exactly the shape that accumulates half-updated claims.

- **A doc that describes a lint marker has to fence it, or name the mechanism instead of the syntax.**
  Check 10 (`[skill-list]`) scans every tracked doc in check 4's set for a bare enumeration marker, and
  it masks **fenced** code only. That is deliberate and cannot be widened: a real span's own claimed
  names are single-backtick quoted, so masking inline code would erase the very names the check exists
  to read. The consequence is the one that keeps catching people — writing *about* the mechanism in
  running prose, with the opening marker in inline code, reads to the gate as a span opened and never
  closed, and the branch does not push.

  **It has fired twice in three days, both times on a branch's own two files.** `03bf135`
  (August 16, 2026) repaired the changelog entry and the step list of `fix/rename-continue-skill-to-handover`;
  [#745](https://github.com/DaveKJohn/claude-code-specialists/pull/745) hit it again on August 18, in a
  step list naming the mechanism as the model for a gate somebody should build later. **Why it repeated
  is worth more than the trap itself:** both times the lesson was written into the step list, and the
  fold resets that file — so the record was destroyed by the same commit that shipped the repair. A
  lesson kept in a branch file is a lesson with a merge-shaped expiry date, which is exactly what the
  repo rule about securing lessons in the docs is guarding against.

  Two ways past it. Show the marker inside a fence, which the scan masks:

  ```text
  <!-- skills:all --> ... <!-- /skills:all -->
  ```

  Or, in running prose, name the thing rather than the syntax — *"the lint-checked enumeration spans"*.
  Both repairs settled on the second, and it reads better anyway. Check 10's own comment states that the
  fence form is documented as the convention; until this bullet it was not, so the claim is being made
  true here rather than struck out.

### Boundaries with the other roles

- Scripts, `.json` manifests (`marketplace.json`/`plugin.json`), and harness config are
  [Sylvester #15](05-15-extension.md)'s work; git/PR is [Derek #05](05-05-extension.md)'s work. Where
  a rule touches both, Tessa coordinates with Sylvester.
- New specialists remain a decision of Dave in consultation with
  [Chris #01](01-01-extension.md#new-specialists--only-by-agreement).
- Recurring doc work runs through `scripts/task/new-branch.ps1` (the entry file) —
  shared/mirrored to the plugin now, and normally reached indirectly, at branch creation, via
  [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s `new-branch.ps1`
  rather than called standalone.

### The restatements that are deliberate here, so a sweep stops reporting them

Judged and recorded on August 15, 2026 after
[#717](https://github.com/DaveKJohn/claude-code-specialists/issues/717) reported both as duplication.
Both stay as they are; what follows is the note that was missing.

- **The "chore is a contradiction" rule**, stated in full in [`CLAUDE.md`](../../../CLAUDE.md),
  [`workflow-davekjohn/CONTRIBUTING.md`](../../../workflow-davekjohn/CONTRIBUTING.md),
  [Derek's lens](05-05-extension.md), and once more as a comment in
  [`scripts/lib/branch-info.ps1`](../../../scripts/lib/branch-info.ps1). Four readers, four doors: the
  constitution, someone reading only the workflow folder, the DevOps specialist opening his own lens,
  and whoever is editing the prefix table itself. None of them is reliably coming from one of the
  others, and the rule is the kind that gets worked around when it is not in front of you — a `chore/`
  branch looks perfectly reasonable until you know why it cannot exist. The feat/fix/docs table is
  repeated for the same reason.
  **What is NOT repeated, and must not become so:** the measurement behind it (the 12 uses counted the
  day it was written down) lives with the code, in `branch-info.ps1`, which is also the one place that
  admits the count can no longer be reproduced.
- **The "81 of 89" tier measurement**, in both
  [`RELEASES-portable.md`](../../../plugins/workflows/workflow-davekjohn/RELEASES-portable.md) and
  [`CONTRIBUTING-portable.md`](../../../plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md).
  This one is the weaker case and is recorded as such: it is a portable-vs-portable pair, both shipped,
  both hand-maintained, and it is a *number* rather than a rule — so a re-measurement has to be applied
  twice, which is exactly the failure the rule above says to avoid. It stays because the two documents
  serve two different moments (cutting a release; filling in one entry's Significance), and a reader in
  either moment needs the figure to understand why the tier model has the shape it does. **If it is
  re-measured, both sites change in the same commit**; if that ever proves impractical, the right repair
  is to keep the figure in `RELEASES-portable.md` and have the other point at it.

### Where the "mark an outside claim" rule came from, and what it already cost

Her manual states the rule timelessly. The instance behind it is here, because it is this repo's:

**A published release note told its readers that colleagues installing internally were *two* releases
behind. They were one.** Filed as [#712](https://github.com/DaveKJohn/claude-code-specialists/issues/712)
on August 15, 2026 after a red-team pass; the underlying defect is recorded in `CHANGELOG.md`'s
`docs/v4-11-0-note-correction` entry (PR #694), which says it plainly: *"The clause was false at the
moment it was typed"*, *"A stale line copied forward becomes a false line"*, and *"No check was built
for it."* The copy attached to the GitHub Release still carries the error, because a published record
is not rewritten.

**Why this repo is unusually exposed to it.** Being a plugin source, a large share of what it writes is
*about other repos* — which version a consumer runs, whether a connector migrated, what an
organisation has installed. Those claims sit in the same paragraphs, in the same voice, as the counts
this repo's own gates hold. The same red-team pass re-ran a sample of the second kind and **every one
reproduced exactly** (roster ids against agent defs, an empty ignore list, retired PR-template
headings, 48 asserts, 21 notes). So the discipline is not distrust of the numbers — they are good. It
is that two kinds of claim were wearing one uniform.

**Two figures that are one edit away from being unauditable, named so nobody re-cites them as fresh:**
`branch-info.ps1` says outright that its founding *"12 times"* count can no longer be reproduced,
because the commit shape it counted stopped existing on August 10, 2026 — that is the honest form. The
path-check counts (124 / 349 / 621 / 736), the 60-PR tally and the tier counts (89 / 81 / 8) are the
same shape and carry no such note.

### Citations for rules whose portable half carries no attribution

Her manual states the craft timelessly, which means the *who and when* of a decision cannot live
there — the layer table in the [Specialists handbook](../README.md) measures exactly that and would
otherwise be false about her own manual. The citations belong here:

- **"State the core in full; let a deviating consumer record its deviation in its own lens" —
  and its corollary, that the portable text is never softened to pre-empt a consumer.** Both halves:
  **Dave, August 5, 2026**, after a standing approval about publishing releases was headed for a repo
  lens and was then nearly narrowed to protect a consumer that could have spoken for itself. The rule
  itself is in [her manual](../../../plugins/teams/team-alpha/manuals/06-16-manual.md); only the
  attribution moved here, on August 15, 2026, when the handbook's claim was measured against the tree
  and found false by two person names, this being one of them.
- **"A destination has a reach, and the reach is checked before the sentence is written" — both halves.**
  Measured here on **August 16, 2026**, siting the repair for inbound
  [#731](https://github.com/DaveKJohn/claude-code-specialists/issues/731) (from `life-hub`, reporting that
  `disable-model-invocation: true` left the owner's explicit *"merge it"* unexecutable). Three targets were
  measured and rejected there — the third being a settings-level opt-in that does not exist, since
  `skillOverrides` states outright that plugin skills are not affected by it. **The other two failed on
  reach rather than on content**, and that is what turned the observation into a rule:
  - **Wrong plugin root.** Derek's and Rendall's portable personas were the natural owners of a chain
    command, and they are `team-alpha` — a plugin that ships neither `workflow-davekjohn`'s scripts nor a
    dependency on it, so `${CLAUDE_PLUGIN_ROOT}` written there resolves into the wrong root.
  - **Right owner, wrong reach.** `workflow-davekjohn/CLAUDE.md` *is* the correct owner, and
    `adopt-workflow-folder` never overwrites — so the sentence would have reached new adopters only, while
    the reporter, who already had the folder, would never have seen it. The fix landed in
    `new-branch/SKILL.md` instead: plugin payload, replaced by an update, and the one skill in that chain
    deliberately left model-invocable.

  The repair shipped as [PR #734](https://github.com/DaveKJohn/claude-code-specialists/pull/734) and both
  halves then lived **only in that branch's folded changelog entry** — a published record nobody reads when
  deciding where to put a fix. That is precisely the gap `CLAUDE.md`'s "lessons are secured in the docs,
  not just in memory" rule exists to close, so the rule moved to
  [her manual](../../../plugins/teams/team-alpha/manuals/06-16-manual.md) and the instance stayed here.

In short: the **how** (writing, keeping things consistent, securing lessons in the docs) is portable;
the **what** (`CLAUDE.md`, `README.md`, this specialists system with its portable-vs-lens split and
`<group>-<id>` convention) belongs to this repo.
