## The dead-link scan reaches the payload layers it never read

### What does this change do?

`check-plugin-integrity.ps1` builds its scan set from named categories — every root `*.md`, the handbook,
`connectors/README.md`, every `plugins/**/CHANGELOG.md`, the lenses, `SKILL.md`, manuals, personas,
`RELEASE.md`, `releases/**`, and since yesterday `plugins/*.md`. Four kinds of markdown matched **none** of
them and had therefore never been link-checked:

| layer | files |
|---|---|
| `plugins/*/agents/*.md` | 26 |
| `plugins/agent-shared/*.md` | 11 |
| `.github/**/*.md` | 2 |
| `.claude/rules/*.md` | 1 |

The agent defs are the glaring omission: they are the largest single body of prose this repo ships, they
are payload a consumer executes against, and manuals and personas each already had a rule. The scan set
went from 163 files to 202 and surfaced exactly the one dead link the manual pass had found —
`plugins/specialists-lifehub/agents/02-10-agent.md` pointing at `../../CLAUDE.md`, which is
`plugins/CLAUDE.md` and has never existed. The other 38 files are clean, which is worth stating: the gap
was in coverage, not in a backlog of rot.

**Six assertions bind the four layers separately**, plus the existing out-of-scope decoy and a
remove-and-recheck pass. One combined assertion would have passed with three of the four rules missing.

#### The correction that changed half this branch

[#481](https://github.com/DaveKJohn/claude-code-specialists/issues/481) also proposed rewriting eight
payload links that leave their plugin, on the reasoning that no `../` from a plugin reaches the consumer's
tree. **That premise is wrong, and checking it before acting is the only reason this branch did not ship
churn.** There are two install locations:

- `~/.claude/plugins/marketplaces/claude-code-specialists/` — a **full repo clone** (root docs,
  `plugins/`, `scripts/`, `releases/`), and the location the seam `@`-import already targets;
- `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` — **payload only**.

In the clone a repo-following relative link resolves exactly as it does here. So
`skills/specialists-init/SKILL.md` → `../../../../README.md` and the seven like it mean *the source repo*
and reach it. They were left untouched.

**The two `CLAUDE.md` links were still wrong — for the opposite reason to the one reported.**
`../../../CLAUDE.md` from `plugins/specialists-shopify/agents/` does resolve in the clone; it reaches the
**source** `CLAUDE.md`, while the sentence around it means the safety rules of the repo the agent is
working in. A link that resolves to the wrong document is worse than one that 404s, because nothing
reports it. Both now read "the repo's safety rules" with no link at all — the location-independent form
every persona and manual already uses, and the one inbound #64 introduced for personas. This is the
repo's own rule about verifying a report's *reason* before repairing its *symptom*, applied to a report
this repo wrote itself.

Also corrected: `plugins/*/RELEASE.md` was listed in #481 as uncovered. It was already in the scan set.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 2 | two agent defs stop pointing consumers at the source repo's safety rules when they mean the reader's own; no action required of anyone |
| 1 | 3 | the largest body of prose the plugins ship was never link-checked — 39 files joined the scan, and the four rules are individually pinned by tests |

### Type of change

Fix

Plugins: specialists, specialists-lifehub, specialists-shopify
