#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class Breakpoint < Chef::Resource
      unified_mode true

      provides :breakpoint, target_mode: true

      description "Use the **breakpoint** resource to add breakpoints to recipes. Run the #{ChefUtils::Dist::Infra::SHELL} in #{ChefUtils::Dist::Infra::PRODUCT} mode, and then use those breakpoints to debug recipes. Breakpoints are ignored by the #{ChefUtils::Dist::Infra::CLIENT} during an actual #{ChefUtils::Dist::Infra::CLIENT} run. That said, breakpoints are typically used to debug recipes only when running them in a non-production environment, after which they are removed from those recipes before the parent cookbook is uploaded to the Chef server."
      introduced "12.0"
      examples <<~DOC
      **A recipe without a breakpoint**

      ```ruby
      yum_key node['yum']['elrepo']['key'] do
        url  node['yum']['elrepo']['key_url']
        action :add
      end

      yum_repository 'elrepo' do
        description 'ELRepo.org Community Enterprise Linux Extras Repository'
        key node['yum']['elrepo']['key']
        mirrorlist node['yum']['elrepo']['url']
        includepkgs node['yum']['elrepo']['includepkgs']
        exclude node['yum']['elrepo']['exclude']
        action :create
      end
      ```

      **The same recipe with breakpoints**

      In the following example, the name of each breakpoint is an arbitrary string.

      ```ruby
      breakpoint "before yum_key node['yum']['repo_name']['key']" do
        action :break
      end

      yum_key node['yum']['repo_name']['key'] do
        url  node['yum']['repo_name']['key_url']
        action :add
      end

      breakpoint "after yum_key node['yum']['repo_name']['key']" do
        action :break
      end

      breakpoint "before yum_repository 'repo_name'" do
        action :break
      end

      yum_repository 'repo_name' do
        description 'description'
        key node['yum']['repo_name']['key']
        mirrorlist node['yum']['repo_name']['url']
        includepkgs node['yum']['repo_name']['includepkgs']
        exclude node['yum']['repo_name']['exclude']
        action :create
      end

      breakpoint "after yum_repository 'repo_name'" do
        action :break
      end
      ```

      In the previous examples, the names are used to indicate if the breakpoint is before or after a resource and also to specify which resource it is before or after.
      DOC

      default_action :break

      def initialize(action = "break", *args)
        super(caller.first, *args)
      end

      action :break, description: "Add a breakpoint for use with #{ChefUtils::Dist::Infra::SHELL}" do
        if defined?(Shell) && Shell.running?
          with_run_context :parent do
            run_context.resource_collection.iterator.pause
            new_resource.updated_by_last_action(true)
            run_context.resource_collection.iterator
          end
        end
      end
    end
  end
end
