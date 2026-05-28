# Scoped Strictness: spec/unit/tasks

## Scope

- Path: `spec/unit/tasks/**/*.rb`
- Strict config: `.rubocop-strict-spec-unit-tasks.yml`
- Added strict cop: `Style/FrozenStringLiteralComment`

## Why This Rule

- High signal and low noise for Ruby files.
- Small, reviewable scope that does not block unrelated paths.

## Local Validation

```bash
cd /Users/rchawda/github.com/chef/chef
bundle exec cookstyle --chefstyle -c .rubocop-strict-spec-unit-tasks.yml spec/unit/tasks
bundle exec rspec spec/unit/tasks/spellcheck_task_spec.rb
```

## CI Enforcement

- Workflow: `.github/workflows/lint.yml`
- Job: `cookstyle-strict-spec-unit-tasks`
- Command: `bundle exec cookstyle --chefstyle -c .rubocop-strict-spec-unit-tasks.yml spec/unit/tasks`

## Suppressions and Rationale

- No suppressions were required for this scoped strictness increase.
- Rationale: all findings in the chosen scope were fixed directly.

## Rollback

- Remove `cookstyle-strict-spec-unit-tasks` job from `.github/workflows/lint.yml`.
- Remove `.rubocop-strict-spec-unit-tasks.yml`.
- If needed, remove `# frozen_string_literal: true` from `spec/unit/tasks/spellcheck_task_spec.rb`.
