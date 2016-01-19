#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

require "chef/resource/apt_update"

class Chef
  class Provider
    class AptUpdate < Chef::Provider
      provides :apt_update, os: "linux"

      def whyrun_supported?
        true
      end

      def load_current_resource
      end

      def action_periodic
        if !apt_up_to_date?
          converge_by "update new lists of packages" do
            shell_out!("apt-get -q update")
          end
        end
      end

      def action_update
        converge_by "force update new lists of packages" do
          shell_out!("apt-get -q update")
        end
      end

      private
      # Determines whether we need to run `apt-get update`
      #
      # @return [Boolean]
      def apt_up_to_date?
        if ::File.exist?("/var/lib/apt/periodic/update-success-stamp") &&
            ::File.mtime("/var/lib/apt/periodic/update-success-stamp") > Time.now - new_resource.frequency
          true
        else
          false
        end
      end

    end
  end
end
