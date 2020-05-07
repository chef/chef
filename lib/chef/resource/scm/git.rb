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

require_relative "../../resource"

class Chef
  class Resource
    class Git < Chef::Resource
      use "scm"

      unified_mode true

      provides :git

      description "Use the **git** resource to manage source control resources that exist in a git repository. git version 1.6.5 (or higher) is required to use all of the functionality in the git resource."

      property :additional_remotes, Hash,
        description: "A Hash of additional remotes that are added to the git repository configuration.",
        default: lazy { {} }

      property :depth, Integer,
        description: "The number of past revisions to be included in the git shallow clone. Unless specified the default behavior will do a full clone."

      property :enable_submodules, [TrueClass, FalseClass],
        description: "Perform a sub-module initialization and update.",
        default: false

      property :enable_checkout, [TrueClass, FalseClass],
        description: "Check out a repo from master. Set to false when using the checkout_branch attribute to prevent the git resource from attempting to check out master from master.",
        default: true

      property :remote, String,
        description: "The remote repository to use when synchronizing an existing clone.",
        default: "origin"

      property :ssh_wrapper, String,
        desired_state: false,
        description: "The path to the wrapper script used when running SSH with git. The `GIT_SSH` environment variable is set to this."

      property :checkout_branch, String,
        description: "Set this to use a local branch to avoid checking SHAs or tags to a detached head state."

      alias :branch :revision
      alias :reference :revision
      alias :repo :repository
    end
  end
end
