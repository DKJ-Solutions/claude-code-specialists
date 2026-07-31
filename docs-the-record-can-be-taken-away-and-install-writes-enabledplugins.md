### a record can be taken away, and the install writes enabledPlugins · Docs · 2026-07-31

Inbound [#301](https://github.com/DaveKJohn/davekjohns-workshop/issues/301),
[#303](https://github.com/DaveKJohn/davekjohns-workshop/issues/303) and
[#305](https://github.com/DaveKJohn/davekjohns-workshop/issues/305), from `DaveKJohn/life-hub`'s
adoption round **v7** against `v3.0.6`. Three claims in the adoption docs corrected to what was
measured; the code half of the same round is
[#307](https://github.com/DaveKJohn/davekjohns-workshop/pull/307).

## #301 — a project-scoped record can be taken away, not merely moved

#296 established that a project-scoped install record **moves** without being asked. v7 established
something worse and **reproduced it twice**: a *session start* in an unrelated directory rewrites
`installed_plugins.json` by **adopting an existing record**, leaving the repo it belonged to with no
install at all. Once the victim was a real consumer; once it was **this repo**, which lost its project
install to a scratch folder.

`installedAt` is what makes it adoption rather than creation — the CLI sets that to *now* on a real
install, so a record carrying an older repo's stamp did not come into being where it ended up.

Both `specialists-init/SKILL.md` and the `QUICKSTART` said only that a record *"can move without you
asking"* and called the consequence *"small but real"*. The measured consequence is not small: the
record **disappears**, and then there is no version to read — only silence. Both now say so, with the
reproduction table, and both name why this is the expensive half: **no command was run, no file in the
repo changed, `git status` is clean**, and a session that loads no plugin has no hooks to complain
because the hooks are *in* the plugin. It looks exactly like a session where everything is fine.

**A measurement already in the docs is now diagnosed rather than merely observed.** The July 30 note
about `davekjohns-workshop` — *"that repo has `enabledPlugins` set and no install record of its own (the
only `projectPath` pointed at a different repo)"* — is this exact mechanism, recorded a day before it was
reproduced and left with its cause unstated. It now points at the cause, because the two readings call
for different actions: the record had **moved**, not never existed.

**And #301's third proposal is answered in code, not in prose.** "Verify once at adoption" is not enough
if something outside the repo can take the record away, so the `projectPath` query is now what the checks
do themselves — that is #307, and both docs point at it rather than only asking the reader to remember.

What is **not** claimed, kept explicit: the trigger. Two attempts with a barer setup produced no adoption
at all, and which factor of the firing recipe carries the weight is unknown, as is how a victim record is
chosen. This is CLI behaviour; the reproduction stands on its own for anyone reporting it upstream.

## #303 — "the content stays equivalent" is false when the key is absent

`QUICKSTART.md` said of the rewrite `claude plugin install … --scope project` performs: *"The content
stays equivalent; only the formatting moves"* — under a paragraph that calls a diff here **expected
rather than suspect**, so a reader waves it through.

That holds only when `enabledPlugins` is already there. When it is **not**, the install **adds the key,
with `true` per plugin** — switching the plugins **on** in a tracked governance file. That is not
formatting. Measured in `life-hub`, which is deliberately plugin-clean between rounds, so the key was
nowhere; and the reason #295's fixture could not see it is that the fixture already contained the key.
The control case is in the same round: in `davekjohns-workshop`, where the key was set, the identical
command left `settings.json` **byte-identical**.

The paragraph now splits the two cases explicitly, notes that the absent-key case is exactly what a
**repair install** does — the prescribed move after a record goes missing, which is #301's story — and
adds the fifth effect the four-effect list was missing: the CLI writes **LF into a CRLF file**, a second
and lasting source of diff on a Windows repo. It closes on the distinction that matters in review: a
formatting diff here is expected; an added `enabledPlugins` block is the one change you would want to
see.

## #305 — the fourth counting of the seam migration

PR #300 put the seam migration on **five steps (0–4)** in three places and missed a fourth:
`specialists-teardown/SKILL.md` said *"a seam migration … is two steps, in this order"*. Defensible as a
different unit — it is about ordering two acts *within* step 0 — but it was the fourth count of the same
procedure, on the page that explains step 0's danger most fully, and it linked to none of the others. It
now names its unit explicitly and points at the numbered list, the same way the QUICKSTART does for its
*three steps*.

**The methodical half is the more useful half, and it is recorded in the family README** next to the
existing counting-convention note. The sweep that aligned the other three entries was shaped
`(one|two|…|seven) (acts?|steps?)`, and that regex **misses markdown emphasis**: against
`specialists-init/SKILL.md` it found nothing, because the text reads `**five** steps` — the asterisks
sit between the two words. Two lessons for any future count-lint: **a sweep that returns few hits is not
evidence of few instances**, and **a file the same PR touched is not automatically covered by that PR's
verification** (this fourth site sits in a file #300 did edit).

## Verified

- The emphasis-tolerant sweep re-run across the whole family: the three seam-migration counts agree on
  five steps (0–4), the teardown's two acts are now explicitly scoped inside step 0, and there is **no
  fifth uncounted instance**.
- Lint gate `0 error(s)` (link scan included — the new cross-reference to
  `README.md#the-seam-specified` resolves), all 18 suites green.
