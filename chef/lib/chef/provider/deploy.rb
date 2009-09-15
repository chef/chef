#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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

require "chef/mixin/command"
require "chef/mixin/from_file"
require "chef/provider/git"
require "chef/provider/subversion"

class Chef
  class Provider
    class Deploy < Chef::Provider
      
      include Chef::Mixin::FromFile
      include Chef::Mixin::Command
      
      attr_reader :scm_provider, :release_path
      
      def initialize(node, new_resource)
        super(node, new_resource)
        @scm_provider = @new_resource.scm_provider.new(@node, @new_resource)
        @release_path = @new_resource.deploy_to + "/releases/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
        
        # @configuration is not used by Deploy, it is only for backwards compat with
        # chef-deploy or capistrano hooks that might use it to get environment information
        @configuration = @new_resource.to_hash
        @configuration[:environment] = @configuration[:environment] && @configuration[:environment]["RAILS_ENV"]
      end
      
      def load_current_resource
        # TODO: set the current resource to the previous deploy for rollback purposes
      end
      
      def action_deploy
        Chef::Log.info "deploying branch: #{@new_resource.branch}"
        enforce_ownership
        update_cached_repo
        copy_cached_repo
        # chef-deploy then installs gems. hmmm...
        enforce_ownership
        callback(:before_migrate)
        migrate
        callback(:before_symlink)
        symlink
        callback(:before_restart)
        restart
        callback(:after_restart)
        cleanup!
      end
      
      def action_rollback
        @release_path = all_releases[-2]
        raise RuntimeError, "There is no release to rollback to!" unless @release_path
        release_to_nuke = all_releases.last
        Chef::Log.info "rolling back to previous release: #{@release_path}"
        symlink
        Chef::Log.info "removing last release: #{release_to_nuke}"
        FileUtils.rm_rf release_to_nuke
        Chef::Log.info "restarting with previous release"
        restart
      end
      
      # NOTE: if callbacks expect to have attributes available in a
      # @configuration ivar, they will be sorely disappointed.
      # But it wouldn't be too difficult to add a #to_hash method
      # for resources (using the #to_json method as a start) and
      # set @configuration to that...
      def callback(what)
        if ::File.exist?("#{@release_path}/deploy/#{what}.rb")
          Dir.chdir(@release_path) do
            Chef::Log.info "running deploy hook: #{@release_path}/deploy/#{what}.rb from #{@release_path}"
            from_file("#{@release_path}/deploy/#{what}.rb")
          end
        end
      end
      
      def migrate
        if @new_resource.migrate
          enforce_ownership
          link_shared_db_config_to_current_release
          
          environment = @new_resource.environment
          env_info = environment && environment.map do |key_and_val| 
            "#{key_and_val.first}='#{key_and_val.last}'"
          end.join(" ")
          
          Chef::Log.info  "Migrating: running #{@new_resource.migration_command} as #{@new_resource.user} " +
                          "with environment #{env_info}"
          run_command(run_options(:command => @new_resource.migration_command, :cwd=>@release_path))
        end
      end
      
      def symlink
        Chef::Log.info "Symlinking"
        purge_tempfiles_from_current_release
        link_tempfiles_to_current_release
        link_current_release_to_production
      end
      
      def restart
        if @new_resource.restart_command
          Chef::Log.info("Restarting app with #{@new_resource.restart_command} in #{@new_resource.current_path}")
          run_command(run_options(:command => @new_resource.restart_command, :cwd => @new_resource.current_path))
        end
      end
      
      def cleanup!
        all_releases[0..-6].each do |old_release|
          Chef::Log.info "Removing old release #{old_release}"
          FileUtils.rm_rf(old_release)
        end
      end
      
      def all_releases
        Dir.glob(@new_resource.deploy_to + "/releases/*")
      end
      
      def update_cached_repo
        Chef::Log.info "updating the cached checkout"
        @scm_provider.action_sync
      end
      
      def copy_cached_repo
        Chef::Log.info "copying the cached checkout to #{release_path}"
        FileUtils.mkdir_p(@new_resource.deploy_to + "/releases")
        FileUtils.cp_r(@new_resource.destination, @release_path, :preserve => true)
      end
      
      def enforce_ownership
        Chef::Log.info "ensuring proper ownership"
        FileUtils.chown_R(@new_resource.user, @new_resource.group, @new_resource.deploy_to)
      end
      
      def link_current_release_to_production
        Chef::Log.info "Linking release #{@release_path} into production at #{@new_resource.current_path}"
        FileUtils.rm_f(@new_resource.current_path)
        FileUtils.ln_sf(@release_path, @new_resource.current_path)
        enforce_ownership
      end
      
      def link_shared_db_config_to_current_release
        shared_database_yml = @new_resource.shared_path + "/config/database.yml"
        release_database_yml = @release_path + "/config/database.yml"
        Chef::Log.info "Linking shared db config: #{shared_database_yml} to release db config: #{release_database_yml}"
        FileUtils.ln_sf(shared_database_yml, release_database_yml)
      end
      
      def link_tempfiles_to_current_release
        Chef::Log.info("Linking shared /log /tmp/pids and /public/system into current release")
        FileUtils.mkdir_p(@release_path + "/tmp")
        FileUtils.mkdir_p(@release_path + "/public")
        FileUtils.mkdir_p(@release_path + "/config")
        FileUtils.ln_sf(@new_resource.shared_path + "/system",  @release_path + "/public/system")
        FileUtils.ln_sf(@new_resource.shared_path + "/pids",    @release_path + "/tmp/pids")
        FileUtils.ln_sf(@new_resource.shared_path + "/log",     @release_path + "/log")
        link_shared_db_config_to_current_release
        enforce_ownership
      end
      
      def purge_tempfiles_from_current_release
        Chef::Log.info("Purging checked out copies of /log /tmp/pids and /public/system from current release")
        FileUtils.rm_rf(@release_path + "/log")
        FileUtils.rm_rf(@release_path + "/tmp/pids")
        FileUtils.rm_rf(@release_path + "/public/system")
      end
      
      def run_options(run_opts={})
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts[:environment] = @new_resource.environment if @new_resource.environment
        run_opts
      end
      
    end
  end
end
