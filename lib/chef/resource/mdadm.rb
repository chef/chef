#
# Author:: Joe Williams (<joe@joetify.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Joe Williams
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
    class Mdadm < Chef::Resource

      identity_attr :raid_device

      state_attrs :devices, :level, :chunk

      default_action :create
      allowed_actions :create, :assemble, :stop

      def initialize(name, run_context = nil)
        super

        @chunk = 16
        @devices = []
        @exists = false
        @level = 1
        @metadata = "0.90"
        @bitmap = nil
        @raid_device = name
        
        # Can be removed once the chunk member defaults to nil
        @user_set_chunk = false
        # Can be removed once the metadata member defaults to nil
        @user_set_metadata = false

        @action = :create
        @allowed_actions.push(:create, :assemble, :stop)
      end

      def chunk(arg = nil)
        unless arg
          warn_msg = "The default chunk size of 16k will be removed in a "\
            "future release.  This change will allow mdadm to choose "\
            "the default chunk size."
          Chef::Log.warn(warn_msg)
        end
        @user_set_chunk = true
        set_or_return(
          :chunk,
          arg,
          :kind_of => [ Integer ]
        )
      end

      def devices(arg = nil)
        set_or_return(
          :devices,
          arg,
          :kind_of => [ Array ]
        )
      end

      def exists(arg = nil)
        set_or_return(
          :exists,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def level(arg = nil)
        set_or_return(
          :level,
          arg,
          :kind_of => [ Integer ]
        )
      end

      def metadata(arg = nil)
        unless arg
          warn_msg = "The default metadata version of 0.90 will be removed in "\
            "a future release. This change will allow mdadm to choose the "\
            "default metadata version."
          Chef::Log.warn(warn_msg)
        end
        @user_set_metadata = true
        set_or_return(
          :metadata,
          arg,
          :kind_of => [ String ]
        )
      end

      def bitmap(arg = nil)
        set_or_return(
          :bitmap,
          arg,
          :kind_of => [ String ]
        )
      end

      def raid_device(arg = nil)
        set_or_return(
          :raid_device,
          arg,
          :kind_of => [ String ]
        )
      end

      # Can be removed once metadata and chunk defaults are set to nil
      def user_set_metadata(arg=nil)
        set_or_return(
          :exists,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      # Can be removed once metadata and chunk defaults are set to nil
      def user_set_chunk(arg=nil)
        set_or_return(
          :exists,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end
    end
  end
end
