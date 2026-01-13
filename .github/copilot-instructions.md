# GitHub Copilot Instructions for Chef Infra Repository

## Repository Overview

Chef Infra is a configuration management tool designed to bring automation to your entire infrastructure. This repository contains the core Chef Infra Client and related utilities.

## Repository Structure

The Chef repository follows a modular structure with the following key components:

```
chef/
├── .github/                    # GitHub workflows, templates, and configurations
├── chef-bin/                   # Chef binary executables and CLI tools
├── chef-config/                # Configuration management for Chef
├── chef-utils/                 # Utility functions and helpers
├── distro/                     # Distribution-specific templates and files
├── docs/                       # Documentation and development guides
├── ext/                        # External extensions (e.g., win32-eventlog)
├── habitat/                    # Habitat packaging configuration
├── kitchen-tests/              # Test Kitchen integration tests
├── knife/                      # Knife CLI tool for Chef management
├── lib/                        # Main Chef library code
│   ├── chef.rb                 # Main entry point
│   └── chef/                   # Core Chef modules and classes
├── omnibus/                    # Omnibus packaging for distribution
├── spec/                       # Test specifications
│   ├── unit/                   # Unit tests
│   ├── functional/             # Functional tests
│   ├── integration/            # Integration tests
│   └── support/                # Test support files
├── tasks/                      # Rake tasks for development
└── vendor/                     # Vendored dependencies
```

### Key Files

- `chef.gemspec` - Main gem specification
- `Rakefile` - Build and test tasks
- `Gemfile` - Ruby dependencies
- `CONTRIBUTING.md` - Contribution guidelines
- `spec/spec_helper.rb` - Test configuration

## Workflow for Task Implementation

When implementing tasks in this repository, follow this comprehensive workflow:

### 1. Task Analysis and Planning

- **Jira Integration**: When a Jira ID is provided, use the atlassian-mcp-server to fetch issue details
- **Story Understanding**: Read and analyze the Jira story thoroughly to understand requirements
- **Task Breakdown**: Break down complex tasks into smaller, manageable components
- **Impact Assessment**: Evaluate which files and modules will be affected

### 2. Pre-Implementation Steps

- Analyze the existing codebase structure
- Identify the appropriate modules/files to modify
- Review related existing tests
- Check for any dependencies or prerequisites

### 3. Implementation Phase

- Follow Ruby best practices and Chef coding conventions
- Ensure backward compatibility when possible
- Implement changes incrementally
- Write clean, well-documented code
- Follow the existing code style and patterns

### 4. Testing Requirements

- **Unit Tests**: Create comprehensive unit tests for all new functionality
- **Coverage Target**: Maintain test coverage > 80% for the repository
- **Test Types**: Include unit, functional, and integration tests as appropriate
- **Test Location**: Place tests in appropriate `spec/` subdirectories
- **Test Framework**: Use RSpec for testing

### 5. Validation and Quality Assurance

- Run all existing tests to ensure no regressions
- Verify code quality and adherence to Ruby standards
- Check for any security implications
- Validate functionality across different environments

### 6. Documentation

- Update relevant documentation
- Add inline code comments where necessary
- Update CHANGELOG.md if applicable
- Ensure README updates if public API changes

### 7. Pull Request Creation

When prompted to create a PR:

- Use GitHub CLI (`gh`) to create a branch named after the Jira ID
- Push changes to the new branch
- Create a PR with:
  - **Title**: Clear, descriptive title referencing the Jira ID
  - **Description**: HTML-formatted summary of changes made
- All operations should be performed on the local repository

## MCP Server Integration

### Atlassian MCP Server Usage

When working with Jira integration:

- Use the `atlassian-mcp-server` MCP server for all Jira operations
- Fetch issue details using the provided Jira ID
- Parse and understand the story requirements
- Reference the Jira ID in commits and PR descriptions

## GitHub CLI Authentication and Branch Management

### Authentication Setup

- GitHub CLI authentication should be configured separately
- Do not reference `~/.profile` for login procedures
- Ensure `gh auth status` shows authenticated state before proceeding

### Branch and PR Management

```bash
# Create and switch to new branch (using Jira ID as branch name)
gh repo view --json defaultBranch | jq -r '.defaultBranch' # Check default branch
git checkout -b JIRA-123 # Replace with actual Jira ID

# Push changes and create PR
git push origin JIRA-123
gh pr create --title "JIRA-123: Brief description" \
  --body "<h2>Summary</h2><p>Description of changes</p>"
```

## Testing Guidelines

### Test Coverage Requirements

- Maintain overall repository test coverage > 80%
- Write tests for all new functionality
- Update existing tests when modifying behavior
- Include edge cases and error conditions

### Test Execution

```bash
# Run all tests
rake spec

# Run specific test categories
rake spec:unit
rake spec:functional
rake spec:integration

# Check test coverage
rake coverage
```

### Test Organization

- **Unit Tests**: `spec/unit/` - Test individual classes and methods
- **Functional Tests**: `spec/functional/` - Test component interactions
- **Integration Tests**: `spec/integration/` - Test full system behavior
- **Support Files**: `spec/support/` - Shared test utilities

## File Modification Guidelines

