#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016-2017, Chef Software Inc.
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
require "chef/mixin/shell_out"
require "chef/mixin/which"
require "chef/http/simple"
require "chef/provider/noop"

class Chef
  class Provider
    class YumRepository < Chef::Provider
      extend Chef::Mixin::Which

      provides :yum_repository do
        which "yum"
      end

      def load_current_resource
      end

      action :create do
        declare_resource(:template, "/etc/yum.repos.d/#{new_resource.repositoryid}.repo") do
          if template_available?(new_resource.source)
            source new_resource.source
          else
            source ::File.expand_path("../support/yum_repo.erb", __FILE__)
            local true
          end
          sensitive new_resource.sensitive
          variables(config: new_resource)
          mode new_resource.mode
          if new_resource.make_cache
            notifies :run, "execute[yum clean metadata #{new_resource.repositoryid}]", :immediately if new_resource.clean_metadata || new_resource.clean_headers
            notifies :run, "execute[yum-makecache-#{new_resource.repositoryid}]", :immediately
            notifies :create, "ruby_block[yum-cache-reload-#{new_resource.repositoryid}]", :immediately
          end
        end

        declare_resource(:execute, "yum clean metadata #{new_resource.repositoryid}") do
          command "yum clean metadata --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
          action :nothing
        end

        # get the metadata for this repo only
        declare_resource(:execute, "yum-makecache-#{new_resource.repositoryid}") do
          command "yum -q -y makecache --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
          action :nothing
          only_if { new_resource.enabled }
        end

        # reload internal Chef yum cache
        declare_resource(:ruby_block, "yum-cache-reload-#{new_resource.repositoryid}") do
          block { Chef::Provider::Package::Yum::YumCache.instance.reload }
          action :nothing
        end
      end

      action :delete do
        # clean the repo cache first
        declare_resource(:execute, "yum clean all #{new_resource.repositoryid}") do
          command "yum clean all --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
          only_if "yum repolist all | grep -P '^#{new_resource.repositoryid}([ \t]|$)'"
        end

        declare_resource(:file, "/etc/yum.repos.d/#{new_resource.repositoryid}.repo") do
          action :delete
          notifies :create, "ruby_block[yum-cache-reload-#{new_resource.repositoryid}]", :immediately
        end

        declare_resource(:ruby_block, "yum-cache-reload-#{new_resource.repositoryid}") do
          block { Chef::Provider::Package::Yum::YumCache.instance.reload }
          action :nothing
        end
      end

      action :makecache do
        declare_resource(:execute, "yum-makecache-#{new_resource.repositoryid}") do
          command "yum -q -y makecache --disablerepo=* --enablerepo=#{new_resource.repositoryid}"
          action :run
          only_if { new_resource.enabled }
        end

        declare_resource(:ruby_block, "yum-cache-reload-#{new_resource.repositoryid}") do
          block { Chef::Provider::Package::Yum::YumCache.instance.reload }
          action :run
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
