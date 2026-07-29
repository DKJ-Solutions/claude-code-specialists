### Chris's body can serve as a main-thread system prompt · Feat · 2026-07-29

The blocker on [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) is removed. Chris's
portable body said he *"never executes anything himself — he writes no content, opens no PR, does not
merge"*. As a role inside a general-purpose loop that works; as **the main thread's own system prompt**
it is crippling, because the main thread would refuse to edit files. No configuration change could fix
that, which is why the issue sat blocked.

**The rule was reframed, not weakened: it now forbids unattributed work rather than typing.** Every
executing action still belongs to the specialist who owns it, is announced before it happens, and is
performed under that specialist's craft rules — by handing off to a subagent where subagents exist, and
otherwise by Chris doing that specialist's work *under their name*. What is forbidden is work with no
specialist behind it, work done by Chris's general judgment where a craft has rules, and a handover
claimed but not made. Read it as *"nothing happens anonymously"*.

Two things this surfaced. The old wording was **internally inconsistent** — ritual step 5 has always
read *"execute according to their trade rules"*, so the body both forbade and prescribed the same act.
And in a harness without subagents the old rule was already fiction: the work got done anyway, just
without the wording admitting it. The reframing describes what actually happens and keeps the property
that matters, which is attribution.

**The mechanism was verified from the docs rather than assumed**, and recorded in the
[family README](claude-code-plugins/claude-specialists/README.md#adoption-the-bootstrap-path): a plugin
root `settings.json` supports `agent` (and `subagentStatusLine`) and *"activates one of the plugin's
custom agents as the main thread, applying its system prompt, tool restrictions, and model"*. The
issue's compaction worry dissolves in this route: only **skill** descriptions are flagged as not
re-injected after `/compact`, and a main-thread agent's body *is* the system prompt, which travels with
every request anyway.

**The switch stays off, deliberately.** What happens when two enabled plugins both set `agent` is
documented nowhere — not on the plugins page, not in the reference — and that is a poor thing to
discover through your main thread. It would also change every consumer's main loop from a version bump
they did not read, and since Chris ships as a persona there is no agent-def to point at: creating one
means its `tools:` and `model` become the whole main thread's policy. Ready, not thrown; settling the
multi-plugin question needs an experiment, not another read.
