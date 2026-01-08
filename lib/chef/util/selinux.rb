#
# Author:: Sean O'Meara
# Author:: Kevin Keane
# Author:: Lamont Granquist (<lamont@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright 2013-2016, North County Tech Center, LLC
#
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

require_relative "../mixin/shell_out"
require_relative "../mixin/which"

class Chef
  class Util
    #
    # IMPORTANT: We assume that selinux utilities are installed on an
    # selinux enabled server. Provisioning an selinux enabled server
    # without selinux utilities is not supported.
    #
    module Selinux

      include Chef::Mixin::ShellOut
      include Chef::Mixin::Which

      # We want to initialize below variables once during a
      # chef-client run therefore they are class variables.
      @@selinux_enabled = nil
      @@restorecon_path = nil
      @@selinuxenabled_path = nil

      def selinux_enabled?
        @@selinux_enabled = check_selinux_enabled? if @@selinux_enabled.nil?
        @@selinux_enabled
      end

      def restore_security_context(file_path, recursive = false)
        if restorecon_path
          restorecon_flags = [ "-R" ]
          restorecon_flags << "-r" if recursive
          restorecon_flags << file_path
          Chef::Log.trace("Restoring selinux security content with #{restorecon_path}")
          shell_out!(restorecon_path, restorecon_flags)
        else
          Chef::Log.warn "Can not find 'restorecon' on the system. Skipping selinux security context restore."
        end
      end

      private

      def restorecon_path
        @@restorecon_path = which("restorecon") if @@restorecon_path.nil?
        @@restorecon_path
      end

      def selinuxenabled_path
        @@selinuxenabled_path = which("selinuxenabled") if @@selinuxenabled_path.nil?
        @@selinuxenabled_path
      end

      def check_selinux_enabled?
        if selinuxenabled_path
          cmd = shell_out!(selinuxenabled_path, returns: [0, 1])
          case cmd.exitstatus
          when 1
            false
          when 0
            true
          else
            raise "Unknown exit code from command #{selinuxenabled_path}: #{cmd.exitstatus}"
          end
        else
          # We assume selinux is not enabled if selinux utils are not
          # installed.
          false
        end
      end

    end
  end
end
