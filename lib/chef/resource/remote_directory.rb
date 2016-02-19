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

require "chef/resource/directory"
require "chef/provider/remote_directory"
require "chef/mixin/securable"

class Chef
  class Resource
    class RemoteDirectory < Chef::Resource::Directory
      include Chef::Mixin::Securable

      identity_attr :path

      state_attrs :files_owner, :files_group, :files_mode

      default_action :create
      allowed_actions :create, :create_if_missing, :delete

      def initialize(name, run_context = nil)
        super
        @path = name
        @source = ::File.basename(name)
        @delete = false
        @recursive = true
        @purge = false
        @files_backup = 5
        @files_owner = nil
        @files_group = nil
        @files_mode = 0644 unless Chef::Platform.windows?
        @overwrite = true
        @cookbook = nil
      end

      if Chef::Platform.windows?
        # create a second instance of the 'rights' attribute
        rights_attribute(:files_rights)
      end

      def source(args = nil)
        set_or_return(
          :source,
          args,
          :kind_of => String
        )
      end

      def files_backup(arg = nil)
        set_or_return(
          :files_backup,
          arg,
          :kind_of => [ Integer, FalseClass ]
        )
      end

      def purge(arg = nil)
        set_or_return(
          :purge,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def files_group(arg = nil)
        set_or_return(
          :files_group,
          arg,
          :regex => Chef::Config[:group_valid_regex]
        )
      end

      def files_mode(arg = nil)
        set_or_return(
          :files_mode,
          arg,
          :regex => /^\d{3,4}$/
        )
      end

      def files_owner(arg = nil)
        set_or_return(
          :files_owner,
          arg,
          :regex => Chef::Config[:user_valid_regex]
        )
      end

      def overwrite(arg = nil)
        set_or_return(
          :overwrite,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def cookbook(args = nil)
        set_or_return(
          :cookbook,
          args,
          :kind_of => String
        )
      end

    end
  end
end
