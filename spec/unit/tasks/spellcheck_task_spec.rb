# frozen_string_literal: true

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

require "spec_helper"
require "rake"
require "tmpdir"
require "fileutils"

describe "spellcheck rake tasks" do
  let(:tasks_file) { File.expand_path("../../../tasks/spellcheck.rb", __dir__) }

  def with_env(var, value)
    old_value = ENV[var]
    ENV[var] = value
    yield
  ensure
    if old_value.nil?
      ENV.delete(var)
    else
      ENV[var] = old_value
    end
  end

  around do |example|
    original_dir = Dir.pwd
    tmpdir = Dir.mktmpdir("spellcheck-task-spec")

    begin
      # Isolate the task run in a temporary working dir so each example is deterministic.
      Dir.chdir(tmpdir)
      Rake.application = Rake::Application.new
      load tasks_file
      example.run
    ensure
      Dir.chdir(original_dir)
      Rake.application = Rake::Application.new
      FileUtils.remove_entry(tmpdir)
    end
  end

  # Missing file should always produce the same fast-fail message.
  it "aborts when cspell.json is missing" do
    expect { Rake::Task["spellcheck:config_check"].invoke }
      .to raise_error(SystemExit, /Spellcheck config file 'cspell.json' not found, skipping spellcheck/)
  end

  # Invalid JSON should be rejected with parse guidance.
  it "aborts when cspell.json is invalid json" do
    File.write("cspell.json", "{ invalid_json ")

    expect { Rake::Task["spellcheck:config_check"].invoke }
      .to raise_error(SystemExit, /Failed to parse config file 'cspell.json', skipping spellcheck/)
  end

  # Parseable JSON with wrong top-level type should be rejected.
  it "aborts when cspell.json top-level json type is not an object" do
    File.write("cspell.json", "[]")

    expect { Rake::Task["spellcheck:config_check"].invoke }
      .to raise_error(SystemExit, /Spellcheck config file 'cspell.json' must contain a JSON object/)
  end

  # Valid JSON should pass config validation without aborting.
  it "passes when cspell.json is valid json" do
    File.write("cspell.json", '{"version":"0.2"}')

    expect { Rake::Task["spellcheck:config_check"].invoke }.not_to raise_error
  end

  it "emits structured logs when toggle is on" do
    with_env("SPELLCHECK_STRUCTURED_LOGS", "1") do
      File.write("cspell.json", '{"version":"0.2"}')

      expect { Rake::Task["spellcheck:config_check"].invoke }
        .to output(/op=spellcheck_config_check status=ok elapsed_ms=\d+\.\d{3}/).to_stdout
    end
  end

  it "does not emit structured logs when toggle is off" do
    with_env("SPELLCHECK_STRUCTURED_LOGS", "0") do
      File.write("cspell.json", '{"version":"0.2"}')

      expect { Rake::Task["spellcheck:config_check"].invoke }.to output("").to_stdout
    end
  end

  # Resilience: Transient file read failure succeeds on retry
  it "recovers from transient file read failure via retry" do
    File.write("cspell.json", '{"version":"0.2"}')
    call_count = 0

    # Simulate transient read failure on first attempt, success on retry
    allow(File).to receive(:read).and_wrap_original do |original_method, *args|
      call_count += 1
      if call_count == 1
        raise IOError, "Device or resource busy (transient)"
      end

      original_method.call(*args)
    end

    expect { Rake::Task["spellcheck:config_check"].invoke }.not_to raise_error
    expect(call_count).to eq(2) # Verify retry was attempted
  end

  # Resilience: Permanent file read failure after retries exhausted
  it "aborts after retry exhaustion on permanent read failure" do
    File.write("cspell.json", '{"version":"0.2"}')

    # Simulate permanent read failure (all retries fail)
    allow(File).to receive(:read).and_raise(IOError, "Permission denied")

    expect { Rake::Task["spellcheck:config_check"].invoke }
      .to raise_error(SystemExit, /Failed to parse config file 'cspell.json', skipping spellcheck/)
  end
end
