# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with — what the change deploys to `main`, and the PR.
The first holds the change's two audiences, the second of them under `#### What makes this change extra
special`; the tier numbers live in the parser rather than in any heading. Entries written before
August 16, 2026 carry the longer set of headings that shape replaced, and every earlier shape is read
exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## `feat/shopify-live-theme-guard` deployment

### What does the change on this branch deploy to main?

`team-shopify` gains an operational floor: a `PreToolUse` guard that refuses a theme **publish**, a theme
**delete**, or an unauthorised **push aimed at the live theme** — whatever shell wraps the command. It is
this plugin's first hook, and its first executable of any kind: until now the payload was three agent defs,
three manuals and one skill page, all of it instruction text.

**Prose was the whole enforcement, and prose does not stop a command.** Two things make a written rule
insufficient here rather than merely weak. A **permission deny list matches a command prefix**, so a rule
forbidding the CLI never sees the same command wrapped in `powershell -Command "…"` — and a settings file
that allows both leaves the exact forbidden command reachable by wrapping it, which is the default state of
a repo rather than a misconfiguration. And it **was built twice**: both Shopify consumers wrote this guard
independently before it shipped here, which is the definition of something belonging in the plugin.

**Rules 1 and 2 have no escape hatch at all** and need no configuration: publishing makes a theme the
customer-facing one and a delete cannot be undone, so both stay the owner's own keystroke. Rule 3 is
authorised per command by a marker written as a shell comment — a marker rather than an environment
variable, because the hook runs as its own process and would not inherit an inline prefix; a variable would
have to be set session-wide, which is exactly the state that makes a stray push dangerous.

**Two optional seam values, and the absent case is reported rather than left silent.**
`Get-ShopifyLiveThemeId` is what lets the guard recognise a push aimed at live *by id*; without it
`--allow-live` still blocks and that push passes. A guard that is installed reads as protection, so that
half-armed state is the one thing the accompanying `SessionStart` check speaks about — naming the function
to add and, deliberately, which rules **do** still hold, so it cannot read as "unprotected".
`Get-ShopifyLivePushMarker` defaults to accepting any marker **ending in** `LIVE-PUSH-AUTHORIZED`, which is
what both existing consumers already write (`SWB-…`, `XOXO-…`); setting it narrows to one spelling.
Recognise both, write one.

**Nothing changes in this repo**: it enables `team-alpha` and `workflow-davekjohn` only, so the hook is
payload here rather than something that runs.

**Score:** 4

#### What makes this change extra special

Both Shopify consumers serve real customers from a live theme, and Shopify provides no lock. So the failure
this prevents is a single stray command against revenue — which has not happened, and the reason it is
worth 4 rather than 1 is that the route to it was **open by default** in every repo enabling this team,
through the wrapper gap that permissions structurally cannot see.

There is also something to do on receipt, which is why this is not merely a gift: a consumer who does not
answer `Get-ShopifyLiveThemeId` carries a standing `[ERROR]` at session start until they do, and the two
consumers who already wrote their own guard now have two — theirs is redundant, and both of their markers
are accepted by the shipped default, so removing the local copy breaks nothing.

**The transferable half is the matching, not the rule.** The reporting consumer's first version matched the
forbidden words anywhere in the command string, and on day one it blocked the heredoc that wrote the rule
into their own `CLAUDE.md` and the `perl` line that later edited that sentence. Neither would have touched
the store. A guard that makes its own rule impossible to write down is one somebody eventually switches
off, which is worse than no guard — so this asks *where* the words sit rather than whether they occur:
heredoc bodies stripped unless an interpreter reads them, text-tool segments skipped unless the command
pipes into a shell or uses `eval`/`xargs`, everything else matched per segment. **Each of those three
exemptions has a counter-case in the suite**, because an exemption without one is a hole with a comment on
it.

**Score:** 4

### Pull Request · 20260820-050600

the Shopify team ships the live-theme guard

Plugins: team-shopify

[PR #774](https://github.com/DaveKJohn/claude-code-specialists/pull/774)

---

## `feat/release-page-theme-seam` deployment

### What does the change on this branch deploy to main?

The release-notes page takes its colours from the repo. `Get-ReleasePageTheme` joins
`Get-ReleasePageTitle` and `Get-ReleasePageWorkerName` as the third optional answer in that family: a map
of custom-property overrides, written into the page as one `:root` block. Absent, nothing changes — the
page keeps its shipped palette in light and dark.

**`color-scheme` is accepted as a name beside the `--custom-properties`, and that is the half the request
turned on.** A brand with no dark variant pins `light` and keeps its colours on any background; without it
the seam could say *these colours* but not *no dark mode*, which is exactly the case inbound #759 named.
The block is written **after** the dark-mode media query, so a repo's answer beats both defaults rather
than being overridden by whichever matched last — and that is asserted by position, not just by presence.

**The values are validated rather than escaped, and that distinction is the security half.** They land in
a `<style>` element, where escaping a `#` would stop it being a colour while a closing style tag would end
the element and turn everything after it into markup. So `Format-ReleasePageStyle` allows names that are
`--something` or `color-scheme`, and values built from letters, digits, `#`, parentheses, commas, dots,
percent, spaces and hyphens — nothing else. A rejected key is **dropped with a warning naming it**, and the
page is still generated: a report about releases must not be stopped by one bad colour, and a silently
ignored setting is the failure this repo keeps paying for.

