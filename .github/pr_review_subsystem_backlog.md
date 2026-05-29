# PR Review Subsystem Improvement Backlog

Scope: GitHub PR review and CI guardrails in `.github`.

## Prioritized Backlog

| ID | Priority | Title | Good First Task | Suggested Owner |
| --- | --- | --- | --- | --- |
| BR-01 | P1 | Add automated PR template completeness check | Yes | Agent |
| BR-02 | P1 | Replace floating action refs with pinned releases | Yes | Agent |
| BR-03 | P2 | Expand PR label coverage for workflow/test changes | Yes | Team |
| BR-04 | P2 | Add explicit required-check documentation for reviewers | Yes | Team |
| BR-05 | P3 | Add comment-resolution reminder to PR workflow docs | Yes | Agent |

---

## BR-01: Add automated PR template completeness check

Paths:
- [.github/pull_request_template.md](.github/pull_request_template.md)
- [.github/workflows/lint.yml](.github/workflows/lint.yml)
- [.github/workflows/allchecks.yml](.github/workflows/allchecks.yml)

Problem:
PR body quality still depends on manual discipline. The template exists, but there is no automated check that required sections are present in PR descriptions.

Acceptance criteria:
- A workflow job runs on pull requests and validates required headings are present in PR body text.
- Validation checks these sections: Review Focus, Verification Steps, AI Review or Simulated Reviewer Checklist, Findings And Responses, Human Feedback Resolution.
- Missing sections fail CI with a clear, actionable error.
- Workflow does not run for non-PR events.
- A passing and failing case are documented in job output examples.

Delegation notes:
- Good first task because changes are isolated to workflow YAML and shell checks.

### Simulated patch plan for delegation (Agent)

Goal:
Add a lightweight CI guard that verifies required PR review sections.

Patch steps:
1. Create [.github/workflows/pr-body-review-check.yml](.github/workflows/pr-body-review-check.yml) with `pull_request` trigger and least-privilege permissions.
2. Add one job that reads `${{ github.event.pull_request.body }}` and validates required headings using `grep -q` checks.
3. Emit grouped logs explaining exactly which section is missing.
4. Ensure the job exits non-zero on failures.
5. Update [.github/workflows/allchecks.yml](.github/workflows/allchecks.yml) exclusions only if needed (no broad bypasses).

Execution split:
- Agent Task A: add workflow file.
- Agent Task B: add robust shell validation logic.
- Human Review Task: verify error messages are understandable for contributors.

Definition of done:
- Workflow appears in PR checks and fails when required sections are removed.

---

## BR-02: Replace floating action refs with pinned releases

Paths:
- [.github/workflows/dco.yml](.github/workflows/dco.yml)
- [.github/workflows/lint.yml](.github/workflows/lint.yml)

Problem:
Some workflow actions use floating refs such as `@master`, which reduces supply-chain stability and reproducibility.

Acceptance criteria:
- All `uses:` entries in targeted files are pinned to stable release tags or commit SHAs.
- No `@master` remains in the targeted workflow files.
- CI still passes for modified workflows.
- Changes are limited to action version references and comments.

Delegation notes:
- Good first task because it is small, mechanical, and easy to review.

---

## BR-03: Expand PR label coverage for workflow and test changes

Paths:
- [.github/labeler.yml](.github/labeler.yml)
- [.github/workflows/labeler.yml](.github/workflows/labeler.yml)

Problem:
Current labels are limited and may not classify common maintenance changes (workflow-only, test-only, docs-only) consistently.

Acceptance criteria:
- Add labels for workflow-only and test-only updates with clear glob patterns.
- Existing label behavior for documentation remains unchanged.
- Labeler workflow applies labels correctly on `pull_request_target` to main.
- Pattern examples are added in comments for maintainability.

Delegation notes:
- Good first task for team member learning repository path conventions.

---

## BR-04: Add explicit required-check documentation for reviewers

Paths:
- [.github/workflows/allchecks.yml](.github/workflows/allchecks.yml)
- [.github/pull_request_template.md](.github/pull_request_template.md)

Problem:
Reviewers lack a single source of truth in PR context for which CI checks are expected and how to interpret temporary exclusions.

Acceptance criteria:
- Add a short section to PR template describing required CI checks and where to find status.
- Document temporary exclusion rationale in human-readable text with expiry expectation.
- Keep content concise and non-duplicative.
- No change to workflow execution logic.

Delegation notes:
- Good first documentation task with direct reviewer impact.

---

## BR-05: Add comment-resolution reminder to PR workflow docs

Paths:
- [.github/pull_request_template.md](.github/pull_request_template.md)
- [.github/copilot-instructions.md](.github/copilot-instructions.md)

Problem:
Comment resolution can be inconsistently tracked, especially when AI and human findings overlap.

Acceptance criteria:
- Add explicit reminder to update Findings And Responses table for each addressed comment.
- Add one line instructing authors to include comment links for resolved threads.
- Keep wording aligned with existing AI compliance language.
- Preserve existing template structure.

Delegation notes:
- Good first task because it is focused wording-only change with low risk.

---

## Prioritization rationale

- P1 items directly improve review quality gates and workflow safety.
- P2 items improve triage speed and reviewer clarity.
- P3 item improves consistency and auditability with minimal risk.
