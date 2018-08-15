#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource/script"
require "chef/provider/script"

class Chef
  class Resource
    class Bash < Chef::Resource::Script
      description "Use the bash resource to execute scripts using the Bash interpreter. This resource may also use any of the actions and properties that are available to the execute resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use not_if and only_if to guard this resource for idempotence."

      def initialize(name, run_context = nil)
        super
        @interpreter = "bash"
      end

    end
  end
end
