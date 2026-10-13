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

namespace :spellcheck do
  task run: :prereqs do
    sh "typos"
  end

  task prereqs: %i{typos_check config_check}

  task :config_check do
    config_file = "_typos.toml"

    unless File.readable?(config_file)
      abort "Spellcheck config file '#{config_file}' not found, skipping spellcheck"
    end
  end

  task :typos_check do
    typos_version = begin
                      `typos --version`
                    rescue
                      nil
                    end

    typos_version.is_a?(String) || abort(<<~INSTALL_TYPOS)
          typos is needed to run the spellcheck tasks. Run `brew install typos-cli`
          or `cargo install typos-cli` to install.
          For more information: https://github.com/crate-ci/typos
    INSTALL_TYPOS
  end
end

desc "Run spellcheck on the project."
task spellcheck: "spellcheck:run"
