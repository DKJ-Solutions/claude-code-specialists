## `fix/adopt-config-plugin-root` changelog

### Branch title

The adopt-config page stops sending consumers to the author's own disk

### Branch ID

20260809-010428

### Branch type

fix

### What does the change on this branch bring to main?

The `adopt-config` skill page printed both of its commands as an absolute path into the plugin author's
own cache — `C:/Users/DaveKok/.claude/plugins/cache/.../3.8.0/scripts/...` — and shipped that way in
`v3.8.0` and again in `v3.9.0`. Wrong for every consumer twice over (a different username, often a
different OS) and pinned to a version that goes stale at each release. It was the **first command a
consumer runs to reach v3.9.0's headline feature**, which is the release that had just gone out.

**Found by verifying an instruction rather than by reading the page.** The v3.9.0 highlights were about
to tell consumers to run the same script through `$env:CLAUDE_PLUGIN_ROOT`, and checking whether that
actually resolves — it does not, outside a plugin-owned component — is what surfaced the page behind it.
The `cut-release` skill has this lesson written down about its own first command; `adopt-config` was
written after it and did not inherit it.

**The page now uses `${CLAUDE_PLUGIN_ROOT}`**, like the other ten skill pages, and says in one paragraph
what that form does and does not resolve — so a reader who wants to paste the line in a terminal knows
why it will not work there.

**A gate, because the page was correct-looking and nothing read it.** New lint check **22**: the `-File`
argument of a runnable command in a shipped `SKILL.md` may not be an absolute path.

**The subject is the COMMAND and not the path, and that was decided by measuring rather than by
argument.** The obvious rule — no absolute paths under `plugins/` — is **born with three findings and
all three are correct**: comments in `check-report-lib.ps1` and `check-roster-sync.ps1` that quote
`C:\Users\x\.claude\...` precisely in order to explain a path-mangling bug. A check that needs an
exemption list on its first run is the shape this repo already has scar tissue from, so the rule reaches
only the one token a reader is told to execute. Over the tree's **26** invocations in **11** skill
pages: 23 use the substitution, 3 use a `<plugin>` placeholder, **0** exemptions.

**The `<plugin>` placeholder passes on purpose**, and that is asserted rather than left implicit: angle
brackets ask the reader to substitute, while an absolute path reads as a line to paste. A test pinning
only the positive would pass against a stricter check that starts accusing the teardown page.

**The script's own check list was three behind, and is caught up in the same change.** The docstring
enumerated checks 1–18 while 19, 20 and 21 had been added without being listed — adding a 22nd to an
already-stale list would have widened the gap it sits in. All four are now described.

Six asserts pin both directions plus the deliberate pass, including a POSIX home path, which a
drive-letter-only rule would miss.

**Noted, not repaired: the teardown page's three commands use `<plugin>/...` where every other page uses
the substitution.** Honest, and strictly worse than a form that actually resolves when the skill runs —
but it is a consistency question rather than the defect this branch is about, and bundling it in is how
a diff stops being reviewable.

Plugins: specialists-workflow-davekjohn

### Significance

#### Tier 0

The check list in the lint's own docstring was three entries behind and is now current, which matters to
whoever adds check 23. The gate itself costs a developer here nothing: the tree already passed it.

**Score:** 2

#### Tier 1

Nothing here is legible outside this repo's own developers and the consumers below — there is no
organisational effect distinct from the consumer-facing repair itself, which tier 2 states.

**Score:** N/A

#### Tier 2

A consumer following the `adopt-config` page ran a command naming a directory that does not exist on
their machine. That is the entry point to `v3.9.0`'s headline feature, so the failure landed on the
readers most likely to be adopting. Not a 5: the skill route worked all along, so nobody was blocked —
they were sent to a path that could only fail, with no hint of the working alternative.

**Score:** 4

### Pull Request

