#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/log'

class Chef
  module Mixin
    module LanguageIncludeAttribute

      def include_attribute(*args)
        if self.kind_of?(Chef::Node)
          node = self
        else
          node = @node
        end

        args.flatten.each do |attrib|
          if node.run_state[:seen_attributes].has_key?(attrib)
            Chef::Log.debug("I am not loading attribute file #{attrib}, because I have already seen it.")
            next
          end

          Chef::Log.debug("Loading Attribute #{attrib}")
          node.run_state[:seen_attributes][attrib] = true

          if amatch = attrib.match(/(.+?)::(.+)/)
            cookbook = @cookbook_loader[amatch[1].to_sym]
            cookbook.load_attribute(amatch[2], node)
          else
            cookbook = @cookbook_loader[amatch[1].to_sym]
            cookbook.load_attribute("default", node)
          end
        end
        true
      end

    end
  end
end
      

