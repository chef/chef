#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/config"
require "chef/mixin/params_validate"
require "chef/mixin/path_sanity"
require "chef/log"
require "chef/deprecated"
require "chef/server_api"
require "chef/api_client"
require "chef/api_client/registration"
require "chef/audit/runner"
require "chef/node"
require "chef/role"
require "chef/file_cache"
require "chef/run_context"
require "chef/runner"
require "chef/run_status"
require "chef/cookbook/cookbook_collection"
require "chef/cookbook/file_vendor"
require "chef/cookbook/file_system_file_vendor"
require "chef/cookbook/remote_file_vendor"
require "chef/event_dispatch/dispatcher"
require "chef/event_loggers/base"
require "chef/event_loggers/windows_eventlog"
require "chef/exceptions"
require "chef/formatters/base"
require "chef/formatters/doc"
require "chef/formatters/minimal"
require "chef/version"
require "chef/resource_reporter"
require "chef/data_collector"
require "chef/audit/audit_reporter"
require "chef/run_lock"
require "chef/policy_builder"
require "chef/request_id"
require "chef/platform/rebooter"
require "chef/mixin/deprecation"
require "ohai"
require "rbconfig"

class Chef
  # == Chef::Client
  # The main object in a Chef run. Preps a Chef::Node and Chef::RunContext,
  # syncs cookbooks if necessary, and triggers convergence.
  class Client
    include Chef::Mixin::PathSanity

    extend Chef::Mixin::Deprecation

    #
    # The status of the Chef run.
    #
    # @return [Chef::RunStatus]
    #
    attr_reader :run_status

    #
    # The node represented by this client.
    #
    # @return [Chef::Node]
    #
    def node
      run_status.node
    end

    def node=(value)
      run_status.node = value
    end

    #
    # The ohai system used by this client.
    #
    # @return [Ohai::System]
    #
    attr_reader :ohai

    #
    # The rest object used to communicate with the Chef server.
    #
    # @return [Chef::ServerAPI]
    #
    attr_reader :rest

    #
    # A rest object with validate_utf8 set to false.  This will not throw exceptions
    # on non-UTF8 strings in JSON but will sanitize them so that e.g. POSTs will
    # never fail.  Cannot be configured on a request-by-request basis, so we carry
    # around another rest object for it.
    #
    attr_reader :rest_clean

    #
    # The runner used to converge.
    #
    # @return [Chef::Runner]
    #
    attr_accessor :runner

    #
    # Extra node attributes that were applied to the node.
    #
    # @return [Hash]
    #
    attr_reader :json_attribs

    #
    # The event dispatcher for the Chef run, including any configured output
    # formatters and event loggers.
    #
    # @return [EventDispatch::Dispatcher]
    #
    # @see Chef::Formatters
    # @see Chef::Config#formatters
    # @see Chef::Config#stdout
    # @see Chef::Config#stderr
    # @see Chef::Config#force_logger
    # @see Chef::Config#force_formatter
    # TODO add stdout, stderr, and default formatters to Chef::Config so the
    # defaults aren't calculated here.  Remove force_logger and force_formatter
    # from this code.
    # @see Chef::EventLoggers
    # @see Chef::Config#disable_event_logger
    # @see Chef::Config#event_loggers
    # @see Chef::Config#event_handlers
    #
    attr_reader :events

    #
    # Creates a new Chef::Client.
    #
    # @param json_attribs [Hash] Node attributes to layer into the node when it is
    #   fetched.
    # @param args [Hash] Options:
    # @option args [Array<RunList::RunListItem>] :override_runlist A runlist to
    #   use instead of the node's embedded run list.
    # @option args [Array<String>] :specific_recipes A list of recipe file paths
    #   to load after the run list has been loaded.
    #
    def initialize(json_attribs = nil, args = {})
      @json_attribs = json_attribs || {}
      @ohai = Ohai::System.new

      event_handlers = configure_formatters + configure_event_loggers
      event_handlers += Array(Chef::Config[:event_handlers])

      @events = EventDispatch::Dispatcher.new(*event_handlers)
      # TODO it seems like a bad idea to be deletin' other peoples' hashes.
      @override_runlist = args.delete(:override_runlist)
      @specific_recipes = args.delete(:specific_recipes)
      @run_status = Chef::RunStatus.new(nil, events)

      if new_runlist = args.delete(:runlist)
        @json_attribs["run_list"] = new_runlist
      end
    end

    #
    # Do a full run for this Chef::Client.
    #
    # Locks the run while doing its job.
    #
    # Fires run_start before doing anything and fires run_completed or
    # run_failed when finished.  Also notifies client listeners of run_started
    # at the beginning of Compile, and run_completed_successfully or run_failed
    # when all is complete.
    #
    # Phase 1: Setup
    # --------------
    # Gets information about the system and the run we are doing.
    #
    # 1. Run ohai to collect system information.
    # 2. Register / connect to the Chef server (unless in solo mode).
    # 3. Retrieve the node (or create a new one).
    # 4. Merge in json_attribs, Chef::Config.environment, and override_run_list.
    #
    # @see #run_ohai
    # @see #load_node
    # @see #build_node
    # @see Chef::Config#lockfile
    # @see Chef::RunLock#acquire
    #
    # Phase 2: Compile
    # ----------------
    # Decides *what* we plan to converge by compiling recipes.
    #
    # 1. Sync required cookbooks to the local cache.
    # 2. Load libraries from all cookbooks.
    # 3. Load attributes from all cookbooks.
    # 4. Load LWRPs from all cookbooks.
    # 5. Load resource definitions from all cookbooks.
    # 6. Load recipes in the run list.
    # 7. Load recipes from the command line.
    #
    # @see #setup_run_context Syncs and compiles cookbooks.
    # @see Chef::CookbookCompiler#compile
    #
    # Phase 3: Converge
    # -----------------
    # Brings the system up to date.
    #
    # 1. Converge the resources built from recipes in Phase 2.
    # 2. Save the node.
    # 3. Reboot if we were asked to.
    #
    # @see #converge_and_save
    # @see Chef::Runner
    #
    # Phase 4: Audit
    # --------------
    # Runs 'control_group' audits in recipes.  This entire section can be enabled or disabled with config.
    #
    # 1. 'control_group' DSL collects audits during Phase 2
    # 2. Audits are run using RSpec
    # 3. Errors are collected and reported using the formatters
    #
    # @see #run_audits
    # @see Chef::Audit::Runner#run
    #
    # @raise [Chef::Exceptions::RunFailedWrappingError] If converge or audit failed.
    #
    # @see Chef::Config#enforce_path_sanity
    # @see Chef::Config#solo
    # @see Chef::Config#audit_mode
    #
    # @return Always returns true.
    #
    def run
      start_profiling

      run_error = nil

      runlock = RunLock.new(Chef::Config.lockfile)
      # TODO feels like acquire should have its own block arg for this
      runlock.acquire
      # don't add code that may fail before entering this section to be sure to release lock
      begin
        runlock.save_pid

        request_id = Chef::RequestID.instance.request_id
        run_context = nil
        events.run_start(Chef::VERSION)
        Chef::Log.info("*** Chef #{Chef::VERSION} ***")
        Chef::Log.info("Platform: #{RUBY_PLATFORM}")
        Chef::Log.info "Chef-client pid: #{Process.pid}"
        Chef::Log.debug("Chef-client request_id: #{request_id}")
        enforce_path_sanity
        run_ohai

        register unless Chef::Config[:solo_legacy_mode]
        register_data_collector_reporter

        load_node

        build_node

        run_status.run_id = request_id
        run_status.start_clock
        Chef::Log.info("Starting Chef Run for #{node.name}")
        run_started

        do_windows_admin_check

        run_context = setup_run_context

        load_required_recipe(@rest, run_context) unless Chef::Config[:solo_legacy_mode]

        if Chef::Config[:audit_mode] != :audit_only
          converge_error = converge_and_save(run_context)
        end

        if Chef::Config[:why_run] == true
          # why_run should probably be renamed to why_converge
          Chef::Log.debug("Not running controls in 'why-run' mode - this mode is used to see potential converge changes")
        elsif Chef::Config[:audit_mode] != :disabled
          audit_error = run_audits(run_context)
        end

        # Raise converge_error so run_failed reporters/events are processed.
        raise converge_error if converge_error

        run_status.stop_clock
        Chef::Log.info("Chef Run complete in #{run_status.elapsed_time} seconds")
        run_completed_successfully
        events.run_completed(node)

        # keep this inside the main loop to get exception backtraces
        end_profiling

        # rebooting has to be the last thing we do, no exceptions.
        Chef::Platform::Rebooter.reboot_if_needed!(node)
      rescue Exception => run_error
        # CHEF-3336: Send the error first in case something goes wrong below and we don't know why
        Chef::Log.debug("Re-raising exception: #{run_error.class} - #{run_error.message}\n#{run_error.backtrace.join("\n  ")}")
        # If we failed really early, we may not have a run_status yet. Too early for these to be of much use.
        if run_status
          run_status.stop_clock
          run_status.exception = run_error
          run_failed
        end
        events.run_failed(run_error)
      ensure
        Chef::RequestID.instance.reset_request_id
        @run_status = nil
        runlock.release
      end

      # Raise audit, converge, and other errors here so that we exit
      # with the proper exit status code and everything gets raised
      # as a RunFailedWrappingError
      if run_error || converge_error || audit_error
        error = if Chef::Config[:audit_mode] == :disabled
                  run_error || converge_error
                else
                  e = if run_error == converge_error
                        Chef::Exceptions::RunFailedWrappingError.new(converge_error, audit_error)
                      else
                        Chef::Exceptions::RunFailedWrappingError.new(run_error, converge_error, audit_error)
                      end
                  e.fill_backtrace
                  e
                end

        Chef::Application.debug_stacktrace(error)
        raise error
      end

      true
    end

    #
    # Private API
    # TODO make this stuff protected or private
    #

    # @api private
    def configure_formatters
      formatters_for_run.map do |formatter_name, output_path|
        if output_path.nil?
          Chef::Formatters.new(formatter_name, STDOUT_FD, STDERR_FD)
        else
          io = File.open(output_path, "a+")
          io.sync = true
          Chef::Formatters.new(formatter_name, io, io)
        end
      end
    end

    # @api private
    def formatters_for_run
      if Chef::Config.formatters.empty?
        [default_formatter]
      else
        Chef::Config.formatters
      end
    end

    # @api private
    def default_formatter
      if !Chef::Config[:force_logger] || Chef::Config[:force_formatter]
        [:doc]
      else
        [:null]
      end
    end

    # @api private
    def configure_event_loggers
      if Chef::Config.disable_event_logger
        []
      else
        Chef::Config.event_loggers.map do |evt_logger|
          case evt_logger
          when Symbol
            Chef::EventLoggers.new(evt_logger)
          when Class
            evt_logger.new
          else
          end
        end
      end
    end

    # Rest client for use by API reporters.  This rest client will not fail with an exception if
    # it is fed non-UTF8 data.
    #
    # @api private
    def rest_clean(client_name = node_name, config = Chef::Config)
      @rest_clean ||=
        Chef::ServerAPI.new(config[:chef_server_url], client_name: client_name,
                                                      signing_key_filename: config[:client_key], validate_utf8: false)
    end

    # Resource reporters send event information back to the chef server for
    # processing.  Can only be called after we have a @rest object
    # @api private
    def register_reporters
      [
        Chef::ResourceReporter.new(rest_clean),
        Chef::Audit::AuditReporter.new(rest_clean),
      ].each do |r|
        events.register(r)
      end
    end

    #
    # Callback to fire notifications that the Chef run is starting
    #
    # @api private
    #
    def run_started
      self.class.run_start_notifications.each do |notification|
        notification.call(run_status)
      end
      events.run_started(run_status)
    end

    #
    # Callback to fire notifications that the run completed successfully
    #
    # @api private
    #
    def run_completed_successfully
      success_handlers = self.class.run_completed_successfully_notifications
      success_handlers.each do |notification|
        notification.call(run_status)
      end
    end

    #
    # Callback to fire notifications that the Chef run failed
    #
    # @api private
    #
    def run_failed
      failure_handlers = self.class.run_failed_notifications
      failure_handlers.each do |notification|
        notification.call(run_status)
      end
    end

    #
    # Instantiates a Chef::Node object, possibly loading the node's prior state
    # when using chef-client. Sets Chef.node to the new node.
    #
    # @return [Chef::Node] The node object for this Chef run
    #
    # @see Chef::PolicyBuilder#load_node
    #
    # @api private
    #
    def load_node
      policy_builder.load_node
      run_status.node = policy_builder.node
      Chef.set_node(policy_builder.node)
      node
    end

    #
    # Mutates the `node` object to prepare it for the chef run.
    #
    # @return [Chef::Node] The updated node object
    #
    # @see Chef::PolicyBuilder#build_node
    #
    # @api private
    #
    def build_node
      policy_builder.build_node
      run_status.node = node
      node
    end

    #
    # Sync cookbooks to local cache.
    #
    # TODO this appears to be unused.
    #
    # @see Chef::PolicyBuilder#sync_cookbooks
    #
    # @api private
    #
    def sync_cookbooks
      policy_builder.sync_cookbooks
    end

    #
    # Sets up the run context.
    #
    # @see Chef::PolicyBuilder#setup_run_context
    #
    # @return The newly set up run context
    #
    # @api private
    def setup_run_context
      run_context = policy_builder.setup_run_context(specific_recipes)
      assert_cookbook_path_not_empty(run_context)
      run_status.run_context = run_context
      run_context
    end

    #
    # Adds a required recipe as specified by the Chef Server
    #
    # @return The modified run context
    #
    # @api private
    #
    # TODO: @rest doesn't appear to be used anywhere outside
    # of client.register except for here. If it's common practice
    # to create your own rest client, perhaps we should do that
    # here but it seems more appropriate to reuse one that we
    # know is already created. for ease of testing, we'll pass
    # the existing rest client in as a parameter
    #
    def load_required_recipe(rest, run_context)
      required_recipe_contents = rest.get("required_recipe")
      Chef::Log.info("Required Recipe found, loading it")
      Chef::FileCache.store("required_recipe", required_recipe_contents)
      required_recipe_file = Chef::FileCache.load("required_recipe", false)

      # TODO: add integration tests with resource reporting turned on
      #       (presumably requires changes to chef-zero)
      #
      # Chef::Recipe.new takes a cookbook name and a recipe name along
      # with the run context. These names are eventually used in the
      # resource reporter, and if the cookbook name cannot be found in the
      # cookbook collection then we will fail with an exception. Cases where
      # we currently also fail:
      #   - specific recipes
      #   - chef-apply would fail if resource reporting was enabled
      #
      recipe = Chef::Recipe.new(nil, nil, run_context)
      recipe.from_file(required_recipe_file)
      run_context
    rescue Net::HTTPServerException => e
      case e.response
      when Net::HTTPNotFound
        Chef::Log.debug("Required Recipe not configured on the server, skipping it")
      else
        raise
      end
    end

    #
    # The PolicyBuilder strategy for figuring out run list and cookbooks.
    #
    # @return [Chef::PolicyBuilder::Policyfile, Chef::PolicyBuilder::ExpandNodeObject]
    #
    # @api private
    #
    def policy_builder
      @policy_builder ||= Chef::PolicyBuilder::Dynamic.new(node_name, ohai.data, json_attribs, override_runlist, events)
    end

    #
    # Save the updated node to Chef.
    #
    # Does not save if we are in solo mode or using override_runlist.
    #
    # @see Chef::Node#save
    # @see Chef::Config#solo
    #
    # @api private
    #
    def save_updated_node
      if Chef::Config[:solo_legacy_mode]
        # nothing to do
      elsif policy_builder.temporary_policy?
        Chef::Log.warn("Skipping final node save because override_runlist was given")
      else
        Chef::Log.debug("Saving the current state of node #{node_name}")
        node.save
      end
    end

    #
    # Run ohai plugins.  Runs all ohai plugins unless minimal_ohai is specified.
    #
    # Sends the ohai_completed event when finished.
    #
    # @see Chef::EventDispatcher#
    # @see Chef::Config#minimal_ohai
    #
    # @api private
    #
    def run_ohai
      filter = Chef::Config[:minimal_ohai] ? %w{fqdn machinename hostname platform platform_version os os_version} : nil
      ohai.all_plugins(filter)
      events.ohai_completed(node)
    end

    #
    # Figure out the node name we are working with.
    #
    # It tries these, in order:
    # - Chef::Config.node_name
    # - ohai[:fqdn]
    # - ohai[:machinename]
    # - ohai[:hostname]
    #
    # @raise [Chef::Exceptions::CannotDetermineNodeName] If the node name is not
    #   set and cannot be determined via ohai.
    #
    # @see Chef::Config#node_name
    #
    # @api private
    #
    def node_name
      name = Chef::Config[:node_name] || ohai[:fqdn] || ohai[:machinename] || ohai[:hostname]
      Chef::Config[:node_name] = name

      raise Chef::Exceptions::CannotDetermineNodeName unless name

      name
    end

    #
    # Determine our private key and set up the connection to the Chef server.
    #
    # Skips registration and fires the `skipping_registration` event if
    # Chef::Config.client_key is unspecified or already exists.
    #
    # If Chef::Config.client_key does not exist, we register the client with the
    # Chef server and fire the registration_start and registration_completed events.
    #
    # @return [Chef::ServerAPI] The server connection object.
    #
    # @see Chef::Config#chef_server_url
    # @see Chef::Config#client_key
    # @see Chef::ApiClient::Registration#run
    # @see Chef::EventDispatcher#skipping_registration
    # @see Chef::EventDispatcher#registration_start
    # @see Chef::EventDispatcher#registration_completed
    # @see Chef::EventDispatcher#registration_failed
    #
    # @api private
    #
    def register(client_name = node_name, config = Chef::Config)
      if !config[:client_key]
        events.skipping_registration(client_name, config)
        Chef::Log.debug("Client key is unspecified - skipping registration")
      elsif File.exists?(config[:client_key])
        events.skipping_registration(client_name, config)
        Chef::Log.debug("Client key #{config[:client_key]} is present - skipping registration")
      else
        events.registration_start(node_name, config)
        Chef::Log.info("Client key #{config[:client_key]} is not present - registering")
        Chef::ApiClient::Registration.new(node_name, config[:client_key]).run
        events.registration_completed
      end
      # We now have the client key, and should use it from now on.
      @rest = Chef::ServerAPI.new(config[:chef_server_url], client_name: client_name,
                                                            signing_key_filename: config[:client_key])
      # force initialization of the rest_clean API object
      rest_clean(client_name, config)
      register_reporters
    rescue Exception => e
      # TODO this should probably only ever fire if we *started* registration.
      # Move it to the block above.
      # TODO: munge exception so a semantic failure message can be given to the
      # user
      events.registration_failed(client_name, e, config)
      raise
    end

    #
    # Converges all compiled resources.
    #
    # Fires the converge_start, converge_complete and converge_failed events.
    #
    # If the exception `:end_client_run_early` is thrown during convergence, it
    # does not mark the run complete *or* failed, and returns `nil`
    #
    # @param run_context The run context.
    #
    # @return The thrown exception, if we are in audit mode. `nil` means the
    #   converge was successful or ended early.
    #
    # @raise Any converge exception, unless we are in audit mode, in which case
    #   we *return* the exception.
    #
    # @see Chef::Runner#converge
    # @see Chef::Config#audit_mode
    # @see Chef::EventDispatch#converge_start
    # @see Chef::EventDispatch#converge_complete
    # @see Chef::EventDispatch#converge_failed
    #
    # @api private
    #
    def converge(run_context)
      converge_exception = nil
      catch(:end_client_run_early) do
        begin
          events.converge_start(run_context)
          Chef::Log.debug("Converging node #{node_name}")
          @runner = Chef::Runner.new(run_context)
          @runner.converge
          events.converge_complete
        rescue Exception => e
          events.converge_failed(e)
          raise e if Chef::Config[:audit_mode] == :disabled
          converge_exception = e
        end
      end
      converge_exception
    end

    #
    # Converge the node via and then save it if successful.
    #
    # @param run_context The run context.
    #
    # @return The thrown exception, if we are in audit mode. `nil` means the
    #   converge was successful or ended early.
    #
    # @raise Any converge or node save exception, unless we are in audit mode,
    #   in which case we *return* the exception.
    #
    # @see #converge
    # @see #save_updated_mode
    # @see Chef::Config#audit_mode
    #
    # @api private
    #
    # We don't want to change the old API on the `converge` method to have it perform
    # saving.  So we wrap it in this method.
    # TODO given this seems to be pretty internal stuff, how badly do we need to
    # split this stuff up?
    #
    def converge_and_save(run_context)
      converge_exception = converge(run_context)
      unless converge_exception
        begin
          save_updated_node
        rescue Exception => e
          raise e if Chef::Config[:audit_mode] == :disabled
          converge_exception = e
        end
      end
      converge_exception
    end

    #
    # Run the audit phase.
    #
    # Triggers the audit_phase_start, audit_phase_complete and
    # audit_phase_failed events.
    #
    # @param run_context The run context.
    #
    # @return Any thrown exceptions. `nil` if successful.
    #
    # @see Chef::Audit::Runner#run
    # @see Chef::EventDispatch#audit_phase_start
    # @see Chef::EventDispatch#audit_phase_complete
    # @see Chef::EventDispatch#audit_phase_failed
    #
    # @api private
    #
    def run_audits(run_context)
      begin
        events.audit_phase_start(run_status)
        Chef::Log.info("Starting audit phase")
        auditor = Chef::Audit::Runner.new(run_context)
        auditor.run
        if auditor.failed?
          audit_exception = Chef::Exceptions::AuditsFailed.new(auditor.num_failed, auditor.num_total)
          @events.audit_phase_failed(audit_exception, Chef::Audit::Logger.read_buffer)
        else
          @events.audit_phase_complete(Chef::Audit::Logger.read_buffer)
        end
      rescue Exception => e
        Chef::Log.error("Audit phase failed with error message: #{e.message}")
        @events.audit_phase_failed(e, Chef::Audit::Logger.read_buffer)
        audit_exception = e
      end
      audit_exception
    end

    #
    # Expands the run list.
    #
    # @return [Chef::RunListExpansion] The expanded run list.
    #
    # @see Chef::PolicyBuilder#expand_run_list
    #
    def expanded_run_list
      policy_builder.expand_run_list
    end

    #
    # Check if the user has Administrator privileges on windows.
    #
    # Throws an error if the user is not an admin, and
    # `Chef::Config.fatal_windows_admin_check` is true.
    #
    # @raise [Chef::Exceptions::WindowsNotAdmin] If the user is not an admin.
    #
    # @see Chef::platform#windows?
    # @see Chef::Config#fatal_windows_admin_check
    #
    # @api private
    #
    def do_windows_admin_check
      if Chef::Platform.windows?
        Chef::Log.debug("Checking for administrator privileges....")

        if !has_admin_privileges?
          message = "chef-client doesn't have administrator privileges on node #{node_name}."
          if Chef::Config[:fatal_windows_admin_check]
            Chef::Log.fatal(message)
            Chef::Log.fatal("fatal_windows_admin_check is set to TRUE.")
            raise Chef::Exceptions::WindowsNotAdmin, message
          else
            Chef::Log.warn("#{message} This might cause unexpected resource failures.")
          end
        else
          Chef::Log.debug("chef-client has administrator privileges on node #{node_name}.")
        end
      end
    end

    # Notification registration
    class<<self
      #
      # Add a listener for the 'client run started' event.
      #
      # @param notification_block The callback (takes |run_status| parameter).
      # @yieldparam [Chef::RunStatus] run_status The run status.
      #
      def when_run_starts(&notification_block)
        run_start_notifications << notification_block
      end

      #
      # Add a listener for the 'client run success' event.
      #
      # @param notification_block The callback (takes |run_status| parameter).
      # @yieldparam [Chef::RunStatus] run_status The run status.
      #
      def when_run_completes_successfully(&notification_block)
        run_completed_successfully_notifications << notification_block
      end

      #
      # Add a listener for the 'client run failed' event.
      #
      # @param notification_block The callback (takes |run_status| parameter).
      # @yieldparam [Chef::RunStatus] run_status The run status.
      #
      def when_run_fails(&notification_block)
        run_failed_notifications << notification_block
      end

      #
      # Clears all listeners for client run status events.
      #
      # Primarily for testing purposes.
      #
      # @api private
      #
      def clear_notifications
        @run_start_notifications = nil
        @run_completed_successfully_notifications = nil
        @run_failed_notifications = nil
      end

      #
      # TODO These seem protected to me.
      #

      #
      # Listeners to be run when the client run starts.
      #
      # @return [Array<Proc>]
      #
      # @api private
      #
      def run_start_notifications
        @run_start_notifications ||= []
      end

      #
      # Listeners to be run when the client run completes successfully.
      #
      # @return [Array<Proc>]
      #
      # @api private
      #
      def run_completed_successfully_notifications
        @run_completed_successfully_notifications ||= []
      end

      #
      # Listeners to be run when the client run fails.
      #
      # @return [Array<Proc>]
      #
      # @api private
      #
      def run_failed_notifications
        @run_failed_notifications ||= []
      end
    end

    #
    # IO stream that will be used as 'STDOUT' for formatters. Formatters are
    # configured during `initialize`, so this provides a convenience for
    # setting alternative IO stream during tests.
    #
    # @api private
    #
    STDOUT_FD = STDOUT

    #
    # IO stream that will be used as 'STDERR' for formatters. Formatters are
    # configured during `initialize`, so this provides a convenience for
    # setting alternative IO stream during tests.
    #
    # @api private
    #
    STDERR_FD = STDERR

    private

    attr_reader :override_runlist
    attr_reader :specific_recipes

    def profiling_prereqs!
      require "ruby-prof"
    rescue LoadError
      raise "You must have the ruby-prof gem installed in order to use --profile-ruby"
    end

    def start_profiling
      return unless Chef::Config[:profile_ruby]
      profiling_prereqs!
      RubyProf.start
    end

    def end_profiling
      return unless Chef::Config[:profile_ruby]
      profiling_prereqs!
      path = Chef::FileCache.create_cache_path("graph_profile.out", false)
      File.open(path, "w+") do |file|
        RubyProf::GraphPrinter.new(RubyProf.stop).print(file, {})
      end
      Chef::Log.warn("Ruby execution profile dumped to #{path}")
    end

    def empty_directory?(path)
      !File.exists?(path) || (Dir.entries(path).size <= 2)
    end

    def is_last_element?(index, object)
      object.kind_of?(Array) ? index == object.size - 1 : true
    end

    def assert_cookbook_path_not_empty(run_context)
      if Chef::Config[:solo_legacy_mode]
        # Check for cookbooks in the path given
        # Chef::Config[:cookbook_path] can be a string or an array
        # if it's an array, go through it and check each one, raise error at the last one if no files are found
        cookbook_paths = Array(Chef::Config[:cookbook_path])
        Chef::Log.debug "Loading from cookbook_path: #{cookbook_paths.map { |path| File.expand_path(path) }.join(', ')}"
        if cookbook_paths.all? { |path| empty_directory?(path) }
          msg = "None of the cookbook paths set in Chef::Config[:cookbook_path], #{cookbook_paths.inspect}, contain any cookbooks"
          Chef::Log.fatal(msg)
          raise Chef::Exceptions::CookbookNotFound, msg
        end
      else
        Chef::Log.warn("Node #{node_name} has an empty run list.") if run_context.node.run_list.empty?
      end
    end

    def has_admin_privileges?
      require "chef/win32/security"

      Chef::ReservedNames::Win32::Security.has_admin_privileges?
    end

    # Register the data collector reporter to send event information to the
    # data collector server
    def register_data_collector_reporter
      events.register(Chef::DataCollector::Reporter.new) if Chef::DataCollector.register_reporter?
    end
  end
end

# HACK cannot load this first, but it must be loaded.
require "chef/cookbook_loader"
require "chef/cookbook_version"
require "chef/cookbook/synchronizer"
