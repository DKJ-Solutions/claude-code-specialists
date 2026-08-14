## `fix/shared-sentinel-points-nowhere` changelog

### Branch title

the shared-block sentinel stops telling a consumer to edit a file they do not have

### Branch ID

20260814-200205

### Branch type

fix

### What does the change on this branch bring to main?

Item **C2** of inbound [#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669). Every
shared block in every agent def and persona opened with
`<!-- BEGIN shared:<name> -- GENERATED, edit agent-shared/<name>.md -->`. That path resolves in this
repo and nowhere else: `plugins/agent-shared/` sits **outside every plugin root**, so it does not
travel in the package.

**The report called it a dead pointer; measured on pickup it is worse than dead.** Three lines below it,
in the same agent def, the `inbound-behaviour` block says *"You do not modify the shared core locally"*
and names the issue route. The sentinel instructed a consumer to do exactly what the paragraph it
introduces forbids — so it did not merely fail to help, it contradicted the rule it was announcing.

**Both remedies #669 proposed were weighed and declined, and the third one is smaller than either.**
*Shipping `agent-shared/` in the package* hands a consumer a file they may open but which is not the
source — the confusion the inbound route exists to remove. *Repointing it at
`DaveKJohn/claude-code-specialists`* would add **178** references to a personal repo, straight against
**C4 of the same report**. And for the only reader who can act on it — a maintainer here — the pointer
is redundant: `shared:<name>` maps to `agent-shared/<name>.md` by construction, which is what
`Get-SharedBlockText` does. So it is **removed rather than repointed**, and that is the cheaper
direction too: measured, those 178 lines go from **17,332 to 13,027 bytes**.

**The mechanism is the half that stops it coming back.** `Expand-AgentDefShared` used to replace the
content between the sentinels and copy the BEGIN line through unchanged — `$out.Add($lines[$i])`, with
the comment `# BEGIN sentinel unchanged`. That is why the wording sat hand-maintained in 178 places with
nothing holding it. It is now built by `Format-SharedBeginSentinel`, and because the builder *and* lint
check 7 both compare the whole file against that function's output, a reworded sentinel is rebuilt by the
one and reported by the other. **No new check, no exemption list** — the gate this repo already had now
reaches a line it was walking past.

The indent is carried through rather than normalized away. Nothing in this tree is indented today; a
shared block nested in a list would be, and silently unindenting it would change markdown around content
the expander is not allowed to touch. Asserted, so the guard is not an intention.

**The retired wording is still recognised** in the only place that matters — the expander rewrites it
rather than reporting it — which is what lets every branch in flight, here and at every consumer, rebuild
instead of failing. The one place it survives verbatim is `releases/development/1.x/1.15.0.md`: a
published record, and this repo does not rewrite those.

### Significance

#### Tier 0

The wording of a line that appears 178 times stops being hand-maintained, and the existing gate starts
holding it. A maintainer meets this the moment they add a block; before this, rewording the sentinel was
a 178-file edit that nothing would have caught if it were done in 177.

**Score:** 3

#### Tier 2

Every consumer of every team plugin currently reads, in every specialist they invoke, an instruction to
edit a file they do not have — one that contradicts the inbound rule printed directly beneath it. That
goes away without them doing anything, and their agent defs get ~4.3 KB shorter. They receive it through
a plugin update rather than by choosing to; nothing they wrote changes.

**Score:** 3

### Pull Request

