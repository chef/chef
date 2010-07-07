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
  require 'spec/rake/spectask'

  task :default => :spec

  desc "Run all specs in spec directory"
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_opts = ['--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList['spec/unit/**/*_spec.rb']
  end

  desc "Run all functional specs (in functional/ directory)"
  Spec::Rake::SpecTask.new(:functional) do |t|
    t.spec_opts = ['--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList['spec/functional/**/*_spec.rb']
  end

  namespace :spec do
    desc "Run all specs in spec directory with RCov"
    Spec::Rake::SpecTask.new(:rcov) do |t|
      t.spec_opts = ['--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
      t.spec_files = FileList['spec/**/*_spec.rb']
      t.rcov = true
      t.rcov_opts = lambda do
        IO.readlines("#{CHEF_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end

    desc "Print Specdoc for all specs"
    Spec::Rake::SpecTask.new(:doc) do |t|
      t.spec_opts = ["--format", "specdoc", "--dry-run"]
      t.spec_files = FileList['spec/**/*_spec.rb']
    end

    [:unit].each do |sub|
      desc "Run the specs under spec/#{sub}"
      Spec::Rake::SpecTask.new(sub) do |t|
        t.spec_opts = ['--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList["spec/#{sub}/**/*_spec.rb"]
      end
    end

    desc "Translate/upgrade specs using the built-in translator"
    task :translate do
      translator = ::Spec::Translator.new
      dir = CHEF_ROOT + '/spec'
      translator.translate(dir, dir)
    end
  end
rescue LoadError
  STDERR.puts "\n*** Rspec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
