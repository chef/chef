#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/resource/remote_file'
require 'chef/provider/windows_remote_file'
require 'chef/mixin/windows_securable'

class Chef
  class Resource
    class WindowsRemoteFile < Chef::Resource::RemoteFile
      include Chef::Mixin::WindowsSecurable

      provides :remote_file, :on_platforms => ["windows"]

      def initialize(name, run_context=nil)
        super
        @resource_name = :windows_remote_file
        @inherits = nil
        @provider = Chef::Provider::WindowsRemoteFile
      end

      # must override Chef::Resource::RemoteFile's funky
      # backward compat hack
      def provider
        Chef::Provider::WindowsRemoteFile
      end

    end
  end
end
