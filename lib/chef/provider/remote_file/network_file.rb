#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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

require 'uri'
require 'tempfile'
require 'chef/provider/remote_file'
require 'chef/mixin/user_identity'
require 'chef/mixin/user_context'

class Chef
  class Provider
    class RemoteFile
      class NetworkFile

        include Chef::Mixin::UserIdentity
        include Chef::Mixin::UserContext

        attr_reader :new_resource

        TRANSFER_CHUNK_SIZE = 1048576

        def initialize(source, new_resource, current_resource)
          @new_resource = new_resource
          @source = source
        end

        # Fetches the file on a network share, returning a Tempfile-like File handle
        # windows only
        def fetch
          validate_identity(new_resource.remote_user, new_resource.remote_user_password, new_resource.remote_user_domain)
          begin
            tempfile = Chef::FileContentManagement::Tempfile.new(new_resource).tempfile
            Chef::Log.debug("#{new_resource} staging #{@source} to #{tempfile.path}")

            with_user_context(new_resource.remote_user, new_resource.remote_user_password, new_resource.remote_user_domain) do
            ::File.open(@source, 'rb') do | remote_file |
                while data = remote_file.read(TRANSFER_CHUNK_SIZE)
                  tempfile.write(data)
                end
              end
            end
          ensure
            tempfile.close if tempfile
          end
          tempfile
        end

      end
    end
  end
end
