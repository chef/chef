#
# Author:: Mike Dodge (<mikedodge04@gmail.com>)
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

require "chef/resource/service"

class Chef
  class Resource
    class MacosxService < Chef::Resource::Service

      provides :macosx_service, os: "darwin"
      provides :service, os: "darwin"

      identity_attr :service_name

      state_attrs :enabled, :running

      def initialize(name, run_context = nil)
        super
        @plist = nil
        @session_type = nil
      end

      # This will enable user to pass a plist in the case
      # that the filename and label for the service dont match
      def plist(arg = nil)
        set_or_return(
          :plist,
          arg,
          :kind_of => String
        )
      end

      def session_type(arg = nil)
        set_or_return(
          :session_type,
          arg,
          :kind_of => String
        )
      end

    end
  end
end
