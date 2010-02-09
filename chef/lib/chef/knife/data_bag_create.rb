#
# Author:: Adam Jacob (<adam@opscode.com>)
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
require 'chef/data_bag'

class Chef
  class Knife
    class DataBagCreate < Knife

      banner "Sub-Command: data bag create BAG [ITEM] (options)"

      def run 
        if @name_args.length == 2
          create_object({ "id" => @name_args[1] }, "data_bag_item[#{@name_args[1]}]") do |output|
            rest.post_rest("data/#{@name_args[0]}", output)
          end
        else
          rest.post_rest("data", { "name" => @name_args[0] })
          Chef::Log.info("Created data_bag[#{@name_args[0]}]")
        end
      end
    end
  end
end



