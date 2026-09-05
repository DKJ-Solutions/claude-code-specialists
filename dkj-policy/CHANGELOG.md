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

