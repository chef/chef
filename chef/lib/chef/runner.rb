#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/mixin/params_validate'
require 'chef/node'
require 'chef/resource_collection'
require 'chef/platform'

class Chef
  class Runner
    
    include Chef::Mixin::ParamsValidate
    
    def initialize(node, collection)
      validate(
        {
          :node => node,
          :collection => collection,
        },
        {
          :node => {
            :kind_of => Chef::Node,
          },
          :collection => {
            :kind_of => Chef::ResourceCollection,
          },
        }
      )
      @node = node
      @collection = collection
    end
    
    def build_provider(resource)
      provider_klass = resource.provider
      if provider_klass == nil
        provider_klass = Chef::Platform.find_provider_for_node(@node, resource)      
      end
      Chef::Log.debug("#{resource} using #{provider_klass.to_s}")
      provider = provider_klass.new(@node, resource)
      provider.load_current_resource
      provider
    end
    
    def converge

      delayed_actions = Array.new
      
      @collection.each do |resource|
        begin
          Chef::Log.debug("Processing #{resource}")
          
          # Check if this resource has an only_if block - if it does, skip it.
          if resource.only_if
            unless Chef::Mixin::Command.only_if(resource.only_if)
              Chef::Log.debug("Skipping #{resource} due to only_if")
              next
            end
          end
          
          # Check if this resource has a not_if block - if it does, skip it.
          if resource.not_if
            unless Chef::Mixin::Command.not_if(resource.not_if)
              Chef::Log.debug("Skipping #{resource} due to not_if")
              next
            end
          end
          
          # Walk the actions for this resource, building the provider and running each.
          action_list = resource.action.kind_of?(Array) ? resource.action : [ resource.action ]
          action_list.each do |ra|
            provider = build_provider(resource)
            provider.send("action_#{ra}")
            if resource.updated
              resource.actions.each_key do |action|
                if resource.actions[action].has_key?(:immediate)
                  resource.actions[action][:immediate].each do |r|
                    Chef::Log.info("#{resource} sending #{action} action to #{r} (immediate)")
                    build_provider(r).send("action_#{action}")
                  end
                end
                if resource.actions[action].has_key?(:delayed)
                  resource.actions[action][:delayed].each do |r|
                    delayed_actions << lambda {
                      Chef::Log.info("#{resource} sending #{action} action to #{r} (delayed)")
                      build_provider(r).send("action_#{action}") 
                    }
                  end
                end
              end
            end
          end
        rescue => e
          Chef::Log.error("#{resource} (#{resource.source_line}) had an error:\n#{e}\n#{e.backtrace}")
          raise e unless resource.ignore_failure
        end
      end
      
      # Run all our :delayed actions
      delayed_actions.each { |da| da.call }

      true
    end
  end
end
