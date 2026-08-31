# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `fix/shopify-floor-checkout-v5-consistency-v1` · 20260831-225420

`adopt-shopify-floor.ps1` scaffolded `theme-check.yml` with `actions/checkout@v7`, the one pin in the
repo not on `@v5` after the #1175 sweep. Both mirrored copies now pin `@v5`, and the test suite
asserts the scaffolded version so it cannot drift again.

**Score:** 2

#### What makes this deploy extra special

A consumer adopting the Shopify floor gets a `theme-check.yml` whose checkout pin now matches every
other workflow in the tree; no functional change while `@v7` still resolves, but the inconsistency is
gone. N/A — no service subscriber notices this.

**Score:** N/A

#### Pull Request

Shopify floor scaffolds actions/checkout@v5, matching the rest of the repo

Plugins: team-shopify

[PR #1178](https://github.com/DaveKJohn/claude-code-specialists/pull/1178)

---

### DEPLOY: `fix/checkout-v5-node20-deprecation-v1` · 20260831-223457

`actions/checkout@v4` targets Node 20, which GitHub now force-runs on Node 24 while emitting a
deprecation notice on every run. This bumps every `@v4` pin in the repo's shared workflow surface to
`@v5` (Node 24 native): the `workflow-bwj` `asana-mirror.yml` template a consumer copies, the repo's
own `ci.yml` and `branch-entry.yml`, and the `branch-entry.yml` body `adopt-workflow-folder.ps1`
scaffolds into a consumer (both the script and its plugin mirror). Behaviour is unchanged; the
Actions log loses the deprecation line.

**Score:** 1

Cosmetic today -- the runs still succeed. It forecloses one failure: when GitHub retires the Node 24
fallback for actions still targeting Node 20, every `@v4` `checkout` step stops running, and every
`asana-mirror` run plus this repo's CI would break until someone traced it to the pin.

#### What makes this deploy extra special

A `workflow-bwj` consumer who has copied `asana-mirror.yml` sees the deprecation line drop out of
their own Actions log (the reporter, BWJ-ecommerce/smartwatchbanden, filed it for exactly that), and
inherits the same foreclosed future break. Still cosmetic for them until that fallback is retired.

**Score:** 1

#### Pull Request

Bump actions/checkout@v4 to @v5 across shared workflow templates and CI

Plugins: contributing-davekjohn, workflow-bwj

[PR #1176](https://github.com/DaveKJohn/claude-code-specialists/pull/1176)

---

### DEPLOY: `fix/score-line-trailing-reason-v1` · 20260831-211004

`**Score:** N/A -- <reason>` written on one line used to parse as *unanswered* (score 0, not N/A)
because the value has to be the last token on the line; a reason trailing on the score line now reads
the value and is named as a misplaced reason, the way one written below the line already was. Names
the failure it forecloses: an audience-tier entry written as `**Score:** 3 -- <reason>` would have
had its score ignored, resolved to tier 0, and silently under-bumped a release from minor to patch.

**Score:** 2

#### What makes this deploy extra special

Internal changelog-tooling fix; no subscriber of the service observes it.

**Score:** N/A

#### Pull Request

The score-line parser reads the value when a reason trails on the same line

Plugins: contributing-davekjohn

[PR #1174](https://github.com/DaveKJohn/claude-code-specialists/pull/1174)

---

