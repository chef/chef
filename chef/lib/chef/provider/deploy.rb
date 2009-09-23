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
      
      def initialize(node, new_resource, collection=nil, definitions=nil, cookbook_loader=nil)
        super(node, new_resource, collection, definitions, cookbook_loader)
        @scm_provider = @new_resource.scm_provider.new(@node, @new_resource)
        @release_path = @new_resource.deploy_to + "/releases/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
        
        # @configuration is not used by Deploy, it is only for backwards compat with
        # chef-deploy or capistrano hooks that might use it to get environment information
        @configuration = @new_resource.to_hash
        @configuration[:environment] = @configuration[:environment] && @configuration[:environment]["RAILS_ENV"]
      end
      
      def load_current_resource
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
        links_info = @new_resource.symlink_before_migrate.map { |src, dst| "#{src} => #{dst}" }.join(", ")
        Chef::Log.info "Making pre-migration symlinks: #{links_info}"
        @new_resource.symlink_before_migrate.each do |src, dest|
          FileUtils.ln_sf(@new_resource.shared_path + "/#{src}", @release_path + "/#{dest}")
        end
      end
      
      def link_tempfiles_to_current_release
        dirs_info = @new_resource.create_dirs_before_symlink.join(",")
        Chef::Log.info("creating directories before symlink: #{dirs_info}")
        @new_resource.create_dirs_before_symlink.each { |dir| FileUtils.mkdir_p(@release_path + "/#{dir}") }
        
        links_info = @new_resource.symlinks.map { |src, dst| "#{src} => #{dst}" }.join(", ")
        Chef::Log.info("Linking shared paths into current release: #{links_info}")
        @new_resource.symlinks.each do |src, dest|
          FileUtils.ln_sf(@new_resource.shared_path + "/#{src}",  @release_path + "/#{dest}")
        end
        link_shared_db_config_to_current_release
        enforce_ownership
      end
      
      def create_dirs_before_symlink
      end
      
      def purge_tempfiles_from_current_release
        log_info = @new_resource.purge_before_symlink.join(", ")
        Chef::Log.info("Purging directories in checkout #{log_info}")
        @new_resource.purge_before_symlink.each { |dir| FileUtils.rm_rf(@release_path + "/#{dir}") }
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
