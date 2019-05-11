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

require_relative "../mixin/windows_env_helper" if Chef::Platform.windows?
require_relative "../mixin/wide_string"
require_relative "../exceptions"

class Chef
  class Provider
    class WindowsPath < Chef::Provider
      include Chef::Mixin::WindowsEnvHelper if Chef::Platform.windows?

      provides :windows_path

      def load_current_resource
        @current_resource = Chef::Resource::WindowsPath.new(new_resource.name)
        @current_resource.path(new_resource.path)
        @current_resource
      end

      action :add do
        # The windows Env provider does not correctly expand variables in
        # the PATH environment variable. Ruby expects these to be expanded.
        #
        path = expand_path(new_resource.path)
        declare_resource(:env, "path") do
          action :modify
          delim ::File::PATH_SEPARATOR
          value path.tr("/", '\\')
        end
      end

      action :remove do
        # The windows Env provider does not correctly expand variables in
        # the PATH environment variable. Ruby expects these to be expanded.
        #
        path = expand_path(new_resource.path)
        declare_resource(:env, "path") do
          action :delete
          delim ::File::PATH_SEPARATOR
          value path.tr("/", '\\')
        end
      end
    end
  end
end
