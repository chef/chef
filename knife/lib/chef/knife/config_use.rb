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
    class ConfigUse < Knife
      banner "knife config use [PROFILE]"

      deps do
        require "fileutils" unless defined?(FileUtils)
      end

      # Disable normal config loading since this shouldn't fail if the profile
      # doesn't exist of the config is otherwise corrupted.
      def configure_chef
        apply_computed_config
      end

      def run
        profile = @name_args[0]&.strip
        if profile.nil? || profile.empty?
          ui.msg(self.class.config_loader.credentials_profile(config[:profile]))
        else
          credentials_data = self.class.config_loader.parse_credentials_file
          context_file = ChefConfig::PathHelper.home(".chef", "context").freeze

          if credentials_data.nil? || credentials_data.empty?
            ui.fatal("No profiles found, #{self.class.config_loader.credentials_file_path} does not exist or is empty")
            exit 1
          end

          if credentials_data[profile].nil?
            raise ChefConfig::ConfigurationError, "Profile #{profile} doesn't exist. Please add it to #{self.class.config_loader.credentials_file_path} and if it is profile with DNS name check that you are not missing single quotes around it as per docs https://docs.chef.io/workstation/knife_setup/#knife-profiles."
          else
            # Ensure the .chef/ folder exists.
            FileUtils.mkdir_p(File.dirname(context_file))
            IO.write(context_file, "#{profile}\n")
            ui.msg("Set default profile to #{profile}")
          end
        end
      end
    end
  end
end
