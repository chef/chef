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

require 'chef/provider/script'

class Chef
  class Provider
    class WindowsScript < Chef::Provider::Script

      def initialize( new_resource, run_context, script_extension='')
        super( new_resource, run_context )
        @script_extension = script_extension
      end

      def flags
        @new_resource.flags
      end      

      protected
        
      def script_file
        base_script_name = "chef-script"
        temp_file_arguments = [ base_script_name, @script_extension ]
        
        @script_file ||= Tempfile.open(temp_file_arguments)
      end

      def interpreter_script_path
        script_file.path.gsub(::File::SEPARATOR) { | replace | ::File::ALT_SEPARATOR }
      end
    end
  end
end
