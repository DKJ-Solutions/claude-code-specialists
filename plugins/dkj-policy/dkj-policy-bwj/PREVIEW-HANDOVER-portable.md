# The preview handover -- the portable rule

**This page applies in exactly two repos, named by store rather than by org: `smartwatchbanden` and
`xoxowildhearts`** -- see [`WORKFLOW-portable.md`](WORKFLOW-portable.md) for why the org is left out.
It is chapter three of this plugin, beside [`WORKFLOW-portable.md`](WORKFLOW-portable.md) and
[`SYNC-LOG-portable.md`](SYNC-LOG-portable.md), and it answers one question neither of them does:
**how a preview reaches the person who has to look at it.**

It is a layer on top of `dkj-policy` in the same way the other two chapters are -- it changes nothing
about branch naming, what a change owes before a PR, or what a release is. It does not touch the
safety rule it serves either: **no PR is opened before that preview is approved.** This is the carrier
for that approval request, not a relaxation of it.

**How to read this page.** It travels with the plugin, so a link that walks out of this plugin's own
folder is written as an absolute URL -- an installed plugin is read from its own cache directory,
where the repo tree around it does not exist. Measurements and issue numbers on this page are the
**source repo's** (dkj-claude-plugins); they are the evidence behind a rule, never your repo's own
record.

## Why this is policy and not mechanism

