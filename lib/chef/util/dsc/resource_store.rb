#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../../mixin/powershell_exec"
require_relative "../../exceptions"

class Chef
  class Util
    class DSC
      class ResourceStore
        include Chef::Mixin::PowershellExec

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
          powershell_exec("get-dscresource").result
        end

        # Returns a list of dsc resources matching the provided name
        def query_resource(resource_name)
          ret_val = powershell_exec("get-dscresource #{resource_name}").result
          if ret_val.empty?
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
