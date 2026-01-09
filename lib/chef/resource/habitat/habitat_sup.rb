#
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

require_relative "../../resource"

class Chef
  class Resource
    class HabitatSup < Chef::Resource

      provides(:habitat_sup, target_mode: true) do |_node|
        false
      end
      target_mode support: :full

      description "Use the **habitat_sup** resource to runs a Chef Habitat supervisor for one or more Chef Habitat services. The resource is commonly used in conjunction with `habitat_service` which will manage the services loaded and started within the supervisor."
      introduced "17.3"
      examples <<~DOC
      **Set up with just the defaults**

      ```ruby
      habitat_sup 'default'
      ```

      **Update listen ports and use Supervisor toml config**

      ```ruby
      habitat_sup 'test-options' do
        listen_http '0.0.0.0:9999'
        listen_gossip '0.0.0.0:9998'
        toml_config true
      end
      ```

      **Use with an on-prem Habitat Builder. Note: Access to public builder may not be available due to your company policies**

      ```ruby
      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
      end
      ```

      **Using update_condition**

      ```ruby
      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
        habitat_channel 'dev'
        update_condition 'track-channel'
      end
      ```

      **Provide event stream information**

      ```ruby
      habitat_sup 'default' do
        license 'accept'
        event_stream_application 'myapp'
        event_stream_environment 'production'
        event_stream_site 'MySite'
        event_stream_url 'automate.example.com:4222'
        event_stream_token 'myawesomea2clitoken='
        event_stream_cert '/hab/cache/ssl/mycert.crt'
      end
      ```

      **Provide specific versions**

      ```ruby
      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
        sup_version '1.5.50'
        launcher_version '13458'
        service_version '0.6.0' # WINDOWS ONLY
      end
      ```

      **Set latest version of packages to retain**

      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
        sup_version '1.5.86'
        launcher_version '13458'
        service_version '0.6.0' # WINDOWS ONLY
        keep_latest '2'
      end
      ```
      DOC

      property :bldr_url, String,
      description: "The Habitat Builder URL for the `habitat_package` resource, if needed."

      property :permanent_peer, [true, false], default: false,
      description: "Only valid for `:run` action, passes `--permanent-peer` to the hab command."

      property :listen_ctl, String,
      description: "Only valid for `:run` action, passes `--listen-ctl` with the specified address and port, e.g., `0.0.0.0:9632`, to the hab command."

      property :listen_gossip, String,
      description: "Only valid for `:run` action, passes `--listen-gossip` with the specified address and port, e.g., `0.0.0.0:9638`, to the hab command."

      property :listen_http, String,
      description: "Only valid for `:run` action, passes `--listen-http` with the specified address and port, e.g., `0.0.0.0:9631`, to the hab command."

      property :org, String, default: "default",
      description: "Only valid for `:run` action, passes `--org` with the specified org name to the hab command."

      property :peer, [String, Array], coerce: proc { |b| b.is_a?(String) ? [b] : b },
      description: "Only valid for `:run` action, passes `--peer` with the specified initial peer to the hab command."

      property :ring, String,
      description: "Only valid for `:run` action, passes `--ring` with the specified ring key name to the hab command."

      property :hab_channel, String,
      description: "The channel to install Habitat from. Defaults to stable"

      property :auto_update, [true, false], default: false,
      description: "Passes `--auto-update`. This will set the Habitat supervisor to automatically update itself any time a stable version has been released."

      property :auth_token, String,
      description: "Auth token for accessing a private organization on bldr. This value is templated into the appropriate service file."

      property :gateway_auth_token, String,
      description: "Auth token for accessing the supervisor's HTTP gateway. This value is templated into the appropriate service file."

      property :update_condition, String,
      description: "Passes `--update-condition` dictating when this service should updated. Defaults to `latest`. Options are `latest` or `track-channel` **_Note: This requires a minimum habitat version of 1.5.71_**
      - `latest`: Runs the latest package that can be found in the configured channel and local packages.
      - `track-channel`: Always run what is at the head of a given channel. This enables service rollback where demoting a package from a channel will cause the package to rollback to an older version of the package. A ramification of enabling this condition is packages newer than the package at the head of the channel will be automatically uninstalled during a service rollback."

      property :limit_no_files, String,
      description: "allows you to set LimitNOFILE in the systemd service when used Note: Linux Only."

      property :license, String, equal_to: ["accept"],
      description: "Specifies acceptance of habitat license when set to `accept`."

      property :health_check_interval, [String, Integer], coerce: proc { |h| h.is_a?(String) ? h : h.to_s },
      description: "The interval (seconds) on which to run health checks."

      property :event_stream_application, String,
      description: "The name of your application that will be displayed in the Chef Automate Applications Dashboard."

      property :event_stream_environment, String,
      description: "The application environment for the supervisor, this is for grouping in the Applications Dashboard."

      property :event_stream_site, String,
      description: "Application Dashboard label for the 'site' of the application - can be filtered in the dashboard."

      property :event_stream_url, String,
      description: "`AUTOMATE_HOSTNAME:4222` - the Chef Automate URL with port 4222 specified Note: The port can be changed if needed."

      property :event_stream_token, String,
      description: "Chef Automate token for sending application event stream data."

      property :event_stream_cert, String,
      description: "With `Intermediary Certificates` or, Automate 2 being set to use TLS with a valid cert, you will need to provide `Habitat` with your certificate for communication with Automate to work. [Follow these steps!](https://automate.chef.io/docs/applications-setup/#share-the-tls-certificate-with-chef-habitat)."

      property :sup_version, String,
      description: "Allows you to choose which version of supervisor you would like to install. Note: If a version is provided, it will also install that version of habitat if not previously installed."

      property :launcher_version, String,
      description: "Allows you to choose which version of launcher to install."

      property :service_version, String, # Windows only
      description: "Allows you to choose which version of the **_Windows Service_** to install."

      property :keep_latest, String,
      description: "Automatically cleans up old packages. If this flag is enabled, service startup will initiate an uninstall of all previous versions of the associated package. This also applies when a service is restarted due to an update. If a number is passed to this argument, that number of latest versions will be kept. The same logic applies to the Supervisor package `env:HAB_KEEP_LATEST_PACKAGES=1` Note: This requires Habitat version `1.5.86+`"

      property :toml_config, [true, false], default: false,
      description: "Supports using the Supervisor toml configuration instead of passing exec parameters to the service, [reference](https://www.habitat.sh/docs/reference/#supervisor-config)."

      action :run, description: "The `run` action handles installing Habitat using the `habitat_install` resource, ensures that the appropriate versions of the `core/hab-sup` and `core/hab-launcher` packages are installed using `habitat_package`, and then drops off the appropriate init system definitions and manages the service." do
        habitat_install new_resource.name do
          license new_resource.license
          hab_version new_resource.sup_version if new_resource.sup_version
          not_if { ::TargetIO::File.exist?("/bin/hab") }
          not_if { ::TargetIO::File.exist?("/usr/bin/hab") }
          not_if { ::TargetIO::File.exist?("c:/habitat/hab.exe") }
          not_if { ::TargetIO::File.exist?("c:/ProgramData/Habitat/hab.exe") }
        end

        habitat_package "core/hab-sup" do
          bldr_url new_resource.bldr_url if new_resource.bldr_url
          version new_resource.sup_version if new_resource.sup_version
        end

        habitat_package "core/hab-launcher" do
          bldr_url new_resource.bldr_url if new_resource.bldr_url
          version new_resource.launcher_version if new_resource.launcher_version
        end

        if windows?
          directory "C:/hab/sup/default/config" do
            recursive true
            only_if { ::TargetIO::Dir.exist?("C:/hab") }
            only_if { use_toml_config }
            action :create
          end

          template "C:/hab/sup/default/config/sup.toml" do
            source ::File.expand_path("../support/sup.toml.erb", __dir__)
            local true
            sensitive true
            variables(
              bldr_url: new_resource.bldr_url,
              permanent_peer: new_resource.permanent_peer,
              listen_ctl: new_resource.listen_ctl,
              listen_gossip: new_resource.listen_gossip,
              listen_http: new_resource.listen_http,
              organization: new_resource.org,
              peer: peer_list_with_port,
              ring: new_resource.ring,
              auto_update: new_resource.auto_update,
              update_condition: new_resource.update_condition,
              health_check_interval: new_resource.health_check_interval,
              event_stream_application: new_resource.event_stream_application,
              event_stream_environment: new_resource.event_stream_environment,
              event_stream_site: new_resource.event_stream_site,
              event_stream_url: new_resource.event_stream_url,
              event_stream_token: new_resource.event_stream_token,
              event_stream_server_certificate: new_resource.event_stream_cert,
              keep_latest_packages: new_resource.keep_latest
            )
            only_if { use_toml_config }
            only_if { ::TargetIO::Dir.exist?("C:/hab/sup/default/config") }
          end
        else
          directory "/hab/sup/default/config" do
            mode "0755"
            recursive true
            only_if { use_toml_config }
            only_if { ::TargetIO::Dir.exist?("/hab") }
            action :create
          end

          template "/hab/sup/default/config/sup.toml" do
            source ::File.expand_path("../support/sup.toml.erb", __dir__)
            local true
            sensitive true
            variables(
              bldr_url: new_resource.bldr_url,
              permanent_peer: new_resource.permanent_peer,
              listen_ctl: new_resource.listen_ctl,
              listen_gossip: new_resource.listen_gossip,
              listen_http: new_resource.listen_http,
              organization: new_resource.org,
              peer: peer_list_with_port,
              ring: new_resource.ring,
              auto_update: new_resource.auto_update,
              update_condition: new_resource.update_condition,
              health_check_interval: new_resource.health_check_interval,
              event_stream_application: new_resource.event_stream_application,
              event_stream_environment: new_resource.event_stream_environment,
              event_stream_site: new_resource.event_stream_site,
              event_stream_url: new_resource.event_stream_url,
              event_stream_token: new_resource.event_stream_token,
              event_stream_server_certificate: new_resource.event_stream_cert,
              keep_latest_packages: new_resource.keep_latest
            )
            only_if { use_toml_config }
            only_if { ::TargetIO::Dir.exist?("/hab/sup/default/config") }
          end
        end
      end

      action_class do
        use "habitat_shared"
        # validate that peers have been passed with a port # for toml file
        def peer_list_with_port
          if new_resource.peer
            peer_list = new_resource.peer.map do |p|
              if !/.*:.*/.match?(p)
                p + ":9632"
              else
                p
              end
            end
          end
        end

        # Specify whether toml configuration should be used in place of service arguments.
        def use_toml_config
          new_resource.toml_config
        end

        def exec_start_options
          # Populate exec_start_options which will pass to 'hab sup run' for platforms if use_toml_config is not 'true'
          unless use_toml_config
            opts = []
            opts << "--permanent-peer" if new_resource.permanent_peer
            opts << "--listen-ctl #{new_resource.listen_ctl}" if new_resource.listen_ctl
            opts << "--listen-gossip #{new_resource.listen_gossip}" if new_resource.listen_gossip
            opts << "--listen-http #{new_resource.listen_http}" if new_resource.listen_http
            opts << "--org #{new_resource.org}" unless new_resource.org == "default"
            opts.push(*new_resource.peer.map { |b| "--peer #{b}" }) if new_resource.peer
            opts << "--ring #{new_resource.ring}" if new_resource.ring
            opts << "--auto-update" if new_resource.auto_update
            opts << "--update-condition #{new_resource.update_condition}" if new_resource.update_condition
            opts << "--health-check-interval #{new_resource.health_check_interval}" if new_resource.health_check_interval
            opts << "--event-stream-application #{new_resource.event_stream_application}" if new_resource.event_stream_application
            opts << "--event-stream-environment #{new_resource.event_stream_environment}" if new_resource.event_stream_environment
            opts << "--event-stream-site #{new_resource.event_stream_site}" if new_resource.event_stream_site
            opts << "--event-stream-url #{new_resource.event_stream_url}" if new_resource.event_stream_url
            opts << "--event-stream-token #{new_resource.event_stream_token}" if new_resource.event_stream_token
            opts << "--event-stream-server-certificate #{new_resource.event_stream_cert}" if new_resource.event_stream_cert
            opts << "--keep-latest-packages #{new_resource.keep_latest}" if new_resource.keep_latest
            opts.join(" ")
          end
        end
      end
    end
  end
end
