### a reported finding's reason is verified before it is repaired · Docs · 2026-08-02

The working rule that round v13 produced, recorded rather than left in a closing message. A report
carries two things — *what* went wrong and *why* — and the second is an inference by someone
measuring from the outside. The rule is to check the code, doc or output that would have to be true
for that explanation to hold, before writing the repair.

The measured instance is inbound
[#388](https://github.com/DaveKJohn/davekjohns-workshop/issues/388). It reported that the teardown
does not count a fixture's `README.md` *"even as prose"*, and proposed deleting the sentence that
promised the count. The symptom was real: nothing about that file shows up in the output. The reason
was not. `teardown.ps1`'s prose pass scans the **root markdown** — every `*.md` at the repo root,
excluding only `CLAUDE.md` and `CHANGELOG.md` — so the file is squarely in it. It scores **0**
because the fixture README deliberately names no specialist, and the note prints only above zero. The
sentence was not untrue; it was unfindable.

Had the proposal been built as written, the change would have deleted a correct sentence, left the
next measurer with exactly the same confusion minus its explanation, and carried an issue number
vouching for it. That is what makes this worse than the untouched defect: **a wrong repair is a
defect with a citation.** The repair that did ship explains where to look instead
(`DaveKJohn/specialists-adoptietest#2`).

It sits under *General working practices* rather than in a specialist's manual, because it belongs to
whoever is holding the report — which over one evening was the systems administrator, the technical
writer and the test engineer in turn — and because that section loads unconditionally. Nobody has to
go looking for it, which is the property this lesson needs: it applies at the moment you are most
convinced you already know what to build.
