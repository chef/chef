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

      def initialize(new_resource, run_context)
        super(new_resource, run_context)

        @scm_provider = new_resource.scm_provider.new(new_resource, run_context)

        # @configuration is not used by Deploy, it is only for backwards compat with
        # chef-deploy or capistrano hooks that might use it to get environment information
        @configuration = @new_resource.to_hash
        @configuration[:environment] = @configuration[:environment] && @configuration[:environment]["RAILS_ENV"]
      end

      def load_current_resource
        @release_path = @new_resource.deploy_to + "/releases/#{release_slug}"
      end

      def sudo(command,&block)
        execute(command, &block)
      end

      def run(command, &block)
        exec = execute(command, &block)
        exec.user(@new_resource.user) if @new_resource.user
        exec.group(@new_resource.group) if @new_resource.group
        exec.cwd(release_path) unless exec.cwd
        exec.environment(@new_resource.environment) unless exec.environment
        exec
      end

      def action_deploy
        if all_releases.include?(release_path)
          if all_releases[-1] == release_path
            Chef::Log.debug("#{@new_resource} is the latest version")
          else
            action_rollback
          end
        else
          deploy
          @new_resource.updated_by_last_action(true)
        end
      end

      def action_force_deploy
        if all_releases.include?(release_path)
          FileUtils.rm_rf(release_path)
          Chef::Log.info("#{@new_resource} forcing deploy of already deployed app at #{release_path}")
        end
        deploy
        @new_resource.updated_by_last_action(true)
      end

      def action_rollback
        if release_path
          rp_index = all_releases.index(release_path)
          raise RuntimeError, "There is no release to rollback to!" unless rp_index
          rp_index += 1
          releases_to_nuke = all_releases[rp_index..-1]
        else
          @release_path = all_releases[-2]
          raise RuntimeError, "There is no release to rollback to!" unless @release_path
          releases_to_nuke = [ all_releases.last ]
        end

        Chef::Log.info "#{@new_resource} rolling back to previous release #{release_path}"
        symlink
        Chef::Log.info "#{@new_resource} restarting with previous release"
        restart
        releases_to_nuke.each do |i|
          Chef::Log.info "#{@new_resource} removing release: #{i}"
          FileUtils.rm_rf i
          release_deleted(i)
        end
        @new_resource.updated_by_last_action(true)
      end

      def deploy
        enforce_ownership
        verify_directories_exist
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
        Chef::Log.info "#{@new_resource} deployed to #{@new_resource.deploy_to}"
      end

      def callback(what, callback_code=nil)
        @collection = Chef::ResourceCollection.new
        case callback_code
        when Proc
          Chef::Log.info "#{@new_resource} running callback #{what}"
          recipe_eval(&callback_code)
        when String
          callback_file = "#{release_path}/#{callback_code}"
          unless ::File.exist?(callback_file)
            raise RuntimeError, "Can't find your callback file #{callback_file}"
          end
          run_callback_from_file(callback_file)
        when nil
          run_callback_from_file("#{release_path}/deploy/#{what}.rb")
        else
          raise RuntimeError, "You gave me a callback I don't know what to do with: #{callback_code.inspect}"
        end
      end

      def migrate
        run_symlinks_before_migrate

        if @new_resource.migrate
          enforce_ownership

          environment = @new_resource.environment
          env_info = environment && environment.map do |key_and_val|
            "#{key_and_val.first}='#{key_and_val.last}'"
          end.join(" ")

          Chef::Log.info "#{@new_resource} migrating #{@new_resource.user} with environment #{env_info}"
          run_command(run_options(:command => @new_resource.migration_command, :cwd=>release_path, :command_log_level => :info))
        end
      end

      def symlink
        purge_tempfiles_from_current_release
        link_tempfiles_to_current_release
        link_current_release_to_production
        Chef::Log.info "#{@new_resource} updated symlinks"
      end

      def restart
        if restart_cmd = @new_resource.restart_command
          if restart_cmd.kind_of?(Proc)
            Chef::Log.info("#{@new_resource} restarting app with embedded recipe")
            recipe_eval(&restart_cmd)
          else
            Chef::Log.info("#{@new_resource} restarting app")
            run_command(run_options(:command => @new_resource.restart_command, :cwd => @new_resource.current_path))
          end
        end
      end

      def cleanup!
        all_releases[0..-6].each do |old_release|
          Chef::Log.info "#{@new_resource} removing old release #{old_release}"
          FileUtils.rm_rf(old_release)
          release_deleted(old_release)
        end
      end

      def all_releases
        Dir.glob(@new_resource.deploy_to + "/releases/*").sort
      end

      def update_cached_repo
        @scm_provider.load_current_resource
        if @new_resource.svn_force_export
          svn_force_export
        else
          run_scm_sync
        end
      end

      def run_scm_sync
        @scm_provider.action_sync
      end

      def svn_force_export
        Chef::Log.info "#{@new_resource} exporting source repository"
        @scm_provider.action_force_export
      end

      def copy_cached_repo
        FileUtils.mkdir_p(@new_resource.deploy_to + "/releases")
        run_command(:command => "cp -RPp #{::File.join(@new_resource.destination, ".")} #{release_path}")
        Chef::Log.info "#{@new_resource} copied the cached checkout to #{release_path}"
        release_created(release_path)
      end

      def enforce_ownership
        FileUtils.chown_R(@new_resource.user, @new_resource.group, @new_resource.deploy_to)
        Chef::Log.info("#{@new_resource} set user to #{@new_resource.user}") if @new_resource.user
        Chef::Log.info("#{@new_resource} set group to #{@new_resource.group}") if @new_resource.group
      end

      def verify_directories_exist
        create_dir(@new_resource.deploy_to)
        create_dir(@new_resource.shared_path)
      end

      def link_current_release_to_production
        FileUtils.rm_f(@new_resource.current_path)
        begin
          FileUtils.ln_sf(release_path, @new_resource.current_path)
        rescue => e
          raise Chef::Exceptions::FileNotFound.new("Cannot symlink current release to production: #{e.message}")
        end
        Chef::Log.info "#{@new_resource} linked release #{release_path} into production at #{@new_resource.current_path}"
        enforce_ownership
      end

      def run_symlinks_before_migrate
        links_info = @new_resource.symlink_before_migrate.map { |src, dst| "#{src} => #{dst}" }.join(", ")
        @new_resource.symlink_before_migrate.each do |src, dest|
          begin
            FileUtils.ln_sf(@new_resource.shared_path + "/#{src}", release_path + "/#{dest}")
          rescue => e
            raise Chef::Exceptions::FileNotFound.new("Cannot symlink #{@new_resource.shared_path}/#{src} to #{release_path}/#{dest} before migrate: #{e.message}")
          end
        end
        Chef::Log.info "#{@new_resource} made pre-migration symlinks"
      end

      def create_dir(dir)
        begin
          FileUtils.mkdir_p(dir)
        rescue => e
          raise Chef::Exceptions::FileNotFound.new("Cannot create directory #{dir}: #{e.message}")
        end
      end

      def link_tempfiles_to_current_release
        dirs_info = @new_resource.create_dirs_before_symlink.join(",")
        @new_resource.create_dirs_before_symlink.each do |dir| 
          create_dir(release_path + "/#{dir}")
        end
        Chef::Log.info("#{@new_resource} created directories before symlinking #{dirs_info}")

        links_info = @new_resource.symlinks.map { |src, dst| "#{src} => #{dst}" }.join(", ")
        @new_resource.symlinks.each do |src, dest|
          create_dir(::File.join(@new_resource.shared_path, src))
          begin
            FileUtils.ln_sf(::File.join(@new_resource.shared_path, src), ::File.join(release_path, dest))
          rescue => e
            raise Chef::Exceptions::FileNotFound.new("Cannot symlink shared data #{::File.join(@new_resource.shared_path, src)} to #{::File.join(release_path, dest)}: #{e.message}")
          end
        end
        Chef::Log.info("#{@new_resource} linked shared paths into current release: #{links_info}")
        run_symlinks_before_migrate
        enforce_ownership
      end

      def create_dirs_before_symlink
      end

      def purge_tempfiles_from_current_release
        log_info = @new_resource.purge_before_symlink.join(", ")
        @new_resource.purge_before_symlink.each { |dir| FileUtils.rm_rf(release_path + "/#{dir}") }
        Chef::Log.info("#{@new_resource} purged directories in checkout #{log_info}")
      end

      protected

      # Internal callback, called after copy_cached_repo.
      # Override if you need to keep state externally.
      def release_created(release_path)
      end

      # Internal callback, called during cleanup! for each old release removed.
      # Override if you need to keep state externally.
      def release_deleted(release_path)
      end

      def release_slug
        raise Chef::Exceptions::Override, "You must override release_slug in #{self.to_s}"
      end

      def install_gems
        gem_resource_collection_runner.converge
      end

      def gem_resource_collection_runner
        gems_collection = Chef::ResourceCollection.new
        gem_packages.each { |rbgem| gems_collection << rbgem }
        gems_run_context = run_context.dup
        gems_run_context.resource_collection = gems_collection
        Chef::Runner.new(gems_run_context)
      end

      def gem_packages
        return [] unless ::File.exist?("#{release_path}/gems.yml")
        gems = YAML.load(IO.read("#{release_path}/gems.yml"))

        gems.map do |g|
          r = Chef::Resource::GemPackage.new(g[:name], run_context)
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
        run_opts[:command_log_prepend] = @new_resource.to_s
        run_opts[:command_log_level] ||= :debug
        if run_opts[:command_log_level] == :info
          if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info?
            run_opts[:live_stream] = STDOUT
          end
        end
        run_opts
      end

      def run_callback_from_file(callback_file)
        if ::File.exist?(callback_file)
          Dir.chdir(release_path) do
            Chef::Log.info "#{@new_resource} running deploy hook #{callback_file}"
            recipe_eval { from_file(callback_file) }
          end
        end
      end

    end
  end
end
