#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Shared config filename used by both validation and error messages.
CSPELL_CONFIG_FILE = "cspell.json".freeze unless defined?(CSPELL_CONFIG_FILE)
SPELLCHECK_STRUCTURED_LOGS_ENV = "SPELLCHECK_STRUCTURED_LOGS".freeze unless defined?(SPELLCHECK_STRUCTURED_LOGS_ENV)
require "json"

namespace :spellcheck do
  # Helper to read a file with 1 retry for transient failures (lock/permission issues).
  # Returns file content on success or raises StandardError if retries exhausted.
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

  task run: :prereqs do
    sh 'cspell lint --no-progress "**/*"'
  end

  task prereqs: %i{cspell_check config_check}

  task :config_check do
    op_name = "spellcheck_config_check"
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    structured_logs_enabled = ENV.fetch(SPELLCHECK_STRUCTURED_LOGS_ENV, "1") != "0"

    emit_structured_log = lambda do |status|
      next unless structured_logs_enabled

      elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000.0
      puts format("op=%s status=%s elapsed_ms=%.3f", op_name, status, elapsed_ms)
    end

    begin
      # Read the config directly and rescue missing-file errors to avoid a redundant pre-check.
      config_content = read_file_with_retry(CSPELL_CONFIG_FILE)
    rescue Errno::ENOENT
      emit_structured_log.call("error")
      abort "Spellcheck config file '#{CSPELL_CONFIG_FILE}' not found, skipping spellcheck"
    rescue StandardError
      emit_structured_log.call("error")
      abort "Failed to parse config file '#{CSPELL_CONFIG_FILE}', skipping spellcheck"
    end

    begin
      parsed_config = JSON.parse(config_content)
    rescue JSON::ParserError
      emit_structured_log.call("error")
      abort "Failed to parse config file '#{CSPELL_CONFIG_FILE}', skipping spellcheck"
    end

    # cspell expects a JSON object config; reject parseable but invalid top-level types.
    unless parsed_config.is_a?(Hash)
      emit_structured_log.call("error")
      abort "Spellcheck config file '#{CSPELL_CONFIG_FILE}' must contain a JSON object"
    end

    emit_structured_log.call("ok")
  end

  task :cspell_check do
    cspell_version = begin
                       `cspell --version`
                     rescue
                       nil
                     end

    cspell_version.is_a?(String) || abort(<<~INSTALL_CSPELL)
          cspell is needed to run the spellcheck tasks. Run `npm install -g cspell` to install.
          For more information: https://www.npmjs.com/package/cspell
    INSTALL_CSPELL
  end
end

desc "Run spellcheck on the project."
task spellcheck: "spellcheck:run"
