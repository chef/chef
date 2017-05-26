#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource"

class Chef
  class Resource
    class Breakpoint < Chef::Resource
      provides :breakpoint
      resource_name :breakpoinst

      default_action :break

      def initialize(action = "break", *args)
        super(caller.first, *args)
      end

      action :break do
        if defined?(Shell) && Shell.running?
          with_run_context :parent do
            run_context.resource_collection.iterator.pause
            new_resource.updated_by_last_action(true)
            run_context.resource_collection.iterator
          end
        end
      end
    end
  end
end
