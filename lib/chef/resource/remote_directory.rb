#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require_relative "directory"
require_relative "../provider/remote_directory"
require_relative "../mixin/securable"

class Chef
  class Resource
    class RemoteDirectory < Chef::Resource::Directory
      include Chef::Mixin::Securable
      unified_mode true

      provides :remote_directory

      description "Use the **remote_directory** resource to incrementally transfer a directory from a cookbook to a node. The directory that is copied from the cookbook should be located under `COOKBOOK_NAME/files/default/REMOTE_DIRECTORY`. The `remote_directory` resource will obey file specificity."

      default_action :create
      allowed_actions :create, :create_if_missing, :delete

      def initialize(name, run_context = nil)
        super
        @delete = false
      end

      if ChefUtils.windows?
        # create a second instance of the 'rights' attribute (property)
        rights_attribute(:files_rights)
      end

      # This same property exists in the directory resource, but we need to change the default to true here.
      property :recursive, [ TrueClass, FalseClass ],
        description: "Create or delete parent directories recursively. For the owner, group, and mode properties, the value of this attribute applies only to the leaf directory.",
        default: true, desired_state: false

      property :source, String,
        description: "The base name of the source file (and inferred from the path property).",
        default_description: "The base portion of the 'path' property. For example '/some/path/' would be 'path'.",
        default: lazy { ::File.basename(path) }, desired_state: false

      property :files_backup, [ Integer, FalseClass ],
        description: "The number of backup copies to keep for files in the directory.",
        default: 5, desired_state: false

      property :purge, [ TrueClass, FalseClass ],
        description: "Purge extra files found in the target directory.",
        default: false, desired_state: false

      property :overwrite, [ TrueClass, FalseClass ],
        description: "Overwrite a file when it is different.",
        default: true, desired_state: false

      property :cookbook, String,
        description: "The cookbook in which a file is located (if it is not located in the current cookbook). The default value is the current cookbook.",
        desired_state: false

      property :files_group, [String, Integer],
        description: "Configure group permissions for files. A string or ID that identifies the group owner by group name, including fully qualified group names such as `domain\\group` or `group@domain`. If this value is not specified, existing groups remain unchanged and new group assignments use the default POSIX group (if available).",
        regex: Chef::Config[:group_valid_regex]

      property :files_mode, [String, Integer, nil],
        description: "The octal mode for a file.\n UNIX- and Linux-based systems: A quoted 3-5 character string that defines the octal mode that is passed to chmod. For example: '755', '0755', or 00755. If the value is specified as a quoted string, it works exactly as if the chmod command was passed. If the value is specified as an integer, prepend a zero (0) to the value to ensure that it is interpreted as an octal number. For example, to assign read, write, and execute rights for all users, use '0777' or '777'; for the same rights, plus the sticky bit, use 01777 or '1777'.\n Microsoft Windows: A quoted 3-5 character string that defines the octal mode that is translated into rights for Microsoft Windows security. For example: '755', '0755', or 00755. Values up to '0777' are allowed (no sticky bits) and mean the same in Microsoft Windows as they do in UNIX, where 4 equals GENERIC_READ, 2 equals GENERIC_WRITE, and 1 equals GENERIC_EXECUTE. This property cannot be used to set :full_control. This property has no effect if not specified, but when it and rights are both specified, the effects are cumulative.",
        default_description: "0644 on *nix systems",
        regex: /^\d{3,4}$/, default: lazy { 0644 unless Chef::Platform.windows? }

      property :files_owner, [String, Integer],
        description: "Configure owner permissions for files. A string or ID that identifies the group owner by user name, including fully qualified user names such as `domain\\user` or `user@domain`. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary).",
        regex: Chef::Config[:user_valid_regex]
    end
  end
end
