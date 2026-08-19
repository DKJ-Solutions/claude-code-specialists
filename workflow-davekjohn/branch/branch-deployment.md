## `feat/connector-xoxowildhearts` deployment

### What does the change on this branch deploy to main?

`connectors/xoxowildhearts.json` — the second Shopify consumer joins the register, so the source can finally
see where the two have diverged rather than only that there are two. Every field was measured against the
consumer's own tree rather than copied from the report: 25 lens files matching the rosters exactly (19 + 3 +
3), the plugins enabled against the `github` marketplace source, visibility private, the local checkout
present. Registered now and not earlier because their adoption PR merged at 21:33Z — the register records
what a consumer *has*, and a lens claimed early makes the check report it missing.

**The workflow slot is deliberately left out**, which is the one field that could not be answered without
going stale within the day. Their merged `main` enables `workflow-davekjohn`; their in-flight branch switches
it to `workflow-default`. The check reads the **local checkout**, which sits on that branch — so whichever
answer were written here would be an `[ERROR]` half the time. It gets written once that branch merges, which
is the same rule the report applied to the manifest as a whole, one layer along.

**And that switch answers half of inbound
[#763](https://github.com/DaveKJohn/claude-code-specialists/issues/763)**,
found by writing this file rather than by reading the issue. #763 asks for a way to record "this repo does
not want the `workflow-davekjohn/` folder", because the standing `[ERROR]` about it can be cleared no other
way. The way already exists: that error comes from a hook shipped **only** with `workflow-davekjohn`, and
`workflow-default` — "the workflow a repo gets when it has not chosen one; it imposes nothing" — ships no
hook at all. The reporting consumer used it eight hours after filing.

**Score:** 3

#### What makes this change extra special

Nothing here reaches a consumer: this is the maintainer's own register, and the plugin cache never sees it.
What is worth the reading is that the register earned its keep on its first run for this repo — the
divergence it exists to surface was surfaced by the check refusing the manifest, and one of the two open
questions on the board turned out to be already answered by a plugin that has shipped for weeks.

**Score:** 2

### Pull Request

the second Shopify consumer joins the register
