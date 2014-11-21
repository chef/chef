#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

require 'rubygems'
require 'rake'

CHEF_ROOT = File.join(File.dirname(__FILE__), "..")

begin
  require 'rspec/core/rake_task'

  task :default => :spec

  desc "Run standard specs (minus long running specs)"
  RSpec::Core::RakeTask.new(:spec) do |t|
    # right now this just limits to functional + unit, but could also remove
    # individual tests marked long-running
    t.pattern = FileList['spec/{functional,unit}/**/*_spec.rb']
  end

  namespace :spec do
    desc "Run all specs in spec directory with RCov"
    RSpec::Core::RakeTask.new(:rcov) do |t|
      t.pattern = FileList['spec/**/*_spec.rb']
      t.rcov = true
      t.rcov_opts = lambda do
        IO.readlines("#{CHEF_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end

    desc "Run all specs in spec directory"
    RSpec::Core::RakeTask.new(:all) do |t|
      t.pattern = FileList['spec/**/*_spec.rb']
    end

    desc "Print Specdoc for all specs"
    RSpec::Core::RakeTask.new(:doc) do |t|
      t.rspec_opts = ["--format", "specdoc", "--dry-run"]
      t.pattern = FileList['spec/**/*_spec.rb']
    end

    desc "Run the specs under spec/unit with activesupport loaded"
    RSpec::Core::RakeTask.new(:activesupport) do |t|
      t.rspec_opts = ["--require active_support/core_ext"]
      t.pattern = FileList['spec/unit/**/*_spec.rb']
    end

    [:unit, :functional, :integration, :stress].each do |sub|
      desc "Run the specs under spec/#{sub}"
      RSpec::Core::RakeTask.new(sub) do |t|
        t.pattern = FileList["spec/#{sub}/**/*_spec.rb"]
      end
    end
  end
rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
