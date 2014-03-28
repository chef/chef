#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
require 'chef/resource/windows_script'

class Chef
  class Resource
    class PowershellScript < Chef::Resource::WindowsScript

      def initialize(name, run_context=nil)
        super(name, run_context, :powershell_script, "powershell.exe")
        set_guard_inherited_attributes([:architecture])
        @convert_boolean_return = false
      end

      def convert_boolean_return(arg=nil)
        set_or_return(
          :convert_boolean_return,
          arg,
          :kind_of => [ FalseClass, TrueClass ]
        )
      end

      def only_if(command=nil, opts={}, &block)
        augmented_opts = opts.merge((guard_interpreter.nil? || guard_interpreter == :default) ? {} : {:convert_boolean_return => true}) {|key, original_value, augmented_value| original_value}
        super(command, augmented_opts, &block)
      end

      def not_if(command=nil, opts={}, &block)
        augmented_opts = opts.merge((guard_interpreter.nil? || guard_interpreter == :default) ? {} : {:convert_boolean_return => true}) {|key, original_value, augmented_value| original_value}
        super(command, augmented_opts, &block)
      end

    end
  end
end
