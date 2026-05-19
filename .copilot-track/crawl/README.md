# Crawl Notes

Use this folder for crawl artifacts and iterative discovery prompts.

## Chain PRs

- Keep changes in small, reviewable PRs that build on each other.
- Link each follow-up PR to the previous one (for example: "Depends on #12345").
- Keep each PR scoped to one objective or evidence set.

## Evidence in PRs

- Include concrete evidence for claims: test output, logs, traces, or file references.
- Summarize what was validated, what was not, and known risks.
- Prefer reproducible command snippets so reviewers can verify quickly.

## Prompt Usage

- Put the exact prompt (or a stable summary) used for the crawl in the PR body.
- Note important prompt parameters: scope, exclusions, and acceptance criteria.
- Record iteration deltas so reviewers can understand why outcomes changed.
