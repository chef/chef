#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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

# TODO subversion and git should both extend from a base SCM provider.

require_relative "../log"
require_relative "../provider"
require "chef-config/mixin/fuzzy_hostname_matcher"
require "fileutils" unless defined?(FileUtils)

class Chef
  class Provider
    class Subversion < Chef::Provider

      provides :subversion

      SVN_INFO_PATTERN = /^([\w\s]+): (.+)$/.freeze

      include ChefConfig::Mixin::FuzzyHostnameMatcher

      def load_current_resource
        @current_resource = Chef::Resource::Subversion.new(new_resource.name)

        unless %i{export force_export}.include?(Array(new_resource.action).first)
          if current_revision = find_current_revision
            current_resource.revision current_revision
          end
        end
      end

      def define_resource_requirements
        requirements.assert(:all_actions) do |a|
          # Make sure the parent dir exists, or else fail.
          # for why run, print a message explaining the potential error.
          parent_directory = ::File.dirname(new_resource.destination)
          a.assertion { ::File.directory?(parent_directory) }
          a.failure_message(Chef::Exceptions::MissingParentDirectory,
            "Cannot clone #{new_resource} to #{new_resource.destination}, the enclosing directory #{parent_directory} does not exist")
          a.whyrun("Directory #{parent_directory} does not exist, assuming it would have been created")
        end
      end

      action :checkout do
        if target_dir_non_existent_or_empty?
          converge_by("perform checkout of #{new_resource.repository} into #{new_resource.destination}") do
            shell_out!(checkout_command, run_options)
          end
        else
          logger.debug "#{new_resource} checkout destination #{new_resource.destination} already exists or is a non-empty directory - nothing to do"
        end
      end

      action :export do
        if target_dir_non_existent_or_empty?
          action_force_export
        else
          logger.debug "#{new_resource} export destination #{new_resource.destination} already exists or is a non-empty directory - nothing to do"
        end
      end

      action :force_export do
        converge_by("export #{new_resource.repository} into #{new_resource.destination}") do
          shell_out!(export_command, run_options)
        end
      end

      action :sync do
        assert_target_directory_valid!
        if ::File.exist?(::File.join(new_resource.destination, ".svn"))
          current_rev = find_current_revision
          logger.trace "#{new_resource} current revision: #{current_rev} target revision: #{revision_int}"
          unless current_revision_matches_target_revision?
            converge_by("sync #{new_resource.destination} from #{new_resource.repository}") do
              shell_out!(sync_command, run_options)
              logger.info "#{new_resource} updated to revision: #{revision_int}"
            end
          end
        else
          action_checkout
        end
      end

      def sync_command
        c = scm :update, new_resource.svn_arguments, verbose, authentication, proxy, "-r#{revision_int}", new_resource.destination
        logger.trace "#{new_resource} updated working copy #{new_resource.destination} to revision #{new_resource.revision}"
        c
      end

      def checkout_command
        c = scm :checkout, new_resource.svn_arguments, verbose, authentication, proxy,
          "-r#{revision_int}", new_resource.repository, new_resource.destination
        logger.info "#{new_resource} checked out #{new_resource.repository} at revision #{new_resource.revision} to #{new_resource.destination}"
        c
      end

      def export_command
        args = ["--force"]
        args << new_resource.svn_arguments << verbose << authentication << proxy <<
          "-r#{revision_int}" << new_resource.repository << new_resource.destination
        c = scm :export, *args
        logger.info "#{new_resource} exported #{new_resource.repository} at revision #{new_resource.revision} to #{new_resource.destination}"
        c
      end

      # If the specified revision isn't an integer ("HEAD" for example), look
      # up the revision id by asking the server
      # If the specified revision is an integer, trust it.
      def revision_int
        @revision_int ||= if /^\d+$/.match?(new_resource.revision)
                            new_resource.revision
                          else
                            command = scm(:info, new_resource.repository, new_resource.svn_info_args, authentication, "-r#{new_resource.revision}")
                            svn_info = shell_out!(command, run_options(cwd: cwd, returns: [0, 1])).stdout

                            extract_revision_info(svn_info)
                          end
      end

      alias :revision_slug :revision_int

      def find_current_revision
        return nil unless ::File.exist?(::File.join(new_resource.destination, ".svn"))

        command = scm(:info)
        svn_info = shell_out!(command, run_options(cwd: cwd, returns: [0, 1])).stdout

        extract_revision_info(svn_info)
      end

      def current_revision_matches_target_revision?
        (!current_resource.revision.nil?) && (revision_int.strip.to_i == current_resource.revision.strip.to_i)
      end

      def run_options(run_opts = {})
        env = {}
        if new_resource.user
          run_opts[:user] = new_resource.user
          env["HOME"] = get_homedir(new_resource.user)
        end
        run_opts[:group] = new_resource.group if new_resource.group
        run_opts[:timeout] = new_resource.timeout if new_resource.timeout
        env.merge!(new_resource.environment) if new_resource.environment
        run_opts[:environment] = env unless env.empty?
        run_opts
      end

      private

      def cwd
        new_resource.destination
      end

      def verbose
        "-q"
      end

      def extract_revision_info(svn_info)
        repo_attrs = svn_info.lines.inject({}) do |attrs, line|
          if line =~ SVN_INFO_PATTERN
            property, value = $1, $2
            attrs[property] = value
          end
          attrs
        end
        rev = (repo_attrs["Last Changed Rev"] || repo_attrs["Revision"])
        rev.strip! if rev
        raise "Could not parse `svn info` data: #{svn_info}" if repo_attrs.empty?

        logger.trace "#{new_resource} resolved revision #{new_resource.revision} to #{rev}"
        rev
      end

      # If a username is configured for the SCM, return the command-line
      # switches for that. Note that we don't need to return the password
      # switch, since Capistrano will check for that prompt in the output
      # and will respond appropriately.
      def authentication
        return "" unless new_resource.svn_username

        result = "--username #{new_resource.svn_username} "
        result << "--password #{new_resource.svn_password} "
        result
      end

      def proxy
        repo_uri = URI.parse(new_resource.repository)
        proxy_uri = Chef::Config.proxy_uri(repo_uri.scheme, repo_uri.host, repo_uri.port)
        return "" if proxy_uri.nil?

        result = "--config-option servers:global:http-proxy-host=#{proxy_uri.host} "
        result << "--config-option servers:global:http-proxy-port=#{proxy_uri.port} "
        result
      end

      def scm(*args)
        binary = svn_binary
        binary = "\"#{binary}\"" if /\s/.match?(binary)
        [binary, *args].compact.join(" ")
      end

      def target_dir_non_existent_or_empty?
        !::File.exist?(new_resource.destination) || Dir.entries(new_resource.destination).sort == [".", ".."]
      end

      def svn_binary
        new_resource.svn_binary ||
          (ChefUtils.windows? ? "svn.exe" : "svn")
      end

      def assert_target_directory_valid!
        target_parent_directory = ::File.dirname(new_resource.destination)
        unless ::File.directory?(target_parent_directory)
          msg = "Cannot clone #{new_resource} to #{new_resource.destination}, the enclosing directory #{target_parent_directory} does not exist"
          raise Chef::Exceptions::MissingParentDirectory, msg
        end
      end

      # Returns the home directory of the user
      # @param [String] user must be a string.
      # @return [String] the home directory of the user.
      #
      def get_homedir(user)
        require "etc" unless defined?(Etc)
        case user
        when Integer
          Etc.getpwuid(user).dir
        else
          Etc.getpwnam(user.to_s).dir
        end
      end
    end
  end
end
