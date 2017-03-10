#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/guard_interpreter/default_guard_interpreter"
require "chef/guard_interpreter/resource_guard_interpreter"

class Chef
  class GuardInterpreter
    def self.for_resource(resource, command, command_opts)
      if resource.guard_interpreter == :default
        Chef::GuardInterpreter::DefaultGuardInterpreter.new(command, command_opts)
      else
        Chef::GuardInterpreter::ResourceGuardInterpreter.new(resource, command, command_opts)
      end
    end
  end
end
