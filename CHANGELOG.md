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

## `fix/no-skill-ships-with-a-byte-order-mark` changelog

### Branch title

the adopt-config skill registers, and no SKILL.md can ship a BOM

### Branch ID

20260810-165439

### Branch type

fix

### What does the change on this branch bring to main?

`plugins/workflows/workflow-davekjohn/skills/adopt-config/SKILL.md` shipped with a UTF-8 byte-order mark
(`EF BB BF`) in front of its opening `---`, so a frontmatter parser that wants `---` at offset 0 read the
file as having no frontmatter at all. The skill therefore registered under no name and never appeared in a
model-facing skill listing — the only model-invocable skill of the eleven in the two shipped plugins to go
missing, and confirmed absent from this session's own listing. No error was raised anywhere; the page was
simply not there. The three bytes are gone.

The BOM is invisible in every editor a reviewer would open the file in, **and invisible to this repo's own
gate**: every reader in `check-plugin-integrity.ps1` goes through `ReadAllText`, which detects and strips a
BOM before any regex sees it. So the defect could not be found by reading and could not be found by the
lint. Check 26 reads the **first three bytes** of every frontmatter-bearing shipped document — the 26 agent
defs, 26 manuals, 4 personas and 13 skill pages — and holds them to a literal `---`.

Its subject is **registration**, which is what fixes the scope: a top-level `skills/<name>/SKILL.md` is
what the harness registers, so a deeper `references/SKILL.md` is deliberately out of scope rather than
held to a requirement the harness does not have. Measured before widening past `SKILL.md` rather than
assumed — 69 documents, all four sets non-empty, **zero findings** once the one BOM was stripped and **zero
exemptions**, and the check was verified to fire on the real defect by reintroducing it. A rule needing an
exemption list on its first run is the shape this repo has scar tissue from; this one is born green and
would have caught the defect the day it landed.

