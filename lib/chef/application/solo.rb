#
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Mark Mzyk (mmzyk@chef.io)
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

require_relative "base"
require_relative "../../chef"
require_relative "client"
require "fileutils" unless defined?(FileUtils)
require "pathname" unless defined?(Pathname)
require "chef-utils" unless defined?(ChefUtils::CANARY)

# DO NOT MAKE EDITS, see Chef::Application::Base
#
# Do not reference this class it will be removed in Chef-16
#
# @deprecated use Chef::Application::Client instead, this will be removed in Chef-16
#
class Chef::Application::Solo < Chef::Application::Base

  option :config_file,
    short: "-c CONFIG",
    long: "--config CONFIG",
    default: Chef::Config.platform_specific_path("#{ChefConfig::Config.etc_chef_dir}/solo.rb"),
    description: "The configuration file to use."

  unless ChefUtils.windows?
    option :daemonize,
      short: "-d",
      long: "--daemonize",
      description: "Daemonize the process.",
      proc: lambda { |p| true }
  end

  option :recipe_url,
    short: "-r RECIPE_URL",
    long: "--recipe-url RECIPE_URL",
    description: "Pull down a remote gzipped tarball of recipes and untar it to the cookbook cache."

  # Get this party started
  def run(enforce_license: false)
    setup_signal_handlers
    reconfigure
    check_license_acceptance if enforce_license
    for_ezra if Chef::Config[:ez]
    if !Chef::Config[:solo_legacy_mode]
      Chef::Application::Client.new.run
    else
      setup_application
      run_application
    end
  end

  def reconfigure
    super

    load_dot_d(Chef::Config[:solo_d_dir]) if Chef::Config[:solo_d_dir]

    set_specific_recipes

    Chef::Config[:fips] = config[:fips] if config.key? :fips

    Chef::Config[:solo] = true

    if !Chef::Config[:solo_legacy_mode]
      # Because we re-parse ARGV when we move to chef-client, we need to tidy up some options first.
      ARGV.delete("--ez")

      # For back compat reasons, we need to ensure that we try and use the cache_path as a repo first
      Chef::Log.trace "Current chef_repo_path is #{Chef::Config.chef_repo_path}"

      if !Chef::Config.key?(:cookbook_path) && !Chef::Config.key?(:chef_repo_path)
        Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Chef::Config[:cache_path])
      end

      Chef::Config[:local_mode] = true
      Chef::Config[:listen] = false
    else
      configure_legacy_mode!
    end
  end

  def configure_legacy_mode!
    if Chef::Config[:daemonize]
      Chef::Config[:interval] ||= 1800
    end

    # supervisor processes are enabled by default for interval-running processes but not for one-shot runs
    if Chef::Config[:client_fork].nil?
      Chef::Config[:client_fork] = !!Chef::Config[:interval]
    end

    if Chef::Config[:interval]
      if Chef::Platform.windows?
        Chef::Application.fatal!(windows_interval_error_message)
      elsif !Chef::Config[:client_fork]
        Chef::Application.fatal!(unforked_interval_error_message)
      end
    end

    if Chef::Config[:recipe_url]
      cookbooks_path = Array(Chef::Config[:cookbook_path]).detect { |e| Pathname.new(e).cleanpath.to_s =~ %r{/cookbooks/*$} }
      recipes_path = File.expand_path(File.join(cookbooks_path, ".."))

      if Chef::Config[:delete_entire_chef_repo]
        Chef::Log.trace "Cleanup path #{recipes_path} before extract recipes into it"
        FileUtils.rm_rf(recipes_path, secure: true)
      end
      Chef::Log.trace "Creating path #{recipes_path} to extract recipes into"
      FileUtils.mkdir_p(recipes_path)
      tarball_path = File.join(recipes_path, "recipes.tgz")
      fetch_recipe_tarball(Chef::Config[:recipe_url], tarball_path)
      Mixlib::Archive.new(tarball_path).extract(Chef::Config.chef_repo_path, perms: false, ignore: /^\.$/)
    end

    # json_attribs should be fetched after recipe_url tarball is unpacked.
    # Otherwise it may fail if points to local file from tarball.
    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @chef_client_json = config_fetcher.fetch_json
    end
  end

end
