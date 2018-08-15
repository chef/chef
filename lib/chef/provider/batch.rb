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

require "chef/provider/windows_script"

class Chef
  class Provider
    class Batch < Chef::Provider::WindowsScript

      provides :batch

      def initialize(new_resource, run_context)
        super(new_resource, run_context, ".bat")
      end

      def command
        basepath = is_forced_32bit ? wow64_directory : run_context.node["kernel"]["os_info"]["system_directory"]

        interpreter_path = Chef::Util::PathHelper.join(basepath, interpreter)

        "\"#{interpreter_path}\" #{flags} \"#{script_file.path}\""
      end

      def flags
        new_resource.flags.nil? ? "/c" : new_resource.flags + " /c"
      end

    end
  end
end
