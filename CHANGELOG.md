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

## `docs/v4-9-0-timing-total` changelog

### Branch title

The v4.9.0 release note gains its end-to-end total

### Branch ID

20260815-093231

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.9.0`'s note was frozen at a 5m 36s head; the five remaining legs — writing the document
(3m 08s), its gates (3m 41s), its CI (7m 50s), the merge with the fold (3m 53s) and the publish (2s) —
are added, giving a **total of 25m 31s** from clock start to a published Release with its attachments.

**The tail was 19m 55s, 78% of the total, and this is the third consecutive release to land within
seventy seconds of the same figure** — 19m 26s, 18m 47s, 19m 55s. The head over those same three moved
from 15m 31s to 5m 02s to 5m 36s. That pairing is worth more than either number alone: the tail is made
of fixed legs and barely moves, so the growing *fraction* is the head having been fixed rather than the
tail getting worse. It also means the fraction is the wrong statistic to track, and the note now says so
by giving both series rather than the percentage on its own.

**The duplicated leg is measured a third time and is unchanged**: the merge re-runs the suites the pull
request already proved, at 3m 27s of the 3m 53s merge leg here, against roughly three minutes at
`v4.8.0` and 3m 18s at `v4.7.0`. Three consistent measurements make it the largest single saving left in
the release procedure; it stays named in *what was still open* rather than being acted on here.

**The attached copy stays frozen**, and the note says so, following the rule `v4.7.0` set: an attachment
is what was published at the moment of publication, and silently replacing it is the opposite of the
record the document is for.

### Significance

#### Tier 0

The timing series gains a third point, and with it the first conclusion that needed more than one: the
tail is near-constant in absolute terms, so the percentage that has been reported for three releases is
the wrong statistic. The duplicated merge leg now has three consistent measurements behind it rather
than two.

**Score:** 3

#### Tier 2

A consumer reading this release's note gets the whole cost rather than the fifth of it that was visible
before the document was merged. Nothing they do changes.

**Score:** 2

### Pull Request

[PR #684](https://github.com/DaveKJohn/claude-code-specialists/pull/684) · merged 2026-08-15

---

