#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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
require 'chef/json_compat'

class Chef
  class Resource
    class ZenMaster < Chef::Resource
      attr_reader :peace

      def initialize(name, run_context=nil)
        @resource_name = :zen_master
        super
      end

      def peace(tf)
        @peace = tf
      end

      def something(arg=nil)
        if !arg.nil?
          @something = arg
        end
        @something
      end
    end
  end
end
