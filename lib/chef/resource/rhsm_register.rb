#
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "shellwords" unless defined?(Shellwords)

class Chef
  class Resource
    class RhsmRegister < Chef::Resource
      unified_mode true
      provides(:rhsm_register) { true }

      description "Use the **rhsm_register** resource to register a node with the Red Hat Subscription Manager or a local Red Hat Satellite server."
      introduced "14.0"
      examples <<~DOC
        **Register a node with RHSM*

        ```ruby
        rhsm_register 'my-host' do
          activation_key 'ABCD1234'
          organization 'my_org'
        end
        ```
      DOC

      property :activation_key, [String, Array],
        coerce: proc { |x| Array(x) },
        description: "A string or array of activation keys to use when registering; you must also specify the 'organization' property when using this property."

      property :satellite_host, String,
        description: "The FQDN of the Satellite host to register with. If this property is not specified, the host will register with Red Hat's public RHSM service."

      property :organization, String,
        description: "The organization to use when registering; required when using the 'activation_key' property."

      property :environment, String,
        description: "The environment to use when registering; required when using the username and password properties."

      property :username, String,
        description: "The username to use when registering. This property is not applicable if using an activation key. If specified, password and environment properties are also required."

      property :password, String,
        description: "The password to use when registering. This property is not applicable if using an activation key. If specified, username and environment are also required."

      property :system_name, String,
        description: "The name of the system to register, defaults to the hostname.",
        introduced: "16.5"

      property :auto_attach,
        [TrueClass, FalseClass],
        description: "If true, RHSM will attempt to automatically attach the host to applicable subscriptions. It is generally better to use an activation key with the subscriptions pre-defined.",
        default: false

      property :install_katello_agent, [TrueClass, FalseClass],
        description: "If true, the 'katello-agent' RPM will be installed.",
        default: true

      property :force, [TrueClass, FalseClass],
        description: "If true, the system will be registered even if it is already registered. Normally, any register operations will fail if the machine has already been registered.",
        default: false, desired_state: false

      property :https_for_ca_consumer, [TrueClass, FalseClass],
        description: "If true, #{ChefUtils::Dist::Infra::PRODUCT} will fetch the katello-ca-consumer-latest.noarch.rpm from the satellite_host using HTTPS.",
        default: false, desired_state: false,
        introduced: "15.9"

      action :register, description: "Register the node with RHSM." do
        package "subscription-manager"

        unless new_resource.satellite_host.nil? || registered_with_rhsm?
          declare_resource(package_resource, "katello-ca-consumer-latest") do
            options "--nogpgcheck"
            source "#{Chef::Config[:file_cache_path]}/katello-package.rpm"
            action :nothing
          end

          remote_file "#{Chef::Config[:file_cache_path]}/katello-package.rpm" do
            source ca_consumer_package_source
            action :create
            notifies :install, "#{package_resource}[katello-ca-consumer-latest]", :immediately
            not_if { katello_cert_rpm_installed? }
          end

          file "#{Chef::Config[:file_cache_path]}/katello-package.rpm" do
            action :delete
          end
        end

        execute "Register to RHSM" do
          sensitive new_resource.sensitive
          command register_command
          default_env true
          action :run
          not_if { registered_with_rhsm? } unless new_resource.force
        end

        if new_resource.install_katello_agent && !new_resource.satellite_host.nil?
          package "katello-agent"
        end
      end

      action :unregister, description: "Unregister the node from RHSM." do
        execute "Unregister from RHSM" do
          command "subscription-manager unregister"
          default_env true
          action :run
          only_if { registered_with_rhsm? }
          notifies :run, "execute[Clean RHSM Config]", :immediately
        end

        execute "Clean RHSM Config" do
          command "subscription-manager clean"
          default_env true
          action :nothing
        end
      end

      action_class do
        #
        # @return [Symbol] dnf_package or yum_package depending on OS release
        #
        def package_resource
          node["platform_version"].to_i >= 8 ? :dnf_package : :yum_package
        end

        #
        # @return [Boolean] is the node registered with RHSM
        #
        def registered_with_rhsm?
          @registered ||= !shell_out("subscription-manager status").stdout.include?("Overall Status: Unknown")
        end

        #
        # @return [Boolean] is katello-ca-consumer installed
        #
        def katello_cert_rpm_installed?
          shell_out("rpm -qa").stdout.include?("katello-ca-consumer")
        end

        #
        # @return [String] The URI to fetch katello-ca-consumer-latest.noarch.rpm from
        #
        def ca_consumer_package_source
          protocol = new_resource.https_for_ca_consumer ? "https" : "http"
          "#{protocol}://#{new_resource.satellite_host}/pub/katello-ca-consumer-latest.noarch.rpm"
        end

        def register_command
          command = %w{subscription-manager register}

          if new_resource.activation_key
            unless new_resource.activation_key.empty?
              raise "Unable to register - you must specify organization when using activation keys" if new_resource.organization.nil?

              command << new_resource.activation_key.map { |key| "--activationkey=#{Shellwords.shellescape(key)}" }
              command << "--org=#{Shellwords.shellescape(new_resource.organization)}"
              command << "--name=#{Shellwords.shellescape(new_resource.system_name)}" if new_resource.system_name
              command << "--force" if new_resource.force

              return command.join(" ")
            end
          end

          if new_resource.username && new_resource.password
            raise "Unable to register - you must specify environment when using username/password" if new_resource.environment.nil? && using_satellite_host?

            command << "--username=#{Shellwords.shellescape(new_resource.username)}"
            command << "--password=#{Shellwords.shellescape(new_resource.password)}"
            command << "--environment=#{Shellwords.shellescape(new_resource.environment)}" if using_satellite_host?
            command << "--name=#{Shellwords.shellescape(new_resource.system_name)}" if new_resource.system_name
            command << "--auto-attach" if new_resource.auto_attach
            command << "--force" if new_resource.force

            return command.join(" ")
          end

          raise "Unable to create register command - you must specify activation_key or username/password"
        end

        def using_satellite_host?
          !new_resource.satellite_host.nil?
        end
      end
    end
  end
end
