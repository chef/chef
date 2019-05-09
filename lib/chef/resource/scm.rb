#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

class Chef
  class Resource
    class Scm < Chef::Resource
      default_action :sync
      allowed_actions :checkout, :export, :sync, :diff, :log

      property :destination, String,
               description: "The location path to which the source is to be cloned, checked out, or exported. Default value: the name of the resource block.",
               name_property: true, identity: true

      property :repository, String

      property :revision, String,
               description: "The revision to checkout.",
               default: "HEAD"

      property :user, [String, Integer],
               description: "The system user that is responsible for the checked-out code."

      property :group, [String, Integer],
               description: "The system group that is responsible for the checked-out code."

      # Capistrano and git-deploy use ``shallow clone''
      property :depth, Integer,
               description: "The number of past revisions to be included in the git shallow clone. Unless specified the default behavior will do a full clone."

      property :enable_submodules, [TrueClass, FalseClass],
               description: "Perform a sub-module initialization and update.",
               default: false

      property :enable_checkout, [TrueClass, FalseClass],
               description: "Check out a repo from master. Set to false when using the checkout_branch attribute to prevent the git resource from attempting to check out master from master.",
               default: true

      property :remote, String,
               default: "origin"

      property :ssh_wrapper, String,
               desired_state: false

      property :timeout, Integer,
               desired_state: false

      property :checkout_branch, String,
               description: "Do a one-time checkout **or** use when a branch in the upstream repository is named 'deploy'. To prevent the resource from attempting to check out master from master, set 'enable_checkout' to 'false' when using the 'checkout_branch' property.",
               default: "deploy"

      property :environment, [Hash, nil],
               description: "A Hash of environment variables in the form of ({'ENV_VARIABLE' => 'VALUE'}).",
               default: nil

      alias :env :environment
    end
  end
end
