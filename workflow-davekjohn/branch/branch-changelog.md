## `docs/source-repo-naming` changelog

### Branch title

The source repo is called the source repo, and .gitignore speaks English

### Branch ID

20260815-213525

### Branch type

docs

### What does the change on this branch bring to main?

**The retired *workshop* framing was still being used as a live name for this repo, in 32 places
across 20 files** — most of them shipped skill pages, which reach every consumer by plugin update.
The framing was retired on August 3, 2026 in favour of one product per repository, and every other
mention of it is deliberately past-tense. These were not: `new-branch/SKILL.md` called it "the
workshop repo" on line 13 and "the source repo" on line 25, twelve lines apart. A first-time consumer
reads that as two repositories, one of which they cannot find.

All 32 now read "the source repo", the term those same documents already used correctly. One sentence
was reworded rather than substituted: *"The source of this script lives in the source repo"* says
source twice for no gain, so it is now *"This script is maintained in the source repo."* The three
references to the literal old repo name `davekjohns-workshop` were checked and deliberately left
alone — they are the historical record of the rename and are correct as past tense.

**`.gitignore` was half Dutch.** Its four section comments were, while the long explanatory blocks
below them — the PowerShell cache, the release-notes page and its token — had been English all along.
`.claude/rules/language-layers.md` calls its own list of layers "meant to be exhaustive" and says an
undercount is a gap to close on discovery rather than a quiet exception, with `ci.yml` as the
precedent. This is the second time that clause has had to be honoured, so the file now says so, and
`.gitignore` joins its `paths:` list — otherwise the next reader has to re-derive that it was ever in
scope.

**What that same note now also records, because it is the more useful half:** this rule is exhaustive
over the *tree*, and the tree is not the whole product. Two layers of this repo speak Dutch where no
path-scoped rule can ever reach them — the public GitHub repo description and the `inbound` label
description, both in repo settings. Those are filed separately and wait on Dave, being outward-facing
configuration.

### Significance

#### Tier 0

Removes a naming collision that this repo's own documents created and then had to explain around.
Nothing behaves differently; the payoff is that the term now means one thing.

**Score:** 2

#### Tier 2

This is the one that travels. Skill pages are the most consumer-visible layer the plugin ships, and
half of them named a repository that has not existed since August 3. A consumer following those
instructions had to work out for themselves that "the workshop repo" and "the source repo" were the
same place. Scored 3 rather than higher because it misled rather than blocked: everything still worked
once the reader made the leap.

**Score:** 3

### Pull Request

