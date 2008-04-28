#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

require File.join(File.dirname(__FILE__), "mixin", "params_validate")

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
    end
    
    def converge
      start_time = Time.now
      Chef::Log.info("Starting Chef Run")
      delayed_actions = Array.new
      
      @collection.each do |resource|
        Chef::Log.debug("Processing #{resource}")
        provider = build_provider(resource)
        provider.load_current_resource
        provider.send("action_#{resource.action}")
        if resource.updated
          resource.actions.each_key do |action|
            if resource.actions[action].has_key?(:immediate)
              resource.actions[action][:immediate].each do |r|
                Chef::Log.info("#{resource} sending action #{action} to #{r} (immediate)")
                build_provider(r).send("action_#{action}")
              end
            end
            if resource.actions[action].has_key?(:delayed)
              resource.actions[action][:delayed].each do |r|
                delayed_actions << lambda {
                  Chef::Log.info("#{resource} sending action #{action} to #{r} (delayed)")
                  build_provider(r).send("action_#{action}") 
                }
              end
            end
          end
        end
      end
      
      # Run all our :delayed actions
      delayed_actions.each { |da| da.call }
      end_time = Time.now
      Chef::Log.info("Chef Run complete in #{end_time - start_time} seconds")
      true
    end
  end
end