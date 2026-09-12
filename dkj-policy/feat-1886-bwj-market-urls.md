## feat/1886-bwj-market-urls

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Converge `smartwatchbanden:scripts/lib/market-domains.ps1` and
`xoxowildhearts:scripts/lib/market-urls.ps1` into one mechanism in `dkj-policy-bwj`, with the market
table staying a per-store seam answer (#1886, candidate 1 of four).

- [x] Read both copies in full rather than from the report. They are not two versions of one file:
      one is a five-row domain table with two functions, the other a 300-line lib with path
      normalisation, a git-bash refusal, the preview query parameters and an applied-theme-id reader.
- [x] Establish the ownership answer under the #1881 ruling. Both stores need it and neither is
      `dkj-subagents-shopify`'s -- that plugin owns the theme mechanisms, not the storefront's market
      topology -- so it is `dkj-policy-bwj`'s. No *obviously universal* exception: that needs a
      demonstrated reader outside the two stores and there is none.
- [x] Settle the one design question the report does not answer: the two stores have **different
      storefront topologies**, so a shared table has to carry both axes. Decided: one row per market
      with `Market`, `Domain` and `PathPrefix`; five-domains and one-domain-with-locale-paths both
      fall out of it, and a third shape would too.

### CREATE

- [x] `plugins/dkj-policy/dkj-policy-bwj/scripts/lib/market-urls.ps1` -- the converged builder, in
      English and pure ASCII. The superset: both stores' accessors (`Get-MarketDomains`,
      `Get-MarketPaths`) plus everything the richer copy carried.
- [x] `Get-MarketTable` validates rather than repairs -- a scheme or a path in `Domain`, a duplicated
      market label, an empty table and a missing field are each refused by name. Neither source copy
      checked its literal, and the failure mode of a wrong table is a URL that looks right.
- [x] `Get-PreviewPrimeUrls` -- **plural**, one per distinct domain. The singular version it replaces
      is correct for a one-domain store and silently primes one of five for the other.
- [x] `Get-MarketHandoverPairs` -- the preview beside its live control, which is the pair chapter
      three of this plugin already requires and neither store could build.
- [x] The seam: `Get-StorefrontMarkets` in each store's own `scripts/repo-config.ps1`. No default
      table exists here, so a missing seam refuses by name instead of handing one store the other's
      domains.
- [x] `plugins/dkj-policy/dkj-policy-bwj/README.md` -- the *what ships under it today* row, the
      adoption note with its two real migration steps, and the new seam under its own heading
      (deliberately below the `adopt-dkj-policy-bwj` paragraph, which does not propose it).
- [x] `plugins/dkj-policy/dkj-policy-bwj/PREVIEW-portable.md` -- one paragraph under *why this is
      policy and not mechanism*, because that page now sits beside a mechanism in its own plugin and
      is what the builder's output points at.

### TEST

- [x] `scripts/tests/bwj-market-urls.tests.ps1` -- driven by **both** stores' real topologies: the two
      URL shapes, the preview parameters, the comma split, the mangled-path refusal (including that no
      header is printed above it), the per-domain prime URLs, the applied-theme-id reader, the
      handover pair, every table validation, the seam in both states (child process), the surviving
      superset, and the ASCII/English bound. 87 pass, 0 fail.
- [x] Smoke-run against the two real market tables before the suite existed -- the URLs each store's
      own copy produces today, plus the three capabilities it could not.
- [x] Lint gate `check-plugin-integrity.ps1`: 0 errors.
- [x] All suites via `Invoke-TestSuiteGate`, the way CI runs them: pass.

### DEPLOY: feat/1886-bwj-market-urls

`dkj-policy-bwj` gains its second piece of shared mechanism: `scripts/lib/market-urls.ps1`, the
storefront and preview URL builder both BWJ stores had written separately. It is #1886's candidate 1
and the flagship `ALIASED` finding of the sibling check -- one capability under two filenames
(`market-domains.ps1` against `market-urls.ps1`), sharing only the names `Get-MarketPreviewUrls` and
`Write-MarketPreviewUrls`, which is why no grep in either repo would ever have found the other.

**The design problem the report does not state is that the two stores have different storefront
topologies.** One runs its markets on five separate domains; the other runs its locales on a single
domain with path prefixes. So the shared table carries both axes -- `Market`, `Domain`, `PathPrefix`
-- and each store's shape falls out of it. Copying either table onto the other store produces domains
that do not exist, which is the reason this pair stayed apart rather than an accident of naming.

**For one store this is a repair, not a move.** Everything the richer copy carried is here, and its
absence had already cost the other store: without the `_ab=0&_fd=0&_sc=1` parameters a preview holds
only through the cookie and is lost at the first internal link, so the reviewer is looking at **live**
while believing they are looking at the preview -- a whole review was lost to exactly that on
August 5, 2026, and the thinner copy still did not carry them. The git-bash mangled-path refusal and
more-than-one-page-per-run arrive with it.

**One answer changed rather than merged**, and it is the only one: `Get-PreviewPrimeUrl` becomes
`Get-PreviewPrimeUrls`. A preview cookie is set per domain, so a single prime URL is right for a
one-domain store and primes one of five for the other -- silently, inside the check that exists to
prove a scripted fetch is not reading live.

The market table itself stays each store's `Get-StorefrontMarkets` seam answer. Mechanism here, data
there, which is what lets one builder serve two brands that share no domain.

**Score:** 3

#### What makes this deploy extra special

For a subscriber -- a BWJ store repo -- adoption is a forwarder plus a seam answer, and until they
make that move nothing changes for them. So the reach is real but gated on their action, which is why
this is a 3 and not higher: the moment a store next touches its preview handover, the builder is
there, carrying three capabilities one of them never had. The asymmetry is worth naming rather than
averaging away -- for one store this is a relocation of code it already had, and for the other it is
the repair of a failure that has already cost a review.

**Score:** 3

#### Pull Request

dkj-policy-bwj owns the market preview-URL builder

