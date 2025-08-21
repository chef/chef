#!/usr/bin/env ruby

# Always output a valid Buildkite pipeline
puts <<~YAML
  steps:
    - label: ":rocket: Adhoc Test Step"
      command: echo "Running adhoc test step!"
YAML
