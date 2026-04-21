# Workflow Branch Restriction Script

## Overview

This script ensures all GitHub workflows using `pull_request_target` have branch restrictions to `main`. This is a security best practice to prevent workflows from being triggered by pull requests from unauthorized branches.

## Usage

### Dry Run (Preview Changes)

```bash
ruby scripts/fix_workflow_branch_restrictions.rb --dry-run
```

This will scan all workflow files and show which ones would be modified without making any changes.

### Apply Changes

```bash
ruby scripts/fix_workflow_branch_restrictions.rb
```

This will scan all workflow files and apply the necessary branch restrictions.

### Help

```bash
ruby scripts/fix_workflow_branch_restrictions.rb --help
```

## What It Does

The script:

1. Scans all YAML files in `.github/workflows/`
2. Identifies workflows using `pull_request_target` triggers
3. Checks if they have `branches: [main]` restriction
4. Adds the restriction if missing

## Example Changes

### Before
```yaml
on:
  pull_request_target:
  push:
    branches:
      - main
```

### After
```yaml
on:
  pull_request_target:
    branches:
      - main
  push:
    branches:
      - main
```

## Supported Formats

The script handles various YAML formats:

- **Block format**: `pull_request_target:`
- **Inline format**: `on: pull_request_target`
- **Array format**: `on: ['pull_request_target']`
- **Quoted key format**: `"on":`

## Security Rationale

Adding branch restrictions to `pull_request_target` workflows is important because:

1. **Prevents Unauthorized Execution**: Only PRs targeting `main` will trigger the workflow
2. **Reduces Attack Surface**: Limits potential for malicious workflow modifications
3. **Controls Resource Usage**: Prevents unwanted workflow runs from arbitrary branches

## Output

The script provides clear feedback:

- ✅ Files that were fixed
- ✓ Files that already had correct configuration
- ℹ️ Files without `pull_request_target` (skipped)
- ⚠️ Files that need manual attention

## Testing

After running the script, verify changes with:

```bash
git diff .github/workflows/
```

Then test workflows by creating a test PR to ensure they trigger correctly.
