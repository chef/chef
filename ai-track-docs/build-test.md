# Build and Test

This quick reference focuses on local build and test workflows for macOS with bash.

## Prerequisites

- Ruby version required by the repository (see `.ruby-version` if present).
- Bundler.

## Install Dependencies

```bash
bundle install
```

## Common Test Commands

```bash
# Full test suite
bundle exec rake spec

# Unit tests only
bundle exec rake spec:unit

# Functional tests only
bundle exec rake spec:functional

# Integration tests only
bundle exec rake spec:integration
```

## Coverage

```bash
bundle exec ruby -e 'require "coverage"; Coverage.start(lines: true); require "rspec/core"; exit_code = RSpec::Core::Runner.run(["spec/unit"], $stderr, $stdout); result = Coverage.result; project = result.select { |file, _| file.start_with?(Dir.pwd + "/lib/") || file.start_with?(Dir.pwd + "/chef-config/lib/") || file.start_with?(Dir.pwd + "/chef-utils/lib/") }; covered = 0; total = 0; project.each_value do |stats| lines = stats[:lines] || []; lines.each { |n| next if n.nil?; total += 1; covered += 1 if n > 0 }; end; pct = total.zero? ? 0.0 : (covered * 100.0 / total); puts "TOTAL_COVERAGE=#{format("%.2f", pct)}%"; puts "COVERED_LINES=#{covered}"; puts "TOTAL_LINES=#{total}"; exit exit_code'
```

This reports line coverage for `lib/`, `chef-config/lib/`, and `chef-utils/lib/` while executing the full unit suite (`spec/unit`).

## Useful Quality/Validation Tasks

```bash
# Spelling task (if enabled)
bundle exec rake spellcheck

# Target mode validation tests
bundle exec rake test:target_mode
```

To view structured spellcheck logs (op/status/elapsed_ms):

```bash
bundle exec rake spellcheck 2>&1 | rg "op=spellcheck_"
```

## Notes

- Prefer `bundle exec` to ensure commands run against the project's locked gem set.
- If a task is not available in your checkout, list tasks with `bundle exec rake -T`.

## Dependency Notes

- Critical dependency inventory and minimal pinning guidance are documented in `ai-track-docs/dependency-notes.md`.
- Keep constraint changes minimal (no major upgrades) and validate with focused unit tests before broader CI runs.

## CI Reliability and Local Fallback

CI is configured via `.github/workflows/unit_specs.yml` and related workflows. If CI is unavailable, use the local fallback script that mirrors key CI setup steps (env vars, node fixtures, bundle install, targeted tests).

Quick fallback run:

```bash
cd /Users/rchawda/github.com/chef/chef
bash scripts/run_local_ci_tests.sh quick
```

Full fallback run (heavier, closer to CI unit coverage):

```bash
cd /Users/rchawda/github.com/chef/chef
bash scripts/run_local_ci_tests.sh full
```
