#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright 2015-2016, Facebook, Inc.
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

require "chef/log"
require "chef/provider"
require "chef/resource"
require "chef/resource/file"
require "uuidtools"

class Chef
  class Provider
    class OsxProfile < Chef::Provider
      include Chef::Mixin::Command
      provides :osx_profile, os: "darwin"
      provides :osx_config_profile, os: "darwin"

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::OsxProfile.new(@new_resource.name)
        @current_resource.profile_name(@new_resource.profile_name)

        all_profiles = get_installed_profiles
        @new_resource.profile(
          @new_resource.profile ||
          @new_resource.profile_name
        )

        @new_profile_hash = get_profile_hash(@new_resource.profile)
        if @new_profile_hash
          @new_profile_hash["PayloadUUID"] =
            config_uuid(@new_profile_hash)
        end

        if @new_profile_hash
          @new_profile_identifier = @new_profile_hash["PayloadIdentifier"]
        else
          @new_profile_identifier = @new_resource.identifier ||
            @new_resource.profile_name
        end

        current_profile = nil
        if all_profiles && !all_profiles.empty?
          current_profile = all_profiles["_computerlevel"].find do |item|
            item["ProfileIdentifier"] == @new_profile_identifier
          end
        end
        @current_resource.profile(current_profile)
      end

      def define_resource_requirements
        requirements.assert(:remove) do |a|
          if @new_profile_identifier
            a.assertion do
              !@new_profile_identifier.nil? &&
                !@new_profile_identifier.end_with?(".mobileconfig") &&
                /^\w+(?:(\.| )\w+)+$/.match(@new_profile_identifier)
            end
            a.failure_message RuntimeError, "when removing using the identifier attribute, it must match the profile identifier"
          else
            new_profile_name = @new_resource.profile_name
            a.assertion do
              !new_profile_name.end_with?(".mobileconfig") &&
                /^\w+(?:(\.| )\w+)+$/.match(new_profile_name)
            end
            a.failure_message RuntimeError, "When removing by resource name, it must match the profile identifier "
          end
        end

        requirements.assert(:install) do |a|
          if @new_profile_hash.is_a?(Hash)
            a.assertion do
              @new_profile_hash.include?("PayloadIdentifier")
            end
            a.failure_message RuntimeError, "The specified profile does not seem to be valid"
          end
          if @new_profile_hash.is_a?(String)
            a.assertion do
              @new_profile_hash.end_with?(".mobileconfig")
            end
            a.failure_message RuntimeError, "#{new_profile_hash}' is not a valid profile"
          end
        end
      end

      def action_install
        unless profile_installed?
          converge_by("install profile #{@new_profile_identifier}") do
            profile_path = write_profile_to_disk
            install_profile(profile_path)
            get_installed_profiles(true)
          end
        end
      end

      def action_remove
        # Clean up profile after removing it
        if profile_installed?
          converge_by("remove profile #{@new_profile_identifier}") do
            remove_profile
            get_installed_profiles(true)
          end
        end
      end

      def load_profile_hash(new_profile)
        # file must exist in cookbook
        if new_profile.end_with?(".mobileconfig")
          unless cookbook_file_available?(new_profile)
            error_string = "#{self}: '#{new_profile}' not found in cookbook"
            raise Chef::Exceptions::FileNotFound, error_string
          end
          cookbook_profile = cache_cookbook_profile(new_profile)
          return read_plist(cookbook_profile)
        else
          return nil
        end
      end

      def cookbook_file_available?(cookbook_file)
        run_context.has_cookbook_file_in_cookbook?(
          @new_resource.cookbook_name, cookbook_file
        )
      end

      def get_cache_dir
        cache_dir = Chef::FileCache.create_cache_path(
          "profiles/#{@new_resource.cookbook_name}"
        )
      end

      def cache_cookbook_profile(cookbook_file)
        Chef::FileCache.create_cache_path(
          ::File.join(
            "profiles",
            @new_resource.cookbook_name,
            ::File.dirname(cookbook_file)
          )
        )
        remote_file = Chef::Resource::CookbookFile.new(
          ::File.join(
            get_cache_dir,
            "#{cookbook_file}.remote"
          ),
          run_context
        )
        remote_file.cookbook_name = @new_resource.cookbook_name
        remote_file.source(cookbook_file)
        remote_file.backup(false)
        remote_file.run_action(:create)
        remote_file.path
      end

      def get_profile_hash(new_profile)
        if new_profile.is_a?(Hash)
          return new_profile
        elsif new_profile.is_a?(String)
          return load_profile_hash(new_profile)
        end
      end

      def config_uuid(profile)
        # Make a UUID of the profile contents and return as string
        UUIDTools::UUID.sha1_create(
          UUIDTools::UUID_DNS_NAMESPACE,
          profile.to_s
        ).to_s
      end

      def write_profile_to_disk
        @new_resource.path(Chef::FileCache.create_cache_path("profiles"))
        tempfile = Chef::FileContentManagement::Tempfile.new(@new_resource).tempfile
        tempfile.write(@new_profile_hash.to_plist)
        tempfile.close
        tempfile.path
      end

      def install_profile(profile_path)
        cmd = "profiles -I -F '#{profile_path}'"
        Chef::Log.debug("cmd: #{cmd}")
        shellout_results = shell_out(cmd)
        shellout_results.exitstatus
      end

      def remove_profile
        cmd = "profiles -R -p '#{@new_profile_identifier}'"
        Chef::Log.debug("cmd: #{cmd}")
        shellout_results = shell_out(cmd)
        shellout_results.exitstatus
      end

      def get_installed_profiles(update = nil)
        if update
          node.run_state[:config_profiles] = query_installed_profiles
        else
          node.run_state[:config_profiles] ||= query_installed_profiles
        end
      end

      def query_installed_profiles
        # Dump all profile metadata to a tempfile
        tempfile = generate_tempfile
        write_installed_profiles(tempfile)
        installed_profiles = read_plist(tempfile)
        Chef::Log.debug("Saved profiles to run_state")
        # Clean up the temp file as we do not need it anymore
        ::File.unlink(tempfile)
        installed_profiles
      end

      def generate_tempfile
        tempfile = ::Dir::Tmpname.create("allprofiles.plist") {}
      end

      def write_installed_profiles(tempfile)
        cmd = "profiles -P -o '#{tempfile}'"
        shell_out!(cmd)
      end

      def read_plist(xml_file)
        Plist.parse_xml(xml_file)
      end

      def profile_installed?
        # Profile Identifier and UUID must match a currently installed profile
        if @current_resource.profile.nil? || @current_resource.profile.empty?
          false
        else
          if @new_resource.action.include?(:remove)
            true
          else
            @current_resource.profile["ProfileUUID"] ==
              @new_profile_hash["PayloadUUID"]
          end
        end
      end

    end
  end
end
