# Error Inspector Instrumentation

This note documents the debug instrumentation pattern used in `lib/chef/formatters/error_inspectors`.

## Pattern

Each error inspector logs a single debug line at the start of `add_explanation` through the shared `Instrumentation` helper.

The log line includes:

- `event="error_inspector.add_explanation"`
- `inspector="..."`
- `exception_class="..."`
- optional context fields such as `node_name`, `path`, `action`, `resource`, `cookbook_count`, and `expanded_run_list_count`

## Validation

Run the consistency script:

```bash
scripts/validate_error_inspector_instrumentation.sh
```

Run focused specs when the bundle is available:

```bash
bundle exec rspec spec/unit/formatters/error_inspectors/compile_error_inspector_spec.rb \
  spec/unit/formatters/error_inspectors/run_list_expansion_error_inspector_spec.rb \
  spec/unit/formatters/error_inspectors/node_load_error_inspector_spec.rb \
  spec/unit/formatters/error_inspectors/registration_error_inspector_spec.rb
```

Sample debug output format:

```text
event="error_inspector.add_explanation" inspector="Chef::Formatters::ErrorInspectors::NodeLoadErrorInspector" exception_class="RuntimeError" node_name="test-node.example.com"
```
