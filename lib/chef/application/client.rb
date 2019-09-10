#
# Author:: AJ Christensen (<aj@chef.io)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Mark Mzyk (mmzyk@chef.io)
# Copyright:: Copyright 2008-2019, Chef Software Inc.
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
require_relative "../handler/error_report"
require_relative "../workstation_config_loader"
require "uri" unless defined?(URI)

# DO NOT MAKE EDITS, see Chef::Application::Base
#
# External code may call / subclass or make references to this class.
#
class Chef::Application::Client < Chef::Application::Base

  option :config_file,
    short: "-c CONFIG",
    long: "--config CONFIG",
    description: "The configuration file to use."

  unless Chef::Platform.windows?
    option :daemonize,
      short: "-d [WAIT]",
      long: "--daemonize [WAIT]",
      description: "Daemonize the process. Accepts an optional integer which is the " \
        "number of seconds to wait before the first daemonized run.",
      proc: lambda { |wait| wait =~ /^\d+$/ ? wait.to_i : true }
  end

  option :pid_file,
    short: "-P PID_FILE",
    long: "--pid PIDFILE",
    description: "Set the PID file location, for the #{Chef::Dist::CLIENT} daemon process. Defaults to /tmp/chef-client.pid.",
    proc: nil

  option :runlist,
    short: "-r RunlistItem,RunlistItem...",
    long: "--runlist RunlistItem,RunlistItem...",
    description: "Permanently replace current run list with specified items.",
    proc: lambda { |items|
      items = items.split(",")
      items.compact.map do |item|
        Chef::RunList::RunListItem.new(item)
      end
    }

  option :recipe_url,
    long: "--recipe-url=RECIPE_URL",
    description: "Pull down a remote archive of recipes and unpack it to the cookbook cache. Only used in local mode."

  def initialize(solo: false)
    @solo_flag = solo
    super()
  end

  def run(enforce_license: false)
    setup_signal_handlers
    reconfigure
    # setup_application does a Dir.chdir("/") and cannot come before reconfigure or many things break
    setup_application
    check_license_acceptance if enforce_license
    for_ezra if Chef::Config[:ez]
    if Chef::Config[:solo_legacy_mode]
      Chef::Application::Solo.new.run # FIXME: minimally we just need to reparse the cli and then run_application
    else
      run_application
    end
  end

  def configure_logging
    super
    Mixlib::Authentication::Log.use_log_devices( Chef::Log )
    Ohai::Log.use_log_devices( Chef::Log )
  end

end
