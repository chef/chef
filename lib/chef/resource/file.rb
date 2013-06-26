#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011 Opscode, Inc.
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

require 'chef/resource'
require 'chef/platform/query_helpers'
require 'chef/provider/file'
require 'chef/mixin/securable'

class Chef
  class Resource
    class File < Chef::Resource
      include Chef::Mixin::Securable

      identity_attr :path

      if Platform.windows?
        # Use Windows rights instead of standard *nix permissions
        state_attrs :checksum, :rights, :deny_rights
      else
        state_attrs :checksum, :owner, :group, :mode
      end

      provides :file, :on_platforms => :all

      def initialize(name, run_context=nil)
        super
        @resource_name = :file
        @path = name
        @backup = 5
        @action = "create"
        @allowed_actions.push(:create, :delete, :touch, :create_if_missing)
        @provider = Chef::Provider::File
        @atomic_update = Chef::Config[:file_atomic_update]
        @force_unlink = false
        @manage_symlink_source = nil
        @diff = nil
      end


      def content(arg=nil)
        set_or_return(
          :content,
          arg,
          :kind_of => String
        )
      end

      def backup(arg=nil)
        set_or_return(
          :backup,
          arg,
          :kind_of => [ Integer, FalseClass ]
        )
      end

      def checksum(arg=nil)
        set_or_return(
          :checksum,
          arg,
          :regex => /^[a-zA-Z0-9]{64}$/
        )
      end

      def path(arg=nil)
        set_or_return(
          :path,
          arg,
          :kind_of => String
        )
      end

      def diff(arg=nil)
        set_or_return(
          :diff,
          arg,
          :kind_of => String
        )
      end

      def atomic_update(arg=nil)
        set_or_return(
          :atomic_update,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def force_unlink(arg=nil)
        set_or_return(
          :force_unlink,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def manage_symlink_source(arg=nil)
        set_or_return(
          :manage_symlink_source,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

    end
  end
end
