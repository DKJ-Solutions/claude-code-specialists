## `docs/adoption-page-sequence` deployment

### What does the change on this branch deploy to main?

The adoption route stops being three steps and a wrong sentence. `plugins/ADOPTION.md` gains a step
naming the `adopt-*` skill of every plugin that owns repo state -- `adopt-config` and
`adopt-workflow-folder` from `workflow-davekjohn`, `adopt-shopify-floor` from `team-shopify` -- with the
rule that outlives the table (run the adopt skill of every plugin you enabled; your own slash list is
the enumeration) and the note that each is additive and a dry run until `-Apply`. It sits before the
half-day lens step deliberately, because it is minutes and it clears the session checks that would
otherwise sit red throughout. The same page's only description of a workflow-slot *transition* said
"Nothing has to be undone first", which the check shipping beside it falsifies; it now names the one act
that must happen in the same edit and the `[ERROR]` that arrives one session start later, after the
wrong state has been committed.

Two inbound issues, and a subject one document larger than either of them reported: `INSTALL.md`'s
quickstart carries its own copy of the adoption steps, so it gained the adopt step too and its lens step
became Step 5. The step counts follow across `specialists-init`'s cross-reference and four references in
`README.md` -- the count discipline this family has already repaired twice.

**Score:** 2

#### What makes this change extra special

A consumer adopting this family reads exactly these two pages, and until now both stopped short of the
finish line: `specialists-init` was the last named command, while a real install is that skill plus one
adopt step per enabled plugin. The reporting consumer spent a second day on follow-up rounds, each one
triggered by a session-check `[ERROR]` naming something neither page mentioned -- all of it discoverable
up front. And whoever switches the workflow slot was being told, by the only bullet describing the
switch, to leave the outgoing workflow enabled: a guaranteed wrong first attempt, committed and pushed
before the check that catches it ever runs. Neither can be bridged in a consumer's own lens, because the
audience is a repo that has not adopted yet.

**Score:** 4

### Pull Request

The adoption page names the adopt skill of every enabled plugin, and the one thing a workflow switch must undo
