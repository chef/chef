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
    class Subversion < Chef::Provider

      include Chef::Mixin::Command

      def load_current_resource
        @current_resource = Chef::Resource::Subversion.new(@new_resource.name)

        unless [:export, :force_export].include?(Array(@new_resource.action).first)
          if current_revision = find_current_revision
            @current_resource.revision current_revision
          end
        end
      end

      def action_checkout
        assert_target_directory_valid!
        if target_dir_non_existant_or_empty?
          run_command(run_options(:command => checkout_command))
          @new_resource.updated_by_last_action(true)
        else
          Chef::Log.debug "#{@new_resource} checkout destination #{@new_resource.destination} already exists or is a non-empty directory - nothing to do"
        end
      end

      def action_export
        assert_target_directory_valid!
        if target_dir_non_existant_or_empty?
          run_command(run_options(:command => export_command))
          @new_resource.updated_by_last_action(true)
        else
          Chef::Log.debug "#{@new_resource} export destination #{@new_resource.destination} already exists or is a non-empty directory - nothing to do"
        end
      end

      def action_force_export
        assert_target_directory_valid!
        run_command(run_options(:command => export_command))
        @new_resource.updated_by_last_action(true)
      end

      def action_sync
        assert_target_directory_valid!
        if ::File.exist?(::File.join(@new_resource.destination, ".svn"))
          current_rev = find_current_revision
          Chef::Log.debug "#{@new_resource} current revision: #{current_rev} target revision: #{revision_int}"
          unless current_revision_matches_target_revision?
            run_command(run_options(:command => sync_command))
            Chef::Log.info "#{@new_resource} updated to revision: #{revision_int}"
            @new_resource.updated_by_last_action(true)
          end
        else
          action_checkout
          @new_resource.updated_by_last_action(true)
        end
      end

      def sync_command
        c = scm :update, @new_resource.svn_arguments, verbose, authentication, "-r#{revision_int}", @new_resource.destination
        Chef::Log.debug "#{@new_resource} updated working copy #{@new_resource.destination} to revision #{@new_resource.revision}"
				c
      end

      def checkout_command
        c = scm :checkout, @new_resource.svn_arguments, verbose, authentication,
            "-r#{revision_int}", @new_resource.repository, @new_resource.destination
        Chef::Log.info "#{@new_resource} checked out #{@new_resource.repository} at revision #{@new_resource.revision} to #{@new_resource.destination}"
				c
      end

      def export_command
        args = ["--force"]
        args << @new_resource.svn_arguments << verbose << authentication <<
            "-r#{revision_int}" << @new_resource.repository << @new_resource.destination
        c = scm :export, *args
        Chef::Log.info "#{@new_resource} exported #{@new_resource.repository} at revision #{@new_resource.revision} to #{@new_resource.destination}"
				c
      end

      # If the specified revision isn't an integer ("HEAD" for example), look
      # up the revision id by asking the server
      # If the specified revision is an integer, trust it.
      def revision_int
        @revision_int ||= begin
          if @new_resource.revision =~ /^\d+$/
            @new_resource.revision
          else
            command = scm(:info, @new_resource.repository, @new_resource.svn_info_args, authentication, "-r#{@new_resource.revision}")
            status, svn_info, error_message = output_of_command(command, run_options)
            handle_command_failures(status, "STDOUT: #{svn_info}\nSTDERR: #{error_message}")
            extract_revision_info(svn_info)
          end
        end
      end

      alias :revision_slug :revision_int

      def find_current_revision
        return nil unless ::File.exist?(::File.join(@new_resource.destination, ".svn"))
        command = scm(:info)
        status, svn_info, error_message = output_of_command(command, run_options(:cwd => cwd))

        unless [0,1].include?(status.exitstatus)
          handle_command_failures(status, "STDOUT: #{svn_info}\nSTDERR: #{error_message}")
        end
        extract_revision_info(svn_info)
      end

      def current_revision_matches_target_revision?
        (!@current_resource.revision.nil?) && (revision_int.strip.to_i == @current_resource.revision.strip.to_i)
      end

      def run_options(run_opts={})
        run_opts[:user] = @new_resource.user if @new_resource.user
        run_opts[:group] = @new_resource.group if @new_resource.group
        run_opts
      end

      private

      def cwd
        @new_resource.destination
      end

      def verbose
        "-q"
      end

      def extract_revision_info(svn_info)
        begin
          repo_attrs = YAML.load(svn_info)
        rescue ArgumentError
          # YAML doesn't appreciate input like "svn: '/tmp/deploydir' is not a working copy\n"
          return nil
        end
        raise "Could not parse `svn info` data: #{svn_info}" unless repo_attrs.kind_of?(Hash)
        rev = (repo_attrs['Last Changed Rev'] || repo_attrs['Revision']).to_s
        Chef::Log.debug "#{@new_resource} resolved revision #{@new_resource.revision} to #{rev}"
        rev
      end

      # If a username is configured for the SCM, return the command-line
      # switches for that. Note that we don't need to return the password
      # switch, since Capistrano will check for that prompt in the output
      # and will respond appropriately.
      def authentication
        return "" unless @new_resource.svn_username
        result = "--username #{@new_resource.svn_username} "
        result << "--password #{@new_resource.svn_password} "
        result
      end

      def scm(*args)
        ['svn', *args].compact.join(" ")
      end
      
      # TODO these methods are the same as the git provider...need to REFACTOR
      # ...the subversion and git providers should extend from the same parent
      def assert_target_directory_valid!
        target_parent_directory = ::File.dirname(@new_resource.destination)
        unless ::File.directory?(target_parent_directory)
          msg = "Cannot clone #{@new_resource} to #{@new_resource.destination}, the enclosing directory #{target_parent_directory} does not exist"
          raise Chef::Exceptions::MissingParentDirectory, msg
        end
      end

      def target_dir_non_existant_or_empty?
        !::File.exist?(@new_resource.destination) || Dir.entries(@new_resource.destination).sort == ['.','..']
      end
    end
  end
end
