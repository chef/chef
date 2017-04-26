#
# Copyright:: Copyright (c) 2016-2017, Chef Software Inc.
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

require_relative "../version_policy"
require "fileutils"

desc "Tasks to work with the main Gemfile and Gemfile.<platform>"
namespace :bundle do
  desc "Update Gemfile.lock and all Gemfile.<platform>.locks (or one or more gems via bundle:update gem1 gem2 ...)."
  task :update, [:args] do |t, rake_args|
    args = rake_args[:args] || ""
    Bundler.with_clean_env do
      sh "bundle update #{args}"
    end
  end

  desc "Conservatively update Gemfile.lock and all Gemfile.<platform>.locks"
  task :install, [:args] do |t, rake_args|
    args = rake_args[:args] || ""
    args = rake_args[:args] || ""
    Bundler.with_clean_env do
      sh "bundle install #{args}"
    end
  end

  def parse_bundle_outdated(bundle_outdated_output)
    result = []
    bundle_outdated_output.each_line do |line|
      if line =~ /^\s*\* (.+) \(newest ([^,]+), installed ([^,)])*/
        gem_name, newest_version, installed_version = $1, $2, $3
        result << [ line, gem_name ]
      end
    end
    result
  end

  # Find out if we're using the latest gems we can (so we don't regress versions)
  desc "Check for gems that are not at the latest released version, and report if anything not in ACCEPTABLE_OUTDATED_GEMS (version_policy.rb) is out of date."
  task :outdated do
    bundle_outdated = ""
    Bundler.with_clean_env do
      bundle_outdated = `bundle outdated`
      puts bundle_outdated
    end
    outdated_gems = parse_bundle_outdated(bundle_outdated).map { |line, gem_name| gem_name }
    outdated_gems = outdated_gems.reject { |gem_name| ACCEPTABLE_OUTDATED_GEMS.include?(gem_name) }
    unless outdated_gems.empty?
      raise "ERROR: outdated gems: #{outdated_gems.join(", ")}. Either fix them or add them to ACCEPTABLE_OUTDATED_GEMS in #{__FILE__}."
    end
  end
end

desc "Run bundle with arbitrary args"
task :bundle, [:args] do |t, rake_args|
  args = rake_args[:args] || ""
  Bundler.with_clean_env do
    sh "bundle #{args}"
  end
end
