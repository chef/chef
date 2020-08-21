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
    class ConfigGetProfile < Knife
      banner "knife config get-profile"
      category "deprecated"

      # Disable normal config loading since this shouldn't fail if the profile
      # doesn't exist of the config is otherwise corrupted.
      def configure_chef
        apply_computed_config
      end

      def run
        Chef::Log.warn("knife config get-profiles has been deprecated in favor of knife config use. This will removed in marjor release verison!")

        ui.msg(self.class.config_loader.credentials_profile(config[:profile]))
      end

    end
  end
end
