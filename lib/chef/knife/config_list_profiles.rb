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
    class ConfigListProfiles < Knife
      banner "knife config list-profiles (options)"
      category "deprecated"

      deps do
        require_relative "../workstation_config_loader"
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
        Chef::Log.warn("knife config list-profiles has been deprecated in favor of knife config list. This will removed in marjor release verison!")

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

      def render_table(profiles, padding: 2)
        # Replace the home dir in the client key path with ~.
        profiles.each do |profile|
          profile[:client_key] = profile[:client_key].to_s.gsub(/^#{Regexp.escape(Dir.home)}/, "~") if profile[:client_key]
        end
        # Render the data to a 2D array that will be used for the table.
        table_data = [["", "Profile", "Client", "Key", "Server"]] + profiles.map do |profile|
          [profile[:active] ? "*" : ""] + profile.values_at(:profile, :client_name, :client_key, :server_url).map(&:to_s)
        end
        # Compute column widths.
        column_widths = Array.new(table_data.first.length) do |i|
          table_data.map { |row| row[i].length + padding }.max
        end
        # Special case, the first col gets no padding (because indicator) and last
        # get no padding because last.
        column_widths[0] -= padding
        column_widths[-1] -= padding
        # Build the format string for each row.
        format_string = column_widths.map { |w| "%-#{w}.#{w}s" }.join("")
        format_string << "\n"
        # Print the header row and a separator.
        table = ui.color(format_string % table_data.first, :green)
        table << "-" * column_widths.sum
        table << "\n"
        # Print the rest of the table.
        table_data.drop(1).each do |row|
          table << format_string % row
        end
        # Trim the last newline because ui.output adds one.
        table.chomp!
      end

    end
  end
end
