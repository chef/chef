#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/file_system/exceptions"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class AclEntry < RestListEntry
          PERMISSIONS = %w{create read update delete grant}

          def api_path
            "#{super}/_acl"
          end

          def display_path
            pth = if parent.name == "acls"
                    "/acls/#{name}"
                  else
                    "/acls/#{parent.name}/#{name}"
                  end
            File.extname(pth).empty? ? pth + ".json" : pth
          end

          def delete(recurse)
            raise Chef::ChefFS::FileSystem::OperationNotAllowedError.new(:delete, self, nil, "ACLs cannot be deleted")
          end

          def write(file_contents)
            # ACL writes are fun.
            acls = data_handler.normalize(Chef::JSONCompat.parse(file_contents), self)
            PERMISSIONS.each do |permission|
              begin
                rest.put("#{api_path}/#{permission}", { permission => acls[permission] })
              rescue Timeout::Error => e
                raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e, "Timeout writing: #{e}")
              rescue Net::HTTPServerException => e
                if e.response.code == "404"
                  raise Chef::ChefFS::FileSystem::NotFoundError.new(self, e)
                else
                  raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e, "HTTP error writing: #{e}")
                end
              end
            end
          end
        end
      end
    end
  end
end
