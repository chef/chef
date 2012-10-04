#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode
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

class Chef
  class Provider
    class RubyBlock < Chef::Provider
      def whyrun_supported?
        true
      end

      def load_current_resource
        true
      end

      def action_run
        converge_by("execute the ruby block #{@new_resource.name}") do 
          @new_resource.block.call
          Chef::Log.info("#{@new_resource} called")
        end
      end

      alias :action_create :action_run

    end
  end
end