### Prohibited Modifications

- Do not modify `.git/` directory contents
- Avoid changing core configuration files without explicit requirements
- Do not alter existing gem specifications without careful consideration
- Preserve existing license headers and copyright notices

### Safe Modification Areas

- `lib/chef/` - Core Chef functionality
- `spec/` - Test files
- Documentation files
- Configuration templates in `distro/templates/`

## Prompt-Based Workflow

### Step-by-Step Execution

After each major step in the workflow:

1. **Provide Summary**: Give a clear summary of what was accomplished
2. **Next Step Preview**: Explain what the next step will involve
3. **Remaining Steps**: List what steps are still pending
4. **Continuation Prompt**: Ask "Would you like to continue with the next step?"

### Example Progress Communication

```
✅ Step 1 Complete: Analyzed Jira story JIRA-123 and identified requirements
📋 Next Step: Implement the new Chef resource in lib/chef/resource/
🔄 Remaining Steps: Write unit tests, run test suite, create PR
❓ Would you like to continue with the implementation step?
```

## Code Quality Standards

### Ruby Standards

- Follow Ruby community style guidelines
- Use meaningful variable and method names
- Implement proper error handling
- Include appropriate logging where necessary

### Chef-Specific Standards

- Follow Chef resource and provider patterns
- Use Chef's logging mechanisms
- Implement proper Chef exceptions
- Follow Chef naming conventions

### Security Considerations

- Validate all user inputs
- Use secure coding practices
- Avoid hardcoded credentials or sensitive data
- Follow principle of least privilege

## Development Environment

### Prerequisites

- Ruby (version specified in `.ruby-version` or `Gemfile`)
- Bundler for dependency management
- Git for version control
- GitHub CLI for PR management

### Setup Commands

```bash
# Install dependencies
bundle install

# Setup development environment
rake pre_install:all

# Verify setup
rake spec
```

## Integration Points

### External Tools

- **Buildkite**: Continuous integration and testing
- **RuboCop**: Code style and quality checking
- **Test Kitchen**: Infrastructure testing
- **Omnibus**: Package building

### Related Repositories

- `chef-utils`: Utility functions
- `chef-config`: Configuration management
- `knife`: CLI tool
- `chef-bin`: Binary executables

## Emergency Procedures

### Rollback Strategy

- Keep commits atomic and focused
- Use feature branches for all changes
- Test thoroughly before merging
- Have a clear rollback plan for each change

### Issue Escalation

- Check existing GitHub issues for similar problems
- Review recent changes and their impact
- Consult CONTRIBUTING.md for guidance
- Engage with the Chef community if needed

## AI-Assisted Development & Compliance

- ✅ Create PR with `ai-assisted` label (if label doesn't exist, create it with description "Work completed with AI assistance following Progress AI policies" and color "9A4DFF")
- ✅ Include "This work was completed with AI assistance following Progress AI policies" in PR description

### Jira Ticket Updates (MANDATORY)

- ✅ **IMMEDIATELY after PR creation**: Update Jira ticket custom field `customfield_11170` ("Does this Work Include AI Assisted Code?") to "Yes"
- ✅ Use atlassian-mcp tools to update the Jira field programmatically
- ✅ **CRITICAL**: Use correct field format: `{"customfield_11170": {"value": "Yes"}}`
- ✅ Verify the field update was successful

### Documentation Requirements

- ✅ Reference AI assistance in commit messages where appropriate
- ✅ Document any AI-generated code patterns or approaches in PR description
- ✅ Maintain transparency about which parts were AI-assisted vs manual implementation

### Workflow Integration

This AI compliance checklist should be integrated into the main development workflow Step 4 (Pull Request Creation):

```
Step 4: Pull Request Creation & AI Compliance
- Step 4.1: Create branch and commit changes WITH SIGNED-OFF COMMITS
- Step 4.2: Push changes to remote
- Step 4.3: Create PR with ai-assisted label
- Step 4.4: IMMEDIATELY update Jira customfield_11170 to "Yes"
- Step 4.5: Verify both PR labels and Jira field are properly set
- Step 4.6: Provide complete summary including AI compliance confirmation
```

- **Never skip Jira field updates** - This is required for Progress AI governance
- **Always verify updates succeeded** - Check response from atlassian-mcp tools
- **Treat as atomic operation** - PR creation and Jira updates should happen together
- **Double-check before final summary** - Confirm all AI compliance items are completed

### Audit Trail

All AI-assisted work must be traceable through:

1. GitHub PR labels (`ai-assisted`)
2. Jira custom field (`customfield_11170` = "Yes")
3. PR descriptions mentioning AI assistance
4. Commit messages where relevant

---

## Summary

This instruction set ensures:

- ✅ Comprehensive task planning and execution
- ✅ Proper Jira integration using atlassian-mcp-server
- ✅ Adequate testing with >80% coverage requirement
- ✅ Correct GitHub CLI usage for PR creation
- ✅ Prompt-based workflow with user confirmation
- ✅ Clear step-by-step progression
- ✅ Proper repository structure understanding
- ✅ Security and quality considerations

All tasks should be approached methodically, with clear communication at each step, and proper validation throughout the process.
