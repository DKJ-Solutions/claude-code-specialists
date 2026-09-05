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
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

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

### DEPLOY: fix/1444-stranded-page-token · 20260905-184311

The release page's path token is the one file in this system that cannot be rebuilt: it is the only
lock on a public page, it is deliberately uncommitted in a public repo, and nothing in git remembers
the URL it forms. It lives in a directory derived from the note root and ignored by git -- two good
decisions that meet badly, because renaming the folder above it moves every tracked file and leaves the
token where it was. `git mv` cannot see an ignored sibling by construction, so the miss is silent on
the day it happens, and what is left over reads like rename debris.

`build-release-notes-page.ps1` now asks whether a token exists **anywhere in the tree** rather than
whether one exists at the derived path. A copy found elsewhere is named and never adopted: `-Worker`
points at the folder to move, and `-InitToken` -- whose refusal was the design's whole safety property
and which read the derived path alone -- refuses on it too. Where no copy is found, the refusal still
names the move that hides one, because the operator who has just renamed a folder is the reader most
likely to be looking at it.

Measured on this repo: #1437's rename left exactly that orphan (#1444), and the token is gone from this
machine with it.

**Score:** 2

#### What makes this deploy extra special

N/A -- the person who reads a release page never sees any of this. It is a guard between the operator
and one irreversible mistake.

**Score:** N/A

#### Pull Request

The missing-token refusal points at the copy a folder move left behind

Plugins: dkj-policy

[PR #1452](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1452)

---

### DEPLOY: fix/1446-tip-utf8-decode · 20260905-183608

`new-branch.ps1` reads the remote tip's subject with **`-Utf8`**, so the control-and-format strip added in
[#1439](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1439) sees the characters it exists
to remove. Until now it did not, on any Windows console whose code page is not UTF-8 -- which is the
default.

**The guard was green in the one environment that did not need it.** Windows PowerShell 5.1 decodes a
native child's stdout with `[Console]::OutputEncoding`. On a cp850 console the three UTF-8 bytes of an RTL
override (`e2 80 ae`) arrive as the three ordinary printable characters cp850 maps them to -- and
`\p{Cf}` does not match an ordinary printable character, so nothing was stripped. Encoding those same three
characters back out is byte-identical, so the payload was reconstituted intact the moment anything
downstream decoded as UTF-8. The ESC half of the guard always worked, because `0x1B` is ASCII and every
candidate code page agrees below `0x80` -- which is exactly the property
[`language-layers.md`](../.claude/rules/language-layers.md) already names as the reason to hold the wire to
ASCII and decode it yourself.

**The mechanism was already built, documented and unused at this call site.**
`Invoke-NativeCapture -Utf8` exists for precisely this
([#907](https://github.com/DKJ-Solutions/claude-code-specialists/issues/907)), and its docstring says *pass
it wherever the output is DATA rather than progress*. A commit subject that a matcher then inspects
character by character is the strongest form of that case, and the flag was simply not passed.

**And the suite could not have caught it.** Its premise assert -- *"the commit on origin really carries the
RTL override"*, written so the asserts below it are not vacuous -- read the subject back through `& git`,
the same console-code-page decode the product code used. So on a non-UTF-8 console it reported the fixture
as broken while the fixture was intact, and on a UTF-8 console everything passed. It now reads through the
same explicit decode, which is what makes it independent.

**Score:** 4

#### What makes this deploy extra special

Every consumer runs `new-branch.ps1` from the plugin mirror, on their own machine, and the guard this
repairs is about **somebody else's text**: the tip subject is written by whoever pushed to the shared
branch. A consumer on a default Windows console had the strip in their copy of the script and not in
effect -- and the output it protects is read by an agent session as well as by a person, where a crafted
subject wearing this script's own `WARNING` prefix is an injection surface rather than a display bug.

Nothing about how the script is used changes, and no flag is added for them to know about. The line they
already see is now the line the script promised.

**Score:** 4

#### Pull Request

the remote-tip read decodes as UTF-8, so the sanitiser sees the characters it strips

Plugins: dkj-policy

[PR #1451](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1451)

---

### DEPLOY: fix/1445-reminder-install-route · 20260905-181831

`cut-release`'s closing self-consumption reminder no longer prints a command that cannot run in the repo it
is printed for. It used to read `.claude/settings.json` and emit
`claude plugin update <id> --scope project` for every enabled plugin -- but `enabledPlugins` is the
**declarative** route while `plugin update` operates on an **install record**, so in a repo adopted that way
the very source the reminder consulted was the one guaranteeing the command it printed would refuse. Measured
here immediately after the v4.30.0 cut: the refresh succeeded, both update commands answered
`Plugin "..." is not installed`.

It now asks the install administration which of the two routes each enabled plugin actually took, through the
shared `Test-PluginInstalledHere` rather than a second private reader, and prints per plugin: an id with a
record for this path keeps its update command, an id without one is named under the marketplace refresh --
which is its whole remedy, a restart being what applies it. Both routes were measured rather than reasoned
about, because the report flagged the second as inferred and the repair differed per answer; the finding that
settled the shape is that `claude plugin install --scope project` writes the **same** `enabledPlugins` key the
declarative route uses, so the two are indistinguishable from settings and detection had to come from
elsewhere. Where the administration is absent or unreadable the old line is printed unchanged -- absence of
evidence is not evidence of absence, and that default is inherited from the shared predicate rather than
re-decided.

The reminder's premise, its conditionality and its 2026-08-15 reasoning are untouched: this is the remedy it
names, not the reason it exists.

**Score:** 3

#### What makes this deploy extra special

A consuming repo that cuts its own releases with this plugin gets the same correction, and it matters most
for the adoption route `INSTALL.md` does *not* document -- settings keys without an install. Such a repo used
to end every cut with a hard failure against a machine that was in fact fully up to date, with no way to tell
that from a real one. A repo adopted the documented way (`claude plugin install --scope project`) sees no
change at all: it has a record, so it still gets its update command.

**Score:** 2

#### Pull Request

Self-consumption reminder: only print an update command the repo's adoption route can run

Plugins: dkj-policy

[PR #1448](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1448)

---

