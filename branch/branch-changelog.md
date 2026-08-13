## `docs/skill-pages-state-the-audience-tier` changelog

### Branch title

the skill pages show the tier sections the scaffolder actually writes

### Branch ID

20260813-111215

### Branch type

docs

### What does the change on this branch bring to main?

Two portable skill pages showed a `### Significance` shape that `Get-EntryAskedTiers` does not produce.
Both now show **tier 0 plus the one audience tier**, which is what the scaffolder writes once
`Get-ReleaseAudienceTier` is answered.

**`open-pr` was the worse of the two, and it was wrong under every configuration.** Its example block
carried `#### Tier 1` above `#### Tier 2` and **no tier 0 at all** — while tier 0 is in every entry and is
the one tier that can never be `N/A`. The scaffolder writes `@(0, audience)` with an audience stated and
`@(0, 1, 2)` with none, so no repo has ever produced that block. It now leads with tier 0 and names the
retired shape, since a reader who copied the old example will want to know what changed.

**`new-branch` was a self-contradiction rather than a falsehood, which is why it needed reading before
repairing.** Its Significance section *does* document the audience knob correctly, in full, with the
measurement behind it — but forty lines below an opening that announced a sub-section "for each of the
three reaches" and showed three empty tiers. A reader who skims the first block gets the answer the rest
of the page spends three paragraphs retiring. The opening now shows the two-section shape and points down;
the reasoning stays where it was, because the page already said it well and saying it twice is how the two
halves drift apart.

**What was deliberately left alone.** The three-section shape is **correct** for a repo that has stated no
audience — `Get-EntryAskedTiers` returns every tier there, on purpose, so that a consumer taking the plugin
update is not silently switched to a narrower question. So this is not "three was wrong"; it is "three is
the unconfigured case and was being shown as the rule". `branch/templates/`, the `cut-release` skill and
`CONTRIBUTING-portable.md` were checked in the same sweep and already state it correctly.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

Nothing changes for this repo's own scaffolding — it already wrote the right sections; only the pages
describing it were off. What it prevents is the failure that produced the `open-pr` block in the first
place: an entry written from an example that omits tier 0, which the completeness gate then refuses at the
PR with the author unable to see why the page they followed was wrong.

**Score:** 2

#### Tier 2

A consumer reads these two pages to learn what the entry looks like, and one of them showed a block their
scaffolder never writes. The `open-pr` example omitted the only tier that can never be `N/A`, so following
it produced an entry that fails the gate. Both pages now also say the answer is a repo-level decision
rather than a fixed count, which is the part that lets a tier-1 repo read them without translating.

**Score:** 3

### Pull Request

