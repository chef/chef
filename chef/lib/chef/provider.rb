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
require 'chef/mixin/enforce_ownership_and_permissions'
require 'chef/mixin/why_run'
class Chef
  class Provider
    include Chef::Mixin::RecipeDefinitionDSLCore
    include Chef::Mixin::WhyRun
    include Chef::Mixin::EnforceOwnershipAndPermissions

    attr_accessor :new_resource
    attr_accessor :current_resource
    attr_accessor :run_context

    #--
    # TODO: this should be a reader, and the action should be passed in the
    # constructor; however, many/most subclasses override the constructor so
    # changing the arity would be a breaking change. Change this at the next
    # break, e.g., Chef 11.
    attr_accessor :action

    def whyrun_supported?
      false
    end

    def initialize(new_resource, run_context)
      @new_resource = new_resource
      @action = action
      @current_resource = nil
      @run_context = run_context
      @converge_actions = nil
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
      if whyrun_supported?
        load_current_resource
      else
        converge_by("bypassing load current resource, whyrun not supported in resource provider #{self.class.name} ") do
          load_current_resource
        end
      end
      define_resource_requirements

      events.resource_current_state_loaded(@new_resource, @action, @current_resource)
      process_resource_requirements

      # user-defined providers including LWRPs may 
      # not include whyrun support - if they don't support it
      # we can't execute any actions while we're running in
      # whyrun mode. Instead we 'fake' whyrun by documenting that 
      # we can't execute the action. 
      # in non-whyrun mode, this will still cause the action to be
      # executed normally.
      if whyrun_supported?
        if requirements.action_blocked?(@action) 
          converge_by("due to failed resource requirement, action #{@action} cannot be processed in whyrun mode. Assuming normal execution.") { }
        else
          send("action_#{@action}")
        end
      else
        if action == :nothing
          action_nothing
        else
          converge_by("bypassing action #{@action}, whyrun not supported in resource provider #{self.class.name} ") do
            send("action_#{@action}")
          end
        end
      end
      converge
    end

    # exposed publically for accessibility in testing
    def process_resource_requirements
      requirements.run(:all_actions) unless @action == :nothing
      requirements.run(@action)
    end

    def converge
      converge_actions.converge!
      if converge_actions.empty? && !@new_resource.updated_by_last_action?
        events.resource_up_to_date(@new_resource, @action)
      else
        events.resource_updated(@new_resource, @action)
        new_resource.updated_by_last_action(true) 
      end
    end

    def requirements
      @requirements ||= ResourceRequirements.new
    end

    protected

    def converge_actions
      @converge_actions ||= ConvergeActions.new(@new_resource, run_context, @action)
    end

    def converge_by(descriptions, &block)
      converge_actions.add_action(descriptions, &block)
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

      converge_by ("would evaluate block and run any associated actions") do
        saved_run_context = @run_context
        @run_context = @run_context.dup
        @run_context.resource_collection = Chef::ResourceCollection.new
        instance_eval(&block)
        Chef::Runner.new(@run_context).converge
        @run_context = saved_run_context
      end
    end

    public

    class << self
      include Chef::Mixin::ConvertToClassName

      def build_from_file(cookbook_name, filename, run_context)
        pname = filename_to_qualified_string(cookbook_name, filename)

        # Add log entry if we override an existing light-weight provider.
        class_name = convert_to_class_name(pname)
        overriding = Chef::Provider.const_defined?(class_name)
        Chef::Log.info("#{class_name} light-weight provider already initialized -- overriding!") if overriding

        new_provider_class = Class.new self do |cls|

          include Chef::Mixin::RecipeDefinitionDSLCore

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
