### The marketplace remove mechanism was on record · Fix · 2026-07-29

The `claude plugin marketplace remove` bullet added to
[Sylvester's lens](.claude/specialists/lenses/05-15-extension.md) earlier today stated that the exact
scope resolution behind the command's damage "was not captured", and deliberately left the entry as an
operating rule with an unverified mechanism.

**That was wrong, and it was wrong in a checkable way.** The mechanism was on record the whole time, in
[#256](https://github.com/DaveKJohn/davekjohns-workshop/pull/256)'s changelog entry — folded into
`CHANGELOG.md` one commit before the lens bullet was written: the command rewrites the **project**
`settings.json` of the current working directory, not just the scope the marketplace was declared in, and
it emptied the test consumer's `enabledPlugins` *and* `extraKnownMarketplaces`. The bullet now says that,
with the citation.

**The lookup rule is the part worth keeping.** The search that missed it went through the lenses and the
manuals — the places a *rule* lives — and never through `CHANGELOG.md`, which is where this repo's
findings land **first**. A lens is usually a finding's second home, not its first, so "this was never
written down" is not a conclusion you can reach from the manuals alone. That rule is now in the bullet
itself, next to the fact it got wrong. It is also already the standing instruction in
[Chris's lens](.claude/specialists/lenses/01-01-extension.md) under *Consult the docs*, which names
`CHANGELOG.md` explicitly — so this is a documented rule that was skipped, not a missing one, and the
correction belongs where the skip happened.

Found while inspecting the generated v2.15.1 release notes under `-NoPush` — the pass that exists for
catching what the gates cannot see. It caught something other than a stray heading this time.
