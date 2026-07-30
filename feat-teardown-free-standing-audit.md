### The teardown proves standing free instead of claiming it · Feat · 2026-07-30

The last open item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s target shape,
and the one that could not be done as written.

**The item was "reword category 3 plugin-neutrally, so it stays true after an uninstall"** — turning
*"Derek opens the PR"* back into *"changes go in via a branch and a PR"*, a rule that survives the plugin
because it never needed the character. **A script must not do that.** It is the repo owner's governance
prose, and a plugin rewriting an owner's `CLAUDE.md` on its way out is precisely the damage the
three-category classification exists to prevent. Delivering the item literally would have meant building
the thing the design forbids.

**So the deliverable is the half a script legitimately can do: find them.** The teardown now closes with a
**free-standing audit** that answers the question the requirement actually poses — *after this, does the
repo stand free?* — instead of the question every other section answers, which is *what did the bootstrap
put here*.

```
-- free-standing audit: LIVE references left after this teardown --
   scanned 24 file(s) under CLAUDE.md, .claude/ and scripts/ against 19 known specialist name(s)
  [LIVE]   CLAUDE.md:3 -- name 'Derek'
  [LIVE]   CLAUDE.md:6 -- specialist id + name 'Derek'
  [LIVE]   scripts\repo-config.ps1:3 -- plugin-only contract function
```

Three kinds of hit, because they have three different answers — and the choice is **per line, not per
file**, which is why it reports lines:

| hit | answer |
|---|---|
| a **specialist id** (`05-05`) — a roster row, a routing table | usually **delete**: it only ever existed for the plugin |
| a **name** (`Derek`) — a valid rule phrased through a character | usually **reword**: keep the rule, drop the name |
| a **plugin-only contract function** (`Get-RosterPath`, `Get-RosterIgnoredIds`) | **delete the line**, keep the file |

That third one is new information rather than a restatement: `repo-config.ps1` is category 3 and is
correctly *kept* — but two of its eight contract functions exist only to serve the roster check, and "keep
this file" and "keep every line in this file" are different answers. Nothing said so before.

**Report-only, unconditional, and it runs on a dry run too.** It removes nothing, so it needs no `-Apply`,
and a preview that cannot tell you what would still be left is not the inventory a reader needs in order
to say yes. A clean repo gets `[FREE]`, which is the requirement met *verified rather than assumed*.

**The closed loop is the assertion that makes it more than a grep.** A test applies the exact reword the
audit advises and asserts the audit then reaches `[FREE]`. Without that, an audit could name references
that no reasonable edit ever clears — findings that are technically true and practically noise.

**Three boundaries, each of which would otherwise be a quiet false claim:**

- **The names come from the plugin's own payload** (an agent def's `name:`, a persona's H1), never a
  hardcoded list that rots on the next rename. But this skill ships inside **one** plugin and sees only
  that plugin's specialists — a consumer running a domain plugin has names it does not know. The **id scan
  is the general net** (a `<gg>-<ii>` token is name-independent, so it catches a specialist from any
  plugin) and the name scan is the extra pass. Stated in the skill rather than left for someone to discover.
- **Matching is case-insensitive, deliberately biased toward over-reporting.** For an audit whose purpose
  is establishing that nothing was missed, the expensive failure is the reference it did not find — not the
  one a reader dismisses in five seconds. Every hit carries `file:line`, so a false positive is cheap and a
  false negative is silent. Same direction `Test-LooksGenerated` resolves its doubt, for the same reason.
- **History is out of scope and never rewritten.** `CHANGELOG.md` and `releases/` are excluded entirely;
  other root prose is **counted, not listed** — a pointer, not a work queue, since nothing loads, resolves
  or gates on it.

**A bug in the audit's own pattern, found by running it rather than by reading it.** The first version
anchored the plugin-only-function check as `\b(Get-RosterPath|...|\$script:RosterPath|...)`. A shared
leading `\b` in front of `\$` demands a word character immediately before the dollar, so it can never match
an assignment at the start of a line — which is exactly where `$script:RosterPath = 'CLAUDE.md'` lives. The
fixture caught it immediately: line 4 (`function Get-RosterPath`) was reported, line 3 was not. Each
alternative now carries its own anchor, and the regression is asserted. **A pattern that matches some of
what it claims is worse than one that matches none — the partial hit reads as coverage.**
