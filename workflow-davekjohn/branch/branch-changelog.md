## Branch `docs/destination-reach` changelog - 20260816-222808

### What does the change on this branch bring to main?

Tessa's portable manual gains a hard rule: **a destination has a *reach*, and the reach is checked
before the sentence is written.** Picking the right layer is only half of siting a change; the other
half is whether that file can still arrive at the reader who needs it. Two destinations look correct
and are unreachable, and both fail quietly — nothing errors, the text is simply never received.

**A file a plugin scaffolds into a consumer's repo is written once and never again.** The scaffolders
are deliberately additive, so a repair written into a scaffolded file reaches new adopters only, while
every consumer who already ran the scaffold keeps the old text forever — and they are the ones who hit
the defect. A fix that has to reach an already-adopted consumer ships as **plugin payload**, replaced
by an update, never as an edit to the copy in their tree. **And `${CLAUDE_PLUGIN_ROOT}` resolves per
plugin**, to the one shipping the file it is written in — so a command aimed at one plugin's scripts
cannot live in a document a different plugin ships. Check which plugin owns the *file you are typing
into*, not which plugin owns the script.

**Both halves were measured on August 16, 2026 and had nowhere to live until now.** They came out of
siting the repair for inbound [#731](https://github.com/DaveKJohn/claude-code-specialists/issues/731),
where two candidate destinations were rejected for **reach** rather than for content: `team-alpha`
personas could not carry a `workflow-davekjohn` command, and `workflow-davekjohn/CLAUDE.md` was the
right owner but reached new adopters only — which is exactly the consumer the report came from. Until
this branch the lesson existed solely in that PR's folded changelog entry, a published record nobody
consults when deciding where to put a fix. That is the gap `CLAUDE.md`'s *"lessons are secured in the
docs, not just in memory"* rule exists to close.

**Sited by the rule it records, which is the only fair test of it.** The rule is portable payload
(`06-16-manual.md`, replaced by a plugin update, so it reaches consumers who adopted long ago); the
measured instance and the two rejected destinations are this repo's business and stay in her lens,
under the section that already collects citations whose portable half is deliberately timeless. No
runnable command is quoted in either file, so neither can carry a wrong plugin root.

#### Tier 0

The lesson is readable at the moment it is needed — beside the manual's existing "portable is the
default, the lens is the exception" rule, which answers *which layer* where this one answers *whether
that layer still reaches anyone*. Previously it was recoverable only by reading a merged branch's
changelog entry.

**Score:** 3

#### Tier 2

Every consumer's Tessa gains the rule with the next plugin update, and consumers are where the failure
actually bites: they are the ones holding scaffolded files that will never be rewritten. Noticed the
first time someone sites a repair, not before.

**Score:** 2

### Pull Request

A doc's destination is checked for reach before the sentence is written
