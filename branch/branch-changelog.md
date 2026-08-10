## `fix/no-skill-ships-with-a-byte-order-mark` changelog

### Branch title

the adopt-config skill registers, and no SKILL.md can ship a BOM

### Branch ID

20260810-165439

### Branch type

fix

### What does the change on this branch bring to main?

`plugins/workflows/workflow-davekjohn/skills/adopt-config/SKILL.md` shipped with a UTF-8 byte-order mark
(`EF BB BF`) in front of its opening `---`, so a frontmatter parser that wants `---` at offset 0 read the
file as having no frontmatter at all. The skill therefore registered under no name and never appeared in a
model-facing skill listing — the only model-invocable skill of the eleven in the two shipped plugins to go
missing, and confirmed absent from this session's own listing. No error was raised anywhere; the page was
simply not there. The three bytes are gone.

The BOM is invisible in every editor a reviewer would open the file in, **and invisible to this repo's own
gate**: every reader in `check-plugin-integrity.ps1` goes through `ReadAllText`, which detects and strips a
BOM before any regex sees it. So the defect could not be found by reading and could not be found by the
lint. Check 26 reads the **first three bytes** of every frontmatter-bearing shipped document — the 26 agent
defs, 26 manuals, 4 personas and 13 skill pages — and holds them to a literal `---`.

Its subject is **registration**, which is what fixes the scope: a top-level `skills/<name>/SKILL.md` is
what the harness registers, so a deeper `references/SKILL.md` is deliberately out of scope rather than
held to a requirement the harness does not have. Measured before widening past `SKILL.md` rather than
assumed — 69 documents, all four sets non-empty, **zero findings** once the one BOM was stripped and **zero
exemptions**, and the check was verified to fire on the real defect by reintroducing it. A rule needing an
exemption list on its first run is the shape this repo has scar tissue from; this one is born green and
would have caught the defect the day it landed.

Reported as [#581](https://github.com/DaveKJohn/claude-code-specialists/issues/581) from
`BWJ-ecommerce/smartwatchbanden`, who found it by diffing first bytes because reading cannot. They left the
causal claim open on purpose; it was closed here by ruling out the one alternative — the description length
— which measured **433 characters, the shortest of the five** model-invocable skills.

One thing found on the way and repaired in the same file: the gate's own docstring list of checks stopped at
**22** while checks 23, 24 and 25 had been in the body for days. Appending a 26th entry to a list that
already skipped three would have made the map worse than either fixing it or leaving it alone, so all four
are now described.

### Significance

#### Tier 0

The gate's docstring is a complete map of its checks again — it had silently stopped at 22 while three more
were live, which is the one document a developer reads to find out what this gate actually enforces.

**Score:** 2

#### Tier 1

An entire class of defect stops being unfindable. A BOM survives review because no editor renders it and
survived this gate because every reader here strips it before looking, so the only person who could catch
one was somebody who thought to diff bytes. Now it is a named line with the file in it.

**Score:** 3

#### Tier 2

A fresh consumer can reach `adopt-config` — the one skill whose whole job is filling the seam — at exactly
the moment it matters, during bootstrap, and which they were least equipped to notice was missing rather
than hidden by design. Consumers whose seam is already filled see no change.

**Score:** 4

### Pull Request

