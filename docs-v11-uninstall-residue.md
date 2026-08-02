### UNINSTALL names what it leaves behind, and what the leftover does · Docs · 2026-08-02

Three findings from test round v11, all in `UNINSTALL.md`, all the same shape: the page describes an
operation correctly and stops one sentence before the consequence.

**Step 2's predicted error text was stale, and the CLI now suggests the wrong remedy** (inbound #359).
On CLI `2.1.220` a scopeless `uninstall` no longer says *"not installed at scope user"* — it names the
scope and the settings file, which is an improvement, and then suggests `plugin disable --scope local`.
That is a different operation: it writes a local disable key on top of the project setting and leaves
the install in place, so Step 4's verification does not come back empty and the reader has added a key
instead of removing one. The measured message is now quoted, the CLI's own suggestion is explicitly
ruled out, and the paragraph says which part of it is version-bound — the flag is the invariant, the
wording is not.

**Step 5 did not mention that `marketplace remove` leaves an empty key** (inbound #357). It edits
`~/.claude/settings.json`, removes the `davekjohns-workshop` block, leaves `"extraKnownMarketplaces": {}`
and re-serialises the file. Step 2 already says exactly this about `"enabledPlugins": {}` and calls a
diff there the command working rather than a fault; the mirror-image sentence was simply missing. Worth
stating because it settles a question a clean-machine check keeps raising: after a by-the-book teardown
that row is never *literally* clean — the keys are empty, not absent.

**The surviving scaffold prose was listed as inert, and it is not** (inbound #362). `CLAUDE.md` is loaded
into every session as project instructions, so the two lines the bootstrap wrote keep telling later
sessions — in the channel that outranks their defaults — that the repo is governed by a system that is
no longer installed. Two separate fresh sessions flagged the contradiction unprompted. The reasoning for
keeping the lines is unchanged and still right: prose loads nothing on its own, and a script that deletes
sentences out of a governance file is doing the damage the classification exists to prevent. What changed
is that the row is now a to-do with two one-line remedies rather than a note ending in "yours to decide",
and the section's opening count moved with it — three of the five leftovers are correct, two are things
to act on.
