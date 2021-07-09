#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
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
require "rake"

begin
  require "rspec/core/rake_task"

  desc "Run specs for Chef's Gem Components"
  task :component_specs do
    %w{chef-utils chef-config knife}.each do |gem|
      Dir.chdir(gem) do
        puts "--- Running #{gem} specs"
        Bundler.with_unbundled_env do
          puts "Executing tests in #{Dir.pwd}:"
          sh("bundle install --jobs=3 --retry=3 --path=../vendor/bundle")
          sh("bundle exec rake spec")
        end
      end
    end
  end

  task default: :spec

  task spec: :component_specs

  desc "Run all chef specs in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
    t.rspec_opts = %w{--profile}
    t.pattern = FileList["spec/**/*_spec.rb"]
  end

  namespace :spec do
    desc "Run all chef specs in spec directory"
    RSpec::Core::RakeTask.new(:all) do |t|
      t.verbose = false
      t.rspec_opts = %w{--profile}
      t.pattern = FileList["spec/**/*_spec.rb"]
    end

    desc "Print Specdoc for all specs"
    RSpec::Core::RakeTask.new(:doc) do |t|
      t.verbose = false
      t.rspec_opts = %w{--format specdoc --dry-run --profile}
      t.pattern = FileList["spec/**/*_spec.rb"]
    end

    desc "Run chef's node and role unit specs with activesupport loaded"
    RSpec::Core::RakeTask.new(:activesupport) do |t|
      t.verbose = false
      t.rspec_opts = %w{--require active_support/core_ext --profile}
      # Only node_spec and role_spec specifically have issues, target those tests
      t.pattern = FileList["spec/unit/node_spec.rb", "spec/unit/role_spec.rb"]
    end

    %i{unit functional integration stress}.each do |sub|
      desc "Run the chef specs under spec/#{sub}"
      RSpec::Core::RakeTask.new(sub) do |t|
        puts "--- Running chef #{sub} specs"
        t.verbose = false
        t.rspec_opts = %w{--profile}
        t.pattern = FileList["spec/#{sub}/**/*_spec.rb"]
      end
    end
  end
rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
