#
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

require_relative "../knife"
require "local_mode" unless defined?(Chef::LocalMode)
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Knife
    class Serve < Knife

      banner "knife serve (options)"

      option :repo_mode,
        long: "--repo-mode MODE",
        description: "Specifies the local repository layout. Values: static (only environments/roles/data_bags/cookbooks), everything (includes nodes/clients/users), hosted_everything (includes acls/groups/etc. for Enterprise/Hosted Chef). Default: everything/hosted_everything."

      option :chef_repo_path,
        long: "--chef-repo-path PATH",
        description: "Overrides the location of #{ChefUtils::Dist::Infra::PRODUCT} repo. Default is specified by chef_repo_path in the config."

      option :chef_zero_host,
        long: "--chef-zero-host IP",
        description: "Overrides the host upon which #{ChefUtils::Dist::Zero::PRODUCT} listens. Default is 127.0.0.1."

      def configure_chef
        super
        Chef::Config.local_mode = true
        Chef::Config[:repo_mode] = config[:repo_mode] if config[:repo_mode]

        # --chef-repo-path forcibly overrides all other paths
        if config[:chef_repo_path]
          Chef::Config.chef_repo_path = config[:chef_repo_path]
          %w{acl client cookbook container data_bag environment group node role user}.each do |variable_name|
            Chef::Config.delete("#{variable_name}_path".to_sym)
          end
        end
      end

      def run
        server = Chef::LocalMode.chef_zero_server
        begin
          output "Serving files from:\n#{Chef::LocalMode.chef_fs.fs_description}"
          server.stop
          server.start(stdout) # to print header
        ensure
          server.stop
        end
      end
    end
  end
end
