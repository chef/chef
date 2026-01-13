#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require "chef/mixin/shell_out" unless defined?(Chef::Mixin::ShellOut)

class Chef
  class Knife
    class CookbookSCMRepo

      DIRTY_REPO = /^\s+M/.freeze

      include Chef::Mixin::ShellOut

      attr_reader :repo_path
      attr_reader :default_branch
      attr_reader :use_current_branch
      attr_reader :ui

      def initialize(repo_path, ui, opts = {})
        @repo_path = repo_path
        @ui = ui
        @default_branch = "master"
        @use_current_branch = false
        apply_opts(opts)
      end

      def sanity_check
        unless ::File.directory?(repo_path)
          ui.error("The cookbook repo path #{repo_path} does not exist or is not a directory")
          exit 1
        end
        unless git_repo?(repo_path)
          ui.error "The cookbook repo #{repo_path} is not a git repository."
          ui.info("Use `git init` to initialize a git repo")
          exit 1
        end
        if use_current_branch
          @default_branch = get_current_branch
        end
        unless branch_exists?(default_branch)
          ui.error "The default branch '#{default_branch}' does not exist"
          ui.info "If this is a new git repo, make sure you have at least one commit before installing cookbooks"
          exit 1
        end
        cmd = git("status --porcelain")
        if DIRTY_REPO.match?(cmd.stdout)
          ui.error "You have uncommitted changes to your cookbook repo (#{repo_path}):"
          ui.msg cmd.stdout
          ui.info "Commit or stash your changes before importing cookbooks"
          exit 1
        end
        # TODO: any untracked files in the cookbook directory will get nuked later
        # make this an error condition also.
        true
      end

      def reset_to_default_state
        ui.info("Checking out the #{default_branch} branch.")
        git("checkout #{default_branch}")
      end

      def prepare_to_import(cookbook_name)
        branch = "chef-vendor-#{cookbook_name}"
        if branch_exists?(branch)
          ui.info("Pristine copy branch (#{branch}) exists, switching to it.")
          git("checkout #{branch}")
        else
          ui.info("Creating pristine copy branch #{branch}")
          git("checkout -b #{branch}")
        end
      end

      def finalize_updates_to(cookbook_name, version)
        if update_count = updated?(cookbook_name)
          ui.info "#{update_count} files updated, committing changes"
          git("add #{cookbook_name}")
          git("commit -m \"Import #{cookbook_name} version #{version}\" -- #{cookbook_name}")
          ui.info("Creating tag cookbook-site-imported-#{cookbook_name}-#{version}")
          git("tag -f cookbook-site-imported-#{cookbook_name}-#{version}")
          true
        else
          ui.info("No changes made to #{cookbook_name}")
          false
        end
      end

      def merge_updates_from(cookbook_name, version)
        branch = "chef-vendor-#{cookbook_name}"
        Dir.chdir(repo_path) do
          if system("git merge #{branch}")
            ui.info("Cookbook #{cookbook_name} version #{version} successfully installed")
          else
            ui.error("You have merge conflicts - please resolve manually")
            ui.info("Merge status (cd #{repo_path}; git status):")
            system("git status")
            exit 3
          end
        end
      end

      def updated?(cookbook_name)
        update_count = git("status --porcelain -- #{cookbook_name}").stdout.strip.lines.count
        update_count == 0 ? nil : update_count
      end

      def branch_exists?(branch_name)
        git("branch --no-color").stdout.lines.any? { |l| l =~ /\s#{Regexp.escape(branch_name)}(?:\s|$)/ }
      end

      def get_current_branch
        ref = git("symbolic-ref HEAD").stdout
        ref.chomp.split("/")[2]
      end

      private

      def git_repo?(directory)
        if File.directory?(File.join(directory, ".git"))
          true
        elsif File.dirname(directory) == directory
          false
        else
          git_repo?(File.dirname(directory))
        end
      end

      def apply_opts(opts)
        opts.each do |option, value|
          case option.to_s
          when "default_branch"
            @default_branch = value
          when "use_current_branch"
            @use_current_branch = value
          end
        end
      end

      def git(command)
        shell_out!("git #{command}", cwd: repo_path)
      end

    end
  end
end
