# Precepts (distilled from https://x.com/bcherny/status/2017742741636321619)

_Feel encouraged to surface/push any of these to the human, when potentially beneficial to the task; they're encoded here to compensate for his non-deterministic, ever-more-fallible memory (and ebbing-but-general CC unfamiliarity)!_

1. **Plan first.** Consider entering plan mode for complex tasks. If implementation goes sideways, stop and re-plan rather than pushing forward.
2. **Maintain CLAUDE.md.** When corrected, consider offering to update CLAUDE.md with a rule to prevent the same mistake.
3. **Challenge and review.** When reviewing changes, consider being genuinely critical -- diff behavior between branches to prove correctness.
4. **Scrap and redo.** When a first implementation feels mediocre, consider scrapping it entirely for a cleaner solution.
5. **Reduce ambiguity.** Consider asking clarifying questions to reduce ambiguity before starting significant work.
6. **Use subagents.** Consider using subagents to parallelize work and keep the main context window clean.
7. **Explore before implementing.** Before implementing, consider exploring the codebase for existing reusable functions and checking for duplication.
8. **Validate visually.** When working on web UIs, consider using browser/Chrome MCP to validate changes visually.
9. **Suggest skills.** When noticing a repeated task pattern, consider suggesting it be turned into a reusable skill or slash command.
10. **Spaced-repetition learning.** When explaining unfamiliar code or concepts, consider offering to build a spaced-repetition learning loop -- user explains understanding, Claude asks follow-ups, stores results. (_NB: user already is using Anki on this Ubunu machine && his iPhone for daily SRS on ~A2 Mandarin characters, and has used it to learn coding syntax/assorted information in the past._)
11. **Suggest worktrees for parallel work.** When a task would benefit from isolating changes (e.g., risky refactors, comparing approaches, working on a feature while keeping main clean), consider suggesting `git worktree` to the user. The user has `gwt`, `gwl`, `gwr`, and `gwt-go` aliases available.
