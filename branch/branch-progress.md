## `docs/the-reason-goes-above-the-score` progress

### Steps

- [x] Read what the scaffold writes today, rather than trusting #596's description of 4.2.0
- [x] The tier guidance says the reason goes ABOVE the score and that text below it is discarded
- [x] `new-branch`'s scaffold-time printout says the same, for an author who opens no template
- [x] Regenerate `branch/templates/` from the wording; mirror both scripts into the plugin
- [x] A behavioural assert on the PRINTOUT, not on the script's source text
- [x] Lint + full suites green
- [~] The extra blank line above `**Score:**` -- NOT built: it reverses a recorded decision
      (entry-scaffold-lib.ps1, "Not two blanks ... reads as something was deleted here"),
      and reversing that is Dave's call, not mine. Reported at close-out with two alternatives.

### Where I left off

Done, and one thing left open on purpose. The whitespace half of #596's suggestion turned out to collide
with a decision already recorded in the code, so this branch delivers the GOAL (say it before the author
writes) through the two guidance surfaces instead. The two shapes that would make the mistake structurally
impossible -- inverting the section to score-then-reason, or labelling the reason -- both change the entry
format that folds into `CHANGELOG.md` and travels to consumers, so neither was built without Dave's word.
