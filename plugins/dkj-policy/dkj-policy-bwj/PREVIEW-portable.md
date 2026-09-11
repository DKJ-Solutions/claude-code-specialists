# The preview handover -- the portable rule

**This page applies in exactly two repos, named by store rather than by org: `smartwatchbanden` and
`xoxowildhearts`** -- see [`WORKFLOW-portable.md`](WORKFLOW-portable.md) for why the org is left out.
It is chapter three of this plugin, beside [`WORKFLOW-portable.md`](WORKFLOW-portable.md) and
[`SYNC-LOG-portable.md`](SYNC-LOG-portable.md), and it answers one question neither of those does:
**what a preview handover owes.**

It is a layer on top of `dkj-policy` in the same way the other two chapters are. It changes nothing
about **which** changes need a preview before they may open a PR -- that reach is the consumer's own
rule and `dkj-policy`'s, unchanged. It states only what the handover itself contains once one is owed.

**How to read this page.** It travels with the plugin, so a link that walks out of this plugin's own
folder is written as an absolute URL. Measurements and issue numbers are the **source repo's**; they
are the evidence behind a rule, never your repo's own record.

## Why this is policy and not mechanism

`dkj-subagents-shopify` ships the **mechanism** -- `push-preview.ps1`, the theme it creates, the
live-theme guard. That is generic: any repo serving a Shopify theme needs a preview theme, and every
one of them gets the machinery through a plugin update whether or not it ever reads this page.

This page is the **policy** -- *what the person receiving a preview is handed*. That is BWJ's house
rule for two repos, not a Shopify fact.

## The rule

**A preview handover is a PAIR per market: the preview, and the control.** The control variant is the
same page on the **live** theme -- what the visitor sees right now -- so the difference is one
tab-switch rather than a recollection.

**A preview alone shows what a page will look like. It never shows what changed.** Only the reader
knows the current state, from memory, while looking at something else -- and that is precisely the
judgement the preview exists to make possible. A handover that skips the control has moved the hard
half of the work onto the person it was handed to.

Dave, September 11, 2026, after a five-market preview handover that was complete by the letter of the
rule then in force:

> wat ik ook wel fijn vind in het vervolg is een preview naar de control variant. dus hoe het live nu
> staat om het verschil meteen te zien.

The change under review was one colour on a product-page notice. Described in prose it was *"a
lighter, more yellow amber"*; held against the live tab it is obvious in a second. Prose is not a
control variant.

**It costs the producing side nothing.** The session has already resolved the changed page per market
in order to build the preview list at all; the control URL is that same URL with one parameter
changed.

## What the control URL is -- and the trap in the obvious answer

**The control URL names the LIVE theme's id explicitly:**

```
https://<market domain>/<the changed page>?preview_theme_id=<live theme id>
```

**It is NOT the URL with the parameter left off**, and this is the part that has to be written down,
because the obvious answer is wrong in a way that fails silently.

`preview_theme_id` sets a **cookie** on that domain. Once a market's preview URL has been opened, every
later request to that domain keeps rendering the preview theme -- including the bare URL that was meant
to be the control. The control tab then shows the preview, both tabs agree, and the reviewer concludes
the change is not visible.

Measured in `smartwatchbanden` on September 11, 2026, against one product page on `smartwatchbanden.nl`,
reading `Shopify.theme` out of the rendered markup:

| what was requested, in one session, in order | what actually rendered |
|---|---|
| the preview URL, with the branch theme's id | the branch theme (`role: unpublished`) -- correct |
| **the same URL with no parameter at all** | **still the branch theme** -- the cookie survives |
| `?preview_theme_id=0` | no page at all: *"Theme cannot be previewed because it's missing one of these required files: layout/theme.liquid, config/settings_schema.json"* |
| `?preview_theme_id=<live id>` | the live theme (`role: main`) -- correct, and the session is back on live afterwards |

Three consequences, in descending order of how easily they are missed:

- **Pin the control to the live id.** It is the only form measured to be correct regardless of what the
  browser did before it, and it needs no clean browser profile, no incognito window and no instruction
  to the reader.
- **`preview_theme_id=0` is not a reset.** It renders the error above, which reads like a broken
  preview theme and sends the reader hunting for a fault that does not exist. It is worth naming
  because it is the first thing anyone tries, and because that same message is what a reader reports
  when they hit it.
- **The live id is already answered by the repo.** `Get-ShopifyLiveThemeId` in
  `scripts/repo-config.ps1` -- the seam `dkj-subagents-shopify`'s live-theme guard reads -- states it
  once. Read it from there rather than pasting a number into a handover, and a store that republishes
  under a new theme id keeps one place to correct.

## The shape of the handover

Name the page once, then one row per market with both URLs. What the reader is being asked to compare
goes above the table, in the smallest number of words that will do.

```
Product: <handle> (carries the tag/condition the change depends on)

| market | preview | live (control) |
|---|---|---|
| NL | <preview URL> | <control URL> |
| ...
```

Two things this inherits from the consumer's own preview rule rather than restating:

- **Per market**, because these stores serve several and a change can land differently in each.
- **Of the concretely changed page** -- a table of homepages is already refused there, and a control
  that is not the changed page controls nothing.

**And hand the URLs over in a form that can be opened, not only read.** A long URL in a terminal wraps,
truncates and cannot be selected; the reader then cannot reach the preview that was built for them. Open
the pair per market directly, or write them somewhere clickable. Same day, same handover: the first
attempt was a terminal table, and the reply was *"het selecteren is ook onmogelijk"*.

## What this page does not decide

- **Which changes owe a preview at all.** That reach test lives in the consumer's `CLAUDE.md` and in
  `dkj-policy`, and this page neither widens nor narrows it.
- **When the PR may open.** Also the consumer's rule, unchanged: where a preview is owed, its approval
  is what the PR waits on.
- **Anything about pushing to live.** A control URL previews the published theme read-only. It is not a
  live action, it writes nothing, and it goes nowhere near the live-push procedure or its guard.
