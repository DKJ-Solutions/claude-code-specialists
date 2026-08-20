## `feat/shopify-theme-delete-marker` deployment

### What does the change on this branch deploy to main?

`team-shopify`'s live-theme guard gains a third seam, `Get-ShopifyThemeDeleteMarker`, and rule 2 -- a
theme delete -- stops being absolute **for repos that ask**. Requested by a consumer
(`xoxowildhearts`) whose preview themes are created and thrown away by the same workflow: clearing a
spent one was a keystroke somebody had to be present for, and the guard offered no path at all.

**The design decision is the default, and it is the opposite of the push marker's.** `$MARKER` falls
back to a permissive suffix, because both existing consumers already write one and rule 3 has to keep
working unconfigured. `$DELETE_MARKER` falls back to **empty**, which means the capability is off:
nobody writes a delete marker today, because until now no marker could authorise a delete at all. A
default here would hand every consumer a new capability on their next plugin update, silently. An
unstated seam has to mean unchanged, and unchanged for a delete is *always denied*.

**Three bounds, each with its own counter-case in the suite:**

1. **The live theme is refused even with the marker**, and that check runs *before* the authorisation
   path so no marker can reach past it. Shopify will not delete a published theme either -- this is the
   belt to that braces, and it is the one outcome nothing else in the file could undo.
2. **A delete without the marker still blocks.** Answering the seam does not open deletes generally.
3. **One marker may not do two jobs.** Answer both seams with the same string and the delete capability
   stays **off** rather than being granted. A push marker gets written as a matter of routine -- it is in
   the consumer's own step list -- so accepting it here would turn every documented live push into a
   standing authorisation to delete. That is the opposite of a marker authorising one command visibly.

**Why a marker rather than "allow anything that is not live", which was the simpler option offered and
declined.** A real Shopify estate is not the live theme plus this week's preview. Measured on the
requesting store while this was being scoped: **nineteen themes, one of them a current preview** -- the
rest dated backups, two named `DO NOT DELETE`, and five `feat/*` themes from a previous agency. Nothing
in a command distinguishes a spent preview from any of those, so being non-live is not enough to make a
deletion deliberate.

**17 new cases, 85/85 in the suite**, covering every branch of the new condition: seam unanswered (twice
-- including that there is no generic default spelling, unlike the push marker), answered and authorised,
answered and unauthorised, wrong marker, case-insensitivity, the live theme with and without the marker,
the same-string collision in both directions, both markers staying in their own lanes, publish still
absolute, and the heredoc exemption plus its counter-case for the new branch.

Documented where a consumer actually looks: the guard's own header, the `team-shopify` README (a named
section, since this is a capability rather than a narrowing), and a pointer in the seam block
`adopt-shopify-floor` appends -- which is the path by which a consumer learns what is configurable at
all.

**Score:** 4

#### What makes this change extra special

**Consumers must opt in, and doing nothing is a complete answer.** A Shopify consumer who takes this
update and never touches their `repo-config.ps1` sees no behaviour change whatsoever: a theme delete is
refused exactly as before, and no marker they could write would pass it. Nothing to migrate, nothing to
re-check.

For a consumer who *does* want it, it is one function and one marker on the command -- the same shape as
the live-push authorisation they already run, so there is no second mechanism to learn. The README
section names the three bounds, because the one that will surprise somebody is the collision rule: reuse
the push marker's string and the capability silently stays off. It fails safe, and the report says so.

**Score:** 3

### Pull Request

an authorised preview-theme delete, opt-in per repo
