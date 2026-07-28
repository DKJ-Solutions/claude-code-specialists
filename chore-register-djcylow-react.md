### Register djcylow-react in the connector register · Chore · 2026-07-28

The concrete case behind PR #208: `DaveKJohn/djcylow-react` had been a consumer since at least
2026-07-26 — inbound #177 came from there — without a manifest, so the workshop was blind to its
plugin version, lens inventory and agent-def drift. Now registered as the fourth connector.

**Inventory read from the GitHub API, not from a local checkout.** The repo is not cloned on the
workshop machine, so there was nothing to read locally; the repo being public made the API route
possible. Consequence, and the correct behaviour: `check-connectors.ps1` reports it as
`[SKIP] checkout '../djcylow-react' not present on this machine` here, and will actually check it
wherever the repo is cloned. The `localCheckout` follows the existing convention for a `DaveKJohn`
sibling (`../djcylow-react`, same shape as life-hub's `../life-hub`); if that turns out wrong on the
machine that has it, the effect is a `[SKIP]` rather than a false finding.

Two things the inventory settled that were open questions:

- **Fully adopted, so v2.9.0 needs no ignore-list entry there.** All 19 specialists the `specialists`
  plugin ships (15 agents + 4 personas) have both a roster row and a lens — **including 03-02
  (Bianca)**. That was the open risk from inbound #204: a persona a consumer had not adopted becomes
  real drift once the check covers personas. It does not apply here.
- **`visibility` is `public`**, not private like the other two consumers — so the privacy boundary
  the register documents (metadata only) is not even load-bearing for this one.

Recorded in `notes`, because it will otherwise be re-derived by hand later: its
`.claude/settings.json` carries no `extraKnownMarketplaces` block, so the marketplace must be
registered at user level on that machine rather than per repo. Only the `specialists` plugin is
enabled there.
