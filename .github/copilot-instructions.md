# Chef Infra GitHub Copilot Instructions

This document provides comprehensive instructions for GitHub Copilot when working with the Chef Infra repository.

## Repository Structure

The Chef Infra repository is organized as follows:

```
chef/
├── lib/                           # Main Chef library code
│   ├── chef.rb                    # Primary entry point
│   └── chef/                      # Core Chef classes and modules
├── chef-config/                   # Configuration management gem
│   ├── lib/                       # Configuration library code
│   ├── spec/                      # Configuration tests
│   └── chef-config.gemspec
├── chef-utils/                    # Utility functions gem
│   ├── lib/                       # Utility library code
│   ├── spec/                      # Utility tests
│   └── chef-utils.gemspec
├── chef-bin/                      # Command-line binaries
│   ├── bin/                       # Executable files (chef-client, chef-solo, etc.)
│   ├── lib/                       # Binary support code
│   └── chef-bin.gemspec
├── spec/                          # RSpec test suite
│   ├── unit/                      # Unit tests
│   ├── functional/                # Functional tests
│   ├── integration/               # Integration tests
│   ├── support/                   # Test support files
│   └── spec_helper.rb             # Main test configuration
├── kitchen-tests/                 # Test Kitchen integration tests
│   ├── cookbooks/                 # Test cookbooks
│   ├── test/                      # Test cases
│   └── kitchen.yml                # Kitchen configuration
├── omnibus/                       # Omnibus packaging configuration
│   ├── config/                    # Omnibus project config
│   └── package-scripts/           # Package scripts
├── habitat/                       # Habitat packaging configuration
│   ├── plan.sh                    # Habitat plan
│   └── config/                    # Habitat configuration
├── distro/                        # Distribution-specific files and templates
│   └── templates/                 # Platform-specific templates
├── scripts/                       # Build and utility scripts
├── tasks/                         # Rake task definitions
├── docs/                          # Documentation files
├── .github/                       # GitHub configuration and workflows
│   ├── workflows/                 # GitHub Actions workflows
│   ├── ISSUE_TEMPLATE/            # Issue templates
│   └── CODEOWNERS                 # Code ownership
├── Gemfile                        # Ruby dependencies
├── Rakefile                       # Build automation tasks
├── VERSION                        # Current version number
├── CHANGELOG.md                   # Release notes
├── CONTRIBUTING.md                # Contribution guidelines
├── README.md                      # Project overview
└── chef.gemspec                   # Gem specification
```

## Jira Integration with MCP Server

When a Jira ID is provided in a task or issue:

1. **Use the Atlassian MCP Server** configured in `.vscode/mcp.json`
2. **Fetch Jira Issue Details** using the MCP server tools:
   ```
   Use mcp_atlassian-mcp_getJiraIssue to fetch issue details
   Use mcp_atlassian-mcp_search for broader searches
   ```
3. **Read and Understand** the Jira story, acceptance criteria, and requirements
4. **Implement the Task** based on the Jira story requirements
5. **Update Jira** with progress and completion status using MCP server tools

### MCP Server Configuration
The repository uses the `atlassian-mcp-server` configured at `https://mcp.atlassian.com/v1/sse` for Jira integration.

## Testing Requirements

### Unit Test Coverage
- **Minimum Coverage**: 80% or higher for all new code
- **Test Framework**: RSpec
- **Test Location**: Place tests in `spec/unit/` matching the source file structure
- **Test Helper**: Use `spec/spec_helper.rb` for test configuration

### Test Creation Guidelines
1. **Create unit tests** for every new class, method, or function
2. **Mock external dependencies** using RSpec mocks
3. **Follow existing test patterns** found in the spec directory
4. **Include edge cases** and error conditions
5. **Test both positive and negative scenarios**

### Running Tests
```bash
# Run all tests
rake spec

# Run specific test file
rspec spec/unit/path/to/test_spec.rb

# Run with coverage
rake spec:coverage
```

## Pull Request Workflow

### Branch Creation and Management
1. **Branch Naming**: Use the Jira ID as the branch name (e.g., `CHEF-1234`)
2. **Create Branch**: Use GitHub CLI
   ```bash
   gh repo clone chef/chef
   cd chef
   git checkout -b CHEF-1234
   ```

### Making Changes
1. **Implement the feature** based on Jira requirements
2. **Create comprehensive unit tests** with >80% coverage
3. **Follow existing code patterns** and conventions
4. **Update documentation** if needed

### Commit Requirements (DCO Compliance)
All commits must include a Developer Certificate of Origin (DCO) sign-off:

```bash
git commit -s -m "Your commit message"

# Or add manually to commit message:
Signed-off-by: Your Name <your.email@example.com>
```

**DCO Requirements:**
- Every commit must be signed off
- Use `-s` flag with git commit or add sign-off manually
- Ensures legal compliance with open source contributions
- Required for all contributions to be accepted

### Creating Pull Requests
Use GitHub CLI to create PR with proper formatting:

