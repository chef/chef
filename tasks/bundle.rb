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
      bundle "install #{args}", delete_gemfile_lock: true
      platforms.each do |platform|
        puts ""
        puts "-------------------------------------------------------------------"
        puts "Updating Gemfile.#{platform}.lock ..."
        puts "-------------------------------------------------------------------"
        bundle "lock", gemfile: "Gemfile.#{platform}", platform: platform, delete_gemfile_lock: true
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
        puts ""
        puts "-------------------------------------------------------------------"
        puts "Updating Gemfile.#{platform}.lock (conservatively) ..."
        puts "-------------------------------------------------------------------"
        bundle "lock", gemfile: "Gemfile.#{platform}", platform: platform
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
