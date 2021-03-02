#
# Copyright:: Copyright (c) 2018, Noah Kantrowitz
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../knife"

class Chef
  class Knife
    class ConfigList < Knife
      banner "knife config list (options)"

      TABLE_HEADER ||= [" Profile", "Client", "Key", "Server"].freeze

      deps do
        require "chef/workstation_config_loader" unless defined?(Chef::WorkstationConfigLoader)
        require "tty-screen" unless defined?(TTY::Screen)
        require "tty-table" unless defined?(TTY::Table)
      end

      option :ignore_knife_rb,
        short: "-i",
        long: "--ignore-knife-rb",
        description: "Ignore the current config.rb/knife.rb configuration.",
        default: false

      def configure_chef
        apply_computed_config
      end

      def run
        credentials_data = self.class.config_loader.parse_credentials_file
        if credentials_data.nil? || credentials_data.empty?
          # Should this just show the ambient knife.rb config as "default" instead?
          ui.fatal("No profiles found, #{self.class.config_loader.credentials_file_path} does not exist or is empty")
          exit 1
        end

        current_profile = self.class.config_loader.credentials_profile(config[:profile])
        profiles = credentials_data.keys.map do |profile|
          if config[:ignore_knife_rb]
            # Don't do any fancy loading nonsense, just the raw data.
            profile_data = credentials_data[profile]
            {
              profile: profile,
              active: profile == current_profile,
              client_name: profile_data["client_name"] || profile_data["node_name"],
              client_key: profile_data["client_key"],
              server_url: profile_data["chef_server_url"],
            }
          else
            # Fancy loading nonsense so we get what the actual config would be.
            # Note that this modifies the global config, after this, all bets are
            # off as to whats in the config.
            Chef::Config.reset
            wcl = Chef::WorkstationConfigLoader.new(nil, Chef::Log, profile: profile)
            wcl.load
            {
              profile: profile,
              active: profile == current_profile,
              client_name: Chef::Config[:node_name],
              client_key: Chef::Config[:client_key],
              server_url: Chef::Config[:chef_server_url],
            }
          end
        end

        # Try to reset the config.
        unless config[:ignore_knife_rb]
          Chef::Config.reset
          apply_computed_config
        end

        if ui.interchange?
          # Machine-readable output.
          ui.output(profiles)
        else
          # Table output.
          ui.output(render_table(profiles))
        end
      end

      private

      def render_table(profiles, padding: 1)
        rows = []
        # Render the data to a 2D array that will be used for the table.
        profiles.each do |profile|
          # Replace the home dir in the client key path with ~.
          profile[:client_key] = profile[:client_key].to_s.gsub(/^#{Regexp.escape(Dir.home)}/, "~") if profile[:client_key]
          profile[:profile] = "#{profile[:active] ? "*" : " "}#{profile[:profile]}"
          rows << profile.values_at(:profile, :client_name, :client_key, :server_url)
        end

        table = TTY::Table.new(header: TABLE_HEADER, rows: rows)

        # Rotate the table to vertical if the screen width is less than table width.
        if table.width > TTY::Screen.width
          table.orientation = :vertical
          table.rotate
          # Add a new line after each profile record.
          table.render do |renderer|
            renderer.border do
              separator ->(row) { (row + 1) % TABLE_HEADER.size == 0 }
            end
            # Remove the leading space added of the first column.
            renderer.filter = Proc.new do |val, row_index, col_index|
              if col_index == 1 || (row_index) % TABLE_HEADER.size == 0
                val.strip
              else
                val
              end
            end
          end
        else
          table.render do |renderer|
            renderer.border do
              mid "-"
            end
            renderer.padding = [0, padding, 0, 0] # pad right with 2 characters
          end
        end
      end

    end
  end
end
