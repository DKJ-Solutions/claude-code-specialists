# `team-shopify` — the Shopify add-on team

Three specialists for a Shopify store repo, one domain skill, and an **operational floor**: the part that
is not advice.

| what | who / where |
|---|---|
| **Liam** 💧 `04-20` | Liquid Developer — features and fixes in the theme code, plus `assets/` and `locales/` |
| **Sandra** 🛍️ `05-21` | Store Manager — read-only admin reconnaissance and the pre-push checklist |
| **Steven** 🗂️ `05-22` | Configuration Manager — theme estate, cleanup policy, CLI and auth reference |
| `start-task` | the skill that opens a task: a branch plus its matching unpublished preview theme |
| `hooks/guard-live-theme.ps1` | **the floor** — a `PreToolUse` guard on the live theme |
| `hooks/shopify-floor-sessioncheck.ps1` | says when that guard is only half armed |

Teams stack: this one adds to `team-alpha`, and a commercial store typically enables `team-ecomm` beside
it. Which store a repo *is* belongs to that repo's lenses, never to this plugin.

## The floor: why a guard and not a rule

This team exists because a live theme serves real money and Shopify has no locking. The manuals state
that in prose, in three places — and **prose does not stop a command**. Two things make a written rule
insufficient here rather than merely weak:

- **A permission deny list matches a command prefix.** A rule that forbids the CLI never sees the same
  command wrapped in a shell invocation, and a settings file that allows both the CLI and a
  `powershell -Command "…"` wrapper leaves the exact forbidden command reachable by wrapping it. That is
  the default state of a repo, not a misconfiguration.
- **It was built twice.** Two consumers of this plugin independently wrote this same guard before it
  shipped here (inbound [#769](https://github.com/DaveKJohn/claude-code-specialists/issues/769)), and the
  second had to learn the false-positive lesson below from scratch while the first still carries it.

### What it refuses

| | rule | needs configuration? |
|---|---|---|
| 1 | a theme **publish** — always | no |
| 2 | a theme **delete** — always | no |
| 3 | a theme **push** aimed at live — unless authorised | the id half does |

Rules 1 and 2 have **no escape hatch at all**, and that is deliberate: publishing makes a theme the
customer-facing one and a delete cannot be undone, so both stay the store owner's own keystroke rather
than something a marker in a command line can stand in for.

**Untouched:** every form of `theme pull`, including `--live` — reading is how a pre-task sync works —
pushes to an unpublished preview theme, and every other command.

### Authorising the deliberate live push

Add the marker to that exact command, as a shell comment:

```bash
shopify theme push --store yours.myshopify.com --theme <live id> --only assets/x.css --allow-live # LIVE-PUSH-AUTHORIZED
```

It is a comment in both shells, so it changes nothing about what runs. **A marker rather than an
environment variable**, because the hook runs as its own process and would not inherit an inline env
prefix — a variable would have to be set session-wide, which is exactly the state that makes a stray push
dangerous. A marker authorises **one** command, visibly, in the transcript.

## What your repo has to answer

Two optional functions in your own `scripts/repo-config.ps1` — the file `specialists-init` already
scaffolds:

```powershell
function Get-ShopifyLiveThemeId    { return '190793613653' }   # shopify theme list names it
function Get-ShopifyLivePushMarker { return 'SWB-LIVE-PUSH-AUTHORIZED' }
```

| function | absent |
|---|---|
| `Get-ShopifyLiveThemeId` | the **id half of rule 3 cannot fire**: `--allow-live` still blocks, and a push aimed at live *by id* passes. A real hole, so the session check reports it once per session rather than leaving it silent. |
| `Get-ShopifyLivePushMarker` | any marker **ending in** `LIVE-PUSH-AUTHORIZED` is accepted — which is what both existing consumers already write (`SWB-…`, `XOXO-…`). Setting it **narrows** to your spelling alone. |

The guard reads them on every command, so a change takes effect immediately; nothing needs restarting.

## Mentioning a rule is not performing it

This is the part that decides whether a guard survives contact with a repo, so it is worth reading before
changing the matching.

The first version of this guard, in the consumer that wrote it, matched the forbidden words **anywhere**
in the command string. On its first day it blocked, in order: the heredoc that wrote the rule into that
repo's `CLAUDE.md`, and the `perl` one-liner that later edited the same sentence. Neither would have
touched the store.

> A guard that makes its own rule impossible to write down is a guard somebody eventually switches off,
> which is worse than no guard.

So the matching asks **where** the words sit rather than whether they occur:

- **Heredoc bodies are stripped** — `cat > file <<EOF … EOF` writes data and the body never runs. *Unless*
  an interpreter is consuming it (`bash <<EOF`), in which case the body **is** a script.
- **Text tools are skipped** — a segment led by `grep`, `sed`, `perl`, `awk`, `cat`, `echo`, `git` and
  friends is handling the words, not obeying them. *Unless* the command pipes into an interpreter or uses
  `eval`/`xargs`: `echo "…" | bash` really does execute.
- **Everything else is matched per shell segment**, so a real command after a heredoc, after a semicolon,
  or inside a wrapper is still caught.

**Every one of those exemptions has a counter-case in the suite** (`scripts/tests/guard-live-theme.tests.ps1`
in the source repo, 51 asserts), because an exemption without one is a hole with a comment on it.

### The two limits, stated rather than hidden

- **A text tool asked to execute** — `perl -e` with a `system()` call, say — is exempted and is not
  caught. A deliberate trade: that vector needs somebody to go out of their way, while the false
  positives it would otherwise cause happen every time a repo documents its own safety rules.
- **The MCP vector is not covered.** This guard holds the CLI reached through the Bash and PowerShell
  tools. A publish issued through a Shopify MCP connector is a different path, held by that server's own
  permission prompt.
