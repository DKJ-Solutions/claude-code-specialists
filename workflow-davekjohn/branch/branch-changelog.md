## `fix/client-store-data-out-of-the-plugin` changelog

### Branch title

a customer store name and its live theme id leave the shipped agent defs

### Branch ID

20260814-204041

### Branch type

fix

### What does the change on this branch bring to main?

The first half of item **C4** of inbound
[#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669), and Dave's decision on it
(August 14, 2026). Two shipped `team-shopify` agent defs named a real customer's store and its live
theme id — `Shopmonkey MAIN`, `170064871700` — in a repo that is deliberately **public**. Not a
credential: a theme id opens nothing. But it is an identifiable customer, and this repo's own
constitution says nothing confidential belongs here.

**The scope was measured rather than taken from the report, and it was larger.** #669 named the store and
the id. The same pass found two more identifiable brands one item below them, in the ownership rule that
tells the specialist which theme files may be deleted: an external party's theme family and a branded
template family. The manuals and the skills were already clean — only the two agent defs carried any of
it, which is why this is five lines and not a sweep.

**Placeholders would have made the instruction worse, so the rule was rewritten instead.** `<live theme
id>` in a pre-push checklist is a form to fill in, and the ownership item is not even a value — it is a
*fact about a specific tree* ("this prefix is theirs, that one only looks like it is"). Both now state
the rule and point at the repo lens for the specifics, which is the split this system already runs on:
portable craft in the plugin, repo-specific facts in the consumer's lens. The ownership item also gained
the sentence its concrete examples were carrying implicitly — **do not read a prefix as ownership in
either direction** — because that was the actual lesson behind naming those two families, and it survives
the removal of both.

**A gate was measured and declined.** The obvious rule is "no bare 10+ digit number in shipped plugin
content". Run over the tree it is born with **one** finding, and that one is **false**: a GitHub comment
id inside an `anthropics/claude-code#76759` URL. Narrowing it to numbers outside URLs leaves **zero**
subjects after this change — a check with nothing to guard, which this repo has already decided is not
worth building (the title-names-its-own-path rule, declined at four subjects). Store and brand names are
unbounded and cannot be matched at all. Recorded so the next reader does not re-derive it.

**One consequence, stated because it is real and not because anyone has to act here:** a consumer whose
lens does not name their live theme now gets a specialist that says so instead of quoting an id that was
never theirs. That is the correct failure — the old text was concretely wrong for every consumer except
one.

### Significance

#### Tier 0

Nothing changes on this machine: neither of these two specialists has a lens or any work in this repo.
What it settles is the measurement behind the declined gate, which is otherwise re-derived the next time
someone spots a long number in shipped content.

**Score:** 2

#### Tier 2

A public plugin stops carrying one customer's store name, live theme id and two more brand names to every
consumer who installs `team-shopify` — including the ones who have no relationship with that customer and
for whom the id was simply wrong. The instruction is not weakened: both items now state the rule and name
the lens, and the ownership item gained the principle its examples were only implying.

**Score:** 4

### Pull Request

