# GitHub Copilot Instructions for Chef Infra

## Purpose

This document provides authoritative operational workflow guidance for AI assistants contributing to the Chef Infra repository. It defines structured processes for issue retrieval, planning, implementation, testing, DCO-compliant commits, and PR authoring with appropriate safety guardrails and user confirmation gates.

**Audience**: Autonomous AI assistants performing code contributions.

**Scope**: Issue integration, structured planning, implementation gating, testing & coverage enforcement, DCO-compliant commits, PR authoring, labeling, idempotent re-entry, and safety guardrails.

**Non-Goals**: Deep architectural redesign, performance tuning outside explicit task scope.

---

## Repository Structure

The Chef Infra repository is a Ruby-based configuration management system with the following structure:

```
chef/
├── .expeditor/                    # Expeditor CI/CD automation configuration
├── .github/                       # GitHub Actions workflows, CODEOWNERS, templates
│   ├── workflows/                 # CI/CD pipeline definitions
│   └── CODEOWNERS                 # Code ownership definitions
├── chef-bin/                      # Chef binary executables (chef-client, chef-solo, etc.)
├── chef-config/                   # Configuration management gem
├── chef-utils/                    # Utility functions gem
├── distro/                        # Distribution-specific templates
├── docs/                          # Developer documentation
├── ext/                           # Native extensions (win32-eventlog)
├── habitat/                       # Chef Habitat packaging configuration
├── kitchen-tests/                 # Test Kitchen integration tests
├── knife/                         # Knife CLI tool gem
├── lib/chef/                      # Core Chef Infra codebase
│   ├── application/               # Application entry points
│   ├── provider/                  # Resource providers
│   ├── resource/                  # Resource definitions
│   ├── dsl/                       # Domain-specific language components
│   ├── mixin/                     # Reusable module mixins
│   └── util/                      # Utility modules
├── omnibus/                       # Omnibus packaging configuration
├── scripts/                       # Build and maintenance scripts
├── spec/                          # RSpec test suite
│   ├── unit/                      # Unit tests
│   ├── functional/                # Functional tests
│   └── integration/               # Integration tests
├── tasks/                         # Rake task definitions
├── CHANGELOG.md                   # Version history
├── CONTRIBUTING.md                # Contribution guidelines
├── Gemfile                        # Ruby dependency management
├── Rakefile                       # Rake task definitions
└── VERSION                        # Current version number
```

**Key Directories**:
- `lib/chef/`: Core Chef Infra library with resources, providers, DSL, and utilities
- `spec/`: Comprehensive test suite (unit, functional, integration)
- `chef-bin/bin/`: Executable binaries for Chef CLI tools
- `.expeditor/`: Release automation and CI/CD pipeline configuration
- `omnibus/`: Packaging configuration for multi-platform distributions
- `kitchen-tests/`: End-to-end integration testing with Test Kitchen

---

## Tooling & Ecosystem

**Language**: Ruby 3.1+

**Build System**: Rake, Bundler

**Testing Frameworks**:
- RSpec (unit, functional, integration tests)
- Test Kitchen (end-to-end integration tests)
- Cookstyle (RuboCop-based linting)

**Packaging**:
- Omnibus (multi-platform package building)
- Habitat (containerized packaging)
- RubyGems (gem distribution)

**CI/CD**:
- GitHub Actions (lint, unit tests, functional tests, kitchen tests)
- Buildkite (build verification, platform testing)
- Expeditor (release automation, version bumping, changelog generation)

**Key Commands**:
```bash
bundle install                    # Install dependencies
bundle exec rake spec:unit        # Run unit tests
bundle exec rake component_specs  # Run component tests
bundle exec cookstyle            # Run lint checks
kitchen test                      # Run Test Kitchen integration tests
```

---

## Issue (Jira/Tracker) Integration