`dkj-subagents-shopify` ships the **mechanism** --
[`push-preview`](https://github.com/DKJ-Solutions/dkj-claude-plugins/blob/main/plugins/dkj-subagents/dkj-subagents-shopify/skills/push-preview/SKILL.md),
which pushes a branch to its own unpublished theme and prints the preview URL(s). That is
generic: every repo serving a Shopify theme needs a link somebody can open, and every one of them gets
that machinery through a plugin update whether or not it ever reads this page.

This page is the **policy** -- *what the reviewer is handed, and in what form*. That is BWJ's house
rule for two repos with the same five markets, the same preview-theme flow and the same reviewer, not
a Shopify fact. Keeping mechanism in `dkj-subagents-shopify` and policy here is the same seam split
the two repos already run everywhere else.

**The practical consequence is the one thing that makes this chapter different from the other two:**
the mechanism does not go silent waiting for a seam. `push-preview` prints its list in every repo,
every time, with nothing to configure -- so this rule is not competing with an absence, it is
competing with output that is already on the screen. That is why it is carried at the print site as
well as stated here; see [below](#where-the-rule-is-carried).

## The rule

**A preview is handed over as ONE LINK to a published page. The terminal never gets the URLs.**

Not a markdown table, not a bulleted list, not "here are the five markets" followed by five lines. One
link, and the page behind it is the handover.

Three things are wrong with a table of URLs, and only the first is cosmetic
([#1873](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1873), September 11, 2026, measured
on a handover of ten URLs -- five markets by two page types):

1. **The terminal cannot render it.** A preview URL is a full domain plus `?preview_theme_id=...` and
   the three admin parameters -- roughly 70 to 100 characters. Ten of those in two columns wrap, and
   the column structure that was carrying *which market, which page* wraps with them. The layout that
   was the whole point of the table is the first thing it loses.
2. **The reader is on the wrong device.** Storefront work is judged on a phone; some of it exists
   *only* there -- the change that produced this rule lived inside a lazily-fetched mobile menu drawer
   and was invisible on a desktop at any width. A URL in a desktop terminal is something the reviewer
   has to retype on a phone, once per market, query string included.
3. **The handover carries no state.** What the gates already proved, what is still open, and what the
   reviewer is actually being asked all sat in prose above and below the table -- so none of it travels
   with the link when the reviewer comes back to it an hour later.

**What is NOT in question is the requirement the table was trying to serve.** Both repos' own
`CLAUDE.md` asks for the concretely changed pages, per market, unasked. That stands exactly as
written. What this rule replaces is the **carrier**.

## What the page carries

Three blocks, and each is there because the other two cannot supply it:

| block | what it holds |
|---|---|
| **how to see the change** | the steps a reviewer has to take before the change is even visible -- which device, which viewport, which menu to open. A preview URL cannot say this, and a change that is invisible without it reads as *not shipped* |
| **one card per market** | the market code and its domain, a **QR code**, the expected copy in that market's language where the change has copy in it, and text links to the concretely changed pages underneath |
| **what is proven, and what is asked** | which gates ran and what they verified mechanically, then the one question the reviewer is being asked. This is the half that makes the link a self-contained handover rather than a bookmark needing the transcript beside it |

### Why a QR code per market, and not one

**Because a QR is what makes the phone the reviewing device rather than a second one.** The reviewer
scans instead of retyping a 90-character URL with a query string, which is the difference between
reviewing the change and not reviewing it.

**One per market, because the preview is per domain.** A scan puts the preview on the domain it opens,
and that is the domain the code encoded -- a market's card cannot borrow the scan from the card above
it. Five markets means five codes.

**And the code has to encode a URL carrying `_ab=0&_fd=0&_sc=1`**, exactly as `push-preview`'s own page
already requires of every URL that seam produces. Without those three parameters the preview holds only
through the cookie and is lost at the first internal click -- at which point the reviewer is looking at
**live** while believing they are looking at the preview. A consumer lost a whole review to that. It
matters more on a QR than anywhere else: the scan is the reviewer's only entry point, so a code built
from a stripped URL puts them on live from their first tap, and nothing on the screen says so.

### The one mechanism note, and why a policy page carries it

**A QR code served as an image from a QR-image API does not render, and says nothing when it fails.** A
published Artifact runs under a content-security policy that permits external **scripts** from a short
list of CDNs and blocks everything else -- images included, from every host. So an
`<img src="https://some-qr-api/...">` is silently empty, and a page of five markets is a page of five
blank squares with no error anywhere.

The two shapes that do work: render the code **client-side** from a QR library loaded as a script from
an allowlisted CDN, or embed it as a `data:` URI in the page itself.

This is mechanism on a policy page, deliberately and once. A rule that prescribes a carrier and omits
the single constraint that makes the carrier fail *silently* is not a rule anybody can follow -- and
this is the worst kind of failure to leave out, because the page looks published and the reviewer is
the one who finds out.

### And the link is as sensitive as the URLs it encodes

**The CSP is not the reason to keep the QR local, it is only the reason the remote one does not
render.** A preview URL carries `preview_theme_id` plus the three admin parameters, which is exactly
what lets a viewer see an unpublished theme -- so a QR generator that round-trips that URL to a
third-party service hands the store's unreleased work to somebody who was never asked. Rule it out on
its own terms: **the preview URL never leaves the page**, whatever the CSP happens to permit that
month.

**And the page itself inherits that.** The whole point of the handover is that the link is easy to
open, which means it is also easy to forward -- and one link now reaches every market's preview at
once, where the terminal printout reached whoever was looking at the terminal. The page is private
until its link is shared, so treat the link the way you would treat the URLs on it: to the reviewer,
and not onward.

This paragraph exists because the section above it reads as complete without it. *"Render it
client-side"* is a full answer to a rendering problem, and a later editor taking the CSP as the whole
reason picks whichever library renders -- including one that phones home.

## What the terminal gets

One line with the link, and enough to know what it is. Nothing else -- no URLs, no table, and not the
page's contents retold.

That is the same rule the close-out already runs under everywhere in this system: the reasoning goes
somewhere durable and the terminal gets a receipt. Here the durable place is the page.

## Where the rule is carried

A policy page that nothing loads at the moment a preview is pushed loses to the printed list every
time, because that list is what a session has in front of it. So the rule is carried at the print site
too, in the generic plugin and in generic terms:

- `push-preview` prints a closing note whenever it emits **more than one** URL, saying the list is raw
  material rather than the handover and pointing at whatever handover rule the repo's workflow states.
  One URL is left alone -- a single line in a terminal genuinely is a usable handover, and the count is
  the honest trigger.
- [`push-preview`'s own page](https://github.com/DKJ-Solutions/dkj-claude-plugins/blob/main/plugins/dkj-subagents/dkj-subagents-shopify/skills/push-preview/SKILL.md)
  carries the same thing in prose, under its own heading.

**Neither of those names BWJ or this page**, and that is the split holding rather than an omission: the
generic plugin states that a list of URLs is not a handover, which is true of any multi-market Shopify
repo, and *this* page states what BWJ's handover actually is.

## Adopting it in a repo

**Nothing.** There is no seam to answer, no template to copy, no CI to wire and no file to scaffold --
this chapter is a writing rule, and it is in force in both repos from the moment the plugin is enabled.

That is worth saying plainly, because the other two chapters both open with a configuration step: if
you came here looking for the function to answer, there is not one.
