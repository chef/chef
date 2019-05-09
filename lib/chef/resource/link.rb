#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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

require_relative "../resource"
require_relative "../mixin/securable"

class Chef
  class Resource
    class Link < Chef::Resource
      include Chef::Mixin::Securable
      resource_name :link
      provides :link

      description "Use the link resource to create symbolic or hard links.\n\n"\
                  "A symbolic link—sometimes referred to as a soft link—is a directory entry"\
                  " that associates a file name with a string that contains an absolute or"\
                  " relative path to a file on any file system. In other words, “a file that"\
                  " contains a path that points to another file.” A symbolic link creates a new"\
                  " file with a new inode that points to the inode location of the original file.\n\n"\
                  "A hard link is a directory entry that associates a file with another file in the"\
                  " same file system. In other words, “multiple directory entries to the same file.”"\
                  " A hard link creates a new file that points to the same inode as the original file."

      state_attrs :owner # required since it's not a property below

      default_action :create
      allowed_actions :create, :delete

      def initialize(name, run_context = nil)
        verify_links_supported!
        super
      end

      property :target_file, String,
               description: "An optional property to set the target file if it differs from the resource block's name.",
               name_property: true, identity: true

      property :to, String,
               description: "The actual file to which the link is to be created."

      property :link_type, [String, Symbol],
               description: "The type of link: :symbolic or :hard.",
               coerce: proc { |arg| arg.kind_of?(String) ? arg.to_sym : arg },
               equal_to: [ :symbolic, :hard ], default: :symbolic

      property :group, [String, Integer],
               description: "A group name or ID number that identifies the group associated with a symbolic link.",
               regex: [Chef::Config[:group_valid_regex]]

      property :owner, [String, Integer],
               description: "The owner associated with a symbolic link.",
               regex: [Chef::Config[:user_valid_regex]]

      # make link quack like a file (XXX: not for public consumption)
      def path
        target_file
      end

      private

      # On certain versions of windows links are not supported. Make
      # sure we are not on such a platform.
      def verify_links_supported!
        if Chef::Platform.windows?
          require_relative "../win32/file"
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
