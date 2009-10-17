#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

require 'chef/mixin/from_file'
require 'chef/mixin/convert_to_class_name'
require 'chef/mixin/recipe_definition_dsl_core'

class Chef
  class Provider
    
    include Chef::Mixin::RecipeDefinitionDSLCore
    
    attr_accessor :node, :new_resource, :current_resource
    
    def initialize(node, new_resource, collection=nil, definitions={}, cookbook_loader=nil)
      @node = node
      @new_resource = new_resource
      @current_resource = nil
      @collection = collection
      @definitions = definitions
      @cookbook_loader = cookbook_loader
      @cookbook_name = @new_resource.cookbook_name
    end
    
    def load_current_resource
      raise Chef::Exceptions::Override, "You must override load_current_resource in #{self.to_s}"
    end
    
    def action_nothing
      Chef::Log.debug("Doing nothing for #{@new_resource.to_s}")
      true
    end
    
    protected
    
    def recipe_eval(*args, &block)
      provider_collection, @collection = @collection, Chef::ResourceCollection.new
      
      instance_eval(*args, &block)
      Chef::Runner.new(@node, @collection).converge
      
      @collection = provider_collection
    end
    
    public
    
    class << self
      include Chef::Mixin::ConvertToClassName
      
      def build_from_file(cookbook_name, filename)
        pname = filename_to_qualified_string(cookbook_name, filename)
        
        new_provider_class = Class.new self do |cls|
          
          def load_current_resource
            # silence Chef::Exceptions::Override exception
          end
          
          class << cls
            include Chef::Mixin::FromFile
            
            # setup DSL's shortcut methods
            def action(name, &block)
              define_method("action_#{name.to_s}") do
                instance_eval(&block)
              end
            end
          end
          
          # load provider definition from file
          cls.class_from_file(filename)
        end
        
        # register new class as a Chef::Provider
        pname = filename_to_qualified_string(cookbook_name, filename)
        class_name = convert_to_class_name(pname)
        Chef::Provider.const_set(class_name, new_provider_class)
        Chef::Log.debug("Loaded contents of #{filename} into a provider named #{pname} defined in Chef::Provider::#{class_name}")
        
        new_provider_class
      end
    end

  end
end
