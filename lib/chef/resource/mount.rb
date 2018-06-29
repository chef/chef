#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2017, Chef Software Inc.
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

class Chef
  class Resource
    class Mount < Chef::Resource
      description "Use the mount resource to manage a mounted file system."

      default_action :mount
      allowed_actions :mount, :umount, :unmount, :remount, :enable, :disable

      # this is a poor API please do not re-use this pattern
      property :supports, Hash,
        default: lazy { { remount: false } },
        coerce: proc { |x| x.is_a?(Array) ? x.each_with_object({}) { |i, m| m[i] = true } : x }

      property :password, String, sensitive: true

      property :mount_point, String, name_property: true
      property :device, String, identity: true

      property :device_type, [String, Symbol],
        coerce: proc { |arg| arg.kind_of?(String) ? arg.to_sym : arg },
        default: :device,
        equal_to: RUBY_PLATFORM.match?(/solaris/i) ? %i{ device } : %i{ device label uuid }

      property :fsck_device, String, default: "-"
      property :fstype, [String, nil], default: "auto"

      property :options, [Array, String, nil],
        coerce: proc { |arg| arg.kind_of?(String) ? arg.split(",") : arg },
        default: %w{defaults}

      property :dump, [Integer, FalseClass], default: 0
      property :pass, [Integer, FalseClass], default: 2
      property :mounted, [TrueClass, FalseClass], default: false
      property :enabled, [TrueClass, FalseClass], default: false
      property :username, String
      property :domain, String

      private

      # Used by the AIX provider to set fstype to nil.
      # TODO use property to make nil a valid value for fstype
      def clear_fstype
        @fstype = nil
      end

    end
  end
end
