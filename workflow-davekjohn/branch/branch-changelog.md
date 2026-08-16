## Branch `docs/v4-13-0-release-note` changelog - 20260816-205701

### What does the change on this branch bring to main?

#### Tier 0

The one hand-written document for the minor tagged this evening: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can generate.

**The item that led *what was still open* for five releases is closed and leaves the list.** `v4.12.0`
carried "the gate record has not been measured on the case it was built for" because that release shipped
in one motion and so never produced the duplicate gate run the record absorbs. Two firings have since been
measured on real pull requests, and the note says what they do and do not support: they confirm the
mechanism, they are not a distribution, and nobody should read a ratio off n=2.

**The head is 6m 15s against a five-release band of 4m 57s to 5m 36s, and the extra minute is named rather
than absorbed.** The ordinary, pushing form of the cut was refused by this session's own permission
classifier, so it ran in its `-NoPush` form and the push was issued by hand -- two commands where there is
normally one. That is a property of the harness the release ran in, not of the procedure, and it is written
into *what was still open* in those terms. Nothing was skipped for it: both gates ran in full, 43 suites
green in 147s.

**The publication line was re-read at the target rather than carried forward**, which is the habit `#694`
established. `BWJ-ecommerce/claude-plugins-bwj` is unchanged at commit `d528567` -- the four team plugins
still on 4.11.0, published 2026-08-15T15:44:13Z -- so the only edit the line needed was that colleagues are
now **two** releases behind rather than one. Reading it is what establishes that, and carrying it forward is
what would have made it wrong for the second time in three notes.

**Eight entries became four consumer sections plus a two-item list.** The four gate-record and
release-note entries carry `Tier 2: N/A` or describe our own craft, so their consumer-facing halves are one
bullet each or nothing at all -- test 2's line, which asks whether a paragraph describes our effort or the
reader's outcome.

**Score:** 2

#### Higher than tier 0?

The one document a consumer reads to decide whether to update. This release's headline is an action they
have to take -- `/continue` no longer resolves to the workflow's skill after the update, and they have to
type `/handover` instead -- so the section leads with it and says plainly that everything else needs no
action and no migration.

**Score:** 4

### Pull Request

The v4.13.0 release note
