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
