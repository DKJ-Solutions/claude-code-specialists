## `docs/the-contribution-cycle-lives-with-the-plugin` changelog

### Branch title

The contribution cycle lives with the plugin, not with this repo

### Branch ID

20260810-105426

### Branch type

docs

### What does the change on this branch bring to main?

`CONTRIBUTING.md` described the cycle that the `workflow-davekjohn` scripts run, in the voice of a rule,
while stating this repo's own answers as that rule. It is split: the cycle moves to
[`plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md`](plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md)
and names the **seam** wherever a repo owns the answer, and the root document keeps only this repo's
answers under a `## Specific to this repo` slot — the manual/lens split applied to the contribution cycle.
The root page opens with a table mapping each seam function to what this repo answers it with, so a drift
between the document and `scripts/repo-config.ps1` has one place to be visible instead of being woven
through five paragraphs of prose.

Four statements a consumer would have read as their own rule are gone, and each was measurably false
outside this repo: that there are three branch prefixes and no `chore/` (theirs has eighteen), that the
lint gate is `check-plugin-integrity.ps1` (`Get-LintScript` answers it), that the merge waits on a check
named `lint-en-tests`, and that tier 1 earns a minor — which is the shared gate's **floor**, not a repo's
policy, and the portable half now says so and asks each repo to state its own where it is stricter.

**Check 4 was widened in the same movement, because the new document would otherwise have gone out
unguarded.** Every rule in the dead-link scan names either a shape of file (`SKILL.md`, `*-manual.md`,
`*/agents/*.md`) or a place it takes whole (the root, `branch/`, `releases/`), and a markdown file at
**plugin level** matched neither — which is where each plugin's own README sits. Measured: five such files
were already in the tree, their links never once read, and the portable guide would have been the sixth.
`plugins/` is now read whole and the scan set is deduped once, so widening a rule can never double-report;
all six were clean, so the wider gate arrives green. This is the third time this block has been widened for
the same reason — a file leaves the scan set by *moving*, and nothing reports that it has — which is why the
rule now names a place rather than a shape.

Inbound [#566](https://github.com/DaveKJohn/claude-code-specialists/issues/566) reported it, and one of its
load-bearing facts did not survive verification: it proposed `Resolve-PluginScript -RelativePath …` as the
form a consumer invokes a shared script with, and no such function exists anywhere. The real form is
`${CLAUDE_PLUGIN_ROOT}`, which is what the portable half documents. The observation underneath — that the
repo-local script paths in the old text resolve to nothing in a consumer — stood.

### Significance

#### Tier 0

The dead-link gate reads six documents it had never opened, both plugin READMEs among them, and the rule
that let them through is replaced rather than patched: `plugins/` is a place taken whole instead of a list
of file shapes that goes stale each time a document is written or moved.

**Score:** 3

#### Tier 1

The contribution cycle has one description instead of one per repo. A change to how work moves — a new
gate, a renamed section, a different bump rule — is written once in the plugin and reaches every repo that
enables it, rather than being re-explained in each and drifting from the moment it is copied.

**Score:** 3

#### Tier 2

A consumer can adopt the contribution guide instead of rewriting it. The repo that filed this measured the
blockage rather than disliking it: a verbatim copy failed its own lint gate on five paths and six anchors
that do not exist there, so adopting meant a rewrite, and a rewrite is the second source they had spent
four PRs that week removing.

**Score:** 4

### Pull Request
