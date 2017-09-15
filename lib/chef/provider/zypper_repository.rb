#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2017, Chef Software Inc.
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

require "chef/resource"
require "chef/dsl/declare_resource"
require "chef/provider/noop"
require "shellwords"

class Chef
  class Provider
    class ZypperRepository < Chef::Provider
      provides :zypper_repository, platform_family: "suse"

      def load_current_resource
      end

      action :create do
        if new_resource.gpgautoimportkeys
          declare_resource(:execute, "import gpg key from #{new_resource.gpgkey}") do
            command "/bin/rpm --import #{new_resource.gpgkey}"
            action :nothing
          end
        end

        declare_resource(:template, "/etc/zypp/repos.d/#{escaped_repo_name}.repo") do
          if template_available?(new_resource.source)
            source new_resource.source
          else
            source ::File.expand_path("../support/zypper_repo.erb", __FILE__)
            local true
          end
          sensitive new_resource.sensitive
          variables(config: new_resource)
          mode new_resource.mode
          notifies :run, "execute[import gpg key from #{new_resource.gpgkey}]", :before if new_resource.gpgautoimportkeys
          notifies :refresh, new_resource, :immediately if new_resource.refresh_cache
        end
      end

      action :delete do
        declare_resource(:execute, "zypper removerepo #{escaped_repo_name}") do
          only_if "zypper lr #{escaped_repo_name}"
        end
      end

      action :refresh do
        declare_resource(:execute, "zypper#{' --gpg-auto-import-keys' if new_resource.gpgautoimportkeys} --quiet --no-confirm refresh --force #{escaped_repo_name}") do
          only_if "zypper lr #{escaped_repo_name}"
        end
      end

      alias_method :action_add, :action_create
      alias_method :action_remove, :action_delete

      # zypper repos are allowed to have spaces in the names
      def escaped_repo_name
        Shellwords.escape(new_resource.repo_name)
      end

      def template_available?(path)
        !path.nil? && run_context.has_template_in_cookbook?(new_resource.cookbook_name, path)
      end

    end
  end
end

Chef::Provider::Noop.provides :zypper_repository
