#  Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class HabitatService < Chef::Resource
      provides :habitat_service, target_mode: true
      target_mode support: :full

      description "Use the **habitat_service** resource to manage Chef Habitat services. This requires that `core/hab-sup` be running as a service. See the `habitat_sup` resource documentation for more information. Note: Applications may run as a specific user. Often with Habitat, the default is `hab`, or `root`. If the application requires another user, then it should be created with Chef's `user` resource."
      introduced "17.3"
      examples <<~DOC
        **Install and load nginx**

        ```ruby
        habitat_package 'core/nginx'
        habitat_service 'core/nginx'

        habitat_service 'core/nginx unload' do
          service_name 'core/nginx'
          action :unload
        end
        ```

        **Pass the `strategy` and `topology` options to hab service commands**

        ```ruby
        habitat_service 'core/redis' do
          strategy 'rolling'
          topology 'standalone'
        end
        ```

        **Using update_condition**

        ```ruby
        habitat_service 'core/redis' do
          strategy 'rolling'
          update_condition 'track-channel'
          topology 'standalone'
        end
        ```

        **If the service has it's own user specified that is not the `hab` user, don't create the `hab` user on install, and instead create the application user with Chef's `user` resource**

        ```ruby
        habitat_install 'install habitat' do
          create_user false
        end

        user 'acme-apps' do
          system true
        end

        habitat_service 'acme/apps'
        ```
      DOC

      property :service_name, String, name_property: true,
        description: "The name of the service, must be in the form of `origin/name`"

      property :loaded, [true, false], default: false, skip_docs: true,
        description: "state property indicating whether the service is loaded in the supervisor"

      property :running, [true, false], default: false, skip_docs: true,
        description: "state property indicating whether the service is running in the supervisor"

      # hab svc options which get included based on the action of the resource
      property :strategy, [Symbol, String], equal_to: [:none, "none", :'at-once', "at-once", :rolling, "rolling"], default: :none, coerce: proc { |s| s.is_a?(String) ? s.to_sym : s },
        description: "Passes `--strategy` with the specified update strategy to the hab command. Defaults to `:none`. Other options are `:'at-once'` and `:rolling`"

      property :topology, [Symbol, String], equal_to: [:standalone, "standalone", :leader, "leader"], default: :standalone, coerce: proc { |s| s.is_a?(String) ? s.to_sym : s },
        description: "Passes `--topology` with the specified service topology to the hab command"

      property :bldr_url, String, default: "https://bldr.habitat.sh/",
        description: "Passes `--url` with the specified Habitat Builder URL to the hab command. Depending on the type of Habitat Builder you are connecting to, this URL will look different, here are the **3** current types:
        - Public Habitat Builder (default) - `https://bldr.habitat.sh`
        - On-Prem Habitat Builder installed using the [Source Install Method](https://github.com/habitat-sh/on-prem-builder) - `https://your.bldr.url`
        - On-Prem Habitat Builder installed using the [Automate Installer](https://automate.chef.io/docs/on-prem-builder/) - `https://your.bldr.url/bldr/v1`"

      property :channel, [Symbol, String], default: :stable, coerce: proc { |s| s.is_a?(String) ? s.to_sym : s },
        description: "Passes `--channel` with the specified channel to the hab command"

      property :bind, [String, Array], coerce: proc { |b| b.is_a?(String) ? [b] : b }, default: [],
        description: "Passes `--bind` with the specified services to bind to the hab command. If an array of multiple service binds are specified then a `--bind` flag is added for each."

      property :binding_mode, [Symbol, String], equal_to: [:strict, "strict", :relaxed, "relaxed"], default: :strict, coerce: proc { |s| s.is_a?(String) ? s.to_sym : s },
        description: "Passes `--binding-mode` with the specified binding mode. Defaults to `:strict`. Options are `:strict` or `:relaxed`"

      property :service_group, String, default: "default",
        description: " Passes `--group` with the specified service group to the hab command"

      property :shutdown_timeout, Integer, default: 8,
        description: "The timeout in seconds allowed during shutdown."

      property :health_check_interval, Integer, default: 30,
        description: "The interval (seconds) on which to run health checks."

      property :remote_sup, String, default: "127.0.0.1:9632", desired_state: false,
        description: "Address to a remote Supervisor's Control Gateway"

      # Http port needed for querying/comparing current config value
      property :remote_sup_http, String, default: "127.0.0.1:9631", desired_state: false,
        description: "IP address and port used to communicate with the remote supervisor. If this value is invalid, the resource will update the supervisor configuration each time #{ChefUtils::Dist::Server::PRODUCT} runs."

      property :gateway_auth_token, String, desired_state: false,
        description: "Auth token for accessing the remote supervisor's http port."

      property :update_condition, [Symbol, String], equal_to: [:latest, "latest", :'track-channel', "track-channel"], default: :latest, coerce: proc { |s| s.is_a?(String) ? s.to_sym : s },
        description: "Passes `--update-condition` dictating when this service should updated. Defaults to `latest`. Options are `latest` or `track-channel` **_Note: This requires a minimum habitat version of 1.5.71_**
        - `latest`: Runs the latest package that can be found in the configured channel and local packages.
        - `track-channel`: Always run the package at the head of a given channel. This enables service rollback, where demoting a package from a channel will cause the package to rollback to an older version of the package. A ramification of enabling this condition is that packages that are newer than the package at the head of the channel are also uninstalled during a service rollback."

      load_current_value do
        service_details = get_service_details(service_name)

        running service_up?(service_details)
        loaded service_loaded?(service_details)

        if loaded
          service_name get_spec_identifier(service_details)
          strategy get_update_strategy(service_details)
          update_condition get_update_condition(service_details)
          topology get_topology(service_details)
          bldr_url get_builder_url(service_details)
          channel get_channel(service_details)
          bind get_binds(service_details)
          binding_mode get_binding_mode(service_details)
          service_group get_service_group(service_details)
          shutdown_timeout get_shutdown_timeout(service_details)
          health_check_interval get_health_check_interval(service_details)
        end

        Chef::Log.debug("service #{service_name} service name: #{service_name}")
        Chef::Log.debug("service #{service_name} running state: #{running}")
        Chef::Log.debug("service #{service_name} loaded state: #{loaded}")
        Chef::Log.debug("service #{service_name} strategy: #{strategy}")
        Chef::Log.debug("service #{service_name} update condition: #{update_condition}")
        Chef::Log.debug("service #{service_name} topology: #{topology}")
        Chef::Log.debug("service #{service_name} builder url: #{bldr_url}")
        Chef::Log.debug("service #{service_name} channel: #{channel}")
        Chef::Log.debug("service #{service_name} binds: #{bind}")
        Chef::Log.debug("service #{service_name} binding mode: #{binding_mode}")
        Chef::Log.debug("service #{service_name} service group: #{service_group}")
        Chef::Log.debug("service #{service_name} shutdown timeout: #{shutdown_timeout}")
        Chef::Log.debug("service #{service_name} health check interval: #{health_check_interval}")
      end

      # This method is defined here otherwise it isn't usable in the
      # `load_current_value` method.
      #
      # It performs a check with TCPSocket to ensure that the HTTP API is
      # available first. If it cannot connect, it assumes that the service
      # is not running. It then attempts to reach the `/services` path of
      # the API to get a list of services. If this fails for some reason,
      # then it assumes the service is not running.
      #
      # Finally, it walks the services returned by the API to look for the
      # service we're configuring. If it is "Up", then we know the service
      # is running and fully operational according to Habitat. This is
      # wrapped in a begin/rescue block because if the service isn't
      # present and `sup_for_service_name` will be nil and we will get a
      # NoMethodError.
      #
      def get_service_details(svc_name)
        http_uri = "http://#{remote_sup_http}"

        begin
          TCPSocket.new(URI(http_uri).host, URI(http_uri).port).close unless Chef::Config.target_mode?
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          Chef::Log.debug("Could not connect to #{http_uri} to retrieve status for #{service_name}")
          return false
        end

        begin
          headers = {}
          headers["Authorization"] = "Bearer #{gateway_auth_token}" if property_is_set?(:gateway_auth_token)
          svcs = TargetIO::HTTP::SimpleJSON.new(http_uri).get("/services", headers)
        rescue
          Chef::Log.debug("Could not connect to #{http_uri}/services to retrieve status for #{service_name}")
          return false
        end

        origin, name, _version, _release = svc_name.split("/")
        svcs.find do |s|
          s["pkg"]["origin"] == origin && s["pkg"]["name"] == name
        end
      end

      def service_up?(service_details)
        service_details["process"]["state"] == "up"
      rescue
        Chef::Log.debug("#{service_name} not found on the Habitat supervisor")
        false
      end

      def service_loaded?(service_details)
        if service_details
          true
        else
          false
        end
      end

      def get_spec_identifier(service_details)
        service_details["spec_ident"]["spec_identifier"]
      rescue
        Chef::Log.debug("#{service_name} not found on the Habitat supervisor")
        nil
      end

      def get_update_strategy(service_details)
        service_details["update_strategy"].to_sym
      rescue
        Chef::Log.debug("Update Strategy for #{service_name} not found on Supervisor API")
        "none"
      end

      def get_update_condition(service_details)
        service_details["update_condition"].to_sym
      rescue
        Chef::Log.debug("Update condition #{service_name} not found on Supervisor API")
        "latest"
      end

      def get_topology(service_details)
        service_details["topology"].to_sym
      rescue
        Chef::Log.debug("Topology for #{service_name} not found on Supervisor API")
        "standalone"
      end

      def get_builder_url(service_details)
        service_details["bldr_url"]
      rescue
        Chef::Log.debug("Habitat Builder URL for #{service_name} not found on Supervisor API")
        "https://bldr.habitat.sh"
      end

      def get_channel(service_details)
        service_details["channel"].to_sym
      rescue
        Chef::Log.debug("Channel for #{service_name} not found on Supervisor API")
        "stable"
      end

      def get_binds(service_details)
        service_details["binds"]
      rescue
        Chef::Log.debug("Update Strategy for #{service_name} not found on Supervisor API")
        []
      end

      def get_binding_mode(service_details)
        service_details["binding_mode"].to_sym
      rescue
        Chef::Log.debug("Binding mode for #{service_name} not found on Supervisor API")
        "strict"
      end

      def get_service_group(service_details)
        service_details["service_group"].split(".").last
      rescue
        Chef::Log.debug("Service Group for #{service_name} not found on Supervisor API")
        "default"
      end

      def get_shutdown_timeout(service_details)
        service_details["pkg"]["shutdown_timeout"]
      rescue
        Chef::Log.debug("Shutdown Timeout for #{service_name} not found on Supervisor API")
        8
      end

      def get_health_check_interval(service_details)
        service_details["health_check_interval"]["secs"]
      rescue
        Chef::Log.debug("Health Check Interval for #{service_name} not found on Supervisor API")
        30
      end

      action :load, description: "(default action) runs `hab service load` to load and start the specified application service" do
        modified = false
        converge_if_changed :service_name do
          modified = true
        end
        converge_if_changed :strategy do
          modified = true
        end
        converge_if_changed :update_condition do
          modified = true
        end
        converge_if_changed :topology do
          modified = true
        end
        converge_if_changed :bldr_url do
          modified = true
        end
        converge_if_changed :channel do
          modified = true
        end
        converge_if_changed :bind do
          modified = true
        end
        converge_if_changed :binding_mode do
          modified = true
        end
        converge_if_changed :service_group do
          modified = true
        end
        converge_if_changed :shutdown_timeout do
          modified = true
        end
        converge_if_changed :health_check_interval do
          modified = true
        end

        options = svc_options
        if current_resource.loaded && modified
          Chef::Log.debug("Reloading #{current_resource.service_name} using --force due to parameter change")
          options << "--force"
        end

        unless current_resource.loaded && !modified
          execute "load service" do
            command "hab svc load #{new_resource.service_name} #{options.join(" ")}"
            retry_delay 10
            retries 5

            # compensate for lack of TCPSocket support in TM by retries
            returns [0, 1] if Chef::Config.target_mode?
          end
        end
      end

      action :unload, description: "runs `hab service unload` to unload and stop the specified application service" do
        if current_resource.loaded
          execute "hab svc unload #{new_resource.service_name} #{svc_options.join(" ")}"
          wait_for_service_unloaded
        end
      end

      action :start, description: "runs `hab service start` to start the specified application service" do
        unless current_resource.loaded
          Chef::Log.fatal("No service named #{new_resource.service_name} is loaded on the Habitat supervisor")
          raise "No service named #{new_resource.service_name} is loaded on the Habitat supervisor"
        end

        execute "hab svc start #{new_resource.service_name} #{svc_options.join(" ")}" unless current_resource.running
      end

      action :stop, description: "runs `hab service stop` to stop the specified application service" do
        unless current_resource.loaded
          Chef::Log.fatal("No service named #{new_resource.service_name} is loaded on the Habitat supervisor")
          raise "No service named #{new_resource.service_name} is loaded on the Habitat supervisor"
        end

        if current_resource.running
          execute "hab svc stop #{new_resource.service_name} #{svc_options.join(" ")}"
          wait_for_service_stopped
        end
      end

      action :restart, description: "runs the `:stop` and then `:start` actions" do
        action_stop
        action_start
      end

      action :reload, description: "runs the `:unload` and then `:load` actions" do
        action_unload
        action_load
      end

      action_class do
        def svc_options
          opts = []

          # certain options are only valid for specific `hab svc` subcommands.
          case action
          when :load
            opts.push(*new_resource.bind.map { |b| "--bind #{b}" }) if new_resource.bind
            opts << "--binding-mode #{new_resource.binding_mode}"
            opts << "--url #{new_resource.bldr_url}" if new_resource.bldr_url
            opts << "--channel #{new_resource.channel}" if new_resource.channel
            opts << "--group #{new_resource.service_group}" if new_resource.service_group
            opts << "--strategy #{new_resource.strategy}" if new_resource.strategy
            opts << "--update-condition #{new_resource.update_condition}" if new_resource.update_condition
            opts << "--topology #{new_resource.topology}" if new_resource.topology
            opts << "--health-check-interval #{new_resource.health_check_interval}" if new_resource.health_check_interval
            opts << "--shutdown-timeout #{new_resource.shutdown_timeout}" if new_resource.shutdown_timeout
          when :unload, :stop
            opts << "--shutdown-timeout #{new_resource.shutdown_timeout}" if new_resource.shutdown_timeout
          end

          opts << "--remote-sup #{new_resource.remote_sup}" if new_resource.remote_sup

          opts.map(&:split).flatten.compact
        end

        def wait_for_service_unloaded
          ruby_block "wait-for-service-unloaded" do
            block do
              raise "#{new_resource.service_name} still loaded" if service_loaded?(get_service_details(new_resource.service_name))
            end
            retries get_shutdown_timeout(new_resource.service_name) + 1
            retry_delay 1
          end

          ruby_block "update current_resource" do
            block do
              current_resource.loaded = service_loaded?(get_service_details(new_resource.service_name))
            end
            action :nothing
            subscribes :run, "ruby_block[wait-for-service-unloaded]", :immediately
          end
        end

        def wait_for_service_stopped
          ruby_block "wait-for-service-stopped" do
            block do
              raise "#{new_resource.service_name} still running" if service_up?(get_service_details(new_resource.service_name))
            end
            retries get_shutdown_timeout(new_resource.service_name) + 1
            retry_delay 1

            ruby_block "update current_resource" do
              block do
                current_resource.running = service_up?(get_service_details(new_resource.service_name))
              end
              action :nothing
              subscribes :run, "ruby_block[wait-for-service-stopped]", :immediately
            end
          end
        end
      end
    end
  end
end
