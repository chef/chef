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

class Chef
  class Provider
    class WindowsScript < Chef::Provider::Script

      protected

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
        "\"#{interpreter}\" #{flags} \"#{script_file.path}\""
      end

      def set_owner_and_group
        if ChefUtils.windows?
          # And on Windows also this is a no-op if there is no user specified.
          grant_alternate_user_read_access
        else
          # FileUtils itself implements a no-op if +user+ or +group+ are nil
          # You can prove this by running FileUtils.chown(nil,nil,'/tmp/file')
          # as an unprivileged user.
          FileUtils.chown(new_resource.user, new_resource.group, script_file.path)
        end
      end

      def grant_alternate_user_read_access
        # Do nothing if an alternate user isn't specified -- the file
        # will already have the correct permissions for the user as part
        # of the default ACL behavior on Windows.
        return if new_resource.user.nil?

        # Duplicate the script file's existing DACL
        # so we can add an ACE later
        securable_object = Chef::ReservedNames::Win32::Security::SecurableObject.new(script_file.path)
        aces = securable_object.security_descriptor.dacl.reduce([]) { |result, current| result.push(current) }

        username = new_resource.user

        if new_resource.domain
          username = new_resource.domain + '\\' + new_resource.user
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

      def unlink_script_file
        script_file && script_file.close!
      end

      def with_temp_script_file
        script_file.puts(code)
        script_file.close

        set_owner_and_group

        yield

        unlink_script_file
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

      def script_file
        @script_file ||= Tempfile.open(["chef-script", script_extension])
      end

      def script_extension
        raise Chef::Exceptions::Override, "You must override #{__method__} in #{self}"
      end
    end
  end
end
