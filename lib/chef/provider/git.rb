#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Joshua Burt (<joshburt@shapeandshare.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/exceptions"
require "chef/log"
require "chef/provider"
require "fileutils"

class Chef
  class Provider
    class Git < Chef::Provider
      provides :git

      def whyrun_supported?
        true
      end

      def load_current_resource
        @resolved_reference = nil
        @current_resource = Chef::Resource::Git.new(@new_resource.name)

        current_revision = find_current_revision
        @current_resource.revision current_revision if current_revision
      end

      def define_resource_requirements
        # Parent directory of the target must exist.
        requirements.assert(:checkout, :sync) do |a|
          dirname = ::File.dirname(cwd)
          a.assertion { ::File.directory?(dirname) }
          a.whyrun("Directory #{dirname} does not exist, this run will fail unless it has been previously created. Assuming it would have been created.")
          a.failure_message(Chef::Exceptions::MissingParentDirectory,
                            "Cannot clone #{@new_resource} to #{cwd}, the enclosing directory #{dirname} does not exist")
        end

        requirements.assert(:all_actions) do |a|
          a.assertion { !(@new_resource.revision =~ %r{^origin\/}) }
          a.failure_message Chef::Exceptions::InvalidRemoteGitReference,
                            "Deploying remote branches is not supported. " \
                            "Specify the remote branch as a local branch for " \
                            "the git repository you\'re deploying from " \
                            "(ie: '#{@new_resource.revision.gsub('origin/', '')}' rather than '#{@new_resource.revision}')."
        end

        requirements.assert(:all_actions) do |a|
          # this can't be recovered from in why-run mode, because nothing that
          # we do in the course of a run is likely to create a valid target_revision
          # if we can't resolve it up front.
          a.assertion { !target_revision.nil? }
          a.failure_message Chef::Exceptions::UnresolvableGitReference,
                            "Unable to parse SHA reference for '#{@new_resource.revision}' in repository '#{@new_resource.repository}'. " \
                            "Verify your (case-sensitive) repository URL and revision.\n" \
                            "`git ls-remote '#{@new_resource.repository}' '#{rev_search_pattern}'` output: #{@resolved_reference}"
        end
      end

      def find_current_revision
        Chef::Log.debug("#{@new_resource} finding current git revision")
        if ::File.exist?(::File.join(cwd, ".git"))
          # 128 is returned when we're not in a git repo. this is fine
          run_opts = { cwd: cwd, returns: [0, 128] }
          rev_parse_result = git_standard_executor(["rev-parse", "HEAD"], run_opts)
          rev = rev_parse_result.stdout.strip
        end
        sha_hash?(rev) ? rev : nil
      end

      def add_remotes
        unless @new_resource.additional_remotes.empty?
          @new_resource.additional_remotes.each_pair do |remote_name, remote_url|
            converge_by("add remote #{remote_name} from #{remote_url}") do
              Chef::Log.info "#{@new_resource} adding git remote #{remote_name} = #{remote_url}"
              setup_remote_tracking_branches(remote_name, remote_url)
            end
          end
        end
      end

      def clone
        converge_by("clone from #{@new_resource.repository} into #{cwd}") do
          if @new_resource.uploadpack_allow_reachable_sha1_in_want && (git_minor_version >= Gem::Version.new("2.5.0"))
            # Introduced in git 2.5 // uploadpack.allowReachableSHA1InWant
            # https://github.com/git/git/blob/v2.5.0/Documentation/config.txt#L2570
            clone_by_any_ref
          else
            clone_by_advertized_ref
          end
        end
      end

      def checkout
        sha_ref = target_revision
        converge_by("checkout ref #{sha_ref} branch #{@new_resource.revision}") do
          # checkout into a local branch rather than a detached HEAD
          run_opts = { cwd: cwd }
          git_standard_executor(["branch", "-f", @new_resource.checkout_branch, sha_ref], run_opts)
          git_standard_executor(["checkout", @new_resource.checkout_branch], run_opts)
          Chef::Log.info "#{@new_resource} checked out branch: #{@new_resource.revision} onto: #{@new_resource.checkout_branch} reference: #{sha_ref}"
        end
      end

      def enable_submodules
        if @new_resource.enable_submodules
          converge_by("enable git submodules for #{@new_resource}") do
            Chef::Log.info "#{@new_resource} synchronizing git submodules"
            run_opts = { cwd: cwd }
            git_standard_executor(%w{submodule sync}, run_opts)

            Chef::Log.info "#{@new_resource} enabling git submodules"
            # the --recursive flag means we require git 1.6.5+ now, see CHEF-1827
            git_standard_executor(["submodule", "update", "--init", "--recursive"], run_opts)
          end
        end
      end

      def fetch_updates
        converge_by("fetch updates for #{@new_resource.remote}") do
          # uploadpack.allowReachableSHA1InWant introduced in git 2.5.0
          if @new_resource.uploadpack_allow_reachable_sha1_in_want && (git_minor_version >= Gem::Version.new("2.5.0"))
            fetch_by_any_ref
          else
            setup_remote_tracking_branches(@new_resource.remote, @new_resource.repository)
            fetch_by_advertized_ref
          end
        end
      end

      def setup_remote_tracking_branches(remote_name, remote_url)
        converge_by("set up remote tracking branches for #{remote_url} at #{remote_name}") do
          Chef::Log.debug "#{@new_resource} configuring remote tracking branches for repository #{remote_url} at remote #{remote_name}"
          run_opts = { cwd: cwd, returns: [0, 1, 2] }
          remote_status = git_standard_executor(["config", "--get", "remote.#{remote_name}.url"], run_opts)

          run_opts = { cwd: cwd }
          case remote_status.exitstatus
            when 0, 2
              # * Status 0 means that we already have a remote with this name, so we should update the url
              #   if it doesn't match the url we want.
              # * Status 2 means that we have multiple urls assigned to the same remote (not a good idea)
              #   which we can fix by replacing them all with our target url (hence the --replace-all option)

              if multiple_remotes?(remote_status) || !remote_matches?(remote_url, remote_status)
                git_standard_executor(["config", "--replace-all", "remote.#{remote_name}.url", remote_url], run_opts)
              end
            when 1
              git_standard_executor(["remote", "add", remote_name, remote_url], run_opts)
          end
        end
      end

      def multiple_remotes?(check_remote_command_result)
        check_remote_command_result.exitstatus == 2
      end

      def remote_matches?(remote_url, check_remote_command_result)
        check_remote_command_result.stdout.strip.eql?(remote_url)
      end

      def target_revision
        @target_revision ||= sha_hash?(@new_resource.revision) ? @new_resource.revision : remote_resolve_reference
      end

      alias revision_slug target_revision

      private

      def run_options(run_opts = {})
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts[:log_tag] = @new_resource.to_s
        run_opts[:timeout] = @new_resource.timeout if @new_resource.timeout
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_env = run_options_env
        run_opts[:environment] = run_env unless run_env.empty?
        run_opts
      end

      def run_options_env
        env = {}
        env_home = process_executor_home
        env["HOME"] = env_home unless env_home.nil?
        env["GIT_SSH"] = @new_resource.ssh_wrapper if @new_resource.ssh_wrapper
        env.merge!(@new_resource.environment) if @new_resource.environment
        env
      end

      def process_executor_home
        env_home = nil
        if @new_resource.user
          # Certain versions of `git` misbehave if git configuration is
          # inaccessible in $HOME. We need to ensure $HOME matches the
          # user who is executing `git` not the user running Chef.
          env_home = begin
            require "etc"
            Etc.getpwnam(@new_resource.user).dir
          rescue ArgumentError # user not found
            raise Chef::Exceptions::User, "Could not determine HOME for specified user '#{@new_resource.user}' for resource '#{@new_resource.name}'"
          end
        end
        env_home
      end

      def cwd
        @new_resource.destination
      end

      def git(*args)
        ["git", *args].compact.join(" ")
      end

      def git_standard_executor(args, run_opts = {})
        git_command = git(args)
        Chef::Log.debug "> #{git_command}"
        shell_out!(git_command, run_options(run_opts))
      end

      def sha_hash?(string)
        string =~ /^[0-9a-f]{40}$/
      end

      def action_checkout
        if target_dir_non_existent_or_empty?
          clone
          checkout if @new_resource.enable_checkout
          enable_submodules
          add_remotes
        else
          Chef::Log.debug "#{@new_resource} checkout destination #{cwd} already exists or is a non-empty directory"
        end
      end

      def action_export
        action_checkout
        converge_by("complete the export by removing #{cwd}.git after checkout") do
          FileUtils.rm_rf(::File.join(cwd, ".git"))
        end
      end

      def action_sync
        if existing_git_clone?
          Chef::Log.debug "#{@new_resource} current revision: #{@current_resource.revision} target revision: #{target_revision}"
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

      def git_minor_version
        git_result = git_standard_executor ["--version"]
        @git_minor_version ||= Gem::Version.new(git_result.stdout.split.last)
      end

      def existing_git_clone?
        ::File.exist?(::File.join(cwd, ".git"))
      end

      def target_dir_non_existent_or_empty?
        !::File.exist?(cwd) || Dir.entries(cwd).sort == [".", ".."]
      end

      def current_revision_matches_target_revision?
        !@current_resource.revision.nil? && (target_revision.strip.to_i(16) == @current_resource.revision.strip.to_i(16))
      end

      def remote_resolve_reference
        Chef::Log.debug("#{@new_resource} resolving remote reference")
        # The sha pointed to by an annotated tag is identified by the
        # '^{}' suffix appended to the tag. In order to resolve
        # annotated tags, we have to search for "revision*" and
        # post-process. Special handling for 'HEAD' to ignore a tag
        # named 'HEAD'.
        @resolved_reference = git_ls_remote(rev_search_pattern)
        refs = @resolved_reference.split("\n").map { |line| line.split("\t") }
        # First try for ^{} indicating the commit pointed to by an
        # annotated tag.
        # It is possible for a user to create a tag named 'HEAD'.
        # Using such a degenerate annotated tag would be very
        # confusing. We avoid the issue by disallowing the use of
        # annotated tags named 'HEAD'.

        found = rev_search_pattern != "HEAD" ? find_revision(refs, @new_resource.revision, "^{}") : refs_search(refs, "HEAD")
        found = find_revision(refs, @new_resource.revision) if found.empty?
        found.size == 1 ? found.first[0] : nil
      end

      def find_revision(refs, revision, suffix = "")
        found = refs_search(refs, rev_match_pattern("refs/tags/", revision) + suffix)
        found = refs_search(refs, rev_match_pattern("refs/heads/", revision) + suffix) if found.empty?
        found = refs_search(refs, revision + suffix) if found.empty?
        found
      end

      def rev_match_pattern(prefix, revision)
        revision.start_with?(prefix) ? revision : prefix + revision
      end

      def rev_search_pattern
        if ["", "HEAD"].include? @new_resource.revision
          "HEAD"
        else
          @new_resource.revision + "*"
        end
      end

      def git_ls_remote(rev_pattern)
        stdout_obj = git_standard_executor ["ls-remote", "\"#{@new_resource.repository}\"", "\"#{rev_pattern}\""]
        stdout_obj.stdout
      end

      def refs_search(refs, pattern)
        refs.find_all { |m| m[1] == pattern }
      end

      def clone_by_advertized_ref
        git_clone_by_advertized_ref_cmd = ["clone"]
        git_clone_by_advertized_ref_cmd << build_standard_clone_args
        git_clone_by_advertized_ref_cmd << "--no-single-branch" if @new_resource.depth && (git_minor_version >= Gem::Version.new("1.7.10"))
        git_clone_by_advertized_ref_cmd << "\"#{@new_resource.repository}\""
        git_clone_by_advertized_ref_cmd << "\"#{@new_resource.destination}\""

        Chef::Log.info "#{@new_resource} cloning repo #{@new_resource.repository} to #{@new_resource.destination}"
        git_standard_executor git_clone_by_advertized_ref_cmd
      end

      def clone_by_any_ref
        Chef::Log.info "#{@new_resource} cloning [shallow] repo #{@new_resource.repository} to #{cwd}"

        # build out the empty base
        build_lightweight_clone_base

        standard_args = build_standard_clone_args
        # build our light weight fetch command
        fetch_args = [@new_resource.revision]
        fetch_args << standard_args unless standard_args.empty?
        fetch_args << "--no-tags"
        git_fetch("origin", fetch_args)
      end

      def build_lightweight_clone_base
        # Creates a light weight local git repository
        clone_init_cmd = ["init", "\"#{cwd}\""]
        git_standard_executor clone_init_cmd
        setup_remote_tracking_branches("origin", @new_resource.repository)
      end

      def build_standard_clone_args
        remote = @new_resource.remote
        args = []
        args << "-o #{remote}" unless remote == "origin"
        args << "--depth #{@new_resource.depth}" if @new_resource.depth
        args
      end

      def fetch_by_advertized_ref
        # since we're in a local branch already, just reset to specified revision rather than merge
        Chef::Log.debug "Fetching updates from #{new_resource.remote} and resetting to revision #{target_revision}"

        fetch_args = ["--tags"]
        fetch_args << "--depth #{@new_resource.depth}" if @new_resource.depth

        git_fetch(@new_resource.remote, fetch_args)
        git_reset_hard
      end

      def fetch_by_any_ref
        Chef::Log.info "Fetching [shallow] updates from #{new_resource.remote} and resetting to revision #{target_revision}"

        fetch_args = [target_revision]
        fetch_args << "--depth #{@new_resource.depth}" if @new_resource.depth
        git_fetch("origin", fetch_args)
        git_reset_hard
      end

      def git_fetch(fetch_source, args = [])
        git_fetch_command = ["fetch", fetch_source]
        git_fetch_command << args unless args.empty?
        run_opts = { cwd: cwd, returns: [0, 1, 128] }
        git_standard_executor(git_fetch_command, run_opts)
      end

      def git_reset_hard(args = [])
        git_reset_command = ["reset"]
        git_reset_command << args unless args.empty?
        git_reset_command << "--hard"
        git_reset_command << target_revision
        run_opts = { cwd: cwd }
        git_standard_executor(git_reset_command, run_opts)
      end
    end
  end
end
