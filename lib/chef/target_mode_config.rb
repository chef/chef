#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

autoload :URI, "uri"
autoload :Train, "train"

class Chef
  # Translates a parsed -t/--target CLI option into Chef::Config.target_mode
  # settings. Shared by Chef::Application::Client#reconfigure and
  # Shell::Options#parse_opts (chef-shell has its own Mixlib::CLI option
  # parser and does not go through Chef::Application::Base#reconfigure).
  module TargetModeConfig
    # @param config [Hash] a parsed Mixlib::CLI config hash, which may contain
    #   a :target key set via the -t/--target CLI option.
    #
    # No-ops unless config[:target] or Chef::Config.target is already set.
    def self.apply!(config)
      return unless config[:target] || Chef::Config.target

      require "ed25519" # required for net-ssh to support ed25519 keys

      Chef::Config.target_mode.host = config[:target] || Chef::Config.target
      if URI.parse(Chef::Config.target_mode.host).scheme
        train_config = Train.unpack_target_from_uri(Chef::Config.target_mode.host)
        Chef::Config.target_mode = train_config
      end
      # Save the operator's identity BEFORE enabling target mode.
      # client_key must be captured here because its default path changes once
      # target_mode.enabled = true (it would resolve to /etc/chef/<target>/client.pem
      # instead of the workstation's /etc/chef/client.pem).
      Chef::Config[:api_client_name] ||= Chef::Config[:node_name]
      Chef::Config[:api_client_key]  ||= Chef::Config[:client_key]
      Chef::Config.target_mode.enabled = true
      Chef::Config.node_name = Chef::Config.target_mode.host
    end
  end
end
