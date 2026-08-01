### The settings claim is narrowed, and six papercuts from a full walk · Docs · 2026-08-01

The last content group of test round v10 (#340): the `settings.json` claim (#336) and the six small
inaccuracies #337 deliberately bundled. Individually trivial; together they are what a first reader
accumulates as *"the documentation is approximately right"*.

**#336 — a claim the page backed with a hash comparison, and a consumer will trust it because of that.**
The QUICKSTART said that with `enabledPlugins` already present the install leaves `settings.json`
**byte-identical**, and that *"the install writes only when there is something to write"* — verified by
SHA256 in `davekjohns-workshop`. On a fresh Windows profile, key present, written in exactly the prescribed
order, the install **rewrote the file anyway**: `enabledPlugins` moved in front of `extraKnownMarketplaces`
and the nested `source` object was expanded onto separate lines. The likeliest reading is that the workshop's
own file already matched the serialiser's layout, which makes the old claim true of *that file* rather than of
"key already present" as a category.

The half that holds is kept and the half that does not is dropped: content stays **equivalent** (nothing is
switched on that was not on before), but **expect a formatting diff even when the key is there**. Getting a
prediction about a tracked governance file wrong in the reassuring direction is the expensive way round — the
reader is told to expect nothing and gets a diff. The entry also carries v10's own caveat: no hash pair was
captured at the moment of the install, so this is a description of what changed rather than a before/after
hash.

**#337, six of them, each verified here rather than taken from the report:**

1. **"the two `@`-imports in `CLAUDE.md`" — there is one.** The teardown's frontmatter and its body both said
   two: a description left behind on the pre-seam layout, where both did sit there. Since the seam,
   `CLAUDE.md` keeps exactly one import and the other two live inside `SPECIALISTS.md`, which the teardown
   removes whole. It set a false expectation for the very step the `[create]` → `[remove]` table rests on.
2. **The bootstrap writes LF-only files with no trailing newline, on Windows, and no document said so.** The
   QUICKSTART already devotes a paragraph to exactly this class — for `claude plugin install`. Now stated for
   the bootstrap's own output too, including why the missing final newline matters: it turns any later
   hand-edit of `CLAUDE.md` into a two-line diff.
3. **Step 2 gave no counts to check against.** The figures print in the skill's own `SKILL.md`, which a reader
   sees *after* invoking it. This page is meticulous about counting everywhere else — *"the count is part of
   the check, not a detail"*, two steps up — and this was the one step where the script prints numbers with
   nothing to compare them to. The closing line and the arithmetic are now in the QUICKSTART, **counted
   against the payload rather than copied from the report**: 4 personas + 15 agents = 19 lens files, plus 2
   script scaffolds and 1 import.
4. **Two inaccuracies in the bootstrap's own output.** *"scaffold created with orchestrator imports"* was
   plural while it places one — and the script's own next-step 1b already got it right, so two of its lines
   disagreed. Fixed in both places (`[create]` and `[add]`). The second was the `settings.suggested.jsonc`
   warning: *"gitignored in many repos, so git will not remind you"* — conditional, with no way for the
   reader to tell which side they are on, and for a fresh consumer (this script's own audience) "no
   `.gitignore` yet" is the likely case. The v10 repo had none, so the file *did* show up in `git status` and
   the warning was simply wrong there. **The script now asks git instead of hedging** (`git check-ignore`) and
   says which side this repo is on; if git is absent or errors it falls back to the honest conditional rather
   than claiming either way.
5. **The uninstall leaves an undocumented `.orphaned_at`.** Named now, in the section that otherwise predicts
   its own side effects carefully — which is exactly why the one it missed reads as an omission rather than a
   detail.
6. **A plugin-pointing `permissions` entry survives a full teardown.** Not something this family writes, but
   `settings.suggested.jsonc` is a plausible route, and an allow-rule pointing into a directory you are about
   to delete is the kind of leftover a teardown exists to spare you. Step 3 now names it alongside the two
   keys it already listed.

**The lint gate had an opinion on #337.3's neighbour, and it was right.** Check 12 rejected the first version
of the `installPath` snippet added for #330 in the previous PR; the same gate passed everything here, over
four printed record queries. Nothing in this branch needed a gate exception.

Lint green, all suites green (307 + 104 asserts unchanged — no test asserted the old output strings, which is
its own small finding: the bootstrap's report text is not pinned anywhere).

Plugins: specialists
