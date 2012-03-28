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
require 'chef/platform'
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
require 'chef/version'
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
    end

    # Callback to fire notifications that the run completed successfully
    def run_completed_successfully
      self.class.run_completed_successfully_notifications.each do |notification|
        notification.call(run_status)
      end
    end

    # Callback to fire notifications that the Chef run failed
    def run_failed
      self.class.run_failed_notifications.each do |notification|
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

    # Creates a new Chef::Client.
    def initialize(json_attribs=nil, args={})
      @json_attribs = json_attribs
      @node = nil
      @run_status = nil
      @runner = nil
      @ohai = Ohai::System.new
      @override_runlist = args.delete(:override_runlist)
      runlist_override_sanity_check!
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
      run_context = nil

      Chef::Log.info("*** Chef #{Chef::VERSION} ***")
      enforce_path_sanity
      run_ohai
      register unless Chef::Config[:solo]
      build_node

      begin

        run_status.start_clock
        Chef::Log.info("Starting Chef Run for #{node.name}")
        run_started

        run_context = setup_run_context
        converge(run_context)
        save_updated_node

        run_status.stop_clock
        Chef::Log.info("Chef Run complete in #{run_status.elapsed_time} seconds")
        run_completed_successfully
        true
      rescue Exception => e
        run_status.stop_clock
        run_status.exception = e
        run_failed
        Chef::Log.debug("Re-raising exception: #{e.class} - #{e.message}\n#{e.backtrace.join("\n  ")}")
        raise
      ensure
        run_status = nil
      end
      true
    end


    # Configures the Chef::Cookbook::FileVendor class to fetch file from the
    # server or disk as appropriate, creates the run context for this run, and
    # sanity checks the cookbook collection.
    #===Returns
    # Chef::RunContext:: the run context for this run.
    def setup_run_context
      if Chef::Config[:solo]
        Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, Chef::Config[:cookbook_path]) }
        run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new(Chef::CookbookLoader.new(Chef::Config[:cookbook_path])))
      else
        Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::RemoteFileVendor.new(manifest, rest) }
        cookbook_hash = sync_cookbooks
        run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new(cookbook_hash))
      end
      run_status.run_context = run_context

      run_context.load(@run_list_expansion)
      assert_cookbook_path_not_empty(run_context)
      run_context
    end

    def save_updated_node
      unless Chef::Config[:solo]
        Chef::Log.debug("Saving the current state of node #{node_name}")
        if(@original_runlist)
          @node.run_list(*@original_original)
          @node[:runlist_override_history] = {Time.now.to_i => @override_runlist.inspect}
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

      name
    end

    # Builds a new node object for this client.  Starts with querying for the FQDN of the current
    # host (unless it is supplied), then merges in the facts from Ohai.
    #
    # === Returns
    # node<Chef::Node>:: Returns the created node object, also stored in @node
    def build_node
      Chef::Log.debug("Building node object for #{node_name}")

      if Chef::Config[:solo]
        @node = Chef::Node.build(node_name)
      else
        @node = Chef::Node.find_or_create(node_name)
      end

      # Allow user to override the environment of a node by specifying
      # a config parameter.
      if Chef::Config[:environment] && !Chef::Config[:environment].chop.empty?
        @node.chef_environment(Chef::Config[:environment])
      end

      # consume_external_attrs may add items to the run_list. Save the
      # expanded run_list, which we will pass to the server later to
      # determine which versions of cookbooks to use.
      @node.reset_defaults_and_overrides
      @node.consume_external_attrs(ohai.data, @json_attribs)

      unless(@override_runlist.empty?)
        @original_runlist = @node.run_list.run_list_items.dup
        runlist_override_sanity_check!
        @node.run_list(*@override_runlist)
        Chef::Log.warn "Run List override has been provided."
        Chef::Log.warn "Original Run List: [#{@original_runlist.join(', ')}]"
        Chef::Log.warn "Overridden Run List: [#{@node.run_list}]"
      end

      if Chef::Config[:solo]
        @run_list_expansion = @node.expand!('disk')
      else
        @run_list_expansion = @node.expand!('server')
      end

      # @run_list_expansion is a RunListExpansion.
      #
      # Convert @expanded_run_list, which is an
      # Array of Hashes of the form
      #   {:name => NAME, :version_constraint => Chef::VersionConstraint },
      # into @expanded_run_list_with_versions, an
      # Array of Strings of the form
      #   "#{NAME}@#{VERSION}"
      @expanded_run_list_with_versions = @run_list_expansion.recipes.with_version_constraints_strings

      Chef::Log.info("Run List is [#{@node.run_list}]")
      Chef::Log.info("Run List expands to [#{@expanded_run_list_with_versions.join(', ')}]")

      @run_status = Chef::RunStatus.new(@node)

      @node
    end

    #
    # === Returns
    # rest<Chef::REST>:: returns Chef::REST connection object
    def register(client_name=node_name, config=Chef::Config)
      if File.exists?(config[:client_key])
        Chef::Log.debug("Client key #{config[:client_key]} is present - skipping registration")
      else
        Chef::Log.info("Client key #{config[:client_key]} is not present - registering")
        Chef::REST.new(config[:client_url], config[:validation_client_name], config[:validation_key]).register(client_name, config[:client_key])
      end
      # We now have the client key, and should use it from now on.
      self.rest = Chef::REST.new(config[:chef_server_url], client_name, config[:client_key])
    end

    # Sync_cookbooks eagerly loads all files except files and
    # templates.  It returns the cookbook_hash -- the return result
    # from /environments/#{node.chef_environment}/cookbook_versions,
    # which we will use for our run_context.
    #
    # === Returns
    # Hash:: The hash of cookbooks with download URLs as given by the server
    def sync_cookbooks
      Chef::Log.debug("Synchronizing cookbooks")
      cookbook_hash = rest.post_rest("environments/#{@node.chef_environment}/cookbook_versions",
                                     {:run_list => @expanded_run_list_with_versions})
      Chef::CookbookVersion.sync_cookbooks(cookbook_hash)

      # register the file cache path in the cookbook path so that CookbookLoader actually picks up the synced cookbooks
      Chef::Config[:cookbook_path] = File.join(Chef::Config[:file_cache_path], "cookbooks")

      cookbook_hash
    end

    # Converges the node.
    #
    # === Returns
    # true:: Always returns true
    def converge(run_context)
      Chef::Log.debug("Converging node #{node_name}")
      @runner = Chef::Runner.new(run_context)
      runner.converge
      true
    end

    private

    # Ensures runlist override contains RunListItem instances
    def runlist_override_sanity_check!
      @override_runlist = @override_runlist.split(',') if @override_runlist.is_a?(String)
      @override_runlist = [@override_runlist].flatten.compact
      @override_runlist.map! do |item|
        if(item.is_a?(Chef::RunList::RunListItem))
          item
        else
          Chef::RunList::RunListItem.new(item)
        end
      end
    end

    def directory_not_empty?(path)
      File.exists?(path) && (Dir.entries(path).size > 2)
    end

    def is_last_element?(index, object)
      object.kind_of?(Array) ? index == object.size - 1 : true
    end

    def assert_cookbook_path_not_empty(run_context)
      if Chef::Config[:solo]
        # Check for cookbooks in the path given
        # Chef::Config[:cookbook_path] can be a string or an array
        # if it's an array, go through it and check each one, raise error at the last one if no files are found
        Chef::Log.debug "Loading from cookbook_path: #{Array(Chef::Config[:cookbook_path]).map { |path| File.expand_path(path) }.join(', ')}"
        Array(Chef::Config[:cookbook_path]).each_with_index do |cookbook_path, index|
          if directory_not_empty?(cookbook_path)
            break
          else
            msg = "No cookbook found in #{Chef::Config[:cookbook_path].inspect}, make sure cookbook_path is set correctly."
            Chef::Log.fatal(msg)
            raise Chef::Exceptions::CookbookNotFound, msg if is_last_element?(index, Chef::Config[:cookbook_path])
          end
        end
      else
        Chef::Log.warn("Node #{node_name} has an empty run list.") if run_context.node.run_list.empty?
      end

    end
  end
end

# HACK cannot load this first, but it must be loaded.
require 'chef/cookbook_loader'
require 'chef/cookbook_version'

