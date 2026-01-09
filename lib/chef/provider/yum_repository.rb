#
# Author:: Thom May (<thom@chef.io>)
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

require_relative "../resource"
require_relative "../mixin/which"
require_relative "noop"

class Chef
  class Provider
    class YumRepository < Chef::Provider
      extend Chef::Mixin::Which

      provides(:yum_repository, target_mode: true) { which "yum" }

      def load_current_resource; end

      action :create, description: "Create a repository based on the properties." do
        template ::File.join(new_resource.reposdir, "#{new_resource.repositoryid}.repo") do
          if template_available?(new_resource.source)
            source new_resource.source
          else
            source ::File.expand_path("support/yum_repo.erb", __dir__)
            local true
          end
          sensitive new_resource.sensitive
          variables(config: new_resource)
          mode new_resource.mode
          if new_resource.make_cache
            notifies :run, "execute[yum clean metadata #{new_resource.repositoryid}]", :immediately if new_resource.clean_metadata || new_resource.clean_headers
            # makecache fast only works on non-dnf systems.
            if !which("dnf") && new_resource.makecache_fast
              notifies :run, "execute[yum-makecache-fast-#{new_resource.repositoryid}]", :immediately
            else
              notifies :run, "execute[yum-makecache-#{new_resource.repositoryid}]", :immediately
            end
            notifies :flush_cache, "package[package-cache-reload-#{new_resource.repositoryid}]", :immediately
          end
        end

        # avoid extra logging if make_cache property isn't set
        if new_resource.make_cache
          execute "yum clean metadata #{new_resource.repositoryid}" do
            command "yum clean metadata --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
            action :nothing
          end

          # get the metadata for this repo only
          execute "yum-makecache-#{new_resource.repositoryid}" do
            command "yum -q -y makecache --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
            action :nothing
            only_if { new_resource.enabled }
          end

          # download only the minimum required metadata
          execute "yum-makecache-fast-#{new_resource.repositoryid}" do
            command "yum -q -y makecache fast --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
            action :nothing
            only_if { new_resource.enabled }
          end

          package "package-cache-reload-#{new_resource.repositoryid}" do
            action :nothing
          end
        end
      end

      action :delete, description: "Remove a repository." do
        # clean the repo cache first
        execute "yum clean all #{new_resource.repositoryid}" do
          command "yum clean all --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
          only_if "yum repolist all | grep -P '^#{new_resource.repositoryid}([ \t]|$)'"
        end

        file ::File.join(new_resource.reposdir, "#{new_resource.repositoryid}.repo") do
          action :delete
          notifies :flush_cache, "package[package-cache-reload-#{new_resource.repositoryid}]", :immediately
        end

        package "package-cache-reload-#{new_resource.repositoryid}" do
          action :nothing
        end
      end

      action :makecache, description: "Force the creation of the repository cache. This is also done automatically when a repository is updated." do
        execute "yum-makecache-#{new_resource.repositoryid}" do
          command "yum -q -y makecache --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
          action :run
          only_if { new_resource.enabled }
          notifies :flush_cache, "package[package-cache-reload-#{new_resource.repositoryid}]", :immediately
        end

        package "package-cache-reload-#{new_resource.repositoryid}" do
          action :nothing
        end
      end

      alias_method :action_add, :action_create
      alias_method :action_remove, :action_delete

      def template_available?(path)
        !path.nil? && run_context.has_template_in_cookbook?(new_resource.cookbook_name, path)
      end

    end
  end
end

Chef::Provider::Noop.provides :yum_repository
