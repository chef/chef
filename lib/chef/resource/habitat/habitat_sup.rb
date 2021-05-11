#
# Copyright:: 2017-2018 Chef Software, Inc.
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

      provides :habitat_sup do |_node|
        false
      end

      property :bldr_url, String
      property :permanent_peer, [true, false], default: false
      property :listen_ctl, String
      property :listen_gossip, String
      property :listen_http, String
      property :org, String, default: "default"
      property :peer, [String, Array], coerce: proc { |b| b.is_a?(String) ? [b] : b }
      property :ring, String
      property :hab_channel, String
      property :auto_update, [true, false], default: false
      property :auth_token, String
      property :gateway_auth_token, String
      property :update_condition, String
      property :limit_no_files, String
      property :license, String, equal_to: ["accept"]
      property :health_check_interval, [String, Integer], coerce: proc { |h| h.is_a?(String) ? h : h.to_s }
      property :event_stream_application, String
      property :event_stream_environment, String
      property :event_stream_site, String
      property :event_stream_url, String
      property :event_stream_token, String
      property :event_stream_cert, String
      property :sup_version, String
      property :launcher_version, String
      property :service_version, String # Windows only
      property :keep_latest, String
      property :toml_config, [true, false], default: false

      action :run do
        habitat_install new_resource.name do
          license new_resource.license
          hab_version new_resource.sup_version if new_resource.sup_version
          not_if { ::File.exist?("/bin/hab") }
          not_if { ::File.exist?("/usr/bin/hab") }
          not_if { ::File.exist?("c:/habitat/hab.exe") }
          not_if { ::File.exist?("c:/ProgramData/Habitat/hab.exe") }
        end

        habitat_package "core/hab-sup" do
          bldr_url new_resource.bldr_url if new_resource.bldr_url
          version new_resource.sup_version if new_resource.sup_version
        end

        habitat_package "core/hab-launcher" do
          bldr_url new_resource.bldr_url if new_resource.bldr_url
          version new_resource.launcher_version if new_resource.launcher_version
        end

        if platform_family?("windows")
          directory "C:/hab/sup/default/config" do
            recursive true
            only_if { ::Dir.exist?("C:/hab") }
            only_if { use_toml_config }
            action :create
          end

          template "C:/hab/sup/default/config/sup.toml" do
            source "sup/sup.toml.erb"
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
            only_if { ::Dir.exist?("C:/hab/sup/default/config") }
          end
        else
          directory "/hab/sup/default/config" do
            mode "0755"
            recursive true
            only_if { use_toml_config }
            only_if { ::Dir.exist?("/hab") }
            action :create
          end

          template "/hab/sup/default/config/sup.toml" do
            source ::File.expand_path("../support/sup.toml.erb", _dir_)
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
            only_if { ::Dir.exist?("/hab/sup/default/config") }
          end
        end
      end

      action_class do
        use "habitat_shared"
        # validate that peers have been passed with a port # for toml file
        def peer_list_with_port
          if new_resource.peer
            peer_list = []
            new_resource.peer.each do |p|
              peer_list << if p !~ /.*:.*/
                             p + ":9632"
                           else
                             p
                           end
            end
            peer_list
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
