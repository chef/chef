#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/util/powershell/cmdlet"
require "chef/util/powershell/cmdlet_result"
require "chef/exceptions"

class Chef
  class Util
    class DSC
      class ResourceStore

        def self.instance
          @@instance ||= ResourceStore.new.tap do |store|
            store.send(:populate_cache)
          end
        end

        def resources
          @resources ||= []
        end

        def find(name, module_name = nil)
          found = find_resources(name, module_name, resources)

          # We don't have it, query for the resource...it might
          # have been added since we last queried
          if found.length == 0
            rs = query_resource(name)
            add_resources(rs)
            found = find_resources(name, module_name, rs)
          end

          found
        end

        private

        def add_resource(new_r)
          count = resources.count do |r|
            r["ResourceType"].casecmp(new_r["ResourceType"]) == 0
          end
          if count == 0
            resources << new_r
          end
        end

        def add_resources(rs)
          rs.each do |r|
            add_resource(r)
          end
        end

        def populate_cache
          @resources = query_resources
        end

        def find_resources(name, module_name, rs)
          found = rs.find_all do |r|
            name_matches = r["Name"].casecmp(name) == 0
            if name_matches
              module_name.nil? || (r["Module"] && r["Module"]["Name"].casecmp(module_name) == 0)
            else
              false
            end
          end
        end

        # Returns a list of dsc resources
        def query_resources
          cmdlet = Chef::Util::Powershell::Cmdlet.new(nil, "get-dscresource",
              :object)
          result = cmdlet.run
          result.return_value
        end

        # Returns a list of dsc resources matching the provided name
        def query_resource(resource_name)
          cmdlet = Chef::Util::Powershell::Cmdlet.new(nil, "get-dscresource #{resource_name}",
              :object)
          result = cmdlet.run
          ret_val = result.return_value
          if ret_val.nil?
            []
          elsif ret_val.is_a? Array
            ret_val
          else
            [ret_val]
          end
        end
      end
    end
  end
end