**What this deliberately does not do is the design pass**, which is the other half of #759 and is not a
branch's to take: no gate can prove that a page *looks* right. The seam is the prerequisite that request
named, and its shape survives a redesign — whatever the properties end up being called, the mechanism is
the same override block in the same place.

**Score:** 3

#### What makes this change extra special

The interesting part was not the seam but what building it exposed. The template's own doc comment listed
its placeholders **by spelling them in full**, and `String.Replace` hits every occurrence — so the comment
was being filled in on every build. Harmless while all four were short strings, and not harmless the moment
a palette joined them: the page came out with a whole `:root { ... }` rule, comment and all, written inside
an HTML comment above the dark-mode block.

**Nothing rendered wrong.** The real block was also in its proper place, so the page looked correct, no
check spoke, and only an assert measuring *where* the palette landed could see it. That assert existed
because the cascade made position load-bearing — which is the argument for writing the assert that way even
when presence would have been easier. The doc comment now names the placeholders without their sigils, and
carries the reason.

A second, smaller instance of the same shape followed immediately: the assert counting `:root` blocks
counted the new comment, which quotes `:root { ... }` while explaining the defect. It is anchored on the
line start now — the mention-versus-use question this repo's lint has answered four times, arriving in a
test.

**Score:** 3

### Pull Request · 20260820-013624

the release-notes page takes a palette from the repo

Plugins: workflow-davekjohn

