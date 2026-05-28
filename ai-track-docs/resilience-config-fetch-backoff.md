# Resilience: Remote Config Fetch Backoff

## Overview

Added a minimal retry-with-exponential-backoff wrapper for remote config fetches in Chef::ConfigFetcher.
This improves reliability for transient network failures while preserving existing fatal behavior after retries are exhausted.

## External Call Site

- File: lib/chef/config_fetcher.rb
- Method: fetch_remote_config
- External call: Chef::HTTP::Simple#get("")

## Implementation

### Helper Module

- File: lib/chef/resilience/retry_with_backoff.rb
- API: Chef::Resilience::RetryWithBackoff.call(...)
- Behavior:
  - retries selected errors up to configured attempts
  - exponential backoff (base_delay * 2^(attempt-1))
  - optional retry callback for logging

### Integration

- fetch_remote_config now wraps http.get("") with the helper.
- Retryable errors are intentionally narrow:
  - SocketError
  - Timeout::Error
  - Errno::ETIMEDOUT
  - Errno::ECONNRESET

## Tuning Parameters

- REMOTE_FETCH_MAX_ATTEMPTS = 3
- REMOTE_FETCH_BASE_DELAY = 0.1 seconds
- Backoff sequence with defaults: 0.1s, 0.2s

## Failure Tests

Added tests in spec/unit/config_fetcher_spec.rb:

- retries transient timeout failures with backoff and succeeds
  - simulates two timeout failures followed by success
  - verifies sleep(0.1) then sleep(0.2)
- fails after retry exhaustion on transient timeout failures
  - simulates timeout on all attempts
  - verifies fatal error path remains unchanged

## Rollback

1. Remove require_relative "resilience/retry_with_backoff" and wrapper usage from lib/chef/config_fetcher.rb.
2. Remove lib/chef/resilience/retry_with_backoff.rb.
3. Remove the two retry/backoff tests from spec/unit/config_fetcher_spec.rb.
4. Remove this document.

This restores previous single-attempt remote fetch behavior.
