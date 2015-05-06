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

class Chef
  class Provider
    require 'chef/mixin/why_run'
    require 'chef/mixin/shell_out'
    require 'chef/mixin/provides'
    include Chef::Mixin::WhyRun
    include Chef::Mixin::ShellOut
    extend Chef::Mixin::Provides

    # supports the given resource and action (late binding)
    def self.supports?(resource, action)
      true
    end

    attr_accessor :new_resource
    attr_accessor :current_resource
    attr_accessor :run_context

    attr_reader :recipe_name
    attr_reader :cookbook_name

    #--
    # TODO: this should be a reader, and the action should be passed in the
    # constructor; however, many/most subclasses override the constructor so
    # changing the arity would be a breaking change. Change this at the next
    # break, e.g., Chef 11.
    attr_accessor :action

    def initialize(new_resource, run_context)
      @new_resource = new_resource
      @action = action
      @current_resource = nil
      @run_context = run_context
      @converge_actions = nil

      @recipe_name = nil
      @cookbook_name = nil
    end

    def whyrun_mode?
      Chef::Config[:why_run]
    end

    def whyrun_supported?
      false
    end

    def node
      run_context && run_context.node
    end

    # Used by providers supporting embedded recipes
    def resource_collection
      run_context && run_context.resource_collection
    end

    def cookbook_name
      new_resource.cookbook_name
    end

    def load_current_resource
      raise Chef::Exceptions::Override, "You must override load_current_resource in #{self.to_s}"
    end

    def define_resource_requirements
    end

    def cleanup_after_converge
    end

    def action_nothing
      Chef::Log.debug("Doing nothing for #{@new_resource.to_s}")
      true
    end

    def events
      run_context.events
    end

    def run_action(action=nil)
      @action = action unless action.nil?

      # TODO: it would be preferable to get the action to be executed in the
      # constructor...

      # user-defined LWRPs may include unsafe load_current_resource methods that cannot be run in whyrun mode
      if !whyrun_mode? || whyrun_supported?
        load_current_resource
        events.resource_current_state_loaded(@new_resource, @action, @current_resource)
      elsif whyrun_mode? && !whyrun_supported?
        events.resource_current_state_load_bypassed(@new_resource, @action, @current_resource)
      end

      define_resource_requirements
      process_resource_requirements

      # user-defined providers including LWRPs may
      # not include whyrun support - if they don't support it
      # we can't execute any actions while we're running in
      # whyrun mode. Instead we 'fake' whyrun by documenting that
      # we can't execute the action.
      # in non-whyrun mode, this will still cause the action to be
      # executed normally.
      if whyrun_supported? && !requirements.action_blocked?(@action)
        send("action_#{@action}")
      elsif whyrun_mode?
        events.resource_bypassed(@new_resource, @action, self)
      else
        send("action_#{@action}")
      end

      set_updated_status

      cleanup_after_converge
    end

    def process_resource_requirements
      requirements.run(:all_actions) unless @action == :nothing
      requirements.run(@action)
    end

    def resource_updated?
      !converge_actions.empty? || @new_resource.updated_by_last_action?
    end

    def set_updated_status
      if !resource_updated?
        events.resource_up_to_date(@new_resource, @action)
      else
        events.resource_updated(@new_resource, @action)
        new_resource.updated_by_last_action(true)
      end
    end

    def requirements
      @requirements ||= ResourceRequirements.new(@new_resource, run_context)
    end

    def converge_by(descriptions, &block)
      converge_actions.add_action(descriptions, &block)
    end

    def self.provides(short_name, opts={}, &block)
      priority_map = Chef::Platform::ProviderPriorityMap.instance
      priority_map.priority(short_name, self, opts, &block)
    end

    def self.provides?(node, resource)
      Chef::ProviderResolver.new(node, resource, :nothing).provided_by?(self)
    end

    protected

    def converge_actions
      @converge_actions ||= ConvergeActions.new(@new_resource, run_context, @action)
    end

    def recipe_eval(&block)
      # This block has new resource definitions within it, which
      # essentially makes it an in-line Chef run. Save our current
      # run_context and create one anew, so the new Chef run only
      # executes the embedded resources.
      #
      # TODO: timh,cw: 2010-5-14: This means that the resources within
      # this block cannot interact with resources outside, e.g.,
      # manipulating notifies.

      converge_by ("evaluate block and run any associated actions") do
        saved_run_context = @run_context
        @run_context = @run_context.dup
        @run_context.resource_collection = Chef::ResourceCollection.new
        instance_eval(&block)
        Chef::Runner.new(@run_context).converge
        @run_context = saved_run_context
      end
    end

    module DeprecatedLWRPClass
      def const_missing(class_name)
        if deprecated_constants[class_name.to_sym]
          Chef::Log.deprecation("Using an LWRP provider by its name (#{class_name}) directly is no longer supported in Chef 12 and will be removed.  Use Chef::ProviderResolver.new(node, resource, action) instead.")
          deprecated_constants[class_name.to_sym]
        else
          raise NameError, "uninitialized constant Chef::Provider::#{class_name}"
        end
      end

      # @api private
      def register_deprecated_lwrp_class(provider_class, class_name)
        # Register Chef::Provider::MyProvider with deprecation warnings if you
        # try to access it
        if Chef::Provider.const_defined?(class_name, false)
          Chef::Log.warn "Chef::Provider::#{class_name} already exists!  Cannot create deprecation class for #{provider_class}"
        else
          deprecated_constants[class_name.to_sym] = provider_class
        end
      end

      private

      def deprecated_constants
        @deprecated_constants ||= {}
      end
    end
    extend DeprecatedLWRPClass
  end
end

# Requiring things at the bottom breaks cycles
require 'chef/chef_class'
require 'chef/mixin/why_run'
require 'chef/resource_collection'
require 'chef/platform/provider_priority_map'
require 'chef/runner'