[PR #773](https://github.com/DaveKJohn/claude-code-specialists/pull/773)

---

## `fix/retired-seam-scaffold` deployment

### What does the change on this branch deploy to main?

`specialists-init` stops scaffolding `Get-ChangelogHeading` into a fresh consumer's
`scripts/repo-config.ps1`. The seam was **retired** on August 5, 2026 with the flat changelog (#178) —
the contract registry holds no record for it and nothing reads it — but the bootstrap kept writing the
function, its backing variable, and a comment presenting it as live: *"Set it to whatever this repo uses;
the fold stops with a clear message if the heading is not found."* The fold no longer looks for a heading
at all.

**This repo's own two suites asserted both sides of that for fifteen days.** `repo-config.tests.ps1`
requires the source's config **not** to define it — *"a repo-config still answering these would hand values
to a mechanism that no longer reads them"* — while `bootstrap-drift.tests.ps1` required the scaffold to
supply it, under a comment calling it "Optional in the script contract". Optional is the stale half: it is
not optional, it is gone. That assert now reads the other way, on the whole block rather than the function,
and carries the reason so the next reader does not restore it.

**Two neighbours came along, both in the same class — a document that misinforms the reader who trusts it.**
`ship-pr.ps1`'s own header claimed the fold reads `Get-ChangelogHeading`; it does not, and has not since
that retirement. And three `.EXAMPLE`/doc lines in `ship-pr.ps1` and `open-pr.ps1` read
`-Resolves 331,332` **unquoted**, which cannot run: called directly, `331,332` is parsed as an array before
binding, and a script file with `[CmdletBinding()]` refuses an array for a `[string]` parameter. Reproduced
twice before being called a defect — once on the real script, once on a four-line probe — and the probe is
what makes it worth documenting: a **scriptblock** coerces the same argument to `'331 332'` and succeeds, so
testing the behaviour rather than the file hides it. The note now sits beside the parameter, because the
quotes are the price of the type choice rather than a style preference.

**Score:** 3

#### What makes this change extra special

A scaffolded file is written **once and never again**, which is what makes a wrong default expensive rather
than untidy: no later release can correct it. Every consumer bootstrapped with `workflow-davekjohn` since
August 5 carries a dead function with a comment that argues for filling it in — and one of them paid for it
in the way that is easiest to miss, by doing the work properly. `xoxowildhearts`, a Shopify theme repo with
no `CHANGELOG.md` at all, spent **nine lines of comment** reasoning about which of two false values was less
harmful, and then filed the reasoning as an inbound issue. Both of its options were wrong, and so was the
question: nothing reads the answer.

Existing consumers are not reached by this — their file is already written. `INSTALL.md` already tells them
the function may be deleted, which is the only route a write-once scaffold leaves.

**Score:** 3

### Pull Request · 20260820-011031

the bootstrap stops scaffolding a retired seam

Plugins: team-alpha, workflow-davekjohn

[PR #772](https://github.com/DaveKJohn/claude-code-specialists/pull/772)

---

## `fix/manuals-path-and-start-task` deployment

### What does the change on this branch deploy to main?

Two shipped files stop naming things that do not exist.

**`.claude/manuals/` is a path the system has never created.** `specialists-init` creates
`.claude/specialists/lenses/`; the manuals live in the plugin install and are read-only there. Tessa's agent
def named that directory **twice** — once in the `description:` every consumer's model reads at every turn,
once in the body that tells her what she owns — and she is precisely the specialist you reach for to sharpen
those documents, so her own instructions sent her to an empty directory. Both now name the two layers the
system actually has: the repo lenses under `.claude/specialists/lenses/`, and the portable manuals in the
repo that ships them. Her body gained the sentence that split implies — in a consuming repo the manuals
arrive read-only and the lens is where the work lands; in the source they are hers as well.

**`team-shopify`'s `start-task` was written against its home repo**, and all three of its assumptions
failed. Its only executing step ran `scripts/task/start-task.ps1` and called itself a thin wrapper over it,
while no file of that name exists anywhere in the marketplace. It hardcoded a ten-prefix taxonomy while the
seam that states a repo's own taxonomy sits at `scripts/lib/branch-info.ps1`. And it sent the reader to the
`.claude/manuals/` path above for the prefix list.

The page now says what is true: the executing half is **the repo's**, deliberately — creating a preview
theme means the Shopify CLI against one specific store, and which markets get a URL and what counts as a
safe target are facts about a store estate, not about the team. So the skill drives a repo-local script,
states plainly that it has nothing to run where the repo has none, and names the by-hand route instead of
improvising a command. The prefixes come from the repo — its `CLAUDE.md`, and the seam where the repo also
runs `workflow-davekjohn`, which is the hedge that matters: `branch-info.ps1` is scaffolded **only** when
that plugin is enabled, so a `team-shopify` consumer without it has no such file.

**What is deliberately not decided here.** The report offered three routes — ship the script, move the skill
to the workflow plugin, or drop it — and declined to pick, correctly, because the choice is the source's.
This takes none of them: it repairs the three verified defects and leaves the skill where its domain is.
Writing the missing script is a real piece of Shopify-CLI work and moving the skill is a structural call;
both stay open with better information than before.

**Score:** 3

#### What makes this change extra special

The Tessa half reaches **every** consumer, since every repo enables `team-alpha` — and it is the wrong kind
of wrong for a description to be: not a stale detail but an instruction, read every turn, pointing at a
directory the bootstrap has never created. A specialist following it literally has to re-derive the repo
layout before writing a line.

The `start-task` half is smaller in reach and sharper in kind: a shipped skill whose one executing step had
no executable anywhere in the marketplace. It is `disable-model-invocation: true`, so it only ever fires when
the owner types it — which is what kept this a papercut rather than an incident, and also means the failure
landed on him personally, at the moment he expected a shortcut to work.

**Score:** 3

### Pull Request · 20260820-005231

two shipped files stop naming a path and a script that do not exist

Plugins: team-alpha, team-shopify

[PR #771](https://github.com/DaveKJohn/claude-code-specialists/pull/771)

---

## `feat/connector-xoxowildhearts` deployment

### What does the change on this branch deploy to main?

`connectors/xoxowildhearts.json` — the second Shopify consumer joins the register, so the source can finally
see where the two have diverged rather than only that there are two. Every field was measured against the
consumer's own tree rather than copied from the report: 25 lens files matching the rosters exactly (19 + 3 +
3), the plugins enabled against the `github` marketplace source, visibility private, the local checkout
present. Registered now and not earlier because their adoption PR merged at 21:33Z — the register records
what a consumer *has*, and a lens claimed early makes the check report it missing.

**The workflow slot is deliberately left out**, which is the one field that could not be answered without
going stale within the day. Their merged `main` enables `workflow-davekjohn`; their in-flight branch switches
it to `workflow-default`. The check reads the **local checkout**, which sits on that branch — so whichever
answer were written here would be an `[ERROR]` half the time. It gets written once that branch merges, which
is the same rule the report applied to the manifest as a whole, one layer along.

**And that switch answers half of inbound
[#763](https://github.com/DaveKJohn/claude-code-specialists/issues/763)**,
found by writing this file rather than by reading the issue. #763 asks for a way to record "this repo does
not want the `workflow-davekjohn/` folder", because the standing `[ERROR]` about it can be cleared no other
way. The way already exists: that error comes from a hook shipped **only** with `workflow-davekjohn`, and
`workflow-default` — "the workflow a repo gets when it has not chosen one; it imposes nothing" — ships no
hook at all. The reporting consumer used it eight hours after filing.

**Score:** 3

#### What makes this change extra special

Nothing here reaches a consumer: this is the maintainer's own register, and the plugin cache never sees it.
What is worth the reading is that the register earned its keep on its first run for this repo — the
divergence it exists to surface was surfaced by the check refusing the manifest, and one of the two open
questions on the board turned out to be already answered by a plugin that has shipped for weeks.

**Score:** 2

### Pull Request · 20260820-003542

the second Shopify consumer joins the register

[PR #770](https://github.com/DaveKJohn/claude-code-specialists/pull/770)

---

## `fix/team-shopify-store-neutral` deployment

### What does the change on this branch deploy to main?

The three `team-shopify` subagents stop naming one consumer's store. Liam is now the Liquid Developer
**for this repo's Shopify theme**, Sandra and Steven the Store Manager and Configuration Manager **for
this repo's Shopify store** — the shape `team-ecomm` already uses, where its three specialists work "for a
commercial webshop" rather than for a named one. Which store a repo actually is belongs to that repo's
lens, which is where the identity was being read from anyway.

**The report measured three lines; the subject is six**, and the three it missed are the load-bearing half.
Each agent def names the store twice: once in the `description:` a consumer's model reads at every turn,
and once in the body line that tells the subagent who it is — *"You are **Liam 💧**, the Liquid Developer
for smartwatchbanden."* A repair scoped to the descriptions would have left every one of these three
specialists still introducing itself by the wrong store, which is the sentence it acts on. Measured across
the whole plugin: **7** occurrences in 4 files, 6 of them the subject and the seventh
`plugin.json`'s *"(e.g. smartwatchbanden)"* — an example, correctly marked as one, deliberately left.

One neighbour came along because it is the same defect in the same paragraph: Steven's body claimed the
theme landscape is *"the ~68 themes from multiple parties"*, which is one consumer's inventory stated as
the specialist's own reality. It reads "often dozens of themes, from several parties" now; the count is the
lens's to carry. The manuals needed nothing — they already say `--store <store>.myshopify.com` throughout.

**Score:** 1

#### What makes this change extra special

Reported from `xoxowildhearts`, a second Shopify store repo adopted the day before, where the roster the
model is handed read *"Liquid Developer for smartwatchbanden"* — a live theme on a different store, real
customers, real revenue, no staging environment. A subagent whose own description tells it which shop it
works for, naming the wrong one, is a routing hazard in exactly the repo where a wrong-store assumption
costs the most. It could not be corrected from the consuming side either: the descriptions ship with the
plugin, so the repo stayed wrong until this landed.

And the correction is what makes the team reusable at all. `team-shopify` is a team for *Shopify repos*, not
for one of them; with a store name baked into three descriptions, every repo after the first inherited
somebody else's identity.

**Score:** 4

### Pull Request · 20260820-001920

the Shopify team stops naming one consumer store

Plugins: team-shopify

[PR #768](https://github.com/DaveKJohn/claude-code-specialists/pull/768)

---

## `feat/branch-files-cycle-and-deployment` deployment

### What does the change on this branch deploy to main?

The branch dossier is renamed after what each file **is**: `branch-cycle.md` carries the branch through
PLAN / CREATE / TEST / DEPLOY, and `branch-deployment.md` is the part that travels to `main`. The old
names said where a file ended up rather than what it held, which is why the entry kept being read as a
fragment of `CHANGELOG.md` instead of as the claim a branch makes.

Four things move with the names. The step list loses its `### Steps` wrapper — the phases are the
sections now — and gains **DEPLOY** as a fourth heading that deliberately holds no steps, only a pointer to
the other file. The **creation stamp** leaves the entry's heading for the cycle file's, which is the
document created with the branch and reset with the merge; the **landing stamp** appears on the entry's
`Pull Request` heading, written by the fold from the PR's own merge timestamp. So each end of a branch's
life is stamped in the document that owns it.

**And the cycle file becomes a document in its own right** (Dave, by hand in the template, which is this
format's spec): an `#` title over `##` phases, one level shallower than the entry beside it. The entry is
pasted *into* `CHANGELOG.md` and has to arrive at that document's entry level; the cycle file is opened on
its own and travels nowhere, so its title is its own. It loses nothing by no longer switching level between
its reset and written states — nothing folds it, and what tells those states apart is the branch **name** in
the heading, which its reader accepts at either level. `Get-BranchCycleHeadingLevel` and
`Get-BranchCycleSectionLevel` state the pair, so a repo that re-levels its changelog does not silently
re-level the file beside it.

Both old filenames stay readable. `Resolve-BranchFilePath` is the one place that dual-read lives, so a
branch already in flight — here or in any consumer, who meet this through a plugin update rather than by
choosing to — folds and resets in the files it has. Entries whose heading still says `changelog` keep
declaring their type and their shape, which is every entry in `CHANGELOG.md` today.

**Two defects the review on this PR found, both introduced by the move above.** The first would have
blocked the trunk: six section readers were given a shared tolerant tail for the stamped heading, and the
lint's own was the seventh, left on a bare `\s*$`. A folded entry reaches `CHANGELOG.md` as
`### Pull Request · 20260819-171500`, which that gate would have read as a section nobody declares — an
`[entry-heading]` error on the one write that happens directly on `main`, inside the required CI check, so
every PR after the first fold would have been blocked by the fold of the one before it. The stamp is now
stripped before the comparison rather than tolerated inside it, so a misspelled heading is caught exactly as
strictly as before. The second is quieter and reaches consumers: a **pre-dossier** entry has no
`Pull Request` heading to stamp, so moving the date off the closing line took it away from that shape
altogether — silently, in the one document whose subject is when things landed. The fold now asks whether
the section exists and puts the date on the line when it does not. One fact, one place, wherever that place
happens to be.

Two smaller judgement calls, stated rather than buried: the cycle template's guidance no longer says
*"DEPLOY is missing on purpose"* — it would have contradicted the heading three lines below it — and the
fold's closing line carries `[PR #N](url)` alone wherever the heading can hold the moment, rather than
stating the same fact twice in one section.

**Score:** 4

#### What makes this change extra special

The workflow plugin's two branch files are what a subscriber of this system works in every day, and both
their names and the whole shape of the step list change. Nothing breaks on the way — the old names and the
old heading word are still read — but the file you open tomorrow has a different name than the one you
closed today, and the arc you fill in has four phases instead of three, under headings a level up.

And one of the two repairs above is theirs rather than ours: a consumer with a branch in flight from before
the dossier split carries a pre-dossier entry, meets this change through a plugin update rather than by
choosing to, and would have had the landing date quietly dropped from the entry that lands in their
changelog.

**Score:** 4

### Pull Request · 20260820-000541

the branch dossier becomes cycle and deployment

Plugins: workflow-davekjohn

[PR #762](https://github.com/DaveKJohn/claude-code-specialists/pull/762)

---

## Branch `fix/session-status-tier-reader` changelog · 20260819-153236

### What does the change on this branch deploy to main?

`session-status.ps1` reads an entry's tiers through `Resolve-EntryImpact` -- the same reader the fold ranks
on and the release cut groups on -- instead of through a `#### Tier N` pattern of its own. The block now
hands the reader one whole `##` block per entry rather than walking the file a line at a time, which is what
the current format requires: tier 0's section is the entry's opening `###` question, its discriminator is the
score label underneath, and neither is visible one line at a time or fence-aware.

**The pattern it replaces had gone blind in two steps, and both pointed at a patch.** It knew only
`#### Tier N`, so from August 16 it reported tier 0 alone and dropped the audience tier in silence; when tier
0 in turn stopped carrying a heading of its own on August 19 it printed no tier at all for an entry written in
the shape the scaffolder had just been taught to write. Measured on this repo's own three pending entries: one
printed nothing, two printed `tier 0 -> 2` and swallowed their tier-2 line. All three now read correctly, and
the reach they were hiding is a **tier 2 at score 4** -- the minor the pending work has earned, against the
patch a silent tier 0 argues for. `/lock` and `/handover` both open with this script, so that wrong answer was
the first thing a session read.

**Reading through the shared reader is the repair; adding the missing heading would not have been.** Seven
shapes parse there, so every entry already in `CHANGELOG.md` and in every consumer's tree is read as what it
is -- and the next rename cannot reopen this. `N/A` and an unanswered score are now printed as themselves
rather than folded into a zero, and a malformed tier section is surfaced instead of dropped.

**The script keeps its promise that nothing is required.** The library is probed at `..\lib`, the same
relative step `new-branch.ps1` takes, so it resolves in this repo and in the plugin mirror alike; `repo-config`
is loaded once above both readers that need it, because a named tier heading resolves through
`Get-ReleaseAudienceTier`. Absent either, the block states that the tiers are unread rather than inventing a
number -- `tier not read` is a worse-looking answer than `tier 0` and a far better one, because tier 0 is not
a missing answer but a decided one.

Its header said *"it dot-sources nothing"* until today, which had been untrue since the source-repo guard
arrived on August 12 -- and while it stood, that sentence was the argument for giving this block a pattern of
its own. It now says what is actually load-bearing: nothing is **required**.

**Score:** 4

#### What makes this change extra special

A consumer's `/lock` and `/handover` stop reporting a tier nobody declared. How far that reaches depends on
one thing, and it is worth stating rather than averaging over: a repo that has **stated an audience tier** is
scaffolded in the named shape, so its reporter was silently wrong in exactly the way this repo's was; a repo
that has **stated none** keeps the numbered `#### Tier N` headings, which the retired pattern did read -- for
them this is the smaller half. Both gain the parts that were never right: `N/A` rendered as `N/A` instead of a
zero, a malformed section surfaced instead of swallowed, and a reporter that cannot be outrun by the next
format change.

**A consumer who has the reporter and not the format loses nothing.** The library is optional, and where it is
absent the tiers report as unread -- a stated line, not an error and not a fabricated 0.

**Score:** 3

### Pull Request

session-status reads the entry tiers through the shared reader

Plugins: workflow-davekjohn

[PR #761](https://github.com/DaveKJohn/claude-code-specialists/pull/761) · merged 2026-08-19

---

## Branch `feat/entry-format-two-sections` changelog · 20260819-142147

### What does the change on this branch deploy to main?

The changelog entry's tier declarations stop naming themselves. `#### Tier 0` is gone -- the question the
entry opens with IS that section now -- and `#### Higher than tier 0?` reads
`#### What makes this change extra special`, at the same level, inside it. The question itself says
`deploy to main?` where it said `bring to main?`, and the creation stamp is separated from the title by a
middle dot instead of a hyphen. So an entry is still two `###` sections, and no heading names a tier number:
the numbers resolve on read, from `Get-ReleaseAudienceTier`, exactly as the retired heading already did.

Whoever fills one in is answering two questions rather than classifying two readers, which is the point --
and the guidance under the second one now names the repo's own audience in words
(`For tier 2 audiences: the subscriber of a service.`), assembled per repo rather than stored, so a tier-1
repo is not told about subscribers it does not have. That sentence replaces a trailing space left behind when
the previous wording was cut on August 16.

**Seven shapes are read and one is written.** The current nested pair, the `###`-levelled pair this branch
tried on the way to it, the `#### Tier 0` + `#### Higher than tier 0?` pair, the fully numbered
sub-headings, the impact table and the `Tier: N` line all still parse -- which is what keeps the entries
already in `CHANGELOG.md` and in every consumer's tree folding. The discriminator for tier 0's unheaded form
is the **score label** under the question, and it is load-bearing: every entry ever written carries that
heading, so matching it without the guard would have made hundreds of table-shaped and line-shaped entries
read as an unscored tier 0 and emptied every release document built from them. All seven verified before the
gates ran.

**Score:** 4

#### What makes this change extra special

The format arrives through a plugin update rather than by choosing to, so every consumer's next branch is
scaffolded in the new shape and their `branch/templates/` is rewritten to match. Nothing they have already
written has to be migrated, and nothing about their release documents changes. The half they gain is the
guidance naming their own reader: a repo whose audience is tier 1 now reads
`For tier 1 audiences: management and the employer/commissioner.` where the form previously either named a
tier that was only right for a tier-2 repo or trailed off after a space.

**A repo that has stated no audience tier sees no change to its tier headings at all** -- it keeps the
numbered sub-sections and the routing comments between them, because a heading with no tier to resolve to
would read as tier 0 and empty its release documents. That is the same conservative direction the audience
knob has carried since August 12, 2026, and it is deliberate rather than incidental: absent means unchanged.

**Score:** 4

### Pull Request

The entry's tier sections become the two questions it asks

Plugins: workflow-davekjohn

[PR #760](https://github.com/DaveKJohn/claude-code-specialists/pull/760) · merged 2026-08-19

---

## Branch `docs/v4-14-0-timing-total` changelog - 20260819-135552

### What does the change on this branch bring to main?

#### Tier 0

The second timing pass on the `v4.14.0` release note: the end-to-end total, **26m 40s**, plus the four legs
the document could not see while it was being written -- its own gates, CI and the merge, the fold, and the
publish. The head it was frozen with was 8m 35s, so **68% of the release happened after the page describing
it was final**, which is what the two-pass rule exists for.

**Four releases now agree on the split, and the figures are stated so the next reader can check them rather
than trust them.** The head was 32% of the total here, 30% at `v4.13.0`, 24% at `v4.12.0` and 35% at `v4.4.0`
-- all four under a third, each taken from that release's own document. Four readings are not a distribution
and the note says so; what they support is the older claim that the tail is a property of the procedure rather
than a run of coincidences.

**This release ran six minutes longer than either of the two before it, and the note names where rather than
leaving it to be inferred.** All of it is tail: 18m 05s against roughly 14m 23s at `v4.13.0`. Two legs carry
it -- the test gate inside the cut read **364s** where `v4.13.0`'s cut read **147s** for the same 43 suites,
and CI ran **7m 27s** -- and a refused command is in there too: the first `ship-pr` was stopped by the
step-list gate over a step that named the ship chain itself. The gate was right, the step should not have been
written, and it is recorded because the same shape is available to the next person filling in a step list.

**The attachment on the GitHub Release keeps the head-only version and is deliberately not replaced**, per the
published-record rule -- an attachment is what was published when it was published. The bullet saying so is
rewritten from a promise into a statement now that the number exists, and it names this page as the current
version.

**Score:** 2

#### Higher than tier 0?

N/A -- the edit lands in the organisational half of the note, in a figure about what a release cost this repo.
A consumer's decision to update is unaffected, and the section they read is untouched.

**Score:** N/A

### Pull Request

The v4.14.0 release note gains its end-to-end total

[PR #758](https://github.com/DaveKJohn/claude-code-specialists/pull/758) · merged 2026-08-19

---

## Branch `docs/v4-14-0-release-note` changelog - 20260819-133819

### What does the change on this branch bring to main?

#### Tier 0

The hand-written document for `v4.14.0`: the eight tier-2 entries rewritten for somebody deciding whether
to update, plus the two organisational sections a script cannot generate. Three of this release's items
carry an action, so the page is ordered on that rather than on score — the tier-1 release-note repair
leads, because a tier-1 repo's published notes are missing a section and the failure was silent.

**Two entries had to be written in by hand, and the reason is a generator gap worth recording rather than
the writing.** The audience draft rendered `docs/destination-reach` and `feat/agent-shared-under-teams` as
a tier-2 heading with an **empty body**, and neither score sorted. Both were written before the entry-format
change of August 16, 2026, so they head their second section `#### Tier 2` where newer entries head it
`#### Higher than tier 0?` — and the audience renderer reads only the newer wording. The grouping is not
affected: `releases/development/4.x/4.14.0.md` files all eight under *Tier 2 - consumers* correctly, so the
record is complete and only the draft was short. Named in the release note with its measurement and
deliberately **not** repaired mid-release, since a repair reaches the next release either way.

**One carried-forward claim was wrong and is corrected rather than inherited**, which is the rule
`v4.13.0`'s own note stated and this branch is the first to test. That note recorded colleagues as being on
**4.11.0**, two releases behind. Read at the target instead — `BWJ-ecommerce/claude-plugins-bwj`, commit
`9ea8dcf`, 2026-08-16T19:40:08Z, from the published `plugin.json` files — they are on **4.13.0**, one
release behind: a publication landed the same evening the note was written and overtook it. The published
note is left as it stands, because it was true when written; this one states what is true now and says which
figure it replaces.

**The timing is the first pass only**, per the two-pass rule: 8m 35s from clock start to the pushed tag, with
the orientation pass and the cut split out and the 43-suite gate named at 364s inside it. The three legs after
this file is frozen — its own gate, CI and the merge, and the publish — follow in their own small edit once
they exist. That gate reading is itself listed as an open observation: 364s against 147s for the same 43
suites at `v4.13.0`, two single readings on different machine states, named rather than diagnosed.

**Score:** 2

#### Higher than tier 0?

It is the one document a consumer reads to decide whether to update, so it reaches every one of them through
this release's GitHub Release. Three items on the page carry an action — the tier-1 note repair, the
`/continue` → `/handover` rename for anyone coming from 4.12.x or earlier, and `Get-ReleaseHistoryPath` for
a repo that repointed it — and each says plainly what to do; every remaining item says **no action needed**
rather than leaving it to be inferred.

**Score:** 4

### Pull Request

The v4.14.0 release note

[PR #757](https://github.com/DaveKJohn/claude-code-specialists/pull/757) · merged 2026-08-19

---

