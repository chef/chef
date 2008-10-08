#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "file")
require "fileutils"

class Chef
  class Provider
    class Sysctl < Chef::Provider
      def load_current_resource
        @current_resource = Chef::Resource::Sysctl.new(@new_resource.name)
        @current_resource.value(`/sbin/sysctl #{@new_resource.name}`.chomp)
        @current_resource
      end      
      
      def action_set
        if @current_resource.value != @new_resource.value
          system("/sbin/sysctl #{@new_resource.name}=#{@new_resource.value}")
        end
      end
    end
  end
end