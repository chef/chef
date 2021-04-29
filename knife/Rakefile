# Copyright:: Copyright (c) Chef Software Inc.
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

require "rubygems"
require "bundler/gem_tasks"
Bundler::GemHelper.install_tasks

begin
  require "rspec/core/rake_task"

  desc "Run all knife specs"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
    t.rspec_opts = %w{--profile}
    t.pattern = FileList["spec/**/*_spec.rb"]

  end
rescue LoadError
  puts "rspec not available. bundle install first to make sure all dependencies are installed."
end