When an issue key is provided (e.g., GitHub issue #123 or JIRA key like CHEF-1234):

### Invocation Pattern

**For JIRA Issues**: If a JIRA issue key is provided (format: PROJECT-NUMBER, e.g., CHEF-1234), AI MUST use the configured JIRA MCP server (if available in `mcp.json` or MCP settings) to retrieve issue details:

```
Tool: Use configured JIRA MCP server tool (e.g., atlassian-mcp-server)
Method: getIssue or equivalent
Parameters: { "issueKey": "CHEF-1234" }
```

**For GitHub Issues**: If a GitHub issue number is provided (format: #123 or gh-123), use GitHub API or `gh` CLI to retrieve issue details.

**Required Fields** - AI MUST retrieve:
- **Summary**: Issue title/summary
- **Description**: Detailed problem statement
- **Acceptance Criteria**: Expected outcomes (if available)
- **Issue Type**: Bug, Feature, Enhancement, Task, Story

**If MCP server unavailable or fetch fails**: AI MUST abort and prompt user per ABORT_CRITERIA #1.

### Implementation Plan (MUST create before code)

Before any code changes, AI MUST draft and get user approval for:

```
Issue: <ISSUE_KEY>
Summary: <from issue>

Acceptance Criteria:
- <criterion 1>
- <criterion 2>

Implementation Plan:
- Goal: <clear objective>
- Impacted Files: <list of files to modify>
- Public API Changes: <any interface/API changes>
- Data/Integration Considerations: <external dependencies, data migrations>
- Test Strategy: <unit, functional, integration test approach>
- Edge Cases: <boundary conditions, error scenarios>
- Risks & Mitigations: <potential issues and solutions>
- Rollback Strategy: <how to revert if needed>

Proceed? (yes/no)
```

**Freeze Point**: NO code changes until user explicitly responds "yes".

If acceptance criteria are missing, AI MUST prompt user to confirm inferred criteria.

---

## Workflow Overview

AI MUST follow these phases in order:

1. **Intake & Clarify**: Understand task, fetch issue details if provided
2. **Repository Analysis**: Scan relevant code, understand context
3. **Plan Draft**: Create implementation plan with all required sections
4. **Plan Confirmation** (GATE): User must approve with "yes"
5. **Incremental Implementation**: Make smallest cohesive changes
6. **Lint / Style**: Run Cookstyle and fix violations
7. **Test & Coverage Validation**: Ensure tests pass, coverage adequate
8. **DCO Commit**: Create properly formatted, signed-off commits
9. **Push & Draft PR Creation**: Push branch, create draft PR
10. **Label & Risk Application**: Apply appropriate labels, document risks
11. **Final Validation**: Verify all exit criteria met

Each phase ends with:
```
Step: <STEP_NAME>
Summary: <CONCISE_OUTCOME>
Checklist:
- [x] <completed items>
- [ ] <remaining items>

Continue to next step? (yes/no)
```

Non-affirmative response → AI MUST pause and clarify.

---

## Detailed Step Instructions

### Principles (MUST follow)

- **Smallest cohesive change per commit**: Each commit should represent one logical change
- **Add/adjust tests immediately**: Tests must accompany behavior changes
- **Present mapping**: Show relationship between code changes and test coverage
- **Incremental progress**: Break large tasks into reviewable chunks

### Example Step Output

```
Step: Add boundary guard in parser

Summary: Added nil check and size constraint validation in `lib/chef/util/parser.rb`. 
Added tests for empty input and overflow scenarios in `spec/unit/util/parser_spec.rb`.

Checklist:
- [x] Plan approved
- [x] Implementation complete
- [x] Tests added
- [ ] Lint/style check

Proceed? (yes/no)
```

If user responds other than explicit "yes" → AI MUST pause & clarify.

---

## Branching & PR Standards

### Branch Naming (MUST)

**Format**: 
- If issue key provided: Use EXACT issue key (e.g., `gh-1234` for GitHub issue #1234)
- Otherwise: kebab-case slug (≤40 chars) derived from task (e.g., `add-yaml-resource-support`)

**One logical change set per branch** (MUST).

### PR Requirements

PR MUST remain **draft** until:
- All tests pass
- Lint/style checks pass
- Coverage mapping completed
- User explicitly approves moving to "ready for review"

### PR Description Sections (MUST include)

```html
<h2>Summary</h2>
<p>Brief description of WHAT changed and WHY.</p>

<h2>Issue</h2>
<p><a href="https://github.com/chef/chef/issues/123">GitHub #123</a></p>

<h2>Changes</h2>
<ul>
  <li>Modified: <code>lib/chef/resource/file.rb</code> - Added encoding parameter</li>
  <li>Added: <code>spec/unit/resource/file_spec.rb</code> - Tests for encoding</li>
</ul>

<h2>Tests & Coverage</h2>
<p>Changed lines: 45; Estimated covered: ~90%; Coverage mapping complete.</p>

<table>
  <tr>
    <th>File</th>
    <th>Method/Block</th>
    <th>Test File</th>
    <th>Assertion</th>
  </tr>
  <tr>
    <td>lib/chef/resource/file.rb</td>
    <td>encoding validation</td>
    <td>spec/unit/resource/file_spec.rb</td>
    <td>Line 145-160</td>
  </tr>
</table>

<h2>Risk & Mitigations</h2>
<p><strong>Risk Classification</strong>: Low</p>
<p><strong>Rationale</strong>: Localized change to single resource, backward compatible.</p>
<p><strong>Mitigation</strong>: Revert commit <SHA> if issues arise.</p>
<p><strong>Rollback Strategy</strong>: <code>git revert &lt;SHA&gt;</code></p>

<h2>DCO</h2>
<p>All commits include Developer Certificate of Origin sign-off.</p>
```

### Risk Classification (MUST pick one)

- **Low**: Localized change, non-breaking, single resource/provider
- **Moderate**: Shared module change, touches multiple resources, light API modification
- **High**: Public API change, security-related, performance-critical, data migration, breaking change

---

## Commit & DCO Policy

### Commit Format (MUST)

```
<TYPE>(<OPTIONAL_SCOPE>): <SUBJECT> (<ISSUE_KEY>)

<Rationale explaining WHAT changed and WHY>

Issue: <ISSUE_KEY or none>
Signed-off-by: Full Name <email@domain>
```

**Types**: feat, fix, docs, style, refactor, test, chore, perf

**Examples**:
```
feat(resource): add encoding property to file resource (gh-1234)

Added encoding property to support non-UTF8 file encodings.
This allows users to specify file encoding explicitly for
Windows-1252, ISO-8859-1, and other encodings.

Issue: gh-1234
Signed-off-by: John Doe <john.doe@example.com>
```

```
fix(provider): handle nil values in package provider (gh-5678)

Added nil check before accessing package version to prevent
NoMethodError when package is not installed.

Issue: gh-5678
Signed-off-by: Jane Smith <jane.smith@example.com>
```

**Missing sign-off** → AI MUST block and request name/email from user.

---

## Testing & Coverage

### Changed Logic → Test Assertions Mapping (MUST)

For every code change, AI MUST provide:

| File | Method/Block | Change Type | Test File | Assertion Reference |
|------|-------------|-------------|-----------|---------------------|
| `lib/chef/resource/file.rb` | `encoding` property | Added property | `spec/unit/resource/file_spec.rb` | Lines 145-160 |
| `lib/chef/provider/package.rb` | `install_package` | Added nil check | `spec/unit/provider/package_spec.rb` | Lines 89-95 |

### Coverage Threshold (MUST)

**Target**: ≥80% coverage of changed lines

If below threshold: Add tests or refactor for testability. Qualitative reasoning allowed if tooling unavailable.

### Edge Cases (MUST enumerate)

For each implementation plan, AI MUST consider:

- **Large input / boundary size**: Max file size, array length limits
- **Empty / nil input**: Null values, empty strings, empty arrays
- **Invalid / malformed data**: Type mismatches, parsing errors
- **Platform-specific differences**: Windows vs Linux paths, permissions, line endings
- **Concurrency / timing**: Race conditions, parallel execution
- **External dependency failures**: Network timeouts, missing packages, I/O errors

### Test Execution

```bash
# Run all unit tests
bundle exec rake spec:unit

# Run specific test file
bundle exec rspec spec/unit/resource/file_spec.rb

# Run component tests
bundle exec rake component_specs

# Run functional tests
bundle exec rake spec:functional

# Run integration tests (Test Kitchen)
cd kitchen-tests && kitchen test
```

---

## Labels Reference

AI MUST apply appropriate labels when creating/updating PRs. Labels are fetched from the Chef Infra repository.

| Label Name | Description | Typical Use |
|------------|-------------|-------------|
| `Aspect: Integration` | Works correctly with other projects or systems | Multi-project integration work |
| `Aspect: Packaging` | Distribution of the project's compiled artifacts | Omnibus, Habitat, gem packaging |
| `Aspect: Performance` | Works without negatively affecting the system | Performance optimizations |
| `Aspect: Portability` | Works correctly on specified platforms | Cross-platform compatibility fixes |
| `Aspect: Security` | Prevents unwanted third-party access/stability issues | Security vulnerabilities, CVE fixes |
| `Aspect: Stability` | Consistent, reliable results | Bug fixes, race condition fixes |
| `Aspect: Testing` | Project coverage and CI health | Test improvements, CI fixes |
| `Aspect: UI` | User interface interaction and visual design | CLI output, formatting changes |
| `Aspect: UX` | User experience, function, ease-of-use | API design, usability improvements |
| `Backport: 16` | Should be backported to Chef 16 branch | Critical fixes for Chef 16 |
| `Backport: 17` | Should be backported to Chef 17 branch | Critical fixes for Chef 17 |
| `Backport: 18` | Should be backported to Chef 18 branch | Critical fixes for Chef 18 |
| `Chef 17.12` | Targeted for Chef 17.12 release | Release-specific features |
| `Chef 18.4` | Targeted for Chef 18.4 release | Release-specific features |
| `Chef 18.5` | Targeted for Chef 18.5 release | Release-specific features |
| `Chef 18.6` | Targeted for Chef 18.6 release | Release-specific features |
| `Chef 18.8` | Targeted for Chef 18.8 release | Release-specific features |
| `Chef 19` | Targeted for Chef 19 release | Chef 19 features |
| `community-blockers` | Community Engagement Blockers | High-priority community issues |
| `dependencies` | Updates a dependency file | Gemfile, dependency updates |
| `Design Proposal: Accepted. PRs Welcome` | Design approved, implementation needed | Feature requests ready for implementation |
| `Do Not Merge` | Explicitly prevents merging | WIP, blocked PRs |
| `documentation` | Documentation changes | README, docs, code comments |
| `Epic` | Large multi-PR feature work | Major feature initiatives |
| `Expeditor: Bump Version Major` | Triggers major version bump | Breaking changes |
| `Expeditor: Bump Version Minor` | Triggers minor version bump | New features |
| `Expeditor: Skip All` | Skips all Expeditor merge actions | Special automation bypass |
| `Expeditor: Skip Changelog` | Skips changelog update | Non-user-facing changes |
| `Expeditor: Skip Habitat` | Skips Habitat package build | Changes not requiring Habitat rebuild |
| `Expeditor: Skip Omnibus` | Skips Omnibus package build | Changes not requiring Omnibus rebuild |

### Label Mapping Guidance

- **Bug fixes** → `Aspect: Stability` + relevant aspect (Security, Performance, etc.)
- **New features** → `Expeditor: Bump Version Minor` + relevant aspects
- **Breaking changes** → `Expeditor: Bump Version Major` + `Do Not Merge` (until release ready)
- **Test-only changes** → `Aspect: Testing` + `Expeditor: Skip Omnibus` + `Expeditor: Skip Habitat`
- **Documentation-only** → `documentation` + `Expeditor: Skip Omnibus` + `Expeditor: Skip Habitat`
- **Dependency updates** → `dependencies`
- **Security issues** → `Aspect: Security` + backport labels if critical

If required label missing → AI MUST prompt user to confirm alternative or note that label creation is outside scope.

---

## CI / Release Automation Integration

### GitHub Actions Workflows

The repository uses GitHub Actions for continuous integration:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `unit_specs.yml` | PR, push to chef-18 | Runs unit tests and component specs on macOS |
| `func_spec.yml` | PR, push to chef-18 | Runs functional tests (chocolatey on Windows, userdefaults on macOS) |
| `lint.yml` | PR, push to chef-18 | Cookstyle linting and spell checking |
| `kitchen.yml` | PR, push to chef-18 | Test Kitchen integration tests on Windows and macOS |
| `kitchen-fips.yml` | PR, push to chef-18 | FIPS-compliant kitchen tests |
| `selfhosted-fips.yml` | PR, push to chef-18 | Self-hosted FIPS testing |
| `sonarqube.yml` | PR | SonarQube code quality analysis |
| `danger.yml` | PR | Automated PR review with Danger |
| `labeler.yml` | PR | Automatic label application |
| `ci-main-pull-request-checks.yml` | PR to main, release branches | Comprehensive CI checks including complexity, TruffleHog scanning, SBOM generation |

### Expeditor Release Automation

Chef Infra uses **Expeditor** for release automation:

**Configuration**: `.expeditor/config.yml`

**Key Features**:
- **Automatic version bumping**: Via `Expeditor: Bump Version Minor/Major` labels
- **Changelog generation**: Automatic CHANGELOG.md updates (skip with `Expeditor: Skip Changelog`)
- **Multi-platform builds**: Omnibus packages for Linux, Windows, macOS via Buildkite
- **Habitat packages**: Automated Habitat package builds
- **Docker images**: Multi-architecture Docker image builds and manifests
- **RubyGems publishing**: Publishes chef, chef-config, chef-bin, chef-utils gems
- **Branch-based releases**: 
  - `main` → Chef 19.x
  - `chef-18` → Chef 18.x
  - `chef-17` → Chef 17.x

**Version Management**: `VERSION` file in repository root

**Pipelines**:
- `verify`: Standard CI verification
- `validate/release`: Release validation pipeline
- `validate/adhoc`: Ad-hoc testing builds
- `omnibus/release`: Production package builds
- `omnibus/adhoc`: Development package builds
- `docker/build`: Docker image builds
- `habitat/build`: Habitat package builds

### CRITICAL Constraint

**AI MUST NOT directly edit release automation configs without explicit user instruction**:
- `.expeditor/config.yml`
- `.expeditor/*.yml` pipeline files
- `.github/workflows/*.yml` (CI workflows)
- `VERSION` file (managed by Expeditor)

---

## Security & Protected Files

### Protected Files (NEVER edit without explicit approval)

- `LICENSE` - Apache 2.0 license
- `CODE_OF_CONDUCT.md` - Community standards
- `.github/CODEOWNERS` - Code ownership
- `SECURITY.md` - Security policy
- `.expeditor/config.yml` - Release automation
- `.expeditor/*.yml` - Pipeline definitions
- `.github/workflows/*.yml` - CI workflows
- `VERSION` - Version file (Expeditor-managed)
- Any credential files, secrets, or auth configs

### Security Constraints (NEVER)

- Exfiltrate or inject secrets
- Force-push to default branch (main, chef-18, chef-17)
- Merge PR autonomously
- Insert new binaries without review
- Remove license headers
- Fabricate issue or label data
- Reference `~/.profile` or user home directory for credentials

### Security Best Practices

- Use environment variables for sensitive data
- Follow least-privilege principle
- Validate all external inputs
- Sanitize user-provided data
- Document security implications in PR risk assessment

---

## Prompts Pattern (Interaction Model)

After each step, AI MUST output:

```
Step: <STEP_NAME>
Summary: <CONCISE_OUTCOME>

Checklist:
- [x] <completed phase>
- [x] <completed phase>
- [ ] <next phase>
- [ ] <remaining phase>

Continue to next step? (yes/no)
```

**Non-affirmative response** → AI MUST pause and clarify.

User must explicitly type "yes" to proceed. Any other response requires clarification.

---

## Validation & Exit Criteria

Task is COMPLETE ONLY IF all criteria met:

1. ✅ Feature/fix branch exists and pushed to remote
2. ✅ Lint/style checks pass (Cookstyle)
3. ✅ All tests pass (unit, functional, integration as applicable)
4. ✅ Coverage mapping complete + ≥80% changed lines covered
5. ✅ PR open (draft or ready) with all required HTML sections
6. ✅ Appropriate labels applied to PR
7. ✅ All commits DCO-compliant (Signed-off-by present)
8. ✅ No unauthorized Protected File modifications
9. ✅ User explicitly confirms completion

If any criterion unmet, AI MUST list unmet items and block completion.

---

## Issue Planning Template

Use this template for all issues:

```markdown
Issue: <ISSUE_KEY>
Summary: <from issue>

Acceptance Criteria:
- <criterion 1>
- <criterion 2>
- <criterion 3>

Implementation Plan:

**Goal**: <clear, measurable objective>

**Impacted Files**:
- `lib/chef/resource/example.rb` - Add new property
- `spec/unit/resource/example_spec.rb` - Add tests

**Public API Changes**:
- New property: `encoding` (String, optional, default: 'UTF-8')
- Backward compatible: Yes

**Data/Integration Considerations**:
- No database migrations required
- Compatible with existing cookbooks
- No external service dependencies

**Test Strategy**:
- Unit tests: Property validation, default values
- Functional tests: File operations with various encodings
- Integration tests: Kitchen test with real-world cookbooks

**Edge Cases**:
- Nil/empty encoding value
- Invalid encoding name
- Platform-specific encoding (Windows-1252 on Windows)
- Large files (> 1GB)
- Binary files with encoding specified

**Risks & Mitigations**:
- Risk: Breaking existing cookbooks if encoding is enforced
  Mitigation: Make optional with sensible default
- Risk: Performance impact on large files
  Mitigation: Lazy evaluation, benchmark tests

**Rollback Strategy**:
- Revert commit <SHA>
- Property is optional, so removal won't break existing code
- No data migration required

Proceed? (yes/no)
```

---

## PR Description Canonical Template

**Note**: If `.github/PULL_REQUEST_TEMPLATE.md` exists in repository, use that template and inject required sections without redefining.

If no PR template exists in this repository, use this format:

```html
<h2>Summary</h2>
<p>Brief description of WHAT changed and WHY this change is needed.</p>

<h2>Issue</h2>
<p><a href="https://github.com/chef/chef/issues/123">GitHub #123</a></p>

<h2>Changes</h2>
<ul>
  <li>Modified: <code>path/to/file.rb</code> - Description of change</li>
  <li>Added: <code>path/to/test_spec.rb</code> - Test coverage</li>
  <li>Updated: <code>CHANGELOG.md</code> - Documented change</li>
</ul>

<h2>Tests & Coverage</h2>
<p>Changed lines: N; Estimated covered: ~X%; Coverage mapping complete.</p>

<table>
  <tr>
    <th>File</th>
    <th>Method/Block</th>
    <th>Change Type</th>
    <th>Test File</th>
    <th>Assertion Reference</th>
  </tr>
  <tr>
    <td>...</td>
    <td>...</td>
    <td>...</td>
    <td>...</td>
    <td>...</td>
  </tr>
</table>

<h2>Risk & Mitigations</h2>
<p><strong>Risk Classification</strong>: Low/Moderate/High</p>
<p><strong>Rationale</strong>: Explanation of risk level</p>
<p><strong>Mitigation</strong>: How risks are addressed</p>
<p><strong>Rollback Strategy</strong>: <code>git revert &lt;SHA&gt;</code></p>

<h2>DCO</h2>
<p>All commits signed off with Developer Certificate of Origin.</p>
```

---

## Idempotency Rules

### Re-entry Detection (MUST check in order)

When resuming work or re-running workflow:

1. **Branch existence**: `git rev-parse --verify <branch> 2>/dev/null`
2. **PR existence**: `gh pr list --head <branch> --json number`
3. **Uncommitted changes**: `git status --porcelain`

If any exist, AI MUST provide delta summary before proceeding.

### Delta Summary (MUST provide if re-entering)

```markdown
Re-entry Detected

**Existing State**:
- Branch: `feature-branch` exists
- PR: #123 (draft)
- Uncommitted changes: 3 files modified

**Delta Summary**:
- Added Sections: New test coverage for edge cases
- Modified Sections: Updated risk assessment
- Deprecated Sections: None
- Rationale: Addressing review feedback

**Proposed Actions**:
1. Commit uncommitted changes
2. Update PR description
3. Push changes

Proceed? (yes/no)
```

---

## Failure Handling

### Decision Tree (MUST follow)

**JIRA/MCP server fetch fails**:
→ Abort; prompt: "JIRA issue fetch failed (MCP server unavailable or authentication issue). Please provide issue details manually or fix MCP configuration. Retry? (yes/no)"

**Labels fetch fails**:
→ Abort; prompt: "Label fetch failed. Provide label list manually or fix authentication. Retry? (yes/no)"

**Issue fetch incomplete**:
→ Ask: "Missing acceptance criteria in issue. Provide criteria or proceed with inferred? (provide/proceed)"

**Coverage below threshold**:
→ Add more tests; re-run coverage; block commit until ≥80% satisfied

**Missing DCO sign-off**:
→ Block commit; request: "Commits require DCO sign-off. Provide full name and email for Signed-off-by line."

**Protected file modification attempt**:
→ Reject immediately; restate: "File '<filename>' is protected. Explicit user authorization required. Approve modification? (yes/no)"

**Test failures**:
→ Analyze failures; fix code or tests; re-run; do not proceed until green

**Lint failures**:
→ Run `bundle exec cookstyle -a` for auto-fixes; manually fix remaining; re-run until passing

**Merge conflicts**:
→ Inform user; request: "Merge conflicts detected. Resolve manually or provide conflict resolution strategy."

---

## Glossary

- **Changed Lines Coverage**: Portion of modified/added lines executed by test assertions
- **Implementation Plan Freeze Point**: No code changes permitted until user approves plan with "yes"
- **Protected Files**: Policy-restricted assets requiring explicit user authorization to modify
- **Idempotent Re-entry**: Resuming workflow without creating duplicate or conflicting state
- **Risk Classification**: Qualitative impact assessment (Low/Moderate/High) based on scope and breaking potential
- **Rollback Strategy**: Concrete, actionable reversal method (commit revert, feature toggle, configuration change)
- **DCO**: Developer Certificate of Origin - sign-off confirming legal right to contribute code
- **Expeditor**: Chef's CI/CD automation system for building, testing, and releasing software
- **Omnibus**: Full-stack installer packaging system for multi-platform distribution
- **Cookstyle**: Ruby linting tool based on RuboCop with Chef-specific rules
- **Test Kitchen**: Integration testing framework for Chef cookbooks and infrastructure code

---

## Quick Reference Commands

### Development Workflow

```bash
# Setup
git clone https://github.com/chef/chef.git
cd chef
bundle install

# Create feature branch
git checkout -b <BRANCH_NAME>

# Run tests
bundle exec rake spec:unit              # Unit tests
bundle exec rake component_specs        # Component tests
bundle exec rake spec:functional        # Functional tests
bundle exec rspec spec/unit/path/to/specific_spec.rb  # Specific test

# Lint
bundle exec cookstyle                   # Check style
bundle exec cookstyle -a                # Auto-fix issues

# Test Kitchen
cd kitchen-tests
kitchen list                            # List test suites
kitchen test <SUITE>                    # Run specific suite
kitchen converge <SUITE>                # Converge only
kitchen verify <SUITE>                  # Verify only

# Commit with DCO
git add .
git commit -m "feat(resource): add new property (gh-123)

Added encoding property to file resource for non-UTF8 support.

Issue: gh-123
Signed-off-by: Your Name <your.email@example.com>"

# Push and create PR
git push -u origin <BRANCH_NAME>
gh pr create --base main --head <BRANCH_NAME> --title "gh-123: Brief description" --draft

# Add labels
gh pr edit <PR_NUMBER> --add-label "Aspect: Stability"
gh pr edit <PR_NUMBER> --add-label "Expeditor: Skip Omnibus"

# Convert draft to ready
gh pr ready <PR_NUMBER>
```

### Troubleshooting

```bash
# Check Ruby version
ruby --version                          # Should be 3.1+

# Clean and reinstall dependencies
rm -rf vendor/bundle .bundle
bundle install

# Check for syntax errors
ruby -c lib/chef/path/to/file.rb

# Run single test with backtrace
bundle exec rspec spec/unit/path/to/spec.rb --backtrace

# Debug with binding.pry
# Add `binding.pry` in code, then run test
bundle exec rspec spec/unit/path/to/spec.rb
```

---

## AI Conduct

AI MUST:
- Honor all user confirmation gates ("yes/no" prompts)
- Escalate ambiguities with blocking questions
- Preserve safety constraints (no autonomous merging, no Protected File edits)
- Provide accurate, complete mappings of changes to tests
- Request DCO information if missing
- Apply appropriate labels based on change type
- Follow Chef Ruby style guide and community conventions

AI MUST NOT:
- Merge pull requests autonomously
- Fabricate issue data or make assumptions about requirements
- Edit Protected Files without explicit approval
- Skip test coverage validation
- Proceed without "yes" confirmation at gates
- Force-push to protected branches
- Bypass Expeditor automation controls


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
