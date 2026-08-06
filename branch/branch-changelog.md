## A skipped plugin says why it was skipped, not that it is missing

### What does this change do?

`check-roster-sync.ps1` told two different situations apart that it used to report as one. When it cannot
resolve a plugin's cache dir it now says either *not on this machine* or *here, but it ships no `agents/`
directory* — and only the first is the install problem the old wording described.

**`Resolve-PluginDir` cannot distinguish them, and that is correct of it.** It requires an `agents/` dir at
every return path, because a roster check has nothing to read without one. So it answers `$null` both for a
plugin that is absent and for one sitting in the cache with skills, hooks or MCP servers and no agents —
two different facts about the machine, reported as the absent one.

**Measured on `figma@claude-plugins-official`.** It sits in the cache at 2.2.90, its `installPath` is in the
administration and resolves, and the session start reported it as *"enabled but not found in the cache
— skipped (the install may run on another machine)"*. Every part of the behaviour was right: a plugin of
skills and MCP servers is nothing for a roster check to check. Only the stated reason was false, which is
the failure shape this repo keeps paying for — a reader acting on that line goes looking for a broken
install, on a machine where nothing is broken.

**The discriminator is `Get-CachedPluginDirs`, and it lives next to `Resolve-PluginDir` rather than in the
caller.** `<CacheRoot>/<Marketplace>/<Name>/<version>` is that function's own layout knowledge, and a second
construction of it in the script asking the question could disagree with the one answering it.
`Resolve-PluginDir`'s version scan now reads from the same helper, so the enumeration and the discriminator
cannot drift apart. Its `[version]` sort travels along unchanged — a string sort puts 1.9.0 above 1.10.0.

**The test pins the false reason being gone, not just a truer one being present.** Verified in both
directions: with the discriminator removed, the three asserts that name the real reason, the version found,
and the absence of the old wording all fail. The fourth — exit code 0 — passes either way and is labelled
an invariant, because a skills-only plugin was never an error.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 2 | every consumer runs this check at session start, and any plugin they enable that ships no agents produced the same false line |
| 1 | 2 | one fewer session-start message that sends a reader after a problem that is not there |

### Type of change

Fix
