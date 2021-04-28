require_relative "base"
require_relative "../config"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  module Formatters

    # Formatter similar to RSpec's documentation formatter. Uses indentation to
    # show context.
    class Doc < Formatters::Base

      attr_reader :start_time, :end_time

      cli_name(:doc)

      def initialize(out, err)
        super

        @updated_resources = 0
        @up_to_date_resources = 0
        @start_time = Time.now
        @end_time = @start_time
        @skipped_resources = 0
        @progress = {}
      end

      def elapsed_time
        end_time - start_time
      end

      def pretty_elapsed_time
        time = elapsed_time
        if time < 60
          message = Time.at(time).utc.strftime("%S seconds")
        elsif time < 3600
          message = Time.at(time).utc.strftime("%M minutes %S seconds")
        else
          message = Time.at(time).utc.strftime("%H hours %M minutes %S seconds")
        end
        message
      end

      def run_start(version, run_status)
        puts_line "Starting #{ChefUtils::Dist::Infra::PRODUCT}, version #{version}"
        puts_line "Patents: #{ChefUtils::Dist::Org::PATENTS}"
        puts_line "Targeting node: #{Chef::Config.target_mode.host}" if Chef::Config.target_mode?
        puts_line "OpenSSL FIPS 140 mode enabled" if Chef::Config[:fips]
      end

      def total_resources
        @up_to_date_resources + @updated_resources + @skipped_resources
      end

      def run_completed(node)
        @end_time = Time.now
        # Print out deprecations.
        unless deprecations.empty?
          puts_line ""
          puts_line "Deprecation warnings that must be addressed before upgrading to Chef Infra #{Chef::VERSION.to_i + 1}:"
          puts_line ""
          deprecations.each do |message, details|
            locations = details[:locations]
            if locations.size == 1
              puts_line "  #{message} at 1 location:"
            else
              puts_line "  #{message} at #{locations.size} locations:"
            end
            locations.each do |location|
              prefix = "    - "
              Array(location).each do |line|
                puts_line "#{prefix}#{line}"
                prefix = "      "
              end
            end
            unless details[:url].nil?
              puts_line "   See #{details[:url]} for further details."
            end
          end
          puts_line ""
        end
        if Chef::Config[:why_run]
          puts_line "#{ChefUtils::Dist::Infra::PRODUCT} finished, #{@updated_resources}/#{total_resources} resources would have been updated"
        else
          puts_line "#{ChefUtils::Dist::Infra::PRODUCT} finished, #{@updated_resources}/#{total_resources} resources updated in #{pretty_elapsed_time}"
        end
      end

      def run_failed(exception)
        @end_time = Time.now
        if Chef::Config[:why_run]
          puts_line "#{ChefUtils::Dist::Infra::PRODUCT} failed. #{@updated_resources} resources would have been updated"
        else
          puts_line "#{ChefUtils::Dist::Infra::PRODUCT} failed. #{@updated_resources} resources updated in #{pretty_elapsed_time}"
        end
      end

      # Called right after ohai runs.
      def ohai_completed(node); end

      # Already have a client key, assuming this node has registered.
      def skipping_registration(node_name, config); end

      # About to attempt to register as +node_name+
      def registration_start(node_name, config)
        puts_line "Creating a new client identity for #{node_name} using the validator key."
      end

      def registration_completed; end

      def node_load_start(node_name, config); end

      # Failed to load node data from the server
      def node_load_failed(node_name, exception, config)
        super
      end

      # Default and override attrs from roles have been computed, but not yet applied.
      # Normal attrs from JSON have been added to the node.
      def node_load_completed(node, expanded_run_list, config); end

      def policyfile_loaded(policy)
        puts_line "Using policy '#{policy["name"]}' at revision '#{policy["revision_id"]}'"
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
      def cookbook_resolution_complete(cookbook_collection); end

      # Called before unneeded cookbooks are removed
      def cookbook_clean_start; end

      # Called after the file at +path+ is removed. It may be removed if the
      # cookbook containing it was removed from the run list, or if the file was
      # removed from the cookbook.
      def removed_cookbook_file(path); end

      # Called when cookbook cleaning is finished.
      def cookbook_clean_complete; end

      # Called before cookbook sync starts
      def cookbook_sync_start(cookbook_count)
        puts_line "Synchronizing Cookbooks:"
        indent
      end

      # Called when cookbook +cookbook+ has been sync'd
      def synchronized_cookbook(cookbook_name, cookbook)
        puts_line "- #{cookbook.name} (#{cookbook.version})"
      end

      # Called when an individual file in a cookbook has been updated
      def updated_cookbook_file(cookbook_name, path); end

      # Called after all cookbooks have been sync'd.
      def cookbook_sync_complete
        unindent
      end

      # Called when starting to collect gems from the cookbooks
      def cookbook_gem_start(gems)
        puts_line "Installing Cookbook Gems:"
        indent
      end

      # Called when the result of installing the bundle is to install the gem
      def cookbook_gem_installing(gem, version)
        puts_line "- Installing #{gem} #{version}", :green
      end

      # Called when the result of installing the bundle is to use the gem
      def cookbook_gem_using(gem, version)
        puts_line "- Using #{gem} #{version}"
      end

      # Called when finished installing cookbook gems
      def cookbook_gem_finished
        unindent
      end

      # Called when cookbook gem installation fails
      def cookbook_gem_failed(exception)
        unindent
      end

      # Called when cookbook loading starts.
      def library_load_start(file_count)
        puts_line "Compiling Cookbooks..."
      end

      # Called after a file in a cookbook is loaded.
      def file_loaded(path); end

      # Called when recipes have been loaded.
      def recipe_load_complete; end

      # Called before convergence starts
      def converge_start(run_context)
        puts_line "Converging #{run_context.resource_collection.all_resources.size} resources"
      end

      # Called when the converge phase is finished.
      def converge_complete
        unindent if @current_recipe
      end

      def converge_failed(e)
        # Currently a failed converge is handled the same way as a successful converge
        converge_complete
      end

      # Called before action is executed on a resource.
      def resource_action_start(resource, action, notification_type = nil, notifier = nil)
        if resource.cookbook_name && resource.recipe_name
          resource_recipe = "#{resource.cookbook_name}::#{resource.recipe_name}"
        else
          resource_recipe = "<Dynamically Defined Resource>"
        end

        if resource_recipe != @current_recipe && !resource.enclosing_provider
          unindent if @current_recipe
          puts_line "Recipe: #{resource_recipe}"
          @current_recipe = resource_recipe
          indent
        end
        # @todo info about notifies
        start_line "* #{resource} action #{action}", stream: resource
        indent
      end

      def resource_update_progress(resource, current, total, interval)
        @progress[resource] ||= -1

        percent_complete = (current.to_f / total.to_f * 100).to_i unless total.to_f == 0.0

        if percent_complete && percent_complete > @progress[resource]

          @progress[resource] = percent_complete

          if percent_complete % interval == 0
            start_line " - Progress: #{percent_complete}%", :green
          end
        end
      end

      # Called when a resource fails, but will retry.
      def resource_failed_retriable(resource, action, retry_count, exception); end

      # Called when a resource fails and will not be retried.
      def resource_failed(resource, action, exception)
        super
        unindent
      end

      # Called when a resource action has been skipped b/c of a conditional
      def resource_skipped(resource, action, conditional)
        @skipped_resources += 1
        # TODO: more info about conditional
        puts " (skipped due to #{conditional.short_description})", stream: resource
        unindent
      end

      # Called after #load_current_resource has run.
      def resource_current_state_loaded(resource, action, current_resource); end

      # Called when a resource has no converge actions, e.g., it was already correct.
      def resource_up_to_date(resource, action)
        @up_to_date_resources += 1
        puts " (up to date)", stream: resource unless resource.suppress_up_to_date_messages?
        unindent
      end

      def resource_bypassed(resource, action, provider)
        puts " (Skipped: whyrun not supported by provider #{provider.class.name})", stream: resource
        unindent
      end

      def output_record(line); end

      # Called when a change has been made to a resource. May be called multiple
      # times per resource, e.g., a file may have its content updated, and then
      # its permissions updated.
      def resource_update_applied(resource, action, update)
        prefix = Chef::Config[:why_run] ? "Would " : ""
        Array(update).each do |line|
          next if line.nil?

          output_record line
          if line.is_a? String
            start_line "- #{prefix}#{line}", :green
          elsif line.is_a? Array
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
        unindent
        puts "\n"
      end

      # Called when resource current state load is skipped due to the provider
      # not supporting whyrun mode.
      def resource_current_state_load_bypassed(resource, action, current_resource)
        puts_line("* Whyrun not supported for #{resource}, bypassing load.", :yellow)
      end

      def stream_output(stream, output, options = {})
        print(output, { stream: stream }.merge(options))
      end

      # Called before handlers run
      def handlers_start(handler_count)
        puts ""
        puts "Running handlers:"
        indent
      end

      # Called after an individual handler has run
      def handler_executed(handler)
        puts_line "- #{handler.class.name}"
      end

      # Called after all handlers have executed
      def handlers_completed
        unindent
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

      # (see Base#deprecation)
      def deprecation(deprecation, _location = nil)
        if Chef::Config[:treat_deprecation_warnings_as_errors]
          super
        elsif !deprecation.silenced?
          # Save non-silenced deprecations to the screen until the end.
          deprecations[deprecation.message] ||= { url: deprecation.url, locations: Set.new }
          deprecations[deprecation.message][:locations] << deprecation.location
        end
      end

      def indent
        indent_by(2)
      end

      def unindent
        indent_by(-2)
      end

      protected

      def deprecations
        @deprecations ||= {}
      end
    end
  end
end
