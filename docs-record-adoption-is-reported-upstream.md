### the record-adoption reproduction is reported upstream, with the link · Docs · 2026-07-31

Closing the one item [#306](https://github.com/DaveKJohn/davekjohns-workshop/issues/306) left outside the
PR series: the record-adoption behaviour from
[#301](https://github.com/DaveKJohn/davekjohns-workshop/issues/301) is CLI behaviour, so the only thing this
repo could do with it was report it. Reported, and now recorded here rather than living only in an issue
comment.

**It went to [anthropics/claude-code#76759](https://github.com/anthropics/claude-code/issues/76759#issuecomment-5146633011)
as a comment, not as a new issue.** That report already documented the *write* — a session start driven by
`enabledPlugins` writing `installed_plugins.json` — measured on Linux with CLI `2.1.207`. What v7 measured is
the same write with a consequence it had not covered: the entries can carry the `installedAt` of **another
project's** record, and that project's record is gone afterwards. Same root, worse outcome, so adding to a
well-written report beats filing a near-duplicate beside it.

Two things came out of searching before writing, which is the part worth keeping:

- **The upstream tracker already held eight open issues about this file**, including
  [#75392](https://github.com/anthropics/claude-code/issues/75392) — `install --scope project` **overwriting**
  `installed_plugins.json` rather than merging. That is a plausible mechanism for the loss we measured: a
  write that replaces the map instead of adding to it takes every other project's entry with it. Named as a
  possibility in the comment, not as a conclusion — we measured the file's contents, not the implementation.
- **Our reproduction adds a platform and a version**: Windows 11, CLI `2.1.220`, against that report's
  Linux/`2.1.207`.

`specialists-init/SKILL.md` now carries the link and that framing, plus the line that matters most for a
reader of this plugin: **nothing here depends on an upstream fix.** The checks detect the state locally since
v3.0.7, which is the half this repo controls.

The gaps stay stated rather than smoothed over: the trigger is still not isolated, and the rule by which a
victim record is chosen is still unmeasured.
