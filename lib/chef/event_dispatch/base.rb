class Chef

  # ==EventDispatch
  # Classes in EventDispatch deal with collecting, distributing, and handling
  # information in response to events that occur during a chef-client run.
  #
  # EventDispatch uses a simple publishing system where data from all events
  # are forwarded to all subscribers unconditionally.
  #
  # EventDispatch is used to implement custom console output formatters so that
  # users may have more control over the formatting and verbosity of Chef
  # client output and client-side data collection for server-side client
  # history storage and reporting.
  #
  # === API Stability Status
  # The EventDispatch API is intended to become a stable, public API upon which
  # end-users can implement their own custom output formatters, reporting
  # integration libraries, and more. This is a new feature, however, so
  # breaking changes may be required as it "bakes" in order to provide a clean,
  # coherent and supportable API in the long term. Therefore, developers should
  # consider the feature "beta" for now and be prepared for possible breaking
  # changes in point releases.
  module EventDispatch

    # == EventDispatch::Base
    # EventDispatch::Base is a completely abstract base class that defines the
    # API used by both the classes that collect event information and those
    # that process them.
    class Base

      # Called at the very start of a Chef Run
      def run_start(version, run_status); end

      def run_started(run_status); end

      # Called at the end a successful Chef run.
      def run_completed(node, run_status); end

      # Called at the end of a failed Chef run.
      def run_failed(exception, run_status); end

      # Called right after ohai runs.
      # NOTE: the node object here is always nil because of when it is called
      def ohai_completed(node); end

      # Announce that we're not going to register the client. Generally because
      # we already have the private key, or because we're deliberately not using
      # a key.
      def skipping_registration(node_name, config); end

      # About to attempt to create a private key registered to the server with
      # client +node_name+.
      def registration_start(node_name, config); end

      # Successfully created the private key and registered this client with the
      # server.
      def registration_completed; end

      # Failed to register this client with the server.
      def registration_failed(node_name, exception, config); end

      # Called before Chef client loads the node data from the server
      def node_load_start(node_name, config); end

      # TODO: def node_run_list_overridden(*args)

      # Called once the node is loaded by the policy builder
      def node_load_success(node); end

      # Failed to load node data from the server
      def node_load_failed(node_name, exception, config); end

      # Error expanding the run list
      def run_list_expand_failed(node, exception); end

      # Called after Chef client has loaded the node data.
      # Default and override attrs from roles have been computed, but not yet applied.
      # Normal attrs from JSON have been added to the node.
      def node_load_completed(node, expanded_run_list, config); end

      # Called after the Policyfile was loaded. This event only occurs when
      # chef is in policyfile mode.
      def policyfile_loaded(policy); end

      # Called before the cookbook collection is fetched from the server.
      def cookbook_resolution_start(expanded_run_list); end

      # Called when there is an error getting the cookbook collection from the
      # server.
      def cookbook_resolution_failed(expanded_run_list, exception); end

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
      def cookbook_sync_start(cookbook_count); end

      # Called when cookbook +cookbook+ has been sync'd
      def synchronized_cookbook(cookbook_name, cookbook); end

      # Called when an individual file in a cookbook has been updated
      def updated_cookbook_file(cookbook_name, path); end

      # Called when an error occurs during cookbook sync
      def cookbook_sync_failed(cookbooks, exception); end

      # Called after all cookbooks have been sync'd.
      def cookbook_sync_complete; end

      # Called when starting to collect gems from the cookbooks
      def cookbook_gem_start(gems); end

      # Called when the result of installing the bundle is to install the gem
      def cookbook_gem_installing(gem, version); end

      # Called when the result of installing the bundle is to use the gem
      def cookbook_gem_using(gem, version); end

      # Called when finished installing cookbook gems
      def cookbook_gem_finished; end

      # Called when cookbook gem installation fails
      def cookbook_gem_failed(exception); end

      ## TODO: add cookbook name to the API for file load callbacks

      ## TODO: add callbacks for overall cookbook eval start and complete.

      # Called immediately after creating the run_context and before any cookbook compilation happens
      def cookbook_compilation_start(run_context); end

      # Called when library file loading starts
      def library_load_start(file_count); end

      # Called when library file has been loaded
      def library_file_loaded(path); end

      # Called when a library file has an error on load.
      def library_file_load_failed(path, exception); end

      # Called when library file loading has finished
      def library_load_complete; end

      # Called when LWRP loading starts
      def lwrp_load_start(lwrp_file_count); end

      # Called after a LWR or LWP has been loaded
      def lwrp_file_loaded(path); end

      # Called after a LWR or LWP file errors on load
      def lwrp_file_load_failed(path, exception); end

      # Called when LWRPs are finished loading
      def lwrp_load_complete; end

      # Called when an ohai plugin file loading starts
      def ohai_plugin_load_start(file_count); end

      # Called when an ohai plugin file has been loaded
      def ohai_plugin_file_loaded(path); end

      # Called when an ohai plugin file has an error on load.
      def ohai_plugin_file_load_failed(path, exception); end

      # Called when an ohai plugin file loading has finished
      def ohai_plugin_load_complete; end

      # Called before attribute files are loaded
      def attribute_load_start(attribute_file_count); end

      # Called after the attribute file is loaded
      def attribute_file_loaded(path); end

      # Called when an attribute file fails to load.
      def attribute_file_load_failed(path, exception); end

      # Called when attribute file loading is finished
      def attribute_load_complete; end

      # Called before resource definitions are loaded
      def definition_load_start(definition_file_count); end

      # Called when a resource definition has been loaded
      def definition_file_loaded(path); end

      # Called when a resource definition file fails to load
      def definition_file_load_failed(path, exception); end

      # Called when resource definitions are done loading
      def definition_load_complete; end

      # Called before recipes are loaded
      def recipe_load_start(recipe_count); end

      # Called after the recipe has been loaded
      def recipe_file_loaded(path, recipe); end

      # Called after a recipe file fails to load
      def recipe_file_load_failed(path, exception, recipe); end

      # Called when a recipe cannot be resolved
      def recipe_not_found(exception); end

      # Called when recipes have been loaded.
      def recipe_load_complete; end

      # This is called after all cookbook compilation phases are completed.
      def cookbook_compilation_complete(run_context); end

      # Called before convergence starts
      def converge_start(run_context); end

      # Callback hook for handlers to grab a reference to the action_collection
      # (sent before compiling cookbooks, consumers can also find it off the run_context.action_collection)
      def action_collection_registration(action_collection); end

      # Called when the converge phase is finished.
      def converge_complete; end

      # Called if the converge phase fails
      def converge_failed(exception); end

      # TODO: need events for notification resolve?
      # def notifications_resolved
      # end

      #
      # Resource events and ordering:
      #
      # 1. Start the action
      #    - resource_action_start
      # 2. Check the guard
      #    - resource_skipped: (goto 7) if only_if/not_if say to skip
      # 3. Load the current resource
      #    - resource_current_state_loaded
      #    - resource_current_state_load_bypassed (if not why-run safe)
      # 4. Check if why-run safe
      #    - resource_bypassed: (goto 7) if not why-run safe
      # 5. During processing:
      #    - resource_update_applied: For each actual change (many per action)
      # 6. Processing complete status:
      #    - resource_failed if the resource threw an exception while running
      #    - resource_failed_retriable: (goto 3) if resource failed and will be retried
      #    - resource_updated if the resource was updated (resource_update_applied will have been called)
      #    - resource_up_to_date if the resource was up to date (no resource_update_applied)
      # 7. Processing complete:
      #    - resource_completed
      #

      # Called before action is executed on a resource.
      def resource_action_start(resource, action, notification_type = nil, notifier = nil); end

      # Called when a resource action has been skipped b/c of a conditional
      def resource_skipped(resource, action, conditional); end

      # Called after #load_current_resource has run.
      def resource_current_state_loaded(resource, action, current_resource); end

      # Called after #load_after_resource has run.
      def resource_after_state_loaded(resource, action, after_resource); end

      # Called when resource current state load is skipped due to the provider
      # not supporting whyrun mode.
      def resource_current_state_load_bypassed(resource, action, current_resource); end

      # Called when evaluating a resource that does not support whyrun in whyrun mode
      def resource_bypassed(resource, action, current_resource); end

      # Called when a change has been made to a resource. May be called multiple
      # times per resource, e.g., a file may have its content updated, and then
      # its permissions updated.
      def resource_update_applied(resource, action, update); end

      # Called when a progress notification should be sent to the user to
      # indicate the overall progress of a long running operation, such as
      # a large file download.
      def resource_update_progress(resource, current, total, interval); end

      # Called when a resource fails, but will retry.
      def resource_failed_retriable(resource, action, retry_count, exception); end

      # Called when a resource fails and will not be retried.
      def resource_failed(resource, action, exception); end

      # Called after a resource has been completely converged, but only if
      # modifications were made.
      def resource_updated(resource, action); end

      # Called when a resource has no converge actions, e.g., it was already correct.
      def resource_up_to_date(resource, action); end

      # Called when a resource action has been completed
      def resource_completed(resource); end

      # A stream has opened.
      def stream_opened(stream, options = {}); end

      # A stream has closed.
      def stream_closed(stream, options = {}); end

      # A chunk of data from a stream.  The stream is managed by "stream," which
      # can be any tag whatsoever.  Data in different "streams" may not be placed
      # on the same line or even sent to the same console.
      def stream_output(stream, output, options = {}); end

      # Called before handlers run
      def handlers_start(handler_count); end

      # Called after an individual handler has run
      def handler_executed(handler); end

      # Called after all handlers have executed
      def handlers_completed; end

      # Called when an assertion declared by a provider fails
      def provider_requirement_failed(action, resource, exception, message); end

      # Called when a provider makes an assumption after a failed assertion
      # in whyrun mode, in order to allow execution to continue
      def whyrun_assumption(action, resource, message); end

      # Emit a message about something being deprecated.
      def deprecation(message, location = caller(2..2)[0]); end

      def run_list_expanded(run_list_expansion); end

      # An uncategorized message. This supports the case that a user needs to
      # pass output that doesn't fit into one of the callbacks above. Note that
      # there's no semantic information about the content or importance of the
      # message. That means that if you're using this too often, you should add a
      # callback for it.
      def msg(message); end

      # Called when an attribute is changed by simple assignment
      def attribute_changed(precedence, keys, value); end
    end
  end
end
