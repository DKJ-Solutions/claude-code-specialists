# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-8-0-release-note` changelog

### Branch title

The v4.8.0 release note

### Branch ID

20260813-204153

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged tonight: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The consumer section leads with the one item that asks the reader to re-check something** — an
audience-tier answer given from strings that stated the superseded ladder — and gives the check in one
look: who reads your release notes decides your tier, not who uses your product. The other items are
opt-ins: one seam answer to put a whole test suite behind the gates, one deletion to replace a
hand-copied process page with the plugin's maintained one, and a pointer back at `v4.7.0`'s notes.

**The *what it is worth* section is built on the release's own shape: four of the seven changes arrived
as consumer-filed inbound issues, each measured against a real adoption attempt.** The section names
what the organisation stops paying — not the 4,154 hand-copied words per mirror, but the standing risk
that a page a consumer's gates enforce against them describes a convention three claims out of date —
and records that both silent failures this release closed had produced plausible output the whole time
they stood.

**Step 0a's first pass is a subtotal of 5m 02s to the pushed tag**, three times less than `v4.7.0`'s
frozen 15m 31s, and the note says plainly that the gates cost the same three-and-a-bit minutes in both:
the difference is a pre-flight of two reads, on the second consecutive cut to start on the first
attempt. It names that five-minute figure as the fixed cost the release-cadence trade should be
computed against.

### Significance

#### Tier 0

The record of what a clean release now costs (about five minutes to the pushed tag) lives here or
nowhere, and it is the figure the next "make releases cheaper" discussion should start from.

**Score:** 3

#### Tier 2

It is the only document written *to* a consumer for `v4.8.0`, and it leads with the one item that asks
them to act: re-checking an audience-tier answer that, given wrong, silently degrades every release to
a patch — the failure one consumer already met.

**Score:** 4

### Pull Request

[PR #651](https://github.com/DaveKJohn/claude-code-specialists/pull/651) · merged 2026-08-13

---

