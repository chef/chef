class Chef

  # Receives callbacks from various stages of a Chef run, printing information
  # in a user-friendly format.
  #--
  # TODO: this should form the base of a dispatcher that forwards info to
  # multiple end-user objects. Known use cases for now are configurable/pretty
  # Console output formatters and reporting data collectors.
  #
  # Before making this "final" the API needs to be future-proofed by making the
  # higher arity methods take a single Struct object as input so we can add
  # fields in the future.
  #
  # Also. Should provide aggregate methods for file load/fail/complete, so
  # implementors can easily do the same thing for all/most file types.
  class ConsoleUI

    attr_reader :updated_resources
    attr_reader :updates_by_resource


    def initialize
      require 'pp'
      @updated_resources = []
      @updates_by_resource = Hash.new {|h, k| h[k] = []}
    end

    # Called at the very start of a Chef Run
    def run_start(version)
      puts "Starting Chef Client, version #{version}"
    end

    # Called at the end of the Chef run.
    def run_completed
      puts "Chef Client finished, #{@updated_resources.size} resources updated"
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
    #--
    # TODO: this will encourage mixing of the meaning of the various failure
    # scenarios with presentation concerns. Probably should error handling in
    # Client#register figure out what the various errors are and wrap it up.
    def registration_failed(node_name, exception, config)
    end

    def node_load_start(node_name, config)
    end

    # Failed to load node data from the server
    #--
    # TODO: refactor Chef::Client so that logic to figure out the meaning of
    # the exception occurs there and not in here. This is the first API request
    # that is made if the client key already exists.
    def node_load_failed(node_name, exception, config)
    end

    # Default and override attrs from roles have been computed, but not yet applied.
    # Normal attrs from JSON have been added to the node.
    #--
    # TODO: need to handle run list overrides.
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
    #--
    # TODO: should be called in CookbookVersion.clear_obsoleted_cookbooks
    def removed_cookbook_file(path)
    end

    # Called when cookbook cleaning is finished.
    def cookbook_clean_complete
    end

    # Called before cookbook sync starts
    #--
    # TODO: Should be called in CookbookVersion.sync_cookbooks
    def cookbook_sync_start(cookbook_count)
      puts "Synchronizing cookbooks"
    end

    # Called when cookbook +cookbook_name+ has been sync'd
    def synchronized_cookbook(cookbook_name)
      print "."
    end

    # Called when an individual file in a cookbook has been updated
    def updated_cookbook_file(cookbook_name, path)
    end

    # Called after all cookbooks have been sync'd.
    def cookbook_sync_complete
      puts "done."
    end

    ## TODO: add cookbook name to the API for file load callbacks

    # Called when library file loading starts
    def library_load_start(file_count)
      puts "Evaluating cookbooks"
    end

    # Called when library file has been loaded
    def library_file_loaded(path)
      print "."
    end

    # Called when a library file has an error on load.
    def library_file_load_failed(path, exception)
    end

    # Called when library file loading has finished
    def library_load_complete
    end

    # Called when LWRP loading starts
    def lwrp_load_start(lwrp_file_count)
    end

    # Called after a LWR or LWP has been loaded
    def lwrp_file_loaded(path)
      print "."
    end

    # Called after a LWR or LWP file errors on load
    def lwrp_file_load_failed(path, exception)
    end

    # Called when LWRPs are finished loading
    def lwrp_load_complete
    end

    # Called before attribute files are loaded
    def attribute_load_start(attribute_file_count)
    end

    # Called after the attribute file is loaded
    def attribute_file_loaded(path)
      print "."
    end

    # Called when an attribute file fails to load.
    def attribute_file_load_failed(path, exception)
    end

    # Called when attribute file loading is finished
    def attribute_load_complete
    end

    # Called before resource definitions are loaded
    def definition_load_start(definition_file_count)
    end

    # Called when a resource definition has been loaded
    def definition_file_loaded(path)
      print "."
    end

    # Called when a resource definition file fails to load
    def definition_file_load_failed(path, exception)
    end

    # Called when resource defintions are done loading
    def definition_load_complete
    end

    # Called before recipes are loaded
    def recipe_load_start(recipe_count)
    end

    # Called after the recipe has been loaded
    def recipe_file_loaded(path)
      print "."
    end

    # Calles after a recipe file fails to load
    def recipe_file_load_failed(path, exception)
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
      puts "\nsystem converged."
      if updated_resources.empty?
        puts "no resources updated"
      else
        puts "resources updated this run:"
        updated_resources.each do |resource|
          puts "* #{resource.to_s}"
          updates_by_resource[resource.name].flatten.each do |update|
            puts "  - #{update}"
          end
        end
      end
    end

    # TODO: need events for notification resolve?
    # def notifications_resolved
    # end

    # Called before action is executed on a resource.
    def resource_action_start(resource, action, notification_type=nil, notifier=nil)
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
      @updates_by_resource[resource.name] << update
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
