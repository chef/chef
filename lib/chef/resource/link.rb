#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource"
require "chef/mixin/securable"

class Chef
  class Resource
    class Link < Chef::Resource
      include Chef::Mixin::Securable

      identity_attr :target_file

      state_attrs :to, :owner, :group

      default_action :create
      allowed_actions :create, :delete

      def initialize(name, run_context = nil)
        verify_links_supported!
        super
        @to = nil
        @link_type = :symbolic
        @target_file = name
      end

      def to(arg = nil)
        set_or_return(
          :to,
          arg,
          :kind_of => String
        )
      end

      def target_file(arg = nil)
        set_or_return(
          :target_file,
          arg,
          :kind_of => String
        )
      end

      def link_type(arg = nil)
        real_arg = arg.kind_of?(String) ? arg.to_sym : arg
        set_or_return(
          :link_type,
          real_arg,
          :equal_to => [ :symbolic, :hard ]
        )
      end

      def group(arg = nil)
        set_or_return(
          :group,
          arg,
          :regex => Chef::Config[:group_valid_regex]
        )
      end

      def owner(arg = nil)
        set_or_return(
          :owner,
          arg,
          :regex => Chef::Config[:user_valid_regex]
        )
      end

      # make link quack like a file (XXX: not for public consumption)
      def path
        target_file
      end

      private

      def verify_links_supported!
        # On certain versions of windows links are not supported. Make
        # sure we are not on such a platform.

        if Chef::Platform.windows?
          require "chef/win32/file"
          begin
            Chef::ReservedNames::Win32::File.verify_links_supported!
          rescue Chef::Exceptions::Win32APIFunctionNotImplemented => e
            Chef::Log.fatal("Link resource is not supported on this version of Windows")
            raise e
          end
        end
      end
    end
  end
end
