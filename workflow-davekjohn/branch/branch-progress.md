## `docs/portability-claim` progress

### Steps

#### PLAN

- [x] Test the claim before repairing it: count what above the repo slot is owner- or repo-specific.
      15 mentions of Dave as decision-maker, 1 link to this repo's own issue, 4 lines of mechanism
      that exists nowhere else. The claim fails.
- [x] Find every place the claim is made — three, not one.
- [x] Check whether anything links to the `### The how (portable) vs. ...` anchor before renaming it.
      Nothing does.

#### CREATE

- [x] Intro, slot blockquote and the how-vs-what heading + body: *portable* replaced by what is
      actually true, with the copying consequence spelled out in the blockquote.
- [x] Add the note that the word is correct elsewhere in the file (the plugin sense) and must not be
      swept — the six standing uses would otherwise be broken to fix the three wrong ones.
- [x] Strip the count out of that note: a tally of a word inside a sentence using that word is stale
      on its own next edit.

#### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] Full test suites.

### Where I left off

Nothing open.

Worth knowing rather than acting on: the top half still carries this repo's own measured instances —
issue #388's teardown fixture, the `v4.0.0` preparation commits, the `plugin.json` bump. They are
correct where they are (they are what the rule was decided on) and the text no longer claims they
travel. Moving them would be a separate decision about where a constitution keeps its evidence, not
a repair of this defect.
