## `fix/manuals-path-and-start-task` deployment

### What does the change on this branch deploy to main?

Two shipped files stop naming things that do not exist.

**`.claude/manuals/` is a path the system has never created.** `specialists-init` creates
`.claude/specialists/lenses/`; the manuals live in the plugin install and are read-only there. Tessa's agent
def named that directory **twice** — once in the `description:` every consumer's model reads at every turn,
once in the body that tells her what she owns — and she is precisely the specialist you reach for to sharpen
those documents, so her own instructions sent her to an empty directory. Both now name the two layers the
system actually has: the repo lenses under `.claude/specialists/lenses/`, and the portable manuals in the
repo that ships them. Her body gained the sentence that split implies — in a consuming repo the manuals
arrive read-only and the lens is where the work lands; in the source they are hers as well.

**`team-shopify`'s `start-task` was written against its home repo**, and all three of its assumptions
failed. Its only executing step ran `scripts/task/start-task.ps1` and called itself a thin wrapper over it,
while no file of that name exists anywhere in the marketplace. It hardcoded a ten-prefix taxonomy while the
seam that states a repo's own taxonomy sits at `scripts/lib/branch-info.ps1`. And it sent the reader to the
`.claude/manuals/` path above for the prefix list.

The page now says what is true: the executing half is **the repo's**, deliberately — creating a preview
theme means the Shopify CLI against one specific store, and which markets get a URL and what counts as a
safe target are facts about a store estate, not about the team. So the skill drives a repo-local script,
states plainly that it has nothing to run where the repo has none, and names the by-hand route instead of
improvising a command. The prefixes come from the repo — its `CLAUDE.md`, and the seam where the repo also
runs `workflow-davekjohn`, which is the hedge that matters: `branch-info.ps1` is scaffolded **only** when
that plugin is enabled, so a `team-shopify` consumer without it has no such file.

**What is deliberately not decided here.** The report offered three routes — ship the script, move the skill
to the workflow plugin, or drop it — and declined to pick, correctly, because the choice is the source's.
This takes none of them: it repairs the three verified defects and leaves the skill where its domain is.
Writing the missing script is a real piece of Shopify-CLI work and moving the skill is a structural call;
both stay open with better information than before.

**Score:** 3

#### What makes this change extra special

The Tessa half reaches **every** consumer, since every repo enables `team-alpha` — and it is the wrong kind
of wrong for a description to be: not a stale detail but an instruction, read every turn, pointing at a
directory the bootstrap has never created. A specialist following it literally has to re-derive the repo
layout before writing a line.

The `start-task` half is smaller in reach and sharper in kind: a shipped skill whose one executing step had
no executable anywhere in the marketplace. It is `disable-model-invocation: true`, so it only ever fires when
the owner types it — which is what kept this a papercut rather than an incident, and also means the failure
landed on him personally, at the moment he expected a shortcut to work.

**Score:** 3

### Pull Request

two shipped files stop naming a path and a script that do not exist
