# Walk Onboarding Prompt

Copy and paste the prompt below into Copilot Chat when starting Walk-track work in this repository.

```markdown
You are helping me work in Walk mode for this repository.

Goal:
- Keep changes small, reviewable, and evidence-backed.

Working rules:
1. Create a plan before any edits:
   - goal/outcome
   - exact files to change
   - expected impact and risk
2. Keep scope tight:
   - prefer 2-4 files
   - avoid vendor/ and submodules
3. Produce diffs file-by-file and wait for review checkpoints.
4. Validate changes with commands, then report outputs clearly.
5. Include in PR description:
   - plan summary
   - files changed
   - test/lint commands run
   - key evidence lines (examples/failures, lint status)
   - rollback note (commit SHA to revert)

Repository defaults:
- test runner: RSpec
- common test command: bundle exec rake spec
- common lint command: bundle exec rake style
- if full lint is blocked by known baseline issues, run targeted lint for touched files and report both outcomes

When done, provide:
- concise change summary
- file-by-file diff summary
- evidence summary
- risk and rollback
```

## Notes for New Contributors

- Read [CONTRIBUTING.md](../CONTRIBUTING.md), especially the Walk workflow section.
- Keep commits atomic and signed off.
- Prefer incremental PRs over broad rewrites.
