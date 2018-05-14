#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2009-2016, Opscode
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

require "chef/provider/lwrp_base"

class Chef
  class Provider
    class Recipe < Chef::Provider::LWRPBase
      provides :recipe

      def whyrun_supported?
        true
      end

      def load_current_resource
        true
      end

      action :run do
        new_resource.block.call
      end
    end
  end
end
