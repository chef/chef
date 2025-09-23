# GitHub Copilot Instructions for Chef Infra Client Repository

This document provides comprehensive instructions for GitHub Copilot to effectively assist with tasks in the Chef Infra Client repository.

## Repository Structure

The Chef Infra Client repository is organized as follows:

```
chef/
├── .buildkite/                 # Buildkite CI/CD configuration
├── .expeditor/                 # Expeditor build system configuration
├── .github/                    # GitHub configuration (workflows, templates, etc.)
├── chef-bin/                   # Chef binary executables package
├── chef-config/                # Chef configuration library
├── chef-utils/                 # Chef utility functions library
├── distro/                     # Distribution-specific templates
├── docs/                       # Documentation
├── ext/                        # Extensions (e.g., win32-eventlog)
├── habitat/                    # Habitat packaging configuration
├── kitchen-tests/              # Test Kitchen integration tests
├── knife/                      # Knife command-line tool
├── lib/                        # Main Chef Infra Client code
├── omnibus/                    # Omnibus packaging configuration
├── scripts/                    # Build and utility scripts
├── spec/                       # RSpec test suite
│   ├── unit/                   # Unit tests
│   ├── functional/             # Functional tests
│   ├── integration/            # Integration tests
│   └── support/                # Test support files
└── tasks/                      # Rake tasks
```

### Key Files and Directories:
- **`lib/chef/`** - Main Chef Infra Client code
- **`spec/`** - All test files organized by test type
- **`.github/workflows/`** - GitHub Actions CI/CD workflows
- **`.expeditor/`** - Expeditor build automation configuration
- **`chef.gemspec`** - Main gem specification
- **`Rakefile`** - Build and task definitions

## Jira Integration Workflow

When a Jira ID is provided:

1. **Use the atlassian-mcp-server MCP server** to fetch Jira issue details
2. **Read the story description** thoroughly to understand requirements
3. **Analyze acceptance criteria** and any technical specifications
4. **Implement the task** based on the story requirements
5. **Create appropriate unit and integration tests**
6. **Ensure test coverage remains above 80%**

### MCP Server Configuration
Use the `atlassian-mcp-server` for Jira integration. Ensure you have proper authentication configured for accessing Jira issues.

## Testing Requirements

### Coverage Standards
- **Minimum test coverage: 80%**
- All new code must include corresponding tests
- Use RSpec for unit and functional testing
- Integration tests should be placed in `spec/integration/`

### Test Types
1. **Unit Tests** (`spec/unit/`) - Test individual methods and classes
2. **Functional Tests** (`spec/functional/`) - Test feature functionality
3. **Integration Tests** (`spec/integration/`) - Test end-to-end scenarios

### Running Tests
```bash
# Run unit tests
bundle exec rspec spec/unit

# Run functional tests  
bundle exec rspec spec/functional

# Run integration tests
bundle exec rspec spec/integration

# Run all tests with coverage
bundle exec rspec --format documentation
```

## DCO Compliance Requirements

All commits must be signed off for Developer Certificate of Origin (DCO) compliance:

### DCO Sign-off Format
```
Signed-off-by: Your Name <your.email@example.com>
```

### Methods to Sign Commits
1. **Command line**: Use `-s` or `--signoff` flag
   ```bash
   git commit -s -m "Your commit message"
   ```
2. **Amend existing commit**: 
   ```bash
   git commit --amend -s
   ```
3. **Manual addition**: Add sign-off line to commit message

**Important**: All commits in a PR must be DCO signed. Force push may be required after amending: `git push -f`

## Expeditor Build System Integration

The repository uses Expeditor for automated build and release processes:

### Expeditor Labels
- **`Expeditor: Skip All`** - Skip all merge actions
- **`Expeditor: Skip Changelog`** - Skip changelog updates
- **`Expeditor: Skip Habitat`** - Skip Habitat package builds
- **`Expeditor: Skip Omnibus`** - Skip Omnibus builds
- **`Expeditor: Skip Version Bump`** - Skip version bumping
- **`Expeditor: Bump Version Major`** - Trigger major version bump
- **`Expeditor: Bump Version Minor`** - Trigger minor version bump

### GitHub Workflows
The repository uses GitHub Actions for CI/CD:
- `ci-main-pull-request-checks.yml` - Main PR validation
- `unit_specs.yml` - Unit test execution
- `func_spec.yml` - Functional test execution
- `kitchen.yml` - Test Kitchen integration tests
- `lint.yml` - Code linting and style checks
- `sonarqube.yml` - Code quality analysis

## Repository-Specific GitHub Labels

### Aspect Labels
- **Aspect: Integration** - Works correctly with other projects/systems
- **Aspect: Packaging** - Distribution of compiled artifacts
- **Aspect: Performance** - System performance impact
- **Aspect: Portability** - Cross-platform compatibility
- **Aspect: Security** - Security-related changes
- **Aspect: Stability** - Consistency and reliability
- **Aspect: Testing** - Test coverage and CI improvements
- **Aspect: UI** - User interface changes
- **Aspect: UX** - User experience improvements

### Status Labels
- **Status: Good First Issue** - Suitable for new contributors
- **Status: Help Wanted** - Community contribution welcome
- **Status: Needs JIRA** - Requires Jira ticket creation
- **Status: Needs RFC** - Requires RFC for behavior changes
- **Status: Waiting on Contributor** - Author action required

### Platform Labels
- **Platform: Linux**, **Platform: Windows**, **Platform: macOS** - Platform-specific
- **Platform: AWS**, **Platform: Azure**, **Platform: GCP** - Cloud platform specific
- **Platform: Docker** - Container-related

