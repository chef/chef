require 'chef/formatters/base'
require 'chef/config'

class Chef
  module Formatters
    #--
    # TODO: not sold on the name, but the output is similar to what rspec calls
    # "specdoc"
    class Doc < Formatters::Base

      attr_reader :start_time, :end_time
      cli_name(:doc)
      

      def initialize(out, err)
        super

        @updated_resources = 0
        @up_to_date_resources = 0
        @start_time = Time.now
        @end_time = @start_time
      end

      def elapsed_time
        end_time - start_time
      end

      def run_start(version)
        puts_line "Starting Chef Client, version #{version}"
      end

      def total_resources
        @up_to_date_resources + @updated_resources
      end

      def run_completed(node)
        @end_time = Time.now
        if Chef::Config[:why_run]
          puts_line "Chef Client finished, #{@updated_resources}/#{total_resources} resources would have been updated"
        else
          puts_line "Chef Client finished, #{@updated_resources}/#{total_resources} resources updated in #{elapsed_time} seconds"
        end
      end

      def run_failed(exception)
        @end_time = Time.now
        if Chef::Config[:why_run]
          puts_line "Chef Client failed. #{@updated_resources} resources would have been updated"
        else
          puts_line "Chef Client failed. #{@updated_resources} resources updated in #{elapsed_time} seconds"
        end
      end

      # Called right after ohai runs.
      def ohai_completed(node)
      end

      # Already have a client key, assuming this node has registered.
      def skipping_registration(node_name, config)
      end

      # About to attempt to register as +node_name+
      def registration_start(node_name, config)
        puts_line "Creating a new client identity for #{node_name} using the validator key."
      end

      def registration_completed
      end

      def node_load_start(node_name, config)
      end

      # Failed to load node data from the server
      def node_load_failed(node_name, exception, config)
        super
      end

      # Default and override attrs from roles have been computed, but not yet applied.
      # Normal attrs from JSON have been added to the node.
      def node_load_completed(node, expanded_run_list, config)
      end

      # Called before the cookbook collection is fetched from the server.
      def cookbook_resolution_start(expanded_run_list)
        puts_line "resolving cookbooks for run list: #{expanded_run_list.inspect}"
      end

      # Called when there is an error getting the cookbook collection from the
      # server.
      def cookbook_resolution_failed(expanded_run_list, exception)
        super
      end

      # Called when the cookbook collection is returned from the server.
      def cookbook_resolution_complete(cookbook_collection)
      end

      # Called before unneeded cookbooks are removed
      def cookbook_clean_start
      end

      # Called after the file at +path+ is removed. It may be removed if the
      # cookbook containing it was removed from the run list, or if the file was
      # removed from the cookbook.
      def removed_cookbook_file(path)
      end

      # Called when cookbook cleaning is finished.
      def cookbook_clean_complete
      end

      # Called before cookbook sync starts
      def cookbook_sync_start(cookbook_count)
        puts_line "Synchronizing Cookbooks:"
        indent_by(2)
      end

      # Called when cookbook +cookbook_name+ has been sync'd
      def synchronized_cookbook(cookbook_name)
        puts_line "- #{cookbook_name}"
      end

      # Called when an individual file in a cookbook has been updated
      def updated_cookbook_file(cookbook_name, path)
      end

      # Called after all cookbooks have been sync'd.
      def cookbook_sync_complete
        indent_by(-2)
      end

      # Called when cookbook loading starts.
      def library_load_start(file_count)
        puts_line "Compiling Cookbooks..."
      end

      # Called after a file in a cookbook is loaded.
      def file_loaded(path)
      end

      # Called when recipes have been loaded.
      def recipe_load_complete
      end

      # Called before convergence starts
      def converge_start(run_context)
        puts_line "Converging #{run_context.resource_collection.all_resources.size} resources"
      end

      # Called when the converge phase is finished.
      def converge_complete
        indent_by(-2) if @current_recipe
      end

      # Called before action is executed on a resource.
      def resource_action_start(resource, action, notification_type=nil, notifier=nil)
        if resource.cookbook_name && resource.recipe_name
          resource_recipe = "#{resource.cookbook_name}::#{resource.recipe_name}"
        else
          resource_recipe = "<Dynamically Defined Resource>"
        end

        if resource_recipe != @current_recipe && !resource.enclosing_provider
          indent_by(-2) if @current_recipe
          puts_line "Recipe: #{resource_recipe}"
          @current_recipe = resource_recipe
          indent_by(2)
        end
        # TODO: info about notifies
        start_line "* #{resource} action #{action}"
        indent_by(2)
      end

      # Called when a resource fails, but will retry.
      def resource_failed_retriable(resource, action, retry_count, exception)
      end

      # Called when a resource fails and will not be retried.
      def resource_failed(resource, action, exception)
        super
        indent_by(-2)
      end

      # Called when a resource action has been skipped b/c of a conditional
      def resource_skipped(resource, action, conditional)
        # TODO: more info about conditional
        puts " (skipped due to #{conditional.short_description})"
        indent_by(-2)
      end

      # Called after #load_current_resource has run.
      def resource_current_state_loaded(resource, action, current_resource)
      end

      # Called when a resource has no converge actions, e.g., it was already correct.
      def resource_up_to_date(resource, action)
        @up_to_date_resources+= 1
        puts " (up to date)"
        indent_by(-2)
      end

      def resource_bypassed(resource, action, provider)
        puts " (Skipped: whyrun not supported by provider #{provider.class.name})"
        indent_by(-2)
      end

      def output_record(line)

      end

      # Called when a change has been made to a resource. May be called multiple
      # times per resource, e.g., a file may have its content updated, and then
      # its permissions updated.
      def resource_update_applied(resource, action, update)
        prefix = Chef::Config[:why_run] ? "Would " : ""
        Array(update).each do |line|
          next if line.nil?
          output_record line
          if line.kind_of? String
            start_line "- #{prefix}#{line}", :green
          elsif line.kind_of? Array
            # Expanded output - delta
            # @todo should we have a resource_update_delta callback?
            line.each do |detail|
              start_line detail, :white
            end
          end
        end
      end

      # Called after a resource has been completely converged.
      def resource_updated(resource, action)
        @updated_resources += 1
        indent_by(-2)
        puts "\n"
      end

      # Called when resource current state load is skipped due to the provider
      # not supporting whyrun mode.
      def resource_current_state_load_bypassed(resource, action, current_resource)
        puts_line("* Whyrun not supported for #{resource}, bypassing load.", :yellow)
      end

      # Called before handlers run
      def handlers_start(handler_count)
        puts ''
        puts "Running handlers:"
        indent_by(2)
      end

      # Called after an individual handler has run
      def handler_executed(handler)
        puts_line "- #{handler.class.name}"
      end

      # Called after all handlers have executed
      def handlers_completed
        indent_by(-2)
        puts_line "Running handlers complete\n"
      end

      # Called when a provider makes an assumption after a failed assertion
      # in whyrun mode, in order to allow execution to continue
      def whyrun_assumption(action, resource, message)
        return unless message
        [ message ].flatten.each do |line|
          start_line("* #{line}", :yellow)
        end
      end

      # Called when an assertion declared by a provider fails
      def provider_requirement_failed(action, resource, exception, message)
        return unless message
        color = Chef::Config[:why_run] ? :yellow : :red
        [ message ].flatten.each do |line|
          start_line("* #{line}", color)
        end
      end
    end
  end
end
