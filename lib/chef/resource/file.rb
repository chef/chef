#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

require_relative "../resource"
require_relative "../platform/query_helpers"
require_relative "../mixin/securable"
require_relative "file/verification"
require "pathname" unless defined?(Pathname)
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef
  class Resource
    class File < Chef::Resource
      include Chef::Mixin::Securable
      unified_mode true

      provides :file

      description "Use the **file** resource to manage files directly on a node. Note: Use the **cookbook_file** resource to copy a file from a cookbook's `/files` directory. Use the **template** resource to create a file based on a template in a cookbook's `/templates` directory. And use the **remote_file** resource to transfer a file to a node from a remote location."

      if ChefUtils.windows?
        # Use Windows rights instead of standard *nix permissions
        state_attrs :checksum, :rights, :deny_rights
      else
        state_attrs :checksum, :owner, :group, :mode
      end

      attr_writer :checksum

      #
      # The checksum of the rendered file.  This has to be saved on the
      # new_resource for the 'after' state for reporting but we cannot
      # mutate the new_resource.checksum which would change the
      # user intent in the new_resource if the resource is reused.
      #
      # @return [String] Checksum of the file we actually rendered
      attr_accessor :final_checksum

      default_action :create
      allowed_actions :create, :delete, :touch, :create_if_missing

      property :path, String, name_property: true,
        description: "The full path to the file, including the file name and its extension. For example: /files/file.txt. Default value: the name of the resource block. Microsoft Windows: A path that begins with a forward slash `/` will point to the root of the current working directory of the #{ChefUtils::Dist::Infra::PRODUCT} process. This path can vary from system to system. Therefore, using a path that begins with a forward slash `/` is not recommended."

      property :atomic_update, [ TrueClass, FalseClass ], desired_state: false, default: lazy { docker? && special_docker_files?(path) ? false : Chef::Config[:file_atomic_update] },
        default_description: "False if modifying /etc/hosts, /etc/hostname, or /etc/resolv.conf within Docker containers. Otherwise default to the client.rb 'file_atomic_update' config value.",
        description: "Perform atomic file updates on a per-resource basis. Set to true for atomic file updates. Set to false for non-atomic file updates. This setting overrides `file_atomic_update`, which is a global setting found in the `client.rb` file."

      property :backup, [ Integer, FalseClass ], desired_state: false, default: 5,
        description: "The number of backups to be kept in `/var/chef/backup` (for UNIX- and Linux-based platforms) or `C:/chef/backup` (for the Microsoft Windows platform). Set to `false` to prevent backups from being kept."

      property :checksum, [ String, nil ],
        regex: /^\h{64}$/,
        coerce: lambda { |s| s.is_a?(String) ? s.downcase : s },
        description: "The SHA-256 checksum of the file. Use to ensure that a specific file is used. If the checksum does not match, the file is not used."

      property :content, [ String, nil ], desired_state: false,
        description: "A string that is written to the file. The contents of this property replace any previous content when this property has something other than the default value. The default behavior will not modify content."

      property :diff, [ String, nil ], desired_state: false, skip_docs: true

      property :force_unlink, [ TrueClass, FalseClass ], desired_state: false, default: false,
        description: "How #{ChefUtils::Dist::Infra::PRODUCT} handles certain situations when the target file turns out not to be a file. For example, when a target file is actually a symlink. Set to `true` for #{ChefUtils::Dist::Infra::PRODUCT} to delete the non-file target and replace it with the specified file. Set to `false` for #{ChefUtils::Dist::Infra::PRODUCT} to raise an error."

      property :manage_symlink_source, [ TrueClass, FalseClass ], desired_state: false,
        description: "Change the behavior of the file resource if it is pointed at a symlink. When this value is set to true, #{ChefUtils::Dist::Infra::PRODUCT} will manage the symlink's permissions or will replace the symlink with a normal file if the resource has content. When this value is set to false, #{ChefUtils::Dist::Infra::PRODUCT} will follow the symlink and will manage the permissions and content of symlink's target file. The default behavior is true but emits a warning that the default value will be changed to false in a future version; setting this explicitly to true or false suppresses this warning."

      property :verifications, Array, default: lazy { [] }, desired_state: false, skip_docs: true

      def verify(command = nil, opts = {}, &block)
        unless command.nil? || [String, Symbol].include?(command.class)
          raise ArgumentError, "verify requires either a string, symbol, or a block"
        end

        if command || block_given?
          verifications << Verification.new(self, command, opts, &block)
        else
          verifications
        end
      end

      def state_for_resource_reporter
        state_attrs = super()
        # fix up checksum state with final_checksum saved by the provider
        if checksum.nil? && final_checksum
          state_attrs[:checksum] = final_checksum
        end
        state_attrs
      end

      def special_docker_files?(file)
        %w{/etc/hosts /etc/hostname /etc/resolv.conf}.include?(Pathname(file.scrub).cleanpath.to_path)
      end
    end
  end
end
