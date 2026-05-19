# Resilience: File Read Retry

## Overview

Added a minimal retry mechanism to the spellcheck config validation task to handle transient file read failures (e.g., temporary lock contention or permission issues).

## Implementation

### Helper Function: `read_file_with_retry`

**Location**: [tasks/spellcheck.rb](../tasks/spellcheck.rb#L23-L37)

```ruby
def read_file_with_retry(path, max_attempts = 2)
  attempt = 0
  last_error = nil

  loop do
    attempt += 1
    begin
      return File.read(path)
    rescue StandardError => e
      last_error = e
      raise if attempt >= max_attempts
      sleep(0.01) # brief backoff before retry
    end
  end
end
```

**Features**:
- **1 retry**: 2 total attempts (initial + 1 retry)
- **Brief backoff**: 10ms sleep between attempts
- **Broad error handling**: Catches any StandardError on file read

### Usage in `config_check` Task

**Location**: [tasks/spellcheck.rb](../tasks/spellcheck.rb#L53-L57)

```ruby
config_content = read_file_with_retry(CSPELL_CONFIG_FILE)
parsed_config = JSON.parse(config_content)
```

Transient errors are absorbed on retry; permanent errors are surfaced via existing error handling.

## Test Coverage

Added 2 resilience tests in [spec/unit/tasks/spellcheck_task_spec.rb](../spec/unit/tasks/spellcheck_task_spec.rb#L101-L131):

| Test | Scenario | Validation |
|------|----------|-----------|
| `recovers from transient file read failure via retry` | First read fails with IOError, second succeeds | Verifies retry occurs (call_count == 2) |
| `aborts after retry exhaustion on permanent read failure` | All retries fail with permission denied | Verifies error is still surfaced with correct message |

**Test Results**: ✅ 8 examples, 0 failures (6 original + 2 resilience tests)

## Impact

- **Resilience**: Handles transient file lock/permission issues without user intervention
- **Backward Compatible**: No changes to task API or error messaging
- **Minimal**: 12 lines of code + 30 lines of test coverage
- **Performance**: Negligible (10ms backoff only on transient failure)

## Observability

- Error conditions still produce structured logs with error status
- Transient failures are transparent to callers (succeed silently after retry)
- Permanent failures maintain existing error messages for CI troubleshooting
