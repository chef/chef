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

      identity_attr :device

      state_attrs :mount_point, :device_type, :fstype, :username, :password, :domain

      default_action :mount
      allowed_actions :mount, :umount, :unmount, :remount, :enable, :disable

      # this is a poor API please do not re-use this pattern
      property :supports, Hash, default: lazy { { remount: false } },
                                coerce: proc { |x| x.is_a?(Array) ? x.each_with_object({}) { |i, m| m[i] = true } : x }

      def initialize(name, run_context = nil)
        super
        @mount_point = name
        @device = nil
        @device_type = :device
        @fsck_device = "-"
        @fstype = "auto"
        @options = ["defaults"]
        @dump = 0
        @pass = 2
        @mounted = false
        @enabled = false
        @username = nil
        @password = nil
        @domain = nil
      end

      def mount_point(arg = nil)
        set_or_return(
          :mount_point,
          arg,
          :kind_of => [ String ]
        )
      end

      def device(arg = nil)
        set_or_return(
          :device,
          arg,
          :kind_of => [ String ]
        )
      end

      def device_type(arg = nil)
        real_arg = arg.kind_of?(String) ? arg.to_sym : arg
        valid_devices = if RUBY_PLATFORM =~ /solaris/i
                          [ :device ]
                        else
                          [ :device, :label, :uuid ]
                        end
        set_or_return(
          :device_type,
          real_arg,
          :equal_to => valid_devices
        )
      end

      def fsck_device(arg = nil)
        set_or_return(
          :fsck_device,
          arg,
          :kind_of => [ String ]
        )
      end

      def fstype(arg = nil)
        set_or_return(
          :fstype,
          arg,
          :kind_of => [ String ]
        )
      end

      def options(arg = nil)
        ret = set_or_return(
                            :options,
                            arg,
                            :kind_of => [ Array, String ]
                            )

        if ret.is_a? String
          ret.tr(",", " ").split(/ /)
        else
          ret
        end
      end

      def dump(arg = nil)
        set_or_return(
          :dump,
          arg,
          :kind_of => [ Integer, FalseClass ]
        )
      end

      def pass(arg = nil)
        set_or_return(
          :pass,
          arg,
          :kind_of => [ Integer, FalseClass ]
        )
      end

      def mounted(arg = nil)
        set_or_return(
          :mounted,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def enabled(arg = nil)
        set_or_return(
          :enabled,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def username(arg = nil)
        set_or_return(
          :username,
          arg,
          :kind_of => [ String ]
        )
      end

      def password(arg = nil)
        set_or_return(
          :password,
          arg,
          :kind_of => [ String ]
        )
      end

      def domain(arg = nil)
        set_or_return(
          :domain,
          arg,
          :kind_of => [ String ]
        )
      end

      private

      # Used by the AIX provider to set fstype to nil.
      # TODO use property to make nil a valid value for fstype
      def clear_fstype
        @fstype = nil
      end

    end
  end
end
