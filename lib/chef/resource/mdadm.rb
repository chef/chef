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

        @mdadm_defaults = false
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
      end

      def mdadm_defaults(arg = nil)
        set_or_return(
          :mdadm_defaults,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def chunk(arg = nil)
        @user_set_chunk = true unless arg.nil?
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
        @user_set_metadata = true unless arg.nil?
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

      # Track if user set metadata attribute which is used in after_create
      # method to facilitate proper behavior of the mdadm_defaults attribute
      def user_set_metadata(arg = nil)
        set_or_return(
          :exists,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      # Track if user set chunk attribute which is used in after_create
      # method to facilitate proper behavior of the mdadm_defaults attribute
      def user_set_chunk(arg = nil)
        set_or_return(
          :exists,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def after_created
        # Once the mdadm_defaults defaults to true the nil's below will need
        # to be replaced with 16 and "0.90"
        if @mdadm_defaults
          @chunk = nil unless @user_set_chunk
          @metadata = nil unless @user_set_metadata
        end

        metadata_warn_msg = "#{self} the default metadata version of 0.90 "\
          "will be removed in a future release. To maintain backwards "\
          "compatibility please explicitly specify the metadata version that "\
          "you desire on the the mdadm resource if the mdadm default is not "\
          "desired. This future change will only impact newly created md "\
          "devices."
        chunk_warn_msg = "#{self} default chunk size of 16k will be removed "\
          "in a future release. To maintain backwards compatibility please "\
          "explicitly specify the chunk size that you desire on the the mdadm "\
          "resource if the mdadm default is not desired. This future change "\
          "will only impact newly created md devices."

        Chef.log_deprecation(metadata_warn_msg) unless @user_set_metadata
        Chef.log_deprecation(chunk_warn_msg) unless @user_set_chunk
      end
    end
  end
end
