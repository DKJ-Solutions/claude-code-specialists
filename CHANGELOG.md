# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`workflow-davekjohn/releases/README.md`](workflow-davekjohn/releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-9-0-release-note` changelog

### Branch title

The v4.9.0 release note

### Branch ID

20260815-091156

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning: the consumer section rewritten from
the cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The consumer section leads with a required migration, which is the first time one has led here.**
After this update a consumer's session start reports an `[ERROR]` until `workflow-davekjohn/` exists,
and their branch dossier has moved out of their repo root — so the document opens by saying that two
items ask for action, names the skill that closes the first, and states plainly that a leftover root
`branch/` is theirs to delete because nothing removes it for them. The third action item is the one
nobody would infer from a fix's title: the Shopify specialists stopped quoting one customer's live
theme id, so a consumer whose lens does not name their own now gets a refusal where they used to get a
wrong answer.

**The capability *loss* is written as a capability loss.** Sandra's subagent no longer holds `Bash`,
which removes `shopify theme list` from step 1 of her working method. The draft carried this as a
boundary repair; for the reader it is a habit that stops working, so it says what to do instead — ask
the persona, which still has the CLI — rather than describing the construction that changed.

**Test 2 did most of the cutting.** The tier-2 entries carry the measurements that justified each
change — 42 repo-bound words down to 20, 178 sentinels from 17,332 to 13,027 bytes, 751 of 1,004
occurrences inside shared blocks, one false finding on a declined gate. Every one of them describes our
effort rather than the reader's outcome, and none survived into the consumer section. They are what the
development record is for.

**The *what it is worth* section is built on where this release's work came from: six of its changes
were filed by people using the product, four from a single Cowork session with no repository at all.**
The section names what that one session bought — the environment where every reserve the specialists
lean on is absent simultaneously, so a boundary's claim and its enforcement come apart in public — and
records the risk actually closed: an identifiable customer's store and live theme id, in a repo that is
deliberately public. It also states the declined gate, because a closure by removal rather than by a
check is the kind a later reader re-opens.

**Step 0a's first pass is a subtotal of 5m 36s to the pushed tag**, against `v4.8.0`'s 5m 02s and
`v4.7.0`'s 15m 31s, with the gates once again the floor at three-and-a-bit minutes on the third
consecutive cut to start on the first attempt. The 1m 28s of intake is named as the only leg that
blocked a person, because it ends in the one question a script cannot answer — what the release is
called.

### Significance

#### Tier 0

The release record gains its hand-written half, and the timing series gains a third consecutive data
point with the gates identified as the floor. Nothing about how this repo works changes.

**Score:** 3

#### Tier 2

The document is how a consumer learns that this release asks them to run a skill, delete a directory,
and check their lens — three actions they would otherwise meet as a session-start error, a stale
directory nothing reads, and a specialist refusing to name their theme.

**Score:** 4

### Pull Request

[PR #682](https://github.com/DaveKJohn/claude-code-specialists/pull/682) · merged 2026-08-15

---

