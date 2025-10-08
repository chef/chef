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
require_relative "./config_use"

class Chef
  class Knife
    class ConfigUseProfile < ConfigUse

      # Handle the subclassing (knife doesn't do this :()
      dependency_loaders.concat(superclass.dependency_loaders)

      banner "knife config use-profile PROFILE"
      category "deprecated"

      def run
        Chef::Log.warn("knife config use-profile has been deprecated in favor of knife config use. This will be removed in the major release version!")

        credentials_data = self.class.config_loader.parse_credentials_file
        context_file = ChefConfig::PathHelper.home(".chef", "context").freeze
        profile = @name_args[0]&.strip
        if profile.nil? || profile.empty?
          show_usage
          ui.fatal("You must specify a profile")
          exit 1
        end

        super
      end
    end
  end
end
