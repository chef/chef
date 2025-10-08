#
# Author:: Adam Edwards (<adamed@chef.io>)
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

require_relative "script"
require_relative "../mixin/windows_architecture_helper"
require_relative "../win32/security" if ChefUtils.windows?
require "tempfile" unless defined?(Tempfile)

class Chef
  class Provider
    class WindowsScript < Chef::Provider::Script

      protected

      attr_accessor :script_file_path

      include Chef::Mixin::WindowsArchitectureHelper

      def target_architecture
        @target_architecture ||= if new_resource.architecture.nil?
                                   node_windows_architecture(run_context.node)
                                 else
                                   new_resource.architecture
                                 end
      end

      def basepath
        if forced_32bit_override_required?(run_context.node, target_architecture)
          wow64_directory
        else
          run_context.node["kernel"]["os_info"]["system_directory"]
        end
      end

      def with_wow64_redirection_disabled
        wow64_redirection_state = nil

        if wow64_architecture_override_required?(run_context.node, target_architecture)
          wow64_redirection_state = disable_wow64_file_redirection(run_context.node)
        end

        begin
          yield
        rescue
          raise
        ensure
          unless wow64_redirection_state.nil?
            restore_wow64_file_redirection(run_context.node, wow64_redirection_state)
          end
        end
      end

      def command
        "\"#{interpreter}\" #{flags} \"#{script_file_path}\""
      end

      def grant_alternate_user_read_access(file_path)
        # Do nothing if an alternate user isn't specified -- the file
        # will already have the correct permissions for the user as part
        # of the default ACL behavior on Windows.
        return if new_resource.user.nil?

        # Duplicate the script file's existing DACL
        # so we can add an ACE later
        securable_object = Chef::ReservedNames::Win32::Security::SecurableObject.new(file_path)
        aces = securable_object.security_descriptor.dacl.reduce([]) { |result, current| result.push(current) }

        username = new_resource.user

        if new_resource.domain
          username = new_resource.domain + "\\" + new_resource.user
        end

        # Create an ACE that allows the alternate user read access to the script
        # file so it can be read and executed.
        user_sid = Chef::ReservedNames::Win32::Security::SID.from_account(username)
        read_ace = Chef::ReservedNames::Win32::Security::ACE.access_allowed(user_sid, Chef::ReservedNames::Win32::API::Security::GENERIC_READ | Chef::ReservedNames::Win32::API::Security::GENERIC_EXECUTE, 0)
        aces.push(read_ace)
        acl = Chef::ReservedNames::Win32::Security::ACL.create(aces)

        # This actually applies the modified DACL to the file
        # Use parentheses to bypass RuboCop / ChefStyle warning
        # about useless setter
        (securable_object.dacl = acl)
      end

      def with_temp_script_file
        Tempfile.open(["chef-script", script_extension]) do |script_file|
          script_file.puts(code)
          script_file.close

          grant_alternate_user_read_access(script_file.path)

          # This needs to be set here so that the call to #command in Execute works.
          self.script_file_path = script_file.path

          yield

          self.script_file_path = nil
        end
      end

      def input
        nil
      end

      public

      action :run do
        with_wow64_redirection_disabled do
          with_temp_script_file do
            super()
          end
        end
      end

      def script_extension
        raise Chef::Exceptions::Override, "You must override #{__method__} in #{self}"
      end
    end
  end
end
