### Migrate this repo onto the seam · Feat · 2026-07-29

The last piece of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221): the workshop now
runs the layout it ships. `.claude/plugins/` is **gone** — the 19 repo lenses live in
`.claude/specialists/lenses/`, the handbook moved to `.claude/specialists/README.md`, and
`.claude/specialists/SPECIALISTS.md` holds the two imports plus everything specialist-shaped that used to
be woven through `CLAUDE.md`. **`CLAUDE.md` went from 282 lines to 184 and from two imports to one.**

What moved out: the whole *"The Claude Specialists — who does what"* section (visible sender, the shared
laziness trait, where this runs, the loading strategy) and *"The team: roster & routing"* (the routing
table, the subagent id line, and the two paragraphs on why the descriptions are deliberately not
repeated). 99 lines. What stayed: the safety-rules constitution, the general working practices, the
language section, the structure pointer and the repo's safety implementation — with their lens links
repointed.

**Five things could have broken silently, and each was caught by a check rather than by reading.**

- **Link depth.** Lenses sat four levels deep and now sit three, so every `../../../../CLAUDE.md` was
  wrong by one hop. Eight lens files fixed; the dead-link scan confirmed the rest.
- **Moved headings.** Three links pointed at anchors that travelled with the text into `SPECIALISTS.md`
  (`#the-claude-specialists--who-does-what`, `#the-team-roster--routing`). The anchor scan named all
  three; they now point at the inclusion.
- **`Get-RosterPath` still said `CLAUDE.md`.** That one is nasty precisely because it fails *quietly*:
  the roster check would have read a file that legitimately no longer has a roster and reported the whole
  team as missing. Repointed at the inclusion, verified by a live run — 0 errors, no missing ids.
- **The archived release notes.** Twelve files linked to lens paths that this change moved. Repointed —
  **paths only, no prose** — and that deserves stating rather than sliding past: history is not
  rewritten, but a link is not a claim about the past. It points at a file *we* moved, both sides are
  ours, and the alternative was a dozen permanently dead links inside the scan set, forcing an exception
  that would hide real breakage later. Every sentence stands exactly as written.
- **Empty directories.** `git mv` leaves the tree behind; `.claude/plugins/` was removed explicitly, so
  "remove one directory" is now literally true here.

**Verified after the move, not assumed:** lint gate 0 errors, roster check exit 0, script-contract check
0 errors, drift lint exit 0 (and it resolves the lenses at the new path), and all **17 suites green** —
`bootstrap-drift` 87, `teardown` 101, `roster-sync` 157, `script-contract` 128, `shared-scripts` 110,
`release-lib` 123, and the rest. `CLAUDE.md` carries exactly one import and zero lone LFs.

**One boundary held deliberately.** Item 2 of #221 — rewording the surviving rules plugin-neutrally, so
"Derek opens the PR" does not outlive Derek — is **not** in this change. It rewrites the sentences of the
constitution Dave reads most, and that belongs in a visible decision of its own rather than inside a
migration. The mechanism is what moved here; the wording is next.

**And one thing nobody can verify from inside this session:** the `@`-import chain only takes effect at
the *next* session start, and the plugin body still loads from the pushed `github` source. The files are
proven by every gate available; the loading itself shows up on the next start.
