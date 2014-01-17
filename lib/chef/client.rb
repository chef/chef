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
require 'chef/platform/query_helpers'
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
require 'chef/formatters/base'
require 'chef/formatters/doc'
require 'chef/formatters/minimal'
require 'chef/version'
require 'chef/resource_reporter'
require 'chef/run_lock'
require 'chef/policy_builder'
require 'ohai'
require 'rbconfig'

class Chef
  # == Chef::Client
  # The main object in a Chef run. Preps a Chef::Node and Chef::RunContext,
  # syncs cookbooks if necessary, and triggers convergence.
  class Client
    include Chef::Mixin::PathSanity

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

    #--
    # TODO: timh/cw: 5-19-2010: json_attribs should be moved to RunContext?
    attr_reader :json_attribs
    attr_reader :run_status
    attr_reader :events

    # Creates a new Chef::Client.
    def initialize(json_attribs=nil, args={})
      @json_attribs = json_attribs
      @node = nil
      @run_status = nil
      @runner = nil
      @ohai = Ohai::System.new

      event_handlers = configure_formatters
      event_handlers += Array(Chef::Config[:event_handlers])

      @events = EventDispatch::Dispatcher.new(*event_handlers)
      @override_runlist = args.delete(:override_runlist)
      @specific_recipes = args.delete(:specific_recipes)
    end

    def configure_formatters
      formatters_for_run.map do |formatter_name, output_path|
        if output_path.nil?
          Chef::Formatters.new(formatter_name, STDOUT, STDERR)
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

    # Do a full run for this Chef::Client.  Calls:
    # * do_run
    #
    # This provides a wrapper around #do_run allowing the
    # run to be optionally forked.
    # === Returns
    # boolean:: Return value from #do_run. Should always returns true.
    def run
      # win32-process gem exposes some form of :fork for Process
      # class. So we are seperately ensuring that the platform we're
      # running on is not windows before forking.
      if(Chef::Config[:client_fork] && Process.respond_to?(:fork) && !Chef::Platform.windows?)
        Chef::Log.info "Forking chef instance to converge..."
        pid = fork do
          [:INT, :TERM].each {|s| trap(s, "EXIT") }
          client_solo = Chef::Config[:solo] ? "chef-solo" : "chef-client"
          $0 = "#{client_solo} worker: ppid=#{Process.ppid};start=#{Time.new.strftime("%R:%S")};"
          begin
            Chef::Log.debug "Forked instance now converging"
            do_run
          rescue Exception => e
            Chef::Log.error(e.to_s)
            exit 1
          else
            exit 0
          end
        end
        Chef::Log.debug "Fork successful. Waiting for new chef pid: #{pid}"
        result = Process.waitpid2(pid)
        handle_child_exit(result)
        Chef::Log.debug "Forked instance successfully reaped (pid: #{pid})"
        true
      else
        do_run
      end
    end

    def handle_child_exit(pid_and_status)
      status = pid_and_status[1]
      return true if status.success?
      message = if status.signaled?
        "Chef run process terminated by signal #{status.termsig} (#{Signal.list.invert[status.termsig]})"
      else
        "Chef run process exited unsuccessfully (exit code #{status.exitstatus})"
      end
      raise Exceptions::ChildConvergeError, message
    end

    def load_node
      policy_builder.load_node
      @node = policy_builder.node
    end

    def build_node
      policy_builder.build_node
      @run_status = Chef::RunStatus.new(node, events)
    end

    def setup_run_context
      run_context = policy_builder.setup_run_context(@specific_recipes)
      assert_cookbook_path_not_empty(run_context)
      run_status.run_context = run_context
      run_context
    end

    def policy_builder
      @policy_builder ||= Chef::PolicyBuilder.strategy.new(node_name, ohai.data, json_attribs, @override_runlist, events)
    end


    def save_updated_node
      unless Chef::Config[:solo]
        Chef::Log.debug("Saving the current state of node #{node_name}")
        if(@original_runlist)
          @node.run_list(*@original_runlist)
          @node.automatic_attrs[:runlist_override_history] = {Time.now.to_i => @override_runlist.inspect}
        end
        @node.save
      end
    end

    def run_ohai
      ohai.all_plugins
    end

    def node_name
      name = Chef::Config[:node_name] || ohai[:fqdn] || ohai[:hostname]
      Chef::Config[:node_name] = name

      unless name
        msg = "Unable to determine node name: configure node_name or configure the system's hostname and fqdn"
        raise Chef::Exceptions::CannotDetermineNodeName, msg
      end

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
      @resource_reporter = Chef::ResourceReporter.new(@rest)
      @events.register(@resource_reporter)
    rescue Exception => e
      # TODO: munge exception so a semantic failure message can be given to the
      # user
      @events.registration_failed(node_name, e, config)
      raise
    end

    # Converges the node.
    #
    # === Returns
    # true:: Always returns true
    def converge(run_context)
      @events.converge_start(run_context)
      Chef::Log.debug("Converging node #{node_name}")
      @runner = Chef::Runner.new(run_context)
      runner.converge
      @events.converge_complete
      true
    rescue Exception
      # TODO: should this be a separate #converge_failed(exception) method?
      @events.converge_complete
      raise
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

    private

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
    def do_run
      runlock = RunLock.new(Chef::Config.lockfile)
      runlock.acquire
      # don't add code that may fail before entering this section to be sure to release lock
      begin
        runlock.save_pid
        run_context = nil
        @events.run_start(Chef::VERSION)
        Chef::Log.info("*** Chef #{Chef::VERSION} ***")
        Chef::Log.info "Chef-client pid: #{Process.pid}"
        enforce_path_sanity
        run_ohai
        @events.ohai_completed(node)
        register unless Chef::Config[:solo]

        load_node

        build_node

        run_status.start_clock
        Chef::Log.info("Starting Chef Run for #{node.name}")
        run_started

        do_windows_admin_check

        run_context = setup_run_context

        converge(run_context)

        save_updated_node

        run_status.stop_clock
        Chef::Log.info("Chef Run complete in #{run_status.elapsed_time} seconds")
        run_completed_successfully
        @events.run_completed(node)
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
        @run_status = nil
        run_context = nil
        runlock.release
        GC.start
      end
      true
    end

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

