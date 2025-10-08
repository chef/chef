#
# Author:: Vivek Singh (<vsingh@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
    class ConfigShow < Knife
      banner "knife config show [OPTION...] (options)\nDisplays the value of Chef::Config[OPTION] (or all config values)"

      option :all,
        short: "-a",
        long: "--all",
        description: "Include options that are not set in the configuration.",
        default: false

      option :raw,
        short: "-r",
        long: "--raw",
        description: "Display a each value with no formatting.",
        default: false

      def run
        if config[:format] == "summary" && !config[:raw]
          # If using the default, human-readable output, also show which config files are being loaded.
          # Some of this is a bit hacky since it duplicates
          wcl = self.class.config_loader
          if wcl.credentials_found
            loading_from("credentials", ChefConfig::PathHelper.home(".chef", "credentials"))
          end
          if wcl.config_location
            loading_from("configuration", wcl.config_location)
          end

          if Chef::Config[:config_d_dir]
            wcl.find_dot_d(Chef::Config[:config_d_dir]).each do |path|
              loading_from(".d/ configuration", path)
            end
          end
        end

        # Dump the whole config, including defaults is --all was given.
        config_data = Chef::Config.save(config[:all])
        # Two special cases, these are set during knife startup but we don't usually care about them.
        unless config[:all]
          config_data.delete(:color)
          # Only keep these if true, false is much less important because it's the default.
          config_data.delete(:local_mode) unless config_data[:local_mode]
          config_data.delete(:enforce_default_paths) unless config_data[:enforce_default_paths]
          config_data.delete(:enforce_path_sanity) unless config_data[:enforce_path_sanity]
        end

        # Extract the data to show.
        output_data = {}
        if @name_args.empty?
          output_data = config_data
        else
          @name_args.each do |filter|
            if filter =~ %r{^/(.*)/(i?)$}
              # It's a regex.
              filter_re = Regexp.new($1, $2 ? Regexp::IGNORECASE : 0)
              config_data.each do |key, value|
                output_data[key] = value if key.to_s&.match?(filter_re)
              end
            else
              # It's a dotted path string.
              filter_parts = filter.split(".")
              extract = lambda do |memo, filter_part|
                memo.is_a?(Hash) ? memo[filter_part.to_sym] : nil
              end
              # Check against both config_data and all of the data, so that even
              # in non-all mode, if you ask for a key that isn't in the non-all
              # data, it will check against the broader set.
              output_data[filter] = filter_parts.inject(config_data, &extract) || filter_parts.inject(Chef::Config.save(true), &extract)
            end
          end
        end

        # Fix up some values.
        output_data.each do |key, value|
          if value == STDOUT
            output_data[key] = "STDOUT"
          elsif value == STDERR
            output_data[key] = "STDERR"
          end
        end

        # Show the data.
        if config[:raw]
          output_data.each_value do |value|
            ui.msg(value)
          end
        else
          ui.output(output_data)
        end
      end

      private

      # Display a banner about loading from a config file.
      #
      # @api private
      # @param type_of_file [String] Description of the file for the banner.
      # @param path [String] Path of the file.
      # @return [nil]
      def loading_from(type_of_file, path)
        path = Pathname.new(path).realpath
        ui.msg(ui.color("Loading from #{type_of_file} file #{path}", :yellow))
      end
    end
  end
end
