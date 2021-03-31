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
      examples <<~DOC
      **Use the git mirror**

      ```ruby
      git '/opt/my_sources/couch' do
        repository 'git://git.apache.org/couchdb.git'
        revision 'master'
        action :sync
      end
      ```

      **Use different branches**

      To use different branches, depending on the environment of the node:

      ```ruby
      branch_name = if node.chef_environment == 'QA'
                      'staging'
                    else
                      'master'
                    end

      git '/home/user/deployment' do
         repository 'git@github.com:git_site/deployment.git'
         revision branch_name
         action :sync
         user 'user'
         group 'test'
      end
      ```

      Where the `branch_name` variable is set to staging or master, depending on the environment of the node. Once this is determined, the `branch_name` variable is used to set the revision for the repository. If the git status command is used after running the example above, it will return the branch name as `deploy`, as this is the default value. Run Chef Infra Client in debug mode to verify that the correct branches are being checked out:

      ```
      sudo chef-client -l debug
      ```

      **Install an application from git using bash**

      The following example shows how Bash can be used to install a plug-in for rbenv named ruby-build, which is located in git version source control. First, the application is synchronized, and then Bash changes its working directory to the location in which ruby-build is located, and then runs a command.

      ```ruby
      git "#{Chef::Config[:file_cache_path]}/ruby-build" do
        repository 'git://github.com/rbenv/ruby-build.git'
        revision 'master'
        action :sync
      end

      bash 'install_ruby_build' do
        cwd "#{Chef::Config[:file_cache_path]}/ruby-build"
        user 'rbenv'
        group 'rbenv'
        code <<-EOH
          ./install.sh
          EOH
        environment 'PREFIX' => '/usr/local'
      end
      ```

      **Notify a resource post-checkout**

      ```ruby
      git "#{Chef::Config[:file_cache_path]}/my_app" do
        repository node['my_app']['git_repository']
        revision node['my_app']['git_revision']
        action :sync
        notifies :run, 'bash[compile_my_app]', :immediately
      end
      ```

      **Pass in environment variables**

      ```ruby
      git '/opt/my_sources/couch' do
        repository 'git://git.apache.org/couchdb.git'
        revision 'master'
        environment 'VAR' => 'whatever'
        action :sync
      end
      ```
      DOC

      property :additional_remotes, Hash,
        description: "A Hash of additional remotes that are added to the git repository configuration.",
        default: {}

      property :depth, Integer,
        description: "The number of past revisions to be included in the git shallow clone. Unless specified the default behavior will do a full clone."

      property :enable_submodules, [TrueClass, FalseClass],
        description: "Perform a sub-module initialization and update.",
        default: false

      property :enable_checkout, [TrueClass, FalseClass],
        description: "Check out a repo from master. Set to `false` when using the `checkout_branch` attribute to prevent the git resource from attempting to check out `master` from `master`.",
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
