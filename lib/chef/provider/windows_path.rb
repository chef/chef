#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "Win32API" if Chef::Platform.windows?
require "chef/exceptions"

class Chef
  class Provider
    class WindowsPath < Chef::Provider
      ExpandEnvironmentStrings = Win32API.new("kernel32", "ExpandEnvironmentStrings", %w{ P P L }, "L") if Chef::Platform.windows? && !defined?(ExpandEnvironmentStrings)

      def load_current_resource
        @current_resource = Chef::Resource::WindowsPath.new(new_resource.name)
        @current_resource.path(new_resource.path)
        @current_resource
      end

      action :add do
        declare_resource(:env, "path") do
          action :modify
          delim ::File::PATH_SEPARATOR
          value new_resource.path.tr("/", '\\')
        end
        # Expands environment-variable strings and replaces them with the values defined for the current user
        ENV["PATH"] = expand_env_vars(ENV["PATH"])
      end

      action :remove do
        declare_resource(:env, "path") do
          action :delete
          delim ::File::PATH_SEPARATOR
          value new_resource.path.tr("/", '\\')
        end
      end

      # Expands the environment variables
      def expand_env_vars(path)
        # We pick 32k because that is the largest it could be:
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms724265%28v=vs.85%29.aspx
        buf = 0.chr * 32 * 1024 # 32k
        if Chef::Provider::WindowsPath::ExpandEnvironmentStrings.call(path.dup, buf, buf.length) == 0
          raise Chef::Exceptions::Win32APIError, "Failed calling ExpandEnvironmentStrings with error code #{FFI.errno}"
        end
        buf.strip
      end
    end
  end
end
