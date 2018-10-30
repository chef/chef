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

      description "Use the remote_directory resource to incrementally transfer a directory"\
                  " from a cookbook to a node. The director that is copied from the cookbook"\
                  " should be located under COOKBOOK_NAME/files/default/REMOTE_DIRECTORY. The"\
                  " remote_directory resource will obey file specificity."

      identity_attr :path

      state_attrs :files_owner, :files_group, :files_mode

      default_action :create
      allowed_actions :create, :create_if_missing, :delete

      def initialize(name, run_context = nil)
        super
        @path = name
        @delete = false
        @recursive = true
        @files_owner = nil
        @files_group = nil
        @files_mode = 0644 unless Chef::Platform.windows?
      end

      if Chef::Platform.windows?
        # create a second instance of the 'rights' attribute
        rights_attribute(:files_rights)
      end

      property :source, String, default: lazy { ::File.basename(path) }
      property :files_backup, [ Integer, FalseClass ], default: 5, desired_state: false
      property :purge, [ TrueClass, FalseClass ], default: false, desired_state: false
      property :overwrite, [ TrueClass, FalseClass ], default: true, desired_state: false
      property :cookbook, String, desired_state: false

      def files_group(arg = nil)
        set_or_return(
          :files_group,
          arg,
          regex: Chef::Config[:group_valid_regex]
        )
      end

      def files_mode(arg = nil)
        set_or_return(
          :files_mode,
          arg,
          regex: /^\d{3,4}$/
        )
      end

      def files_owner(arg = nil)
        set_or_return(
          :files_owner,
          arg,
          regex: Chef::Config[:user_valid_regex]
        )
      end
    end
  end
end
