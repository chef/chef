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
require 'json'
require 'chef/data_bag_item'

class Chef
  class Knife
    class DataBagSet < Knife

      banner "knife data bag set BAG ITEM NEW_ENTRY"
      category "data bag"

      def run 
        if @name_args.length != 3
          Chef::Log.fatal("You must supply the data bag , item and new entries to put!")
          exit 42
        else
          object = Chef::DataBagItem.load(@name_args[0], @name_args[1])
          
          new_entries_hash = JSON.parse(@name_args[2])
          new_entries_hash.keys.each{ |head|
            confirm("You realy want to overwrite the attribute \"#{head}\" ") if object[head]
            object[head] = new_entries_hash[head]
          }

          output = object

          rest.put_rest("data/#{@name_args[0]}/#{@name_args[1]}", output)

          Chef::Log.info("Saved data_bag_item[#{@name_args[1]}]")

          output(format_for_display(object)) if config[:print_after]
        end
      end
    end
  end
end