Reported as [#581](https://github.com/DaveKJohn/claude-code-specialists/issues/581) from
`BWJ-ecommerce/smartwatchbanden`, who found it by diffing first bytes because reading cannot. They left the
causal claim open on purpose; it was closed here by ruling out the one alternative — the description length
— which measured **433 characters, the shortest of the five** model-invocable skills.

One thing found on the way and repaired in the same file: the gate's own docstring list of checks stopped at
**22** while checks 23, 24 and 25 had been in the body for days. Appending a 26th entry to a list that
already skipped three would have made the map worse than either fixing it or leaving it alone, so all four
are now described.

### Significance

#### Tier 0

The gate's docstring is a complete map of its checks again — it had silently stopped at 22 while three more
were live, which is the one document a developer reads to find out what this gate actually enforces.

**Score:** 2

#### Tier 1

An entire class of defect stops being unfindable. A BOM survives review because no editor renders it and
survived this gate because every reader here strips it before looking, so the only person who could catch
one was somebody who thought to diff bytes. Now it is a named line with the file in it.

**Score:** 3

#### Tier 2

A fresh consumer can reach `adopt-config` — the one skill whose whole job is filling the seam — at exactly
the moment it matters, during bootstrap, and which they were least equipped to notice was missing rather
than hidden by design. Consumers whose seam is already filled see no change.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #583](https://github.com/DaveKJohn/claude-code-specialists/pull/583) · merged 2026-08-10

---

## `docs/v4-1-0-release-documents` changelog

### Branch title

The v4.1.0 release documents

### Branch ID

20260810-140324

### Branch type

docs

### What does the change on this branch bring to main?

The two documents `cut-release.ps1` deliberately does not write, for the minor tagged earlier today: the
**consumer-facing highlights** and the **internal summary**. They arrive via a branch and a PR because the
release commit is already tagged, and neither is one of the two changes allowed to land directly on the
trunk.

**The highlights went from 849 lines to about 130, and the cutting was not the work.** The generated draft
is the tier-2 entries verbatim, still in the words their authors wrote for someone reviewing a diff — six
of the fourteen open with the branch id and type before saying anything. What a consumer needs from
`v4.1.0` is almost the inverse: this release is largely about failures that produce **no error message**,
so the page leads with **three checks to run against their own repo**, each about state that may already
be wrong there rather than about anything this release changes underneath them.

The order of those three is a judgement rather than the draft's order, and it is the one editorial
decision on this branch worth arguing about. The drifted PR-template placeholder leads because it is the
only one with a measured cost attached — twelve merged PRs with no description — and because a reader can
test it in one action: open a PR and see whether the warning appears. `Get-ReleaseNotesGrouping` is second
because its failure is invisible *and* delayed: the contract check reports `[OK]` after a wrong adoption,
and the wrong tree only appears one release later. The `v3.x` migration path is third because it reaches
the fewest readers, and the ones it reaches are the ones least likely to be reading at all.

**The internal note is the published Release body, so its "what was still open" section is written as a
snapshot.** That is the section this repo has measured going stale in hours rather than months. It names
the two follow-ups that were declined with their reasons — the pre-written repo slot in the shipped
template, and extending `adopt-config` to files — and the one real gap: a consumer's own template is
checked by nothing, because the new gate runs here.

**Its "what it is worth" section names the theme rather than the changes**, which is what separates this
tier from the highlights: failures with no error message. Twelve empty PR bodies is not a crisis on any
given day; it is a record that quietly stopped being usable, found by diffing two files months later. The
same shape appeared three times in one week across different seams, and that pattern is the thing a
colleague outside this repo can actually use.

### Significance

#### Tier 0

Two documents that would otherwise be missing from the release, plus the `releases/README.md` row now
pointing at the internal note. Routine work with a checklist behind it.

**Score:** 2

#### Tier 1

The internal note is what a colleague reads about this release, and it is the only place the release's
theme is stated as a theme rather than as fourteen separate changes.

**Score:** 3

#### Tier 2

The highlights are the page a consumer opens, and this release's whole point is three things that may
already be wrong in their repo. A draft left in reviewer language would have buried all three under
branch ids.

**Score:** 4

### Pull Request

[PR #577](https://github.com/DaveKJohn/claude-code-specialists/pull/577) · merged 2026-08-10

---

## `docs/the-v4-0-0-page-holds-itself-to-the-seven-tests` changelog

### Branch title

The v4.0.0 consumer page is rewritten for its own reader

### Branch ID

20260810-161502

### Branch type

docs

### What does the change on this branch bring to main?

The seven tests in the `cut-release` skill were written after reviewing `v4.0.0`'s own consumer page and
finding it half-written for a maintainer. This applies them to that page. **Every factual claim it made
is still there** — what changed is who it is addressed to, and in what order.

**What the tests actually caught:**

- **Test 3, the order.** The three migration sections — the only actionable content on the page — sat at
  the *bottom*, and the lead had to tell the reader to skip down to them. They are now the first section,
  and they run chronologically (`3.2.0` → `3.8.0` → `3.10.0`) instead of the previous
  `3.10.0` → `3.2.0` → `3.8.0`, so a reader on an old version walks forward from wherever they are
  instead of jumping backwards.
- **Test 5, the symptom.** The page said both breaking changes "fail in silence" and stopped there.
  Silence is a category; what a reader can check is a fact. Each one now names what they will actually
  see — a session that starts normally with no specialists in it, and a name that no longer resolves.
- **Test 2, our effort versus their outcome.** Gone: "twenty-one releases and fifty-one pull requests in
  ten days", and the whole block about a lint check we measured over 120 documents and declined. Both are
  true and neither is theirs; the second is tier-0 material that had reached a tier-2 page.
- **Test 4, the lead.** It now answers both branches of the only question the reader arrives with: on
  `v3.10.0` there is nothing to do, before it there are two things that break with no error message.
- **Test 1, the second person.** Three of the three "what you get" items are now addressed to the reader,
  including the release-rules correction, which is genuinely useful to them and had been written as a
  description of our documentation.

**Measured, because "it reads better" is not a measurement:** 654 words from 679 and `you`/`your` from 27
to 33. The word count barely moved, and that is the honest result — this was not a trim. One block left,
structure arrived (the symptoms, the numbered walk), and the essayistic paragraphs became two-to-four
sentence items. What moved was what the words are about and where they sit.

### Significance

#### Tier 0

The page is one of eleven consumer documents and nothing reads it programmatically. Its value here is as
the worked example: the next person editing a consumer draft has a before-and-after of the seven tests
applied to a real page rather than a list of rules.

**Score:** 2

#### Tier 1

The norm proved itself on the document that provoked it, and the measurement is the part worth carrying:
the word count barely moved. Anyone expecting "write for the reader" to mean "cut it down" now has the
counterexample — the repair was ordering, addressee and one deletion, not length.

**Score:** 3

#### Tier 2

Anyone updating from `v3.x` opens this page to answer one question, and the answer used to be at the
bottom behind a chapter retrospective. It is now the first thing on the page, in the order they would
actually walk it, and each breaking change tells them what they will see when it bites.

**Score:** 3

### Pull Request

[PR #582](https://github.com/DaveKJohn/claude-code-specialists/pull/582) · merged 2026-08-10

---

## `feat/the-consumer-document-is-written-for-its-reader` changelog

### Branch title

The consumer document has a writing norm, and a gate against misrouting its reader

### Branch ID

20260810-153739

### Branch type

feat

### What does the change on this branch bring to main?

Renaming the tier-2 document after its reader was half the answer. This is the other half: **seven tests
for the document itself**, in the portable `cut-release` skill, and **one of them as a gate**.

**Where the tests come from.** `v4.0.0`'s own consumer document was reviewed against the question *"is
this written for someone who paid for the product?"*, and the answer was: partly. One of its four
substantive blocks was in the second person; it opened with "twenty-one releases and fifty-one pull
requests in ten days" — our effort, not their outcome; it carried a full block about a lint check we
measured and declined, which is tier-0 material in a tier-2 document; it used in-house vocabulary; it had
to tell the reader to skip to the bottom for the useful part; and it linked them into the development
notes. Five dev-tool changelogs were then read — Linear, Stripe, Vercel, Raycast, GitHub — and each of the
seven tests is carried by what one of them actually does, rather than by taste. Vercel runs 2–4 sentences
per entry; Stripe puts a `Breaking change? Yes/No` on every one; Raycast's changelog contains *zero*
internal metrics; React's upgrade guide orders its whole contents by urgency.

**The split between prose and gate is the measured part, and it is what travels.** Three candidate rules
were run over this repo's eleven consumer documents before anything was built:

| candidate rule | findings | true | verdict |
|---|---|---|---|
| links into `development/` or `internal/` | 2 | **2** | built — lint check 25 |
| a significance score in the document | 4 | 0 | declined |
| a branch name or PR number in the document | 3 | 0 | declined |

Both declined rules fail on the same document for the same reason: `v3.7.0`'s release **was about the
entry format**, so its consumer document correctly quotes `#### Tier 2`, `**Score:** N/A` and
`` ## `feat/your-branch` changelog `` as illustrations of the shape it was announcing. No regex separates
an illustration from a leak, and both rules would have needed an exemption list on the day they landed.

**Check 25 escapes that by reading the link TARGET only.** A path in prose is check 4's declined territory
— 124 findings, none real, because most paths this product names describe somebody else's repo — while a
link is not a path being discussed but a destination being offered. The two real findings were removed in
the same change, so the gate reports 11 documents and 0 findings rather than being born red behind an
exemption list. Eight asserts hold it, including all three deliberate narrowings and the case where a repo
has no consumer tier at all.

### Significance

#### Tier 0

The gate closes a defect class no other check sees, and the three-rule measurement means the next person
who proposes "flag X in the consumer document" has the answer already: two of the three obvious rules are
false-positive machines on this tree, and the reason is a document that legitimately quotes the format it
announces.

**Score:** 3

#### Tier 1

This is the transferable half. The finding was not sloppiness but **audience drift** — a maintainer editing
the draft keeps writing for the reader they have been writing for all week — and the seven tests are a
checklist against exactly that, with a named example behind each. Anyone here writing anything
outward-facing can hold it against the same list.

**Score:** 4

#### Tier 2

A consumer who enables this workflow gets the seven tests in the `cut-release` skill they already follow,
and the instruction to run the same three-rule measurement over their own documents before automating any
of it — because which rule a repo can afford as a gate is a fact about that repo's tree, not about the
list. Two of their release pages here also stop pointing them into a document written for developers.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #579](https://github.com/DaveKJohn/claude-code-specialists/pull/579) · merged 2026-08-10

---

## `feat/consumer-facing-document-named-for-its-reader` changelog

### Branch title

The consumer-facing release document is named for its reader

### Branch ID

20260810-145624

### Branch type

feat

### What does the change on this branch bring to main?

The tier-2 release document was called **highlights** everywhere — the directory, the seam, the
renderer, some ten documents of prose — and that name described the **form** (a selection of the nice
bits) instead of the audience. Its two neighbours name their reader, and the tier table has always said
tier 2 is "consumers", so this was the one of the three whose name disagreed with the model it belongs
to. It is `releases/consumer/` now, and the seam is `Get-ReleaseConsumerBumps`.

**The measurement that decided it.** Five dev-tool changelogs in the field were read before renaming —
Linear, Stripe, Vercel, Raycast and GitHub — and **not one publishes anything called "highlights"**. The
live names are *Changelog*, *Release notes* and *What's new*, every one of which names the document or
its reader. The same pass found the split this repo already runs: GitHub keeps a terse engineering
changelog beside readable announcements, which is `development`/`internal` beside this tier. The form-name
was also earning its keep in the wrong direction — it invites the register a self-selected best-of
invites, which is what a review of `v4.0.0`'s own document had just found it guilty of.

**The one thing that could have broken a consumer in silence is the seam, and it is read under both
names.** `Get-ReleaseConsumerBumps` is tried first and `Get-ReleaseHighlightsBumps` second, because the
fallback for an undefined seam is `@()` — the tier switched **off**. A repo still carrying the old name
would otherwise cut a minor, write no document for the very consumer it was cut for, and report success;
consumers receive this rename through a plugin update rather than by choosing to. `Get-SeamValue` takes a
list of names now, and three asserts hold the pair: both names present in the code view, the current one
**first**, and the reader accepting more than one.

**What was deliberately not renamed.** No GitHub Release body links to a `releases/highlights/…` path —
checked, not assumed — so there was no external permalink to protect and all eleven documents moved. The
**prose** in the archived `releases/development/` notes and in the already-folded `CHANGELOG.md` entries
keeps the old word: those describe what the document was called on the day they were written, which is
the same published-record rule that left seven wrong merge dates standing. Their **links** were
repointed, because a dead link in a record is worse than a relocated one and repointing one changes no
claim. `Get-ReleaseHighlightsStakeholderTypes` and `Get-ReleaseHighlightsWording` keep their names too —
they name functions that no longer exist under any name.

### Significance

#### Tier 0

Roughly ten hand-maintained documents, six scripts and six suites described this tier by a name that
contradicted the tier table two screens above them. The rename costs a developer nothing to read and
removes the question "is the highlights document the tier-2 one?" from every future pass over the
release machinery.

**Score:** 2

#### Tier 1

The reason travels further than the word: a document named after its form invites a best-of register,
and a document named after its reader invites the reader's question. That is the half a colleague can
apply to their own outward-facing writing, and it is now written down with the five-changelog measurement
behind it rather than as taste.

**Score:** 3

#### Tier 2

A consumer who overrode `Get-ReleaseHighlightsBumps` keeps working — the seam reads both names — but the
directory their release documents land in changes name, and their own repo-config should follow. The
silent-failure mode this rename could have had is exactly the class of defect the previous release was
about, so it is worth one line of their attention: check the seam name, expect `releases/consumer/`.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #578](https://github.com/DaveKJohn/claude-code-specialists/pull/578) · merged 2026-08-10

---

