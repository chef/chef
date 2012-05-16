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
require 'chef/mixin/shell_out'
require 'fileutils'
require 'shellwords'

class Chef
  class Provider
    class Git < Chef::Provider

      include Chef::Mixin::ShellOut
      
      def whyrun_supported?
        true
      end

      def load_current_resource
        @resolved_reference = nil
        @current_resource = Chef::Resource::Git.new(@new_resource.name)
        if current_revision = find_current_revision
          @current_resource.revision current_revision
        end
      end

      def define_resource_requirements
        # Parent directory of the target must exist. 
        requirements.assert(:checkout, :sync) do |a|
          dirname = ::File.dirname(@new_resource.destination)
          a.assertion { ::File.directory?(dirname) }
          a.whyrun("Directory #{dirname} does not exist, this run will fail unless it has been previously created. Assuming it would have been created.")
          a.failure_message(Chef::Exceptions::MissingParentDirectory,
            "Cannot clone #{@new_resource} to #{@new_resource.destination}, the enclosing directory #{dirname} does not exist")
        end


        requirements.assert(:all_actions) do |a|
          a.assertion { !(@new_resource.revision =~ /^origin\//) }
          a.failure_message Chef::Exceptions::InvalidRemoteGitReference,
             "Deploying remote branches is not supported. " +
             "Specify the remote branch as a local branch for " +
             "the git repository you're deploying from " +
             "(ie: '#{@new_resource.revision.gsub('origin/', '')}' rather than '#{@new_resource.revision}')."
        end

        requirements.assert(:all_actions) do |a|
          # this can't be recovered from in why-run mode, because nothing that 
          # we do in the course of a run is likely to create a valid target_revision 
          # if we can't resolve it up front.
          a.assertion { target_revision != nil }
          a.failure_message Chef::Exceptions::UnresolvableGitReference, 
            "Unable to parse SHA reference for '#{@new_resource.revision}' in repository '#{@new_resource.repository}'. " +
            "Verify your (case-sensitive) repository URL and revision.\n" + 
            "`git ls-remote` output: #{@resolved_reference}"
        end
      end 

      def action_checkout
        if target_dir_non_existent_or_empty?
          clone
          checkout
          enable_submodules
          add_remotes
        else
          Chef::Log.debug "#{@new_resource} checkout destination #{@new_resource.destination} already exists or is a non-empty directory"
        end
      end

      def action_export
        action_checkout
        converge_by("complete the export by removing #{@new_resource.destination}.git after checkout") do 
          FileUtils.rm_rf(::File.join(@new_resource.destination,".git"))
        end
      end

      def action_sync
        if existing_git_clone?
          current_rev = find_current_revision
          Chef::Log.debug "#{@new_resource} current revision: #{current_rev} target revision: #{target_revision}"
          unless current_revision_matches_target_revision?
            fetch_updates
            enable_submodules
            Chef::Log.info "#{@new_resource} updated to revision #{target_revision}"
          end
          add_remotes
        else
          action_checkout
        end
      end


      def existing_git_clone?
        ::File.exist?(::File.join(@new_resource.destination, ".git"))
      end

      def target_dir_non_existent_or_empty?
        !::File.exist?(@new_resource.destination) || Dir.entries(@new_resource.destination).sort == ['.','..']
      end

      def find_current_revision
        Chef::Log.debug("#{@new_resource} finding current git revision")
        if ::File.exist?(::File.join(cwd, ".git"))
          # 128 is returned when we're not in a git repo. this is fine
          result = shell_out!('git rev-parse HEAD', :cwd => cwd, :returns => [0,128]).stdout.strip
        end
        sha_hash?(result) ? result : nil
      end

      def add_remotes
        if (@new_resource.additional_remotes.length > 0)
          @new_resource.additional_remotes.each_pair do |remote_name, remote_url|
            converge_by("add remote #{remote_name} from #{remote_url}") do
              Chef::Log.info "#{@new_resource} adding git remote #{remote_name} = #{remote_url}"
              command = "git remote add #{remote_name} #{remote_url}"
              if shell_out(command, run_options(:cwd => @new_resource.destination, :log_level => :info)).exitstatus != 0
                @new_resource.updated_by_last_action(true)
              end
            end
          end
        end
      end

      def clone 
        converge_by("clone from #{@new_resource.repository} into #{@new_resource.destination}") do
          remote = @new_resource.remote

          args = []
          args << "-o #{remote}" unless remote == 'origin'
          args << "--depth #{@new_resource.depth}" if @new_resource.depth

          Chef::Log.info "#{@new_resource} cloning repo #{@new_resource.repository} to #{@new_resource.destination}"

          clone_cmd = "git clone #{args.join(' ')} #{@new_resource.repository} #{Shellwords.escape @new_resource.destination}"
          shell_out!(clone_cmd, run_options(:log_level => :info))
        end
      end

      def checkout
        sha_ref = target_revision
        converge_by("checkout ref #{sha_ref} branch #{@new_resource.revision}") do
          # checkout into a local branch rather than a detached HEAD
          shell_out!("git checkout -b deploy #{sha_ref}", run_options(:cwd => @new_resource.destination))
          Chef::Log.info "#{@new_resource} checked out branch: #{@new_resource.revision} reference: #{sha_ref}"
        end
      end

      def enable_submodules
        if @new_resource.enable_submodules
          converge_by("enable git submodules for #{@new_resource}") do 
            Chef::Log.info "#{@new_resource} enabling git submodules"
            # the --recursive flag means we require git 1.6.5+ now, see CHEF-1827
            command = "git submodule update --init --recursive"
            shell_out!(command, run_options(:cwd => @new_resource.destination, :log_level => :info))
          end
        end
      end

      def fetch_updates
        setup_remote_tracking_branches if @new_resource.remote != 'origin'
        converge_by("fetch updates for #{@new_resource.remote}") do
          # since we're in a local branch already, just reset to specified revision rather than merge
          fetch_command = "git fetch #{@new_resource.remote} && git fetch #{@new_resource.remote} --tags && git reset --hard #{target_revision}"
          Chef::Log.debug "Fetching updates from #{new_resource.remote} and resetting to revision #{target_revision}"
          shell_out!(fetch_command, run_options(:cwd => @new_resource.destination))
        end
      end

      # Use git-config to setup a remote tracking branches. Could use
      # git-remote but it complains when a remote of the same name already
      # exists, git-config will just silenty overwrite the setting every
      # time. This could cause wierd-ness in the remote cache if the url
      # changes between calls, but as long as the repositories are all
      # based from each other it should still work fine.
      def setup_remote_tracking_branches
        command = []
        converge_by("set up remote tracking branches for #{@new_resource.repository} at #{@new_resource.remote}") do
          Chef::Log.debug "#{@new_resource} configuring remote tracking branches for repository #{@new_resource.repository} "+
                          "at remote #{@new_resource.remote}"
          command << "git config remote.#{@new_resource.remote}.url #{@new_resource.repository}"
          command << "git config remote.#{@new_resource.remote}.fetch +refs/heads/*:refs/remotes/#{@new_resource.remote}/*"
          shell_out!(command.join(" && "), run_options(:cwd => @new_resource.destination))
        end
      end

      def current_revision_matches_target_revision?
        (!@current_resource.revision.nil?) && (target_revision.strip.to_i(16) == @current_resource.revision.strip.to_i(16))
      end

      def target_revision
        @target_revision ||= begin
          if sha_hash?(@new_resource.revision)
            @target_revision = @new_resource.revision
          else
            @target_revision = remote_resolve_reference
          end
        end
      end

      alias :revision_slug :target_revision

      def remote_resolve_reference
        Chef::Log.debug("#{@new_resource} resolving remote reference")
        command = git('ls-remote', @new_resource.repository, @new_resource.revision)
        @resolved_reference = shell_out!(command, run_options).stdout
        if  @resolved_reference =~ /^([0-9a-f]{40})\s+(\S+)/
          $1
        else
          nil
        end
      end

      private

      def run_options(run_opts={})
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts[:environment] = {"GIT_SSH" => @new_resource.ssh_wrapper} if @new_resource.ssh_wrapper
        run_opts[:log_tag] = @new_resource.to_s
        run_opts[:log_level] ||= :debug
        if run_opts[:log_level] == :info
          if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info?
            run_opts[:live_stream] = STDOUT
          end
        end
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

    end
  end
end
