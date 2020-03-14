#
# Copyright:: 2019-2020 Chef Software, Inc.
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

require "fileutils"

name "more-ruby-cleanup"

skip_transitive_dependency_licensing true
license :project_license

source path: "#{project.files_path}/#{name}"

build do
  block "Removing additional non-code files from installed gems" do
    # find the embedded ruby gems dir and clean it up for globbing
    target_dir = "#{install_dir}/embedded/lib/ruby/gems/*/gems".tr('\\', "/")
    files = %w{
      .appveyor.yml
      .autotest
      .github
      .kokoro
      Appraisals
      autotest/*
      bench
      benchmark
      benchmarks
      doc
      doc-api
      docs
      donate.png
      ed25519.png
      example
      examples
      ext
      frozen_old_spec
      Gemfile.devtools
      Gemfile.lock
      Gemfile.travis
      logo.png
      man
      rakelib
      release-script.txt
      sample
      samples
      site
      test
      tests
      travis_build_script.sh
      warning.txt
      website
      yard-template
      minitest
      INSTALL.txt
      features
      *Upgrade.md
      vendor
    }

    Dir.glob(Dir.glob("#{target_dir}/*/{#{files.join(",")}}")).each do |f|
      # chef stores the powershell dlls in the ext dir
      next if File.basename(File.expand_path("..", f)).start_with?("chef-")

      puts "Deleting #{f}"
      FileUtils.rm_rf(f)
    end
  end
end