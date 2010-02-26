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

class Chef
  class Knife
    class CookbookBulkDelete < Knife

      banner "Sub-Command: cookbook bulk delete REGEX (options)"

      def run 
        if @name_args.length < 1
          Chef::Log.fatal("You must supply a regular expression to match the results against")
          exit 42
        else
          bulk_delete(Chef::Cookbook, "cookbook", "cookbook", rest.get_rest("cookbooks"), @name_args[0]) do |name, cookbook|
            rest.delete_rest(cookbook)
          end
        end
      end
    end
  end
end







