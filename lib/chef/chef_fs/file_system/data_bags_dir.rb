#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/data_bag_dir'

class Chef
  module ChefFS
    module FileSystem
      class DataBagsDir < RestListDir
        def initialize(parent)
          super("data_bags", parent, "data")
        end

        def child(name)
          result = @children.select { |child| child.name == name }.first if @children
          result || DataBagDir.new(name, self)
        end

        def children
          begin
            @children ||= rest.get_rest(api_path).keys.map do |entry|
              DataBagDir.new(entry, self, true)
            end
          rescue Net::HTTPServerException
            if $!.response.code == "404"
              raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
            else
              raise
            end
          end
        end

        def can_have_child?(name, is_dir)
          is_dir
        end

        def create_child(name, file_contents)
          begin
            rest.post_rest(api_path, { 'name' => name })
          rescue Net::HTTPServerException
            if $!.response.code != "409"
              raise
            end
          end
          DataBagDir.new(name, self, true)
        end
      end
    end
  end
end
