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

namespace :spellcheck do
  task run: :prereqs do
    sh 'cspell lint --no-progress "**/*"'
  end

  task prereqs: %i{cspell_check config_check}

  task :config_check do
    require "json"

    # Fail fast with a clear message before attempting parse.
    unless File.readable?(CSPELL_CONFIG_FILE)
      abort "Spellcheck config file '#{CSPELL_CONFIG_FILE}' not found, skipping spellcheck"
    end

    begin
      JSON.parse(File.read(CSPELL_CONFIG_FILE))
    rescue StandardError
      # Keep this broad so malformed JSON and read-time errors are surfaced uniformly.
      abort "Failed to parse config file '#{CSPELL_CONFIG_FILE}', skipping spellcheck"
    end
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