```bash
# Push changes
git push origin CHEF-1234

# Create PR with HTML-formatted description
gh pr create --title "CHEF-1234: Brief description" --body "
<h2>Summary</h2>
<p>Brief description of changes made</p>

<h2>Changes Made</h2>
<ul>
<li>Change 1</li>
<li>Change 2</li>
<li>Change 3</li>
</ul>

<h2>Testing</h2>
<ul>
<li>Unit tests added with >80% coverage</li>
<li>All existing tests pass</li>
<li>Manual testing performed</li>
</ul>

<h2>Jira Reference</h2>
<p>Resolves: CHEF-1234</p>
"
```

## Repository-Specific GitHub Labels

The Chef repository uses these labels for categorization and workflow:

### Aspect Labels
- `Aspect: Integration` - Works correctly with other projects or systems
- `Aspect: Packaging` - Distribution of compiled artifacts
- `Aspect: Performance` - Performance-related changes
- `Aspect: Portability` - Platform compatibility
- `Aspect: Security` - Security-related changes
- `Aspect: Stability` - Consistency and reliability
- `Aspect: Testing` - Test coverage and CI improvements
- `Aspect: UI` - User interface changes
- `Aspect: UX` - User experience improvements

### Workflow Labels
- `Design Proposal: Accepted. PRs Welcome` - Approved design, ready for implementation
- `Do Not Merge` - Prevents accidental merging
- `Epic` - Large feature or initiative
- `community-blockers` - Community engagement blockers
- `dependencies` - Dependency updates
- `documentation` - Documentation changes

### Expeditor Build System Labels
The repository uses Expeditor for automated builds and releases:

- `Expeditor: Bump Version Major` - Triggers major version bump
- `Expeditor: Bump Version Minor` - Triggers minor version bump
- `Expeditor: Skip All` - Skips all merge actions
- `Expeditor: Skip Changelog` - Skips changelog updates
- `Expeditor: Skip Habitat` - Skips Habitat package build
- `Expeditor: Skip Omnibus` - Skips Omnibus package build

## Prompt-Based Workflow

### Step-by-Step Process
All tasks should follow this prompt-based approach:

1. **Initial Analysis**
   - Read and understand the requirements
   - Analyze existing code structure
   - Identify files that need modification
   - **Prompt**: "Analysis complete. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

2. **Implementation Planning**
   - Create detailed implementation plan
   - Identify test requirements
   - Plan file structure changes
   - **Prompt**: "Implementation plan ready. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

3. **Code Implementation**
   - Implement the feature/fix
   - Follow existing patterns and conventions
   - Ensure code quality and documentation
   - **Prompt**: "Code implementation complete. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

4. **Test Creation**
   - Create comprehensive unit tests
   - Ensure >80% coverage
   - Test edge cases and error conditions
   - **Prompt**: "Tests created. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

5. **Validation**
   - Run all tests
   - Verify coverage requirements
   - Check code quality
   - **Prompt**: "Validation complete. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

6. **Documentation Update**
   - Update relevant documentation
   - Add inline code comments
   - Update CHANGELOG if needed
   - **Prompt**: "Documentation updated. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

7. **PR Preparation**
   - Create branch with Jira ID
   - Commit with DCO sign-off
   - Push changes
   - **Prompt**: "PR preparation complete. Next step: [describe next action]. Remaining steps: [list remaining steps]. Continue?"

8. **PR Creation**
   - Create PR with GitHub CLI
   - Use HTML-formatted description
   - Include summary and testing details
   - **Prompt**: "PR created successfully. Workflow complete. Next steps: [list any follow-up actions]"

### Continuation Prompts
After each major step, always ask: **"Would you like to continue with the next step?"**

This ensures user control over the process and allows for review at each stage.

## File Modification Guidelines

### Prohibited Files
Do not modify these files without explicit approval:
- `VERSION` - Managed by Expeditor
- `CHANGELOG.md` - Managed by Expeditor
- `Gemfile.lock` - Only update with conservative gem updates
- Core configuration files in root directory (unless specifically required)

### Preferred Modification Patterns
- Follow existing code structure and patterns
- Maintain backward compatibility
- Use descriptive variable and method names
- Include comprehensive error handling
- Add appropriate logging where needed

## Additional Notes

### Code Quality Standards
- Follow Ruby style guide and Chefstyle conventions
- Use meaningful commit messages
- Include appropriate comments and documentation
- Ensure code is self-documenting where possible

### CI/CD Integration
- All PRs must pass Buildkite CI
- Tests must pass on all supported platforms
- Code coverage must meet minimum thresholds
- Follow the build and release process documented in the repository

### Community Guidelines
- Be respectful and inclusive in all interactions
- Follow the Chef Community Code of Conduct
- Provide helpful and constructive feedback
- Support community contributions and engagement

This document serves as the primary guide for GitHub Copilot when working with the Chef Infra repository. Always refer to these instructions for consistent and high-quality contributions.