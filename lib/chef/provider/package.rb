#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/mixin/command'
require 'chef/log'
require 'chef/file_cache'
require 'chef/platform'

class Chef
  class Provider
    class Package < Chef::Provider

      include Chef::Mixin::Command

      attr_accessor :candidate_version
      def initialize(new_resource, run_context)
        super
        @candidate_version = nil
      end

      def whyrun_supported?
        true
      end

      def load_current_resource
      end

      def package_name_array
        [ new_resource.package_name ].flatten
      end

      def candidate_version_array
        [ candidate_version ].flatten
      end

      def current_version_array
        [ @current_resource.version ].flatten
      end

      def new_version_array
        [ @new_resource.version ].flatten
      end

      def define_resource_requirements
        requirements.assert(:install) do |a|
          a.assertion { ((@new_resource.version != nil) && !(target_version_already_installed?)) \
            || !(@current_resource.version.nil? && candidate_version.nil?)  }
          a.failure_message(Chef::Exceptions::Package, "No version specified, and no candidate version available for #{@new_resource.package_name}")
          a.whyrun("Assuming a repository that offers #{@new_resource.package_name} would have been configured")
        end

        requirements.assert(:upgrade) do |a|
          # Can't upgrade what we don't have
          a.assertion  { !(@current_resource.version.nil? && candidate_version.nil?) }
          a.failure_message(Chef::Exceptions::Package, "No candidate version available for #{@new_resource.package_name}")
          a.whyrun("Assuming a repository that offers #{@new_resource.package_name} would have been configured")
        end
      end

      def action_install
        # If we specified a version, and it's not the current version, move to the specified version
        if new_version_array.any? && !(target_version_already_installed?)
          install_version = @new_resource.version
        # If it's not installed at all, install it
        elsif current_version_array.any? { |x| x.nil? }
          install_version = candidate_version
        else
          Chef::Log.debug("#{@new_resource} is already installed - nothing to do")
          return
        end

        # We need to make sure we handle the preseed file
        if @new_resource.response_file
          if preseed_file = get_preseed_file(@new_resource.package_name, install_version)
            converge_by("preseed package #{@new_resource.package_name}") do
              preseed_package(preseed_file)
            end
          end
        end
        description = install_version ? "version #{install_version} of" : ""
        converge_by("install #{description} package #{@new_resource.package_name}") do
          @new_resource.version(install_version)
          install_package(@new_resource.package_name, install_version)
        end
      end

      def action_upgrade
        if !candidate_version_array.any?
          Chef::Log.debug("#{@new_resource} no candidate version - nothing to do")
          return
        elsif @current_resource.version == candidate_version
          Chef::Log.debug("#{@new_resource} is at the latest version - nothing to do")
          return
        end
        @new_resource.version(candidate_version)
        orig_version = @current_resource.version || "uninstalled"
        converge_by("upgrade package #{@new_resource.package_name} from #{orig_version} to #{candidate_version}") do
          upgrade_package(@new_resource.package_name, candidate_version)
          Chef::Log.info("#{@new_resource} upgraded from #{orig_version} to #{candidate_version}")
        end
      end

      def action_remove
        if removing_package?
          description = @new_resource.version ? "version #{@new_resource.version} of " :  ""
          converge_by("remove #{description} package #{@current_resource.package_name}") do
            remove_package(@current_resource.package_name, @new_resource.version)
            Chef::Log.info("#{@new_resource} removed")
          end
        else
          Chef::Log.debug("#{@new_resource} package does not exist - nothing to do")
        end
      end

      def have_any_matching_version?
        f = []
        new_version_array.each_with_index do |item, index|
          f << (item == current_version_array[index])
        end
        f.any?
      end
          
      def removing_package?
        if !current_version_array.any?
          # ! any? means it's all nil's, which means nothing is installed
          false
        elsif !new_version_array.any?
          true # remove any version of all packages
        elsif have_any_matching_version?
          true # remove the version we have
        else
          false # we don't have the version we want to remove
        end
      end

      def action_purge
        if removing_package?
          description = @new_resource.version ? "version #{@new_resource.version} of" : ""
          converge_by("purge #{description} package #{@current_resource.package_name}") do
            purge_package(@current_resource.package_name, @new_resource.version)
            Chef::Log.info("#{@new_resource} purged")
          end
        end
      end

      def action_reconfig
        if @current_resource.version == nil then
          Chef::Log.debug("#{@new_resource} is NOT installed - nothing to do")
          return
        end

        unless @new_resource.response_file then
          Chef::Log.debug("#{@new_resource} no response_file provided - nothing to do")
          return
        end

        if preseed_file = get_preseed_file(@new_resource.package_name, @current_resource.version)
          converge_by("reconfigure package #{@new_resource.package_name}") do
            preseed_package(preseed_file)
            reconfig_package(@new_resource.package_name, @current_resource.version)
            Chef::Log.info("#{@new_resource} reconfigured")
          end
        else
          Chef::Log.debug("#{@new_resource} preseeding has not changed - nothing to do")
        end
      end

      def install_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :install"
      end

      def upgrade_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :upgrade"
      end

      def remove_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :remove"
      end

      def purge_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :purge"
      end

      def preseed_package(file)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support pre-seeding package install/upgrade instructions"
      end

      def reconfig_package(name, version)
        raise( Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reconfig" )
      end

      def get_preseed_file(name, version)
        resource = preseed_resource(name, version)
        resource.run_action(:create)
        Chef::Log.debug("#{@new_resource} fetched preseed file to #{resource.path}")

        if resource.updated_by_last_action?
          resource.path
        else
          false
        end
      end

      def preseed_resource(name, version)
        # A directory in our cache to store this cookbook's preseed files in
        file_cache_dir = Chef::FileCache.create_cache_path("preseed/#{@new_resource.cookbook_name}")
        # The full path where the preseed file will be stored
        cache_seed_to = "#{file_cache_dir}/#{name}-#{version}.seed"

        Chef::Log.debug("#{@new_resource} fetching preseed file to #{cache_seed_to}")

        if template_available?(@new_resource.response_file)
          Chef::Log.debug("#{@new_resource} fetching preseed file via Template")
          remote_file = Chef::Resource::Template.new(cache_seed_to, run_context)
          remote_file.variables(@new_resource.response_file_variables)
        elsif cookbook_file_available?(@new_resource.response_file)
          Chef::Log.debug("#{@new_resource} fetching preseed file via cookbook_file")
          remote_file = Chef::Resource::CookbookFile.new(cache_seed_to, run_context)
        else
          message = "No template or cookbook file found for response file #{@new_resource.response_file}"
          raise Chef::Exceptions::FileNotFound, message
        end

        remote_file.cookbook_name = @new_resource.cookbook_name
        remote_file.source(@new_resource.response_file)
        remote_file.backup(false)
        remote_file
      end

      def expand_options(options)
        options ? " #{options}" : ""
      end

      def target_version_already_installed?
        new_version_array == current_version_array
      end

      private

      def template_available?(path)
        run_context.has_template_in_cookbook?(@new_resource.cookbook_name, path)
      end

      def cookbook_file_available?(path)
        run_context.has_cookbook_file_in_cookbook?(@new_resource.cookbook_name, path)
      end

    end
  end
end
