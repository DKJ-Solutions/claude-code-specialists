## `fix/shared-block-coverage` changelog

### Branch title

The conversation-history rule reaches every agent def from its one source

### Branch ID

20260815-215238

### Branch type

fix

### What does the change on this branch bring to main?

**The `no-conversation-history` rule had one source and eleven hand-typed copies.** Measured before
the repair: `team-alpha` carried the sentinel in **15 of 15** agent defs, while `team-ecomm` (0/3),
`team-lifehub` (0/5) and `team-shopify` (0/3) carried the same rule typed by hand — already in **three
different wordings**, which is what makes this a fix rather than a tidy-up:

- *"You are **not given** the conversation history; work **only with** …"* (three `team-lifehub` defs)
- *"You **do not receive** … work **only with** …"* (one)
- *"You **do not receive** … work **with** …"* (all six `team-ecomm` and `team-shopify` defs)

Coverage is now **26 of 26**, and no hand-typed variant remains. This needed no new machinery: the
generator already walked those directories — the same eleven files carry other shared blocks — so the
mechanism had simply never been pointed at this rule in three of the four plugins.

**Why the repair was more than wrapping a sentinel.** In eight of the eleven, the rule shared a bullet
with a role-specific sentence about the final message. Wrapping the merged bullet would have pulled
that role text inside a generated region, where the next generator run would delete it. Each was split
instead: the shared block on its own, the role-specific sentence kept as its own bullet, unchanged in
substance. One further detail was preserved rather than lost — `03-08`'s rule named *which period,
which account* as the context most often missing, which is real knowledge about that specialist's work
and now sits beside the block instead of inside it.

**The proof that the eleven are byte-identical to the source is the generator's own report**:
`build-agent-defs.ps1` ran after the edits and reported **0 files updated**. Had any of the eleven
differed from `agent-shared/no-conversation-history.md` by a character, it would have rewritten it.

**Reach.** `team-shopify` and `team-ecomm` are both enabled in `BWJ-ecommerce/smartwatchbanden`, so
nine of the eleven were live in a consumer.

### Significance

#### Tier 0

The next sharpening of this rule now reaches every specialist instead of 15 of 26. Before, the three
other plugins would have silently kept whichever paraphrase they were written with, and nothing
compares those against anything.

**Score:** 3

#### Tier 2

A consumer running `team-shopify` or `team-ecomm` was getting a behavioural rule that had drifted from
the one the core team runs on — subtly, in the direction of "work **with** what is in your assignment"
rather than "**only with**". Scored 3: nothing was broken, but a boundary rule that says something
slightly different in one plugin than another is the kind of drift that is invisible until it matters.

**Score:** 3

### Pull Request

