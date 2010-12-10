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


require 'chef/log'
require 'chef/provider'
require 'chef/mixin/command'
require 'fileutils'

class Chef
  class Provider
    class Git < Chef::Provider
      
      include Chef::Mixin::Command
      
      def load_current_resource
        @current_resource = Chef::Resource::Git.new(@new_resource.name)
        if current_revision = find_current_revision
          @current_resource.revision current_revision
        end
      end
      
      def action_checkout
        assert_target_directory_valid!

        if target_dir_non_existant_or_empty?
          clone
          checkout
          enable_submodules
          @new_resource.updated_by_last_action(true)
        else
          Chef::Log.info "Taking no action, checkout destination #{@new_resource.destination} already exists or is a non-empty directory"
        end
      end
      
      def action_export
        action_checkout
        FileUtils.rm_rf(::File.join(@new_resource.destination,".git"))
        @new_resource.updated_by_last_action(true)
      end
      
      def action_sync
        assert_target_directory_valid!

        if existing_git_clone?
          current_rev = find_current_revision
          Chef::Log.debug "#{@new_resource} current revision: #{current_rev} target revision: #{target_revision}"
          unless current_revision_matches_target_revision?
            fetch_updates
            enable_submodules
            Chef::Log.info "#{@new_resource} updated to revision: #{target_revision}"
            @new_resource.updated_by_last_action(true)
          end

        else
          action_checkout
          @new_resource.updated_by_last_action(true)
        end
      end

      def assert_target_directory_valid!
        target_parent_directory = ::File.dirname(@new_resource.destination)
        unless ::File.directory?(target_parent_directory)
          msg = "Cannot clone #{@new_resource} to #{@new_resource.destination}, the enclosing directory #{target_parent_directory} does not exist"
          raise Chef::Exceptions::MissingParentDirectory, msg
        end
      end

      def existing_git_clone?
        ::File.exist?(::File.join(@new_resource.destination, ".git"))
      end

      def target_dir_non_existant_or_empty?
        !::File.exist?(@new_resource.destination) || Dir.entries(@new_resource.destination).sort == ['.','..']
      end

      def find_current_revision
        if ::File.exist?(::File.join(cwd, ".git"))
          status, result, error_message = output_of_command("git rev-parse HEAD", run_options(:cwd=>cwd))
          
          # 128 is returned when we're not in a git repo. this is fine
          unless [0,128].include?(status.exitstatus)
            handle_command_failures(status, "STDOUT: #{result}\nSTDERR: #{error_message}")
          end
        end
        sha_hash?(result) ? result : nil
      end
      
      def clone
        remote = @new_resource.remote

        args = []
        args << "-o #{remote}" unless remote == 'origin'
        args << "--depth #{@new_resource.depth}" if @new_resource.depth
        
        Chef::Log.info "Cloning repo #{@new_resource.repository} to #{@new_resource.destination}"
        
        clone_cmd = "git clone #{args.join(' ')} #{@new_resource.repository} #{@new_resource.destination}"
        run_command(run_options(:command => clone_cmd))
      end
      
      def checkout
        sha_ref = target_revision
        Chef::Log.info "Checking out branch: #{@new_resource.revision} reference: #{sha_ref}"
        # checkout into a local branch rather than a detached HEAD
        run_command(run_options(:command => "git checkout -b deploy #{sha_ref}", :cwd => @new_resource.destination))
      end
      
      def enable_submodules
        if @new_resource.enable_submodules
          Chef::Log.info "Enabling git submodules"
          command = "git submodule init && git submodule update"
          run_command(run_options(:command => command, :cwd => @new_resource.destination))
        end
      end
      
      def fetch_updates
        setup_remote_tracking_branches if @new_resource.remote != 'origin'

        # since we're in a local branch already, just reset to specified revision rather than merge
        fetch_command = "git fetch #{@new_resource.remote} && git fetch #{@new_resource.remote} --tags && git reset --hard #{target_revision}"
        Chef::Log.debug "Fetching updates from #{new_resource.remote} and resetting to revison #{target_revision}"
        run_command(run_options(:command => fetch_command, :cwd => @new_resource.destination))
      end

      # Use git-config to setup a remote tracking branches. Could use
      # git-remote but it complains when a remote of the same name already
      # exists, git-config will just silenty overwrite the setting every
      # time. This could cause wierd-ness in the remote cache if the url
      # changes between calls, but as long as the repositories are all
      # based from each other it should still work fine.
      def setup_remote_tracking_branches
        command = []

        Chef::Log.info  "Configuring remote tracking branches for repository #{@new_resource.repository} "+
                        "at remote #{@new_resource.remote}"
        command << "git config remote.#{@new_resource.remote}.url #{@new_resource.repository}"
        command << "git config remote.#{@new_resource.remote}.fetch +refs/heads/*:refs/remotes/#{@new_resource.remote}/*"
        run_command(run_options(:command => command.join(" && "), :cwd => @new_resource.destination))
      end

      def current_revision_matches_target_revision?
        (!@current_resource.revision.nil?) && (target_revision.strip.to_i(16) == @current_resource.revision.strip.to_i(16))
      end

      def target_revision
        @target_revision ||= begin
          assert_revision_not_remote
          
          if sha_hash?(@new_resource.revision)
            @target_revision = @new_resource.revision 
          else
            resolved_reference = remote_resolve_reference
            @target_revision = extract_revision(resolved_reference)
          end
        end
      end
      
      alias :revision_slug :target_revision
      
      def remote_resolve_reference
        command = git('ls-remote', @new_resource.repository, @new_resource.revision)
        Chef::Log.debug("Executing #{command}")
        begin
          status, result, error_message = output_of_command(command, run_options)
          handle_command_failures(status, "STDOUT: #{result}\nSTDERR: #{error_message}")
        rescue Chef::Exceptions::Exec => e
          msg =  "Could not access the remote Git repository. If this is a private repository, "
          msg << "verify that the deploy key for your application has been added to your remote Git account.\n"
          msg << e.message
          raise Chef::Exceptions::Exec, msg
        end
        result
      end
      
      private
      
      def run_options(run_opts={})
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts[:environment] = {"GIT_SSH" => @new_resource.ssh_wrapper} if @new_resource.ssh_wrapper
        run_opts
      end
      
      def cwd
        @new_resource.destination
      end
      
      def git(*args)
        ["git", *args].compact.join(" ")
      end

      def sha_hash?(string)
        string =~ /^[0-9a-f]{40}$/
      end
      
      def assert_revision_not_remote
        if @new_resource.revision =~ /^origin\//
          reference = @new_resource.revision
          error_text =  "Deploying remote branches is not supported. " +
                        "Specify the remote branch as a local branch for " +
                        "the git repository you're deploying from " + 
                        "(ie: '#{reference.gsub('origin/', '')}' rather than '#{reference}')."
          raise RuntimeError, error_text
        end
      end
      
      def extract_revision(resolved_reference)
        unless resolved_reference =~ /^([0-9a-f]{40})\s+(\S+)/
          msg = "Unable to parse SHA reference for '#{@new_resource.revision}' in repository '#{@new_resource.repository}'. "
          msg << "Verify your (case-sensitive) repository URL and revision.\n"
          msg << "`git ls-remote` output: #{resolved_reference}"
          raise Chef::Exceptions::UnresolvableGitReference, msg
        end
        $1
      end
      
    end
  end
end
