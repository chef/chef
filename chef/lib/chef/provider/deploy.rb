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
        
        # NOTE: workaround for CHEF-577
        @definitions ||= Hash.new
        @collection = Chef::ResourceCollection.new
        
        @scm_provider = @new_resource.scm_provider.new(@node, @new_resource)
        @release_path = @new_resource.deploy_to + "/releases/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
        
        # @configuration is not used by Deploy, it is only for backwards compat with
        # chef-deploy or capistrano hooks that might use it to get environment information
        @configuration = @new_resource.to_hash
        @configuration[:environment] = @configuration[:environment] && @configuration[:environment]["RAILS_ENV"]
      end
      
      def load_current_resource
      end
      
      def sudo(command,&block)
        execute(command, &block)
      end
      
      def run(command, &block)
        exec = execute(command, &block)
        exec.user(@new_resource.user)
        exec
      end
      
      def action_deploy
        Chef::Log.info "deploying branch: #{@new_resource.branch}"
        enforce_ownership
        update_cached_repo
        copy_cached_repo
        install_gems
        enforce_ownership
        callback(:before_migrate, @new_resource.before_migrate)
        migrate
        callback(:before_symlink, @new_resource.before_symlink)
        symlink
        callback(:before_restart, @new_resource.before_restart)
        restart
        callback(:after_restart, @new_resource.after_restart)
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
      
      def callback(what, callback_code=nil)
        @collection = Chef::ResourceCollection.new
        case callback_code
        when Proc
          Chef::Log.info "Running callback #{what} code block"
          recipe_eval(&callback_code)
        when String
          callback_file = "#{@release_path}/#{callback_code}"
          unless ::File.exist?(callback_file)
            raise RuntimeError, "Can't find your callback file #{callback_file}"
          end
          run_callback_from_file(callback_file)
        when nil
          run_callback_from_file("#{@release_path}/deploy/#{what}.rb")
        else
          raise RuntimeError, "You gave me a callback I don't know what to do with: #{callback_code.inspect}"
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
        if restart_cmd = @new_resource.restart_command
          if restart_cmd.kind_of?(Proc)
            Chef::Log.info("Restarting app with embedded recipe")
            recipe_eval(&restart_cmd)
          else
            Chef::Log.info("Restarting app with #{@new_resource.restart_command} in #{@new_resource.current_path}")
            run_command(run_options(:command => @new_resource.restart_command, :cwd => @new_resource.current_path))
          end
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
      
      protected
      
      def install_gems
        gems_collection = Chef::ResourceCollection.new
        gem_packages.each { |rbgem| gems_collection << rbgem }
        Chef::Runner.new(@node, gems_collection).converge
      end
      
      def gem_packages
        return [] unless ::File.exist?("#{release_path}/gems.yml")
        gems = YAML.load(IO.read("#{release_path}/gems.yml"))
        
        gems.map do |g|
          r = Chef::Resource::GemPackage.new(g[:name], nil, node)
          r.version g[:version]
          r.action :install
          r.source "http://gems.github.com"
          r
        end
      end
      
      def run_options(run_opts={})
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts[:environment] = @new_resource.environment if @new_resource.environment
        run_opts
      end
      
      def run_callback_from_file(callback_file)
        if ::File.exist?(callback_file)
          Dir.chdir(@release_path) do
            Chef::Log.info "running deploy hook: #{callback_file}"
            recipe_eval { from_file(callback_file) }
          end
        end
      end
      
    end
  end
end
