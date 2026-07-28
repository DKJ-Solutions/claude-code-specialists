### Empty the ignore-list and adopt all six specialists · Docs · 2026-07-28

Dave: *"waarom is er een ignore list? ik kan mij niet herinneren dat ik hier zelf iets op gezet heb."*
He was right, and the history is worth recording because the mechanism had been citing him for it.

**`Get-RosterIgnoredIds` was never a decision.** It was introduced on 2026-07-20 by commit `d2c8393` —
the same commit that built `check-roster-sync.ps1` — already pre-populated with Paula (02-09), Vera
(04-11), Gwen (04-12) and Cody (04-13), and justified in `repo-config.ps1` as *"a documented choice in
CLAUDE.md, not drift"*. `CLAUDE.md` said no such thing. It said those specialists *"rarely has work
here and therefore has no repo lens **(yet)**"* — a statement about the current state, with an explicit
"yet". The list converted "not yet" into "never report this", and then attributed that conversion to
Dave.

Auden (06-30) was added on 2026-07-24 as a **blocking** code-review finding whose stated reason was
literally *"so check-roster-sync / the SessionStart roster hook do not flag Auden as drift after
merge"* — not "Auden has no place here". Bianca (03-02) was added earlier today with the same reflex,
in this session, described in the very comment as "the ignore-list doing its job, not a workaround for
the new coverage". It was the workaround.

So five of the six were a session silencing its own check, and the sixth was this session doing it
again. **The list is now empty and all six are adopted**: six `VUL-IN` lens scaffolds (staged by the
`sync-roster` skill — dogfooding the recovery path this repo ships) and six roster rows. All 19
specialists the plugin ships now validate: `0 error(s), 0 info signal(s)`.

**The roster grows from 13 to 19 rows, and that cost is real.** A longer table says less at a glance
about who actually works here. The compensation is a paragraph stating outright that the roster lists
*every* specialist the enabled plugins ship, that an empty `VUL-IN` lens is the intended state rather
than a backlog item, and why the ignore-list is empty. Chris can now also route to all six when work
does come up, instead of them being invisible to him.

**The rule that replaces the list** was recorded separately in PR #211: adopting a specialist that
arrives with a plugin update is the default and needs no approval. `Get-RosterIgnoredIds` keeps
existing — the script contract requires the function, and a genuine case may arrive — but empty, which
is what the code always said the normal state was: *"A fresh consumer leaves this empty (every enabled
specialist belongs in its roster)."* The workshop was not following its own instruction.

One detail worth knowing for the next reader: `sync-roster` proposed five roster rows, not six. Bianca
counted as "already in the roster" because the token `03-02` appeared in the prose *about* the
ignore-list — a sentence this change removes. The token-scan is deliberately format-agnostic and cannot
tell a roster row from a mention, so her row was written by hand. Worth remembering whenever an id is
named in prose: it silences the missing-row check for that id.
