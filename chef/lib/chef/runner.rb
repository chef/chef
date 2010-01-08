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
    
    def initialize(node, collection, definitions={}, cookbook_loader=nil)
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
      @definitions = definitions
      @cookbook_loader = cookbook_loader
    end
    
    def build_provider(resource)
      provider_klass = Chef::Platform.find_provider_for_node(@node, resource)
      Chef::Log.debug("#{resource} using #{provider_klass.to_s}")
      provider = provider_klass.new(@node, resource, @collection, @definitions, @cookbook_loader)
      provider.load_current_resource
      provider
    end

    def run_action(resource, ra)
      provider = build_provider(resource)
      provider.send("action_#{ra}")

      if resource.updated
        resource.actions.each_key do |action|
          if resource.actions[action].has_key?(:immediate)
            resource.actions[action][:immediate].each do |r|
              Chef::Log.info("#{resource} sending #{action} action to #{r} (immediate)")
              run_action(r, action)
            end
          end
          if resource.actions[action].has_key?(:delayed)
            resource.actions[action][:delayed].each do |r|
              @delayed_actions[r] = Hash.new unless @delayed_actions.has_key?(r)
              unless @delayed_actions[r].has_key?(action)
                @ordered_delayed_actions << [r, action]
                @delayed_actions[r][action] = Array.new
              end
              @delayed_actions[r][action] << lambda {
                Chef::Log.info("#{resource} sending #{action} action to #{r} (delayed)")
              } 
            end
          end
        end
      end
    end

    def converge

      @delayed_actions = Hash.new
      @ordered_delayed_actions = []
      
      @collection.execute_each_resource do |resource|
        begin
          Chef::Log.debug("Processing #{resource}")
          
          # Check if this resource has an only_if block - if it does, skip it.
          if resource.only_if
            unless Chef::Mixin::Command.only_if(resource.only_if, resource.only_if_args)
              Chef::Log.debug("Skipping #{resource} due to only_if")
              next
            end
          end
          
          # Check if this resource has a not_if block - if it does, skip it.
          if resource.not_if
            unless Chef::Mixin::Command.not_if(resource.not_if, resource.not_if_args)
              Chef::Log.debug("Skipping #{resource} due to not_if")
              next
            end
          end
          
          # Walk the actions for this resource, building the provider and running each.
          action_list = resource.action.kind_of?(Array) ? resource.action : [ resource.action ]
          action_list.each do |ra|
            run_action(resource, ra)
          end
        rescue => e
          Chef::Log.error("#{resource} (#{resource.source_line}) had an error:\n#{e}\n#{e.backtrace.join("\n")}")
          raise e unless resource.ignore_failure
        end
      end
      
      # Run all our :delayed actions
      @ordered_delayed_actions.each do |resource, action| 
        log_array = @delayed_actions[resource][action]
        log_array.each { |l| l.call } # Call each log message
        run_action(resource, action)
      end

      true
    end
  end
end
