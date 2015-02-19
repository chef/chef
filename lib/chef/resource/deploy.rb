#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

# EX:
# deploy "/my/deploy/dir" do
#   repo "git@github.com/whoami/project"
#   revision "abc123" # or "HEAD" or "TAG_for_1.0" or (subversion) "1234"
#   user "deploy_ninja"
#   enable_submodules true
#   migrate true
#   migration_command "rake db:migrate"
#   environment "RAILS_ENV" => "production", "OTHER_ENV" => "foo"
#   shallow_clone true
#   action :deploy # or :rollback
#   restart_command "touch tmp/restart.txt"
#   git_ssh_wrapper "wrap-ssh4git.sh"
#   scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion
#   svn_username "whoami"
#   svn_password "supersecret"
# end

require "chef/resource/scm"

class Chef
  class Resource

    # Deploy: Deploy apps from a source control repository.
    #
    # Callbacks:
    # Callbacks can be a block or a string. If given a block, the code
    # is evaluated as an embedded recipe, and run at the specified
    # point in the deploy process. If given a string, the string is taken as
    # a path to a callback file/recipe. Paths are evaluated relative to the
    # release directory. Callback files can contain chef code (resources, etc.)
    #
    class Deploy < Chef::Resource

      provider_base Chef::Provider::Deploy

      identity_attr :repository

      state_attrs :deploy_to, :revision

      def initialize(name, run_context=nil)
        super
        @resource_name = :deploy
        @deploy_to = name
        @environment = nil
        @repository_cache = 'cached-copy'
        @copy_exclude = []
        @purge_before_symlink = %w{log tmp/pids public/system}
        @create_dirs_before_symlink = %w{tmp public config}
        @symlink_before_migrate = {"config/database.yml" => "config/database.yml"}
        @symlinks = {"system" => "public/system", "pids" => "tmp/pids", "log" => "log"}
        @revision = 'HEAD'
        @action = :deploy
        @migrate = false
        @rollback_on_error = false
        @remote = "origin"
        @enable_submodules = false
        @shallow_clone = false
        @scm_provider = Chef::Provider::Git
        @svn_force_export = false
        @allowed_actions.push(:force_deploy, :deploy, :rollback)
        @additional_remotes = Hash[]
        @keep_releases = 5
        @enable_checkout = true
        @checkout_branch = "deploy"
        @timeout = nil
      end

      # where the checked out/cloned code goes
      def destination
        @destination ||= shared_path + "/#{@repository_cache}"
      end

      # where shared stuff goes, i.e., logs, tmp, etc. goes here
      def shared_path
        @shared_path ||= @deploy_to + "/shared"
      end

      # where the deployed version of your code goes
      def current_path
        @current_path ||= @deploy_to + "/current"
      end

      def depth
        @shallow_clone ? "5" : nil
      end

      # note: deploy_to is your application "meta-root."
      attribute :deploy_to, :kind_of => [ String ]

      attribute :repo, :kind_of => [ String ]
      alias :repository :repo

      attribute :remote, :kind_of => [ String ]

      attribute :role, :kind_of => [ String ]

      def restart_command(arg=NULL_ARG, &block)
        arg = block if block_given?
        nillable_set_or_return(
          :restart_command,
          arg,
          :kind_of => [ String, Proc ]
        )
      end
      alias :restart :restart_command

      attribute :migrate, :kind_of => [ TrueClass, FalseClass ]

      attribute :migration_command, kind_of: String

      attribute :rollback_on_error, :kind_of => [ TrueClass, FalseClass ]

      attribute :user, kind_of: String

      attribute :group, kind_of: [ String ]

      attribute :enable_submodules, kind_of: [ TrueClass, FalseClass ]

      attribute :shallow_clone, kind_of: [ TrueClass, FalseClass ]

      attribute :repository_cache, kind_of: String

      attribute :copy_exclude, kind_of: String

      attribute :revision, kind_of: String
      alias :branch :revision

      attribute :git_ssh_wrapper, kind_of: String
      alias :ssh_wrapper :git_ssh_wrapper

      attribute :svn_username, kind_of: String

      attribute :svn_password, kind_of: String

      attribute :svn_arguments, kind_of: String

      attribute :svn_info_args, kind_of: String

      def scm_provider(arg=NULL_ARG)
        klass = if arg.kind_of?(String) || arg.kind_of?(Symbol)
                  lookup_provider_constant(arg)
                else
                  arg
                end
        nillable_set_or_return(
          :scm_provider,
          klass,
          :kind_of => [ Class ]
        )
      end

      attribute :svn_force_export, kind_of: [ TrueClass, FalseClass ]

      def environment(arg=NULL_ARG)
        if arg.is_a?(String)
          Chef::Log.debug "Setting RAILS_ENV, RACK_ENV, and MERB_ENV to `#{arg}'"
          Chef::Log.warn "[DEPRECATED] please modify your deploy recipe or attributes to set the environment using a hash"
          arg = {"RAILS_ENV"=>arg,"MERB_ENV"=>arg,"RACK_ENV"=>arg}
        end
        nillable_set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end

       # The number of old release directories to keep around after cleanup
      def keep_releases(arg=NULL_ARG)
        [nillable_set_or_return(
          :keep_releases,
          arg,
          :kind_of => [ Integer ]), 1].max
      end

      # An array of paths, relative to your app's root, to be purged from a
      # SCM clone/checkout before symlinking. Use this to get rid of files and
      # directories you want to be shared between releases.
      # Default: ["log", "tmp/pids", "public/system"]
      attribute :purge_before_symlink, kind_of: Array

      # An array of paths, relative to your app's root, where you expect dirs to
      # exist before symlinking. This runs after #purge_before_symlink, so you
      # can use this to recreate dirs that you had previously purged.
      # For example, if you plan to use a shared directory for pids, and you
      # want it to be located in $APP_ROOT/tmp/pids, you could purge tmp,
      # then specify tmp here so that the tmp directory will exist when you
      # symlink the pids directory in to the current release.
      # Default: ["tmp", "public", "config"]
      attribute :create_dirs_before_symlink, kind_of: Array

      # A Hash of shared/dir/path => release/dir/path. This attribute determines
      # which files and dirs in the shared directory get symlinked to the current
      # release directory, and where they go. If you have a directory
      # $shared/pids that you would like to symlink as $current_release/tmp/pids
      # you specify it as "pids" => "tmp/pids"
      # Default {"system" => "public/system", "pids" => "tmp/pids", "log" => "log"}
      attribute :symlinks, kind_of: Hash

      # A Hash of shared/dir/path => release/dir/path. This attribute determines
      # which files in the shared directory get symlinked to the current release
      # directory and where they go. Unlike map_shared_files, these are symlinked
      # *before* any migration is run.
      # For a rails/merb app, this is used to link in a known good database.yml
      # (with the production db password) before running migrate.
      # Default {"config/database.yml" => "config/database.yml"}
      attribute :symlink_before_migrate, kind_of: Hash

      # Callback fires before migration is run.
      def before_migrate(arg=NULL_ARG, &block)
        arg = block if block_given?
        nillable_set_or_return(:before_migrate, arg, kind_of: [Proc, String])
      end

      # Callback fires before symlinking
      def before_symlink(arg=NULL_ARG, &block)
        arg = block if block_given?
        nillable_set_or_return(:before_symlink, arg, kind_of: [Proc, String])
      end

      # Callback fires before restart
      def before_restart(arg=NULL_ARG, &block)
        arg = block if block_given?
        nillable_set_or_return(:before_restart, arg, kind_of: [Proc, String])
      end

      # Callback fires after restart
      def after_restart(arg=NULL_ARG, &block)
        arg = block if block_given?
        nillable_set_or_return(:after_restart, arg, kind_of: [Proc, String])
      end

      attribute :additional_remotes, kind_of: Hash

      attribute :enable_checkout, kind_of: [ TrueClass, FalseClass ]

      attribute :checkout_branch, kind_of: String

      # FIXME The Deploy resource may be passed to an SCM provider as its
      # resource.  The SCM provider knows that SCM resources can specify a
      # timeout for SCM operations. The deploy resource must therefore support
      # a timeout method, but the timeout it describes is for SCM operations,
      # not the overall deployment. This is potentially confusing.
      attribute :timeout, kind_of: Integer

    end
  end
end
