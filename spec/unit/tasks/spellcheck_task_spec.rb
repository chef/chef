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

  around do |example|
    original_dir = Dir.pwd
    tmpdir = Dir.mktmpdir("spellcheck-task-spec")

    begin
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

  it "aborts when cspell.json is missing" do
    expect { Rake::Task["spellcheck:config_check"].invoke }
      .to raise_error(SystemExit, /Spellcheck config file 'cspell.json' not found, skipping spellcheck/)
  end

  it "aborts when cspell.json is invalid json" do
    File.write("cspell.json", "{ invalid_json ")

    expect { Rake::Task["spellcheck:config_check"].invoke }
      .to raise_error(SystemExit, /Failed to parse config file 'cspell.json', skipping spellcheck/)
  end

  it "passes when cspell.json is valid json" do
    File.write("cspell.json", '{"version":"0.2"}')

    expect { Rake::Task["spellcheck:config_check"].invoke }.not_to raise_error
  end
end