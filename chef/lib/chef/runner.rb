#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
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

require 'chef/mixin/params_validate'
require 'chef/node'
require 'chef/resource_collection'
require 'chef/platform'

# This class is responsible for executing the steps in a Chef run.
class Chef
  class Runner
    
    attr_reader :run_context
    
    include Chef::Mixin::ParamsValidate

    def initialize(run_context)
      @run_context = run_context
    end
    
    def build_provider(resource)
      provider_class = Chef::Platform.find_provider_for_node(run_context.node, resource)
      Chef::Log.debug("#{resource} using #{provider_class.to_s}")
      provider = provider_class.new(resource, run_context)
      provider.load_current_resource
      provider
    end
    
    # Determine the appropriate provider for the given resource, then
    # execute it.
    def run_action(resource, action, delayed_actions)
      provider = build_provider(resource)
      provider.send("action_#{action}")
      
      # Execute any immediate and queue up any delayed notifications
      # associated with the resource.
      if resource.updated
        resource.notifies_immediate.each do |notify|
          Chef::Log.info("#{resource} sending #{notify.action} action to #{notify.resource} (immediate)")
          run_action(notify.resource, notify.action, delayed_actions)
        end
        
        resource.notifies_delayed.each do |notify|
          unless delayed_actions.include?(notify)
            delayed_actions << notify
            delayed_actions << lambda {
              Chef::Log.info("#{resource} sending #{notify.action} action to #{notify.resource} (delayed)")
            }
          else
            delayed_actions << lambda {
              Chef::Log.info("#{resource} not sending #{notify.action} action to #{notify.resource} (delayed), as it's already been queued")
            }
          end
        end
      end
    end
    
    # Executes a Chef run.
    def converge
      delayed_actions = Array.new
      
      # Execute each resource.
      run_context.resource_collection.execute_each_resource do |resource|
        begin
          Chef::Log.debug("Processing #{resource} on #{run_context.node.name}")
          
          # Check if this resource has an only_if block -- if it does,
          # evaluate the only_if block and skip the resource if
          # appropriate.
          if resource.only_if
            unless Chef::Mixin::Command.only_if(resource.only_if, resource.only_if_args)
              Chef::Log.debug("Skipping #{resource} due to only_if")
              next
            end
          end
          
          # Check if this resource has a not_if block -- if it does,
          # evaluate the not_if block and skip the resource if
          # appropriate.
          if resource.not_if
            unless Chef::Mixin::Command.not_if(resource.not_if, resource.not_if_args)
              Chef::Log.debug("Skipping #{resource} due to not_if")
              next
            end
          end
          
          # Execute each of this resource's actions.
          action_list = resource.action.kind_of?(Array) ? resource.action : [ resource.action ]
          action_list.each do |action|
            run_action(resource, action, delayed_actions)
          end
        rescue => e
          Chef::Log.error("#{resource} (#{resource.source_line}) had an error:\n#{e}\n#{e.backtrace.join("\n")}")
          raise e unless resource.ignore_failure
        end
      end
      
      # Run all our :delayed actions
      delayed_actions.each do |notify_or_lambda|
        if notify_or_lambda.is_a?(Proc)
          # log message
          notify_or_lambda.call
        else
          # OpenStruct of resource/action to call
          run_action(notify_or_lambda.resource, notify_or_lambda.action, delayed_actions)
        end
      end

      true
    end
  end
end
