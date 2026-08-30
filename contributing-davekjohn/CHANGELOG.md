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

### DEPLOY: `fix/named-gate-entry-point-v1` · 20260830-193334

`open-pr.ps1` gains **`-GatesOnly`**: run this repo's lint gate and every test suite against the working
tree, and stop there — no branch check, no push, no PR. It exists for the commits that are made on the
trunk. Three changes land directly on `main` under named exceptions, and the release-notes commit is the one
typed by hand: `cut-release`'s step 4 told its reader to run the gates *"exactly as `open-pr` would have run
them for you"*, and `open-pr` refuses on `main` six hundred lines before it reaches a gate. The rule was
right and the route was closed.

**What that cost is not the missing flag but the invocation that replaces it.** With no named entry point the
reader assembles one, it goes green, and it is quietly missing two things: `Get-TestCommands` is out of
scope, so a repo whose suites are not all PowerShell has the rest of them skipped **without a word**, and the
lint half gets a hardcoded script rather than the repo's own `Get-LintScript`. Both bite a consumer harder
than they bite here.

Mechanically, the gate block moved out of `open-pr.ps1` into `Invoke-WorkflowGates` in
[`scripts/lib/gate-lib.ps1`](../scripts/lib/gate-lib.ps1), and both routes now call it — the flag's whole
value is that the two **cannot** reach a different verdict about the same tree. It is not an escape valve: it
adds a place the gates can run and removes none, `-SkipLint`/`-SkipTests` still mean what they always
meant, and a green run records gate evidence like any other. `cut-release`'s step 4, the `open-pr` skill
page and [`CONTRIBUTING.md`](CONTRIBUTING.md) §4.6 — which carried the same gap in different words — all
name the command now.

**Score:** 3

#### What makes this deploy extra special

A consumer meets this harder than the source repo does: their `scripts/tests` may hold a different set,
`Get-TestCommands` may add commands an ad-hoc call never runs, and they have no #1033 in their history to
warn them off the in-process shape. They receive both the flag and the pages that name it through the plugin
update, so the documented route arrives with the capability rather than after it.

**Score:** 3

#### Pull Request

A named entry point for the gates, so a direct-on-main commit can run them

Plugins: contributing-davekjohn

[PR #1160](https://github.com/DaveKJohn/claude-code-specialists/pull/1160)

---

