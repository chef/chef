#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

require 'chef/config'
require 'chef/mixin/params_validate'
require 'chef/mixin/path_sanity'
require 'chef/log'
require 'chef/rest'
require 'chef/api_client'
require 'chef/api_client/registration'
require 'chef/audit/runner'
require 'chef/node'
require 'chef/role'
require 'chef/file_cache'
require 'chef/run_context'
require 'chef/runner'
require 'chef/run_status'
require 'chef/cookbook/cookbook_collection'
require 'chef/cookbook/file_vendor'
require 'chef/cookbook/file_system_file_vendor'
require 'chef/cookbook/remote_file_vendor'
require 'chef/event_dispatch/dispatcher'
require 'chef/event_loggers/base'
require 'chef/event_loggers/windows_eventlog'
require 'chef/exceptions'
require 'chef/formatters/base'
require 'chef/formatters/doc'
require 'chef/formatters/minimal'
require 'chef/version'
require 'chef/resource_reporter'
require 'chef/audit/audit_reporter'
require 'chef/run_lock'
require 'chef/policy_builder'
require 'chef/request_id'
require 'chef/platform/rebooter'
require 'ohai'
require 'rbconfig'

class Chef
  # == Chef::Client
  # The main object in a Chef run. Preps a Chef::Node and Chef::RunContext,
  # syncs cookbooks if necessary, and triggers convergence.
  class Client
    include Chef::Mixin::PathSanity

    # IO stream that will be used as 'STDOUT' for formatters. Formatters are
    # configured during `initialize`, so this provides a convenience for
    # setting alternative IO stream during tests.
    STDOUT_FD = STDOUT

    # IO stream that will be used as 'STDERR' for formatters. Formatters are
    # configured during `initialize`, so this provides a convenience for
    # setting alternative IO stream during tests.
    STDERR_FD = STDERR

    # Clears all notifications for client run status events.
    # Primarily for testing purposes.
    def self.clear_notifications
      @run_start_notifications = nil
      @run_completed_successfully_notifications = nil
      @run_failed_notifications = nil
    end

    # The list of notifications to be run when the client run starts.
    def self.run_start_notifications
      @run_start_notifications ||= []
    end

    # The list of notifications to be run when the client run completes
    # successfully.
    def self.run_completed_successfully_notifications
      @run_completed_successfully_notifications ||= []
    end

    # The list of notifications to be run when the client run fails.
    def self.run_failed_notifications
      @run_failed_notifications ||= []
    end

    # Add a notification for the 'client run started' event. The notification
    # is provided as a block. The current Chef::RunStatus object will be passed
    # to the notification_block when the event is triggered.
    def self.when_run_starts(&notification_block)
      run_start_notifications << notification_block
    end

    # Add a notification for the 'client run success' event. The notification
    # is provided as a block. The current Chef::RunStatus object will be passed
    # to the notification_block when the event is triggered.
    def self.when_run_completes_successfully(&notification_block)
      run_completed_successfully_notifications << notification_block
    end

    # Add a notification for the 'client run failed' event. The notification
    # is provided as a block. The current Chef::RunStatus is passed to the
    # notification_block when the event is triggered.
    def self.when_run_fails(&notification_block)
      run_failed_notifications << notification_block
    end

    # Callback to fire notifications that the Chef run is starting
    def run_started
      self.class.run_start_notifications.each do |notification|
        notification.call(run_status)
      end
      @events.run_started(run_status)
    end

    # Callback to fire notifications that the run completed successfully
    def run_completed_successfully
      success_handlers = self.class.run_completed_successfully_notifications
      success_handlers.each do |notification|
        notification.call(run_status)
      end
    end

    # Callback to fire notifications that the Chef run failed
    def run_failed
      failure_handlers = self.class.run_failed_notifications
      failure_handlers.each do |notification|
        notification.call(run_status)
      end
    end

    attr_accessor :node
    attr_accessor :ohai
    attr_accessor :rest
    attr_accessor :runner

    attr_reader :json_attribs
    attr_reader :run_status
    attr_reader :events

    # Creates a new Chef::Client.
    def initialize(json_attribs=nil, args={})
      @json_attribs = json_attribs || {}
      @node = nil
      @runner = nil
      @ohai = Ohai::System.new

      event_handlers = configure_formatters + configure_event_loggers
      event_handlers += Array(Chef::Config[:event_handlers])

      @events = EventDispatch::Dispatcher.new(*event_handlers)
      @override_runlist = args.delete(:override_runlist)
      @specific_recipes = args.delete(:specific_recipes)
      @run_status = Chef::RunStatus.new(node, events)

      if new_runlist = args.delete(:runlist)
        @json_attribs["run_list"] = new_runlist
      end
    end

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

    def formatters_for_run
      if Chef::Config.formatters.empty?
        [default_formatter]
      else
        Chef::Config.formatters
      end
    end

    def default_formatter
      if (STDOUT.tty? && !Chef::Config[:force_logger]) || Chef::Config[:force_formatter]
        [:doc]
      else
        [:null]
      end
    end

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

    # Resource repoters send event information back to the chef server for processing.
    # Can only be called after we have a @rest object
    def register_reporters
      [
        Chef::ResourceReporter.new(rest),
        Chef::Audit::AuditReporter.new(rest)
      ].each do |r|
        events.register(r)
      end
    end

    # Instantiates a Chef::Node object, possibly loading the node's prior state
    # when using chef-client. Delegates to policy_builder.  Injects the built node
    # into the Chef class.
    #
    # @return [Chef::Node] The node object for this Chef run
    def load_node
      policy_builder.load_node
      @node = policy_builder.node
      Chef.set_node(@node)
      node
    end

    # Mutates the `node` object to prepare it for the chef run. Delegates to
    # policy_builder
    #
    # @return [Chef::Node] The updated node object
    def build_node
      policy_builder.build_node
      @run_status.node = node
      node
    end

    def setup_run_context
      run_context = policy_builder.setup_run_context(@specific_recipes)
      assert_cookbook_path_not_empty(run_context)
      run_status.run_context = run_context
      run_context
    end

    def sync_cookbooks
      policy_builder.sync_cookbooks
    end

    def policy_builder
      @policy_builder ||= Chef::PolicyBuilder.strategy.new(node_name, ohai.data, json_attribs, @override_runlist, events)
    end

    def save_updated_node
      if Chef::Config[:solo]
        # nothing to do
      elsif policy_builder.temporary_policy?
        Chef::Log.warn("Skipping final node save because override_runlist was given")
      else
        Chef::Log.debug("Saving the current state of node #{node_name}")
        @node.save
      end
    end

    def run_ohai
      filter = Chef::Config[:minimal_ohai] ? %w[fqdn machinename hostname platform platform_version os os_version] : nil
      ohai.all_plugins(filter)
      @events.ohai_completed(node)
    end

    def node_name
      name = Chef::Config[:node_name] || ohai[:fqdn] || ohai[:machinename] || ohai[:hostname]
      Chef::Config[:node_name] = name

      raise Chef::Exceptions::CannotDetermineNodeName unless name

      # node names > 90 bytes only work with authentication protocol >= 1.1
      # see discussion in config.rb.
      if name.bytesize > 90
        Chef::Config[:authentication_protocol_version] = "1.1"
      end

      name
    end

    #
    # === Returns
    # rest<Chef::REST>:: returns Chef::REST connection object
    def register(client_name=node_name, config=Chef::Config)
      if !config[:client_key]
        @events.skipping_registration(client_name, config)
        Chef::Log.debug("Client key is unspecified - skipping registration")
      elsif File.exists?(config[:client_key])
        @events.skipping_registration(client_name, config)
        Chef::Log.debug("Client key #{config[:client_key]} is present - skipping registration")
      else
        @events.registration_start(node_name, config)
        Chef::Log.info("Client key #{config[:client_key]} is not present - registering")
        Chef::ApiClient::Registration.new(node_name, config[:client_key]).run
        @events.registration_completed
      end
      # We now have the client key, and should use it from now on.
      @rest = Chef::REST.new(config[:chef_server_url], client_name, config[:client_key])
      register_reporters
    rescue Exception => e
      # TODO: munge exception so a semantic failure message can be given to the
      # user
      @events.registration_failed(client_name, e, config)
      raise
    end

    # Converges the node.
    #
    # === Returns
    # The thrown exception, if there was one.  If this returns nil the converge was successful.
    def converge(run_context)
      converge_exception = nil
      catch(:end_client_run_early) do
        begin
          @events.converge_start(run_context)
          Chef::Log.debug("Converging node #{node_name}")
          @runner = Chef::Runner.new(run_context)
          runner.converge
          @events.converge_complete
        rescue Exception => e
          @events.converge_failed(e)
          raise e if Chef::Config[:audit_mode] == :disabled
          converge_exception = e
        end
      end
      converge_exception
    end

    # We don't want to change the old API on the `converge` method to have it perform
    # saving.  So we wrap it in this method.
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

    def run_audits(run_context)
      audit_exception = nil
      begin
        @events.audit_phase_start(run_status)
        Chef::Log.info("Starting audit phase")
        auditor = Chef::Audit::Runner.new(run_context)
        auditor.run
        if auditor.failed?
          raise Chef::Exceptions::AuditsFailed.new(auditor.num_failed, auditor.num_total)
        end
        @events.audit_phase_complete
      rescue Exception => e
        Chef::Log.error("Audit phase failed with error message: #{e.message}")
        @events.audit_phase_failed(e)
        audit_exception = e
      end
      audit_exception
    end

    # Expands the run list. Delegates to the policy_builder.
    #
    # Normally this does not need to be called from here, it will be called by
    # build_node. This is provided so external users (like the chefspec
    # project) can inject custom behavior into the run process.
    #
    # === Returns
    # RunListExpansion: A RunListExpansion or API compatible object.
    def expanded_run_list
      policy_builder.expand_run_list
    end

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

    # Do a full run for this Chef::Client.  Calls:
    #
    #  * run_ohai - Collect information about the system
    #  * build_node - Get the last known state, merge with local changes
    #  * register - If not in solo mode, make sure the server knows about this client
    #  * sync_cookbooks - If not in solo mode, populate the local cache with the node's cookbooks
    #  * converge - Bring this system up to date
    #
    # === Returns
    # true:: Always returns true.
    def run
      runlock = RunLock.new(Chef::Config.lockfile)
      runlock.acquire
      # don't add code that may fail before entering this section to be sure to release lock
      begin
        runlock.save_pid

        request_id = Chef::RequestID.instance.request_id
        run_context = nil
        @events.run_start(Chef::VERSION)
        Chef::Log.info("*** Chef #{Chef::VERSION} ***")
        Chef::Log.info "Chef-client pid: #{Process.pid}"
        Chef::Log.debug("Chef-client request_id: #{request_id}")
        enforce_path_sanity
        run_ohai

        register unless Chef::Config[:solo]

        load_node

        build_node

        run_status.run_id = request_id
        run_status.start_clock
        Chef::Log.info("Starting Chef Run for #{node.name}")
        run_started

        do_windows_admin_check

        run_context = setup_run_context

        if Chef::Config[:audit_mode] != :audit_only
          converge_error = converge_and_save(run_context)
        end

        if Chef::Config[:why_run] == true
          # why_run should probably be renamed to why_converge
          Chef::Log.debug("Not running controls in 'why_run' mode - this mode is used to see potential converge changes")
        elsif Chef::Config[:audit_mode] != :disabled
          audit_error = run_audits(run_context)
        end

        if converge_error || audit_error
          e = Chef::Exceptions::RunFailedWrappingError.new(converge_error, audit_error)
          e.fill_backtrace
          raise e
        end

        run_status.stop_clock
        Chef::Log.info("Chef Run complete in #{run_status.elapsed_time} seconds")
        run_completed_successfully
        @events.run_completed(node)

        # rebooting has to be the last thing we do, no exceptions.
        Chef::Platform::Rebooter.reboot_if_needed!(node)

        true

      rescue Exception => e
        # CHEF-3336: Send the error first in case something goes wrong below and we don't know why
        Chef::Log.debug("Re-raising exception: #{e.class} - #{e.message}\n#{e.backtrace.join("\n  ")}")
        # If we failed really early, we may not have a run_status yet. Too early for these to be of much use.
        if run_status
          run_status.stop_clock
          run_status.exception = e
          run_failed
        end
        Chef::Application.debug_stacktrace(e)
        @events.run_failed(e)
        raise
      ensure
        Chef::RequestID.instance.reset_request_id
        request_id = nil
        @run_status = nil
        run_context = nil
        runlock.release
        GC.start
      end
      true
    end

    private

    def empty_directory?(path)
      !File.exists?(path) || (Dir.entries(path).size <= 2)
    end

    def is_last_element?(index, object)
      object.kind_of?(Array) ? index == object.size - 1 : true
    end

    def assert_cookbook_path_not_empty(run_context)
      if Chef::Config[:solo]
        # Check for cookbooks in the path given
        # Chef::Config[:cookbook_path] can be a string or an array
        # if it's an array, go through it and check each one, raise error at the last one if no files are found
        cookbook_paths = Array(Chef::Config[:cookbook_path])
        Chef::Log.debug "Loading from cookbook_path: #{cookbook_paths.map { |path| File.expand_path(path) }.join(', ')}"
        if cookbook_paths.all? {|path| empty_directory?(path) }
          msg = "None of the cookbook paths set in Chef::Config[:cookbook_path], #{cookbook_paths.inspect}, contain any cookbooks"
          Chef::Log.fatal(msg)
          raise Chef::Exceptions::CookbookNotFound, msg
        end
      else
        Chef::Log.warn("Node #{node_name} has an empty run list.") if run_context.node.run_list.empty?
      end

    end

    def has_admin_privileges?
      require 'chef/win32/security'

      Chef::ReservedNames::Win32::Security.has_admin_privileges?
    end

  end
end

# HACK cannot load this first, but it must be loaded.
require 'chef/cookbook_loader'
require 'chef/cookbook_version'
require 'chef/cookbook/synchronizer'
