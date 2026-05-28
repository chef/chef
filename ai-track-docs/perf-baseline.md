# Performance Baseline

## Benchmark Target

- Task: `spellcheck:config_check`
- Module: `tasks/spellcheck.rb`
- Driver: `scripts/spellcheck_config_check_benchmark.rb`

## Command

```bash
cd /Users/rchawda/github.com/chef/chef
for i in 1 2 3; do
  echo "RUN:$i"
  bundle exec ruby scripts/spellcheck_config_check_benchmark.rb
  echo
done
```

## Baseline Results (2026-05-19)

Environment:

- Ruby: 3.4.1
- Warmup: 20
- Iterations per run: 200

Run 1:

- mean: 0.040 ms
- stddev: 0.006 ms
- CV: 15.37%
- p50: 0.038 ms
- p95: 0.051 ms
- min/max: 0.032 / 0.065 ms

Run 2:

- mean: 0.040 ms
- stddev: 0.004 ms
- CV: 10.54%
- p50: 0.039 ms
- p95: 0.048 ms
- min/max: 0.035 / 0.063 ms

Run 3:

- mean: 0.040 ms
- stddev: 0.023 ms
- CV: 57.37%
- p50: 0.035 ms
- p95: 0.051 ms
- min/max: 0.033 / 0.246 ms

## Variance Notes

- Typical latency is stable around 0.040 ms mean and ~0.05 ms p95.
- One long-tail outlier was observed (0.246 ms max), likely scheduler/background noise.
- For this tiny workload, occasional outliers can inflate CV without shifting p95 significantly.

## Practical Guardrail

- Expected mean: ~0.040 ms/invocation
- Expected p95: ~0.05 ms
- Acceptable occasional outlier: up to ~0.25 ms

## Optimization Evidence (2026-05-28)

### Candidate Bottleneck

- Path: `spellcheck:config_check` in `tasks/spellcheck.rb`
- Finding: the task performed a pre-check (`File.readable?`) before reading and required `json` on each invocation.
- Optimization: remove redundant pre-check and load `json` at file load time instead of per-task invocation.

### Measurement Method

- Command:

```bash
cd /Users/rchawda/github.com/chef/chef
for i in 1 2 3; do
  SPELLCHECK_STRUCTURED_LOGS=0 BENCH_WARMUP=50 BENCH_ITERATIONS=5000 \
    bundle exec ruby scripts/spellcheck_config_check_benchmark.rb
done
```

- Environment:
  - Ruby: 3.4.1
  - Warmup: 50
  - Iterations: 5000
  - Structured logs: disabled (`SPELLCHECK_STRUCTURED_LOGS=0`) to reduce I/O noise

### Before vs After (mean_ms)

- Before: 0.040, 0.038, 0.041
- After: 0.026, 0.027, 0.026

Computed summary:

- Before average mean: 0.0397 ms
- After average mean: 0.0263 ms
- Delta: -0.0134 ms
- Relative improvement: ~33.6%

### Tail Latency (p95_ms)

- Before: 0.055, 0.044, 0.050
- After: 0.030, 0.031, 0.030

### Why This Is Safe

- The task still aborts with the same user-facing messages for:
  - missing config file
  - invalid JSON
  - invalid top-level type
- Existing unit tests for these behaviors continue to pass.
- No public API shape or task interface changed.
