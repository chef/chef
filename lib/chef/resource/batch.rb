#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require_relative "windows_script"

class Chef
  class Resource
    class Batch < Chef::Resource::WindowsScript
      provides :batch

      description "Use the batch resource to execute a batch script using the cmd.exe interpreter on Windows. The batch resource creates and executes a temporary file (similar to how the script resource behaves), rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use not_if and only_if to guard this resource for idempotence."

      def initialize(name, run_context = nil)
        super(name, run_context, nil, "cmd.exe")
      end

    end
  end
end
