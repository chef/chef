#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2008-2016 Chef Software, Inc.
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
require "chef/platform/query_helpers"
require "chef/mixin/securable"
require "chef/resource/file/verification"
require "pathname"

class Chef
  class Resource
    class File < Chef::Resource
      include Chef::Mixin::Securable

      if Platform.windows?
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
      # @returns [String] Checksum of the file we actually rendered
      attr_accessor :final_checksum

      default_action :create
      allowed_actions :create, :delete, :touch, :create_if_missing

      property :path, String, name_property: true, identity: true
      property :atomic_update, [ true, false ], desired_state: false, default: lazy { |r| r.docker? && r.special_docker_files?(r.path) ? false : Chef::Config[:file_atomic_update] }
      property :backup, [ Integer, false ], desired_state: false, default: 5
      property :checksum, [ /^[a-zA-Z0-9]{64}$/, nil ]
      property :content, [ String, nil ], desired_state: false
      property :diff, [ String, nil ], desired_state: false
      property :force_unlink, [ true, false ], desired_state: false, default: false
      property :manage_symlink_source, [ true, false ], desired_state: false
      property :verifications, Array, default: lazy { [] }

      def verify(command = nil, opts = {}, &block)
        if ! (command.nil? || [String, Symbol].include?(command.class))
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
