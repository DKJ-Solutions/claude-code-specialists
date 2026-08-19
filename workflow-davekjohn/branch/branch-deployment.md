## `fix/team-shopify-store-neutral` deployment

### What does the change on this branch deploy to main?

The three `team-shopify` subagents stop naming one consumer's store. Liam is now the Liquid Developer
**for this repo's Shopify theme**, Sandra and Steven the Store Manager and Configuration Manager **for
this repo's Shopify store** — the shape `team-ecomm` already uses, where its three specialists work "for a
commercial webshop" rather than for a named one. Which store a repo actually is belongs to that repo's
lens, which is where the identity was being read from anyway.

**The report measured three lines; the subject is six**, and the three it missed are the load-bearing half.
Each agent def names the store twice: once in the `description:` a consumer's model reads at every turn,
and once in the body line that tells the subagent who it is — *"You are **Liam 💧**, the Liquid Developer
for smartwatchbanden."* A repair scoped to the descriptions would have left every one of these three
specialists still introducing itself by the wrong store, which is the sentence it acts on. Measured across
the whole plugin: **7** occurrences in 4 files, 6 of them the subject and the seventh
`plugin.json`'s *"(e.g. smartwatchbanden)"* — an example, correctly marked as one, deliberately left.

One neighbour came along because it is the same defect in the same paragraph: Steven's body claimed the
theme landscape is *"the ~68 themes from multiple parties"*, which is one consumer's inventory stated as
the specialist's own reality. It reads "often dozens of themes, from several parties" now; the count is the
lens's to carry. The manuals needed nothing — they already say `--store <store>.myshopify.com` throughout.

**Score:** 1

#### What makes this change extra special

Reported from `xoxowildhearts`, a second Shopify store repo adopted the day before, where the roster the
model is handed read *"Liquid Developer for smartwatchbanden"* — a live theme on a different store, real
customers, real revenue, no staging environment. A subagent whose own description tells it which shop it
works for, naming the wrong one, is a routing hazard in exactly the repo where a wrong-store assumption
costs the most. It could not be corrected from the consuming side either: the descriptions ship with the
plugin, so the repo stayed wrong until this landed.

And the correction is what makes the team reusable at all. `team-shopify` is a team for *Shopify repos*, not
for one of them; with a store name baked into three descriptions, every repo after the first inherited
somebody else's identity.

**Score:** 4

### Pull Request

the Shopify team stops naming one consumer store
