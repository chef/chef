# Pull Request Size Labeling and Approval Requirements

This repository automatically labels pull requests based on their size and enforces additional approval requirements for extra-large PRs.

## PR Size Labels

PRs are automatically labeled based on the number of lines changed:

- **size/XS** - Extra Small: ≤ 10 lines changed
- **size/S** - Small: ≤ 30 lines changed
- **size/M** - Medium: ≤ 100 lines changed
- **size/L** - Large: ≤ 500 lines changed
- **size/XL** - Extra Large: > 500 lines changed

## Approval Requirements

### Standard PRs (XS, S, M, L)

- Follow the standard approval process as defined in CODEOWNERS
- No additional approval requirements

### Extra Large PRs (XL)

- **Require 2 approvals** from code owners before merging
- A status check "PR Gate Check" will block merging until sufficient approvals are received
- PRs will be automatically commented with a reminder about the additional approval requirement

## Best Practices

- **Consider breaking up XL PRs** into smaller, more focused changes when possible
- Smaller PRs are easier to review, test, and debug
- Use feature branches and incremental commits to keep PRs manageable

## Workflows

The following GitHub Actions workflows implement this system:

1. **PR Size Labeler** (`pr-size-labeler.yml`) - Automatically applies size labels
2. **PR Gate Check** (`pr-gate-check.yml`) - Enforces approval requirements and creates status checks

## Overrides

Repository administrators can override the approval requirements by:

1. Manually adding the `override-xl-requirements` label to bypass additional approvals
2. Using admin privileges to merge despite status check failures (not recommended)
