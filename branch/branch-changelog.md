## `feat/audience-tier-seam` changelog

### Branch title

One audience tier per repo, established up front and never inherited

### Branch ID

20260812-135302

### Branch type

feat

### What does the change on this branch bring to main?

Tier 1 and tier 2 stop being two rungs of a cumulative ladder and become two **kinds** of audience, of
which a repo has exactly one: tier 1 is management and the employer/commissioner, tier 2 is the subscriber
of a service. `Get-ReleaseAudienceTier` states which one, once, per repo. `new-branch` then scaffolds tier 0
plus that tier alone, the routing question under tier 0 points at it, and `open-pr` and `cut-release` require
that tier rather than every rung from 1 up. This repo answers **2** — it sells a service; the webshop that
reported [#620](https://github.com/DaveKJohn/claude-code-specialists/issues/620) answers **1**, its customers
buying a product they never read notes about.

**Measured, and the measurement reversed an argument made against this change three hours earlier.** Counting
tier sections in aggregate said tier 1 was a working axis here (89 of 95 scored) and that switching it off
would destroy it. Counting the highest scored tier **per entry** over the same 97 entries says otherwise: 81
top out at tier 2, 8 at tier 1, 8 at tier 0 — so 81 of those 89 tier-1 sections existed only because the
ladder demanded one under a scored tier 2. The same reach argued twice, in a second register, for a reader
who here is the same person. The consumer measured the mirror image: 37 open entries, 15 at tier 1, zero ever
at tier 2.

**Two separations carry the whole safety of it.** `Get-EntryTierMax` stays 2 and every validator keeps
reading it: the MAX says which tier numbers are valid to *read* — a tier-1 repo must still parse the tier-2
entries in its own history — while the audience says which tiers a repo is *asked* about. And an unstated
seam means **ask about all of them**, exactly as before the knob existed. Reading absence as "no audience
enabled" would switch the tier off in every consumer the moment they took the plugin update, with nothing
erroring and a release document going out empty; the loud channel is the contract instead, where this is a
`decide` record that `adopt-config` scaffolds rather than copies.

**The gate narrowed what it ASKS without narrowing what it ACCEPTS**, which is the half that would otherwise
have cost real work: the six entries pending here when this landed each carry all three tiers, and a gate
that began refusing an extra answered tier would have turned six finished dossiers into six PRs that cannot
be opened. An asserted test holds exactly that case.

### Significance

#### Tier 0

Every branch created here stops answering a question about a reader this repo does not have. On the record so
far that is 81 sections of duplicated reasoning not written, and the first file a developer opens on a new
branch has two Significance sections instead of three.

**Score:** 4

#### Tier 2

A consumer states their audience once, in one line, and their entries stop carrying a section that cannot
apply to them — the reporting repo was writing an `N/A` **with a reason** on all 37 of its open entries,
because a blank is refused. What they do **not** get is a silent change: an unstated seam behaves exactly as
today, so the update alone changes nothing until they answer, and the contract check is what asks them.

**Score:** 4

### Pull Request

