#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

require_relative "bundle_util"
require_relative "../version_policy"
require "fileutils"

desc "Tasks to work with the main Gemfile and Gemfile.<platform>"
namespace :bundle do
  desc "Update Gemfile.lock and all Gemfile.<platform>.locks (or one or more gems via bundle:update gem1 gem2 ...)."
  task :update, [:args] do |t, rake_args|
    extend BundleUtil
    args = rake_args[:args] || ""
    with_bundle_unfrozen do
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating Gemfile.lock ..."
      puts "-------------------------------------------------------------------"
      bundle "update #{args}"
      platforms.each do |platform|
        bundle "update #{args}", platform: platform
      end
    end
  end

  desc "Conservatively update Gemfile.lock and all Gemfile.<platform>.locks"
  task :install, [:args] do |t, rake_args|
    extend BundleUtil
    args = rake_args[:args] || ""
    with_bundle_unfrozen do
      puts ""
      puts "-------------------------------------------------------------------"
      puts "Updating Gemfile.lock ..."
      puts "-------------------------------------------------------------------"
      bundle "install #{args}"
      platforms.each do |platform|
        bundle "lock", platform: platform
      end
    end
  end

  # Find out if we're using the latest gems we can (so we don't regress versions)
  desc "Check for gems that are not at the latest released version, and report if anything not in ACCEPTABLE_OUTDATED_GEMS (version_policy.rb) is out of date."
  task :outdated do
    extend BundleUtil
    puts ""
    puts "-------------------------------------------------------------------"
    puts "Checking for outdated gems ..."
    puts "-------------------------------------------------------------------"
    # TODO check for outdated windows gems too
    with_bundle_unfrozen do
      bundle_outdated = bundle("outdated", extract_output: true)
      puts bundle_outdated
      outdated_gems = parse_bundle_outdated(bundle_outdated).map { |line, gem_name| gem_name }
      # Weed out the acceptable ones
      outdated_gems = outdated_gems.reject { |gem_name| ACCEPTABLE_OUTDATED_GEMS.include?(gem_name) }
      if outdated_gems.empty?
        puts ""
        puts "SUCCESS!"
      else
        raise "ERROR: outdated gems: #{outdated_gems.join(", ")}. Either fix them or add them to ACCEPTABLE_OUTDATED_GEMS in #{__FILE__}."
      end
    end
  end
end

desc "Run bundle with arbitrary args against the given platform; e.g. rake bundle[show]. No platform to run against the main bundle; bundle[show,windows] to run the windows one; bundle[show,*] to run against all non-default platforms."
task :bundle, [:args, :platform] do |t, rake_args|
  extend BundleUtil
  args = rake_args[:args] || ""
  platform = rake_args[:platform]
  with_bundle_unfrozen do
    if platform == "*"
      platforms.each do |platform|
        bundle args, platform: platform
      end
    elsif platform
      bundle args, platform: platform
    else
      bundle args
    end
  end
end