### Type Labels
- **Type: Bug** - Bug fixes
- **Type: Enhancement** - New features
- **Type: Breaking Change** - Breaking changes
- **Type: Tech Debt** - Code refactoring
- **Type: Regression** - Regression fixes

### Priority Labels
- **Priority: Critical** - Fix immediately
- **Priority: High** - Fix ASAP
- **Priority: Medium** - Standard priority
- **Priority: Low** - Low priority

## PR Creation Workflow

### Branch Creation and Management
1. **Branch Naming Convention**:
   - For Jira issues: Use Jira ID as branch name (e.g., `CHEF-1234`)
   - For internal team: Prefix with initials (e.g., `jd/CHEF-1234-feature-desc`)

2. **Branch Creation**:
   ```bash
   git checkout -b JIRA-ID main
   # Make your changes
   git add .
   git commit -s -m "Description of changes

   Implements JIRA-ID feature/fix
   
   Signed-off-by: Your Name <your.email@example.com>"
   ```

3. **Push Changes**:
   ```bash
   git push origin JIRA-ID
   ```

### Creating Pull Requests
Use GitHub CLI to create PRs:

```bash
gh pr create --title "JIRA-ID: Brief description of changes" \
  --body "$(cat << 'EOF'
<h2>Summary</h2>
<p>Brief description of what this PR accomplishes</p>

<h2>Changes Made</h2>
<ul>
<li>Change 1</li>
<li>Change 2</li>
<li>Change 3</li>
</ul>

<h2>Testing</h2>
<ul>
<li>Added unit tests for new functionality</li>
<li>All existing tests pass</li>
<li>Coverage maintained above 80%</li>
</ul>

<h2>Jira Issue</h2>
<p>Implements: <a href="https://progress.atlassian.net/browse/JIRA-ID">JIRA-ID</a></p>
EOF
)" \
  --assignee @me
```

### PR Requirements
1. **DCO Sign-off** - All commits must be signed
2. **Tests** - Unit tests required, maintain >80% coverage
3. **Green CI** - All Buildkite tests must pass
4. **Code Review** - Two approvers required
5. **Rebase** - Rebase before merge (no merge commits)

## Task Implementation Workflow

### Complete Workflow Process
1. **Initialize Task**
   - Read Jira issue using atlassian-mcp-server
   - Understand requirements and acceptance criteria
   - Create implementation plan

2. **Create Branch**
   ```bash
   git checkout -b JIRA-ID main
   ```

3. **Implement Changes**
   - Write code according to requirements
   - Follow existing code patterns and style
   - Ensure Ruby best practices

4. **Create Tests**
   - Write unit tests in `spec/unit/`
   - Add functional tests if needed in `spec/functional/`
   - Verify coverage above 80%

5. **Validate Changes**
   ```bash
   bundle exec rspec
   bundle exec cookstyle  # Ruby linting
   ```

6. **Commit with DCO**
   ```bash
   git add .
   git commit -s -m "Implement JIRA-ID functionality

   - Add new feature X
   - Update existing behavior Y
   - Add comprehensive test coverage
   
   Signed-off-by: Your Name <your.email@example.com>"
   ```

7. **Create PR**
   ```bash
   git push origin JIRA-ID
   gh pr create --title "JIRA-ID: Feature description" --body "HTML formatted description"
   ```

### Files That Should NOT Be Modified
- `.git/` directory and Git configuration
- `VERSION` file (managed by Expeditor)
- `CHANGELOG.md` (auto-generated by Expeditor)
- `.expeditor/config.yml` (unless specifically required)
- Build artifacts in `pkg/`, `results/`

## Prompt-Based Task Execution

### Step-by-Step Approach
After each implementation step, provide:

1. **Summary of Completed Work**
   - What was accomplished
   - Files modified
   - Tests added/updated

2. **Next Step Prompt**
   - Clear description of the next action
   - Remaining steps in the workflow
   - Any dependencies or prerequisites

3. **Progress Check**
   - Ask: "Would you like to continue with the next step?"
   - Wait for user confirmation before proceeding
   - Provide options if multiple paths are available

### Example Step Summary Format
```
✅ **Step Completed**: Implemented core functionality for JIRA-1234

**Files Modified:**
- `lib/chef/resource/new_resource.rb` - Added new resource class
- `spec/unit/resource/new_resource_spec.rb` - Added unit tests

**Coverage**: 85% (above 80% requirement)

**Next Step**: Create functional tests and validate integration

**Remaining Steps**:
1. Add functional tests
2. Run full test suite
3. Create PR with proper DCO sign-off

Would you like to continue with the functional tests?
```

## Quality Assurance Checklist

Before creating a PR, ensure:

- [ ] DCO sign-off on all commits
- [ ] Unit tests written and passing
- [ ] Test coverage above 80%
- [ ] Code follows Ruby style guidelines (Cookstyle)
- [ ] No prohibited files modified
- [ ] Jira requirements fully implemented
- [ ] Integration tests added if applicable
- [ ] Documentation updated if needed
- [ ] Branch name matches Jira ID
- [ ] PR description uses HTML formatting
- [ ] All CI checks passing

## Additional Resources

- [Chef Infra Client Documentation](https://docs.chef.io/chef_client/)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [Developer Certificate of Origin](http://developercertificate.org/)
- [Chef OSS Practices](https://github.com/chef/chef-oss-practices)
- [RSpec Testing Framework](https://rspec.info/)

---

*This document should be kept up-to-date as repository practices evolve.*