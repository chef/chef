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

class Chef
  class Provider
    class Git < Chef::Provider

      include Chef::Mixin::ShellOut

      def load_current_resource
        @current_resource = Chef::Resource::Git.new(@new_resource.name)
        if current_revision = find_current_revision
          @current_resource.revision current_revision
        end
      end

      #
      # Actions
      #
      def action_checkout
        if target_dir_non_existent_or_empty?
          action_sync
        else
          Chef::Log.debug "#{@new_resource} checkout destination #{@new_resource.destination} already exists or is a non-empty directory"
        end
      end

      def action_export
        action_checkout
        FileUtils.rm_rf(::File.join(@new_resource.destination,".git"))
        @new_resource.updated_by_last_action(true)
      end

      def action_sync
        assert_target_directory_valid!

        clone
        setup_remote_tracking_branches
        checkout
        fetch_updates
        enable_submodules
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

      private

      def clone
        if ! existing_git_clone?
          remote = @new_resource.remote

          args = []
          args << "-o #{remote}" unless remote == 'origin'
          args << "--depth #{@new_resource.depth}" if @new_resource.depth

          Chef::Log.info "#{@new_resource} cloning repo #{@new_resource.repository} to #{@new_resource.destination}"

          clone_cmd = "git clone #{args.join(' ')} #{@new_resource.repository} #{@new_resource.destination}"
          shell_out!(clone_cmd, run_options(:command_log_level => :info))
        end
      end

      def checkout
        if current_branch != "deploy"
          # checkout into a local branch rather than a detached HEAD
          exec_git!("checkout -B deploy")
          @new_resource.updated_by_last_action(true)
          Chef::Log.info "#{@new_resource} checked out branch: #{@new_resource.revision}"
        end
      end

      def fetch_updates
        current_rev = find_current_revision
        Chef::Log.debug "#{@new_resource} current revision: #{current_rev} target revision: #{target_revision}"

        if !current_revision_matches_target_revision?
          # since we're in a local branch already, just reset to specified revision rather than merge
          Chef::Log.debug "Fetching updates from #{new_resource.remote} and resetting to revison #{target_revision}"
          exec_git!("fetch #{@new_resource.remote}")
          exec_git!("fetch #{@new_resource.remote} --tags")
          exec_git!("reset --hard #{target_revision}")
          @new_resource.updated_by_last_action(true)
          Chef::Log.info "#{@new_resource} updated to revision #{@new_resource.revision}"
        end
      end

      def enable_submodules
        if @new_resource.enable_submodules
          Chef::Log.info "#{@new_resource} enabling git submodules"
          exec_git!("submodule init")
          exec_git!("submodule update")
        end
      end

      # Use git-config to setup a remote tracking branches. Could use
      # git-remote but it complains when a remote of the same name already
      # exists, git-config will just silenty overwrite the setting every
      # time. This could cause wierd-ness in the remote cache if the url
      # changes between calls, but as long as the repositories are all
      # based from each other it should still work fine.
      def setup_remote_tracking_branches
        # TODO: why not just do this?  What if the repository location changes?
        if @new_resource.remote != "origin"
          setup_remote_tracking_branch(@new_resource.repository, @new_resource.remote)
        end
        
        @new_resource.additional_remotes.each_pair do |remote_name, remote_url|
          setup_remote_tracking_branch(remote_url, remote_name)
        end
      end
      
      def setup_remote_tracking_branch(repository, remote) 
        Chef::Log.debug "#{@new_resource} configuring remote tracking branch for repository #{repository} "+
                        "at remote #{remote}"
        exec_git!("config remote.#{remote}.url #{repository}")
        exec_git!("config remote.#{remote}.fetch +refs/heads/*:refs/remotes/#{remote}/*")
      end

      def assert_target_directory_valid!
        target_parent_directory = ::File.dirname(@new_resource.destination)
        unless ::File.directory?(target_parent_directory)
          msg = "Cannot clone #{@new_resource} to #{@new_resource.destination}, the enclosing directory #{target_parent_directory} does not exist"
          raise Chef::Exceptions::MissingParentDirectory, msg
        end
      end

      def exec_git!(args)
        print "git #{args}\n"
        return shell_out!("git #{args}", run_options(:cwd => @new_resource.destination, :command_log_level => :info))
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

      def current_revision_matches_target_revision?
        (!@current_resource.revision.nil?) && (target_revision.strip.to_i(16) == @current_resource.revision.strip.to_i(16))
      end

      def run_options(run_opts={})
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts[:environment] = {"GIT_SSH" => @new_resource.ssh_wrapper} if @new_resource.ssh_wrapper
        run_opts[:command_log_prepend] = @new_resource.to_s
        run_opts[:command_log_level] ||= :debug
        if run_opts[:command_log_level] == :info
          if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info?
            run_opts[:live_stream] = STDOUT
          end
        end
        run_opts
      end

      def current_branch
        branches = exec_git!("branch").stdout
        # Grab the line that looks like "* branchname", that is the current branch
        current = branches.lines.grep(/^\* /) { |line| line[2..-1].strip }
        current[0]
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

      def remote_resolve_reference
        Chef::Log.debug("#{@new_resource} resolving remote reference")
        command = git('ls-remote', @new_resource.repository, @new_resource.revision)
        shell_out!(command, run_options).stdout
      end

    end
  end
end
