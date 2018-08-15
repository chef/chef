require "chef/formatters/base"

class Chef

  module Formatters

    # == Formatters::Minimal
    # Shows the progress of the chef run by printing single characters, and
    # displays a summary of updates at the conclusion of the run. For events
    # that don't have meaningful status information (loading a file, syncing a
    # cookbook) a dot is printed. For resources, a dot, 'S' or 'U' is printed
    # if the resource is up to date, skipped by not_if/only_if, or updated,
    # respectively.
    class Minimal < Formatters::Base

      cli_name(:minimal)
      cli_name(:min)

      attr_reader :updated_resources
      attr_reader :updates_by_resource

      def initialize(out, err)
        super
        @updated_resources = []
        @updates_by_resource = Hash.new { |h, k| h[k] = [] }
      end

      # Called at the very start of a Chef Run
      def run_start(version)
        puts_line "Starting Chef Client, version #{version}"
        puts_line "OpenSSL FIPS 140 mode enabled" if Chef::Config[:fips]
      end

      # Called at the end of the Chef run.
      def run_completed(node)
        puts "chef client finished, #{@updated_resources.size} resources updated"
      end

      # called at the end of a failed run
      def run_failed(exception)
        puts "chef client failed. #{@updated_resources.size} resources updated"
      end

      # Called right after ohai runs.
      def ohai_completed(node)
      end

      # Already have a client key, assuming this node has registered.
      def skipping_registration(node_name, config)
      end

      # About to attempt to register as +node_name+
      def registration_start(node_name, config)
      end

      def registration_completed
      end

      # Failed to register this client with the server.
      def registration_failed(node_name, exception, config)
        super
      end

      def node_load_start(node_name, config)
      end

      # Failed to load node data from the server
      def node_load_failed(node_name, exception, config)
      end

      # Default and override attrs from roles have been computed, but not yet applied.
      # Normal attrs from JSON have been added to the node.
      def node_load_completed(node, expanded_run_list, config)
      end

      # Called before the cookbook collection is fetched from the server.
      def cookbook_resolution_start(expanded_run_list)
        puts "resolving cookbooks for run list: #{expanded_run_list.inspect}"
      end

      # Called when there is an error getting the cookbook collection from the
      # server.
      def cookbook_resolution_failed(expanded_run_list, exception)
      end

      # Called when the cookbook collection is returned from the server.
      def cookbook_resolution_complete(cookbook_collection)
      end

      # Called before unneeded cookbooks are removed
      #--
      # TODO: Should be called in CookbookVersion.sync_cookbooks
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
        puts "Synchronizing cookbooks"
      end

      # Called when cookbook +cookbook+ has been sync'd
      def synchronized_cookbook(cookbook_name, cookbook)
        print "."
      end

      # Called when an individual file in a cookbook has been updated
      def updated_cookbook_file(cookbook_name, path)
      end

      # Called after all cookbooks have been sync'd.
      def cookbook_sync_complete
        puts "done."
      end

      # Called when cookbook loading starts.
      def library_load_start(file_count)
        puts "Compiling cookbooks"
      end

      # Called after a file in a cookbook is loaded.
      def file_loaded(path)
        print "."
      end

      def file_load_failed(path, exception)
        super
      end

      # Called when recipes have been loaded.
      def recipe_load_complete
        puts "done."
      end

      # Called before convergence starts
      def converge_start(run_context)
        puts "Converging #{run_context.resource_collection.all_resources.size} resources"
      end

      # Called when the converge phase is finished.
      def converge_complete
        puts "\n"
        puts "System converged."
        if updated_resources.empty?
          puts "no resources updated"
        else
          puts "\n"
          puts "resources updated this run:"
          updated_resources.each do |resource|
            puts "* #{resource}"
            updates_by_resource[resource.name].flatten.each do |update|
              puts "  - #{update}"
            end
            puts "\n"
          end
        end
      end

      # Called before action is executed on a resource.
      def resource_action_start(resource, action, notification_type = nil, notifier = nil)
      end

      # Called when a resource fails, but will retry.
      def resource_failed_retriable(resource, action, retry_count, exception)
      end

      # Called when a resource fails and will not be retried.
      def resource_failed(resource, action, exception)
      end

      # Called when a resource action has been skipped b/c of a conditional
      def resource_skipped(resource, action, conditional)
        print "S"
      end

      # Called after #load_current_resource has run.
      def resource_current_state_loaded(resource, action, current_resource)
      end

      # Called when a resource has no converge actions, e.g., it was already correct.
      def resource_up_to_date(resource, action)
        print "."
      end

      ## TODO: callback for assertion failures

      ## TODO: callback for assertion fallback in why run

      # Called when a change has been made to a resource. May be called multiple
      # times per resource, e.g., a file may have its content updated, and then
      # its permissions updated.
      def resource_update_applied(resource, action, update)
        @updates_by_resource[resource.name] << Array(update)[0]
      end

      # Called after a resource has been completely converged.
      def resource_updated(resource, action)
        updated_resources << resource
        print "U"
      end

      # Called before handlers run
      def handlers_start(handler_count)
      end

      # Called after an individual handler has run
      def handler_executed(handler)
      end

      # Called after all handlers have executed
      def handlers_completed
      end

      # An uncategorized message. This supports the case that a user needs to
      # pass output that doesn't fit into one of the callbacks above. Note that
      # there's no semantic information about the content or importance of the
      # message. That means that if you're using this too often, you should add a
      # callback for it.
      def msg(message)
      end

    end
  end
end
