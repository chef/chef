#
# Author:: Stephen Delano (<stephen@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class EnvironmentDelete < Knife

      deps do
        require "chef/environment" unless defined?(Chef::Environment)
      end

      banner "knife environment delete ENVIRONMENT (options)"

      def run
        env_name = @name_args[0]

        if env_name.nil?
          show_usage
          ui.fatal("You must specify an environment name")
          exit 1
        end

        delete_object(Chef::Environment, env_name)
      end
    end
  end
end
