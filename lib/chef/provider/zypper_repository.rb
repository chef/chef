#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2017, Chef Software Inc.
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

require "chef/resource"
require "chef/dsl/declare_resource"
require "chef/provider/noop"
require "chef/mixin/shell_out"
require "shellwords"

class Chef
  class Provider
    class ZypperRepository < Chef::Provider
      provides :zypper_repository, platform_family: "suse"

      def load_current_resource
      end

      action :create do
        if new_resource.gpgautoimportkeys
          install_gpg_key(new_resource.gpgkey)
        else
          Chef::Log.debug("'gpgautoimportkeys' property is set to false. Skipping key import.")
        end

        declare_resource(:template, "/etc/zypp/repos.d/#{escaped_repo_name}.repo") do
          if template_available?(new_resource.source)
            source new_resource.source
          else
            source ::File.expand_path("../support/zypper_repo.erb", __FILE__)
            local true
          end
          sensitive new_resource.sensitive
          variables(config: new_resource)
          mode new_resource.mode
          notifies :refresh, new_resource, :immediately if new_resource.refresh_cache
        end
      end

      action :delete do
        declare_resource(:execute, "zypper --quiet --non-interactive removerepo #{escaped_repo_name}") do
          only_if "zypper --quiet lr #{escaped_repo_name}"
        end
      end

      action :refresh do
        declare_resource(:execute, "zypper --quiet --non-interactive refresh --force #{escaped_repo_name}") do
          only_if "zypper --quiet lr #{escaped_repo_name}"
        end
      end

      alias_method :action_add, :action_create
      alias_method :action_remove, :action_delete

      # zypper repos are allowed to have spaces in the names
      # @return [String] escaped repo string
      def escaped_repo_name
        Shellwords.escape(new_resource.repo_name)
      end

      # determine if a template file is available in the current run
      # @param [String] path the path to the template file
      #
      # @return [Boolean] template file exists or doesn't
      def template_available?(path)
        !path.nil? && run_context.has_template_in_cookbook?(new_resource.cookbook_name, path)
      end

      # determine if a cookbook file is available in the run
      # @param [String] path the path to the template file
      #
      # @return [Boolean] cookbook file exists or doesn't
      def has_cookbook_file?(fn)
        run_context.has_cookbook_file_in_cookbook?(cookbook_name, fn)
      end

      # Given the provided key URI determine what kind of chef resource we need
      # to fetch the key
      # @param [String] uri the uri of the gpg key (local path or http URL)
      #
      # @raise [Chef::Exceptions::FileNotFound] Key isn't remote or found in the current run
      #
      # @return [Symbol] :remote_file or :cookbook_file
      def key_type(uri)
        if uri.start_with?("http")
          Chef::Log.debug("Will use :remote_file resource to cache the gpg key locally")
          :remote_file
        elsif has_cookbook_file?(key)
          Chef::Log.debug("Will use :cookbook_file resource to cache the gpg key locally")
          :cookbook_file
        else
          raise Chef::Exceptions::FileNotFound, "Cannot determine location of gpgkey. Must start with 'http' or be a file managed by Chef."
        end
      end

      # is the provided key already installed
      # @param [String] key_path the path to the key on the local filesystem
      #
      # @return [boolean] is the key already known by rpm
      def key_installed?(key_path)
        so = shell_out("rpm -qa gpg-pubkey*")
        # expected output & match: http://rubular.com/r/RdF7EcXEtb
        status = /gpg-pubkey-#{key_fingerprint(key_path)}/.match(so.stdout)
        Chef::Log.debug("GPG key at #{key_path} is known by rpm? #{status ? "true" : "false"}")
        status
      end

      # extract the gpg key fingerprint from a local file
      # @param [String] key_path the path to the key on the local filesystem
      #
      # @return [String] the fingerprint of the key
      def key_fingerprint(key_path)
        so = shell_out!("gpg --with-fingerprint #{key_path}")
        # expected output and match: http://rubular.com/r/BpfMjxySQM
        fingerprint = /pub\s*\S*\/(\S*)/.match(so.stdout)[1].downcase
        Chef::Log.debug("GPG fingerprint of key at #{key_path} is #{fingerprint}")
        fingerprint
      end

      # install the provided gpg key
      # @param [String] uri the uri of the local or remote gpg key
      def install_gpg_key(uri)
        unless uri
          Chef::Log.debug("'gpgkey' property not provided or set to nil. Skipping key import.")
          return
        end

        cached_keyfile = ::File.join(Chef::Config[:file_cache_path], uri.split("/")[-1])

        declare_resource(key_type(new_resource.gpgkey), cached_keyfile) do
          source uri
          mode "0644"
          sensitive new_resource.sensitive
          action :create
        end

        declare_resource(:execute, "import gpg key from #{new_resource.gpgkey}") do
          command "/bin/rpm --import #{cached_keyfile}"
          not_if { key_installed?(cached_keyfile) }
          action :run
        end
      end
    end
  end
end

Chef::Provider::Noop.provides :zypper_repository
