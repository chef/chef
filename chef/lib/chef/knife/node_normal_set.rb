#
# Author:: Dmitriy Tkachenko (<sepulci@gmail.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'
require 'chef/node'
require 'json'

class Chef
  class Knife
    class NodeNormalSet < Knife

      banner "knife node normal set [NODE] [ENTRY]"

      def run 
        node = Chef::Node.load(@name_args[0])
        entry = @name_args[1]
       
        normal_set(node, entry)

        node.save
      end

      def normal_set(node, new_value)
          new_value_hash = JSON.parse(new_value)
          new_value_hash.keys.each{ |head|
            confirm("You realy want to overwrite the attribute \"#{head}\" ") if node.normal_attrs[head]
            node.normal_attrs[head] = new_value_hash[head]
          }
      end

    end
  end
end
