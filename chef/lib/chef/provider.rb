#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
    
    attr_accessor :node, :new_resource, :current_resource
    
    def initialize(node, new_resource)
      @node = node
      @new_resource = new_resource
      @current_resource = nil
    end
    
    def load_current_resource
      raise Chef::Exceptions::Override, "You must override load_current_resource in #{self.to_s}"
    end
    
    def action_nothing
      Chef::Log.debug("Doing nothing for #{@new_resource.to_s}")
      true
    end
    
    class << self
      def build_from_file(filename)
        Class.new self do |cls|

          def load_current_resource
            # silence Chef::Exceptions::Override exception
          end
          
          # setup DSL's shortcut methods
          class << cls
            include Chef::Mixin::FromFile
            
            def action(name, &block)
              define_method("action_#{name}", block)
            end
          end
          
          # load provider definition from file
          cls.class_from_file(filename)
          
        end
      end
    end

  end
end
