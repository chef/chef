#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright 2015-2016, Facebook, Inc.
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
    class OsxProfile < Chef::Resource
      provides :osx_profile, os: "darwin"
      provides :osx_config_profile, os: "darwin"

      identity_attr :profile_name

      default_action :install
      allowed_actions :install, :remove

      def initialize(name, run_context = nil)
        super
        @profile_name = name
        @profile = nil
        @identifier = nil
        @path = nil
      end

      def profile_name(arg = nil)
        set_or_return(
          :profile_name,
          arg,
          :kind_of => [ String ]
        )
      end

      def profile(arg = nil)
        set_or_return(
          :profile,
          arg,
          :kind_of => [ String, Hash ]
        )
      end

      def identifier(arg = nil)
        set_or_return(
          :identifier,
          arg,
          :kind_of => [ String ]
        )
      end

      def path(arg = nil)
        set_or_return(
          :path,
          arg,
          :kind_of => [ String ]
        )
      end

    end
  end
end
