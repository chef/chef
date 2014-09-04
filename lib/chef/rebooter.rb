#
# Author:: Chris Doherty <cdoherty@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef, Inc.
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

require 'chef/dsl/reboot_pending'
require 'chef/log'
require 'chef/platform'

# this encapsulates any and all gnarly stuff needed to reboot the server.

# where should this file go in the hierarchy?
class Chef
  class Rebooter
    # below are awkward contortions to re-use the RebootPending code.
    include Chef::DSL::RebootPending
    include Chef::Mixin::ShellOut

    attr_reader :reboot_info

    # shims for RebootPending.
    attr_reader :node, :run_context

    def initialize(node)
      @node = node
      @run_context = node.run_context
      @reboot_info = node.run_context.reboot_info
    end

    def reboot!
      Chef::Log.warn "Totally would have rebooted here. #{@reboot_info.inspect}"
      cmd = if Chef::Platform.windows?
        "shutdown /r /t #{reboot_info[:delay_mins]} /c \"#{reboot_info[:reason]}\""
      else
        shutdown_time = reboot_info[:delay_mins] > 0 ? reboot_info[:reboot_timeout] : "now"
        "shutdown -r #{shutdown_time}"
      end
      Chef::Log.warn "Shutdown command: '#{cmd}'"
      # for ease of testing we are not yet actually rebooting.
      #shell_out!(cmd)
    end

    def self.reboot_if_needed!(node)
      @@rebooter ||= self.new(node)
      if @@rebooter.reboot_pending?
        @@rebooter.reboot!
      end
    end

  end
end