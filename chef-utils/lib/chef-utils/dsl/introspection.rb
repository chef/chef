# frozen_string_literal: true
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

require_relative "train_helpers"

module ChefUtils
  module DSL
    # This is for "introspection" helpers in the sense that we are inspecting the
    # actual server or image under management to determine running state (duck-typing the system).
    # The helpers here may use the node object state from ohai, but typically not the big 5:  platform,
    # platform_family, platform_version, arch, os.  The helpers here should infer somewhat
    # higher level facts about the system.
    #
    module Introspection
      include TrainHelpers

      # Determine if the node is using the Chef Effortless pattern in which the Chef Infra Client is packaged using Chef Habitat
      #
      # @param [Chef::Node] node the node to check
      # @since 17.0
      #
      # @return [Boolean]
      #
      def effortless?(node = __getnode)
        !!(node && node.read("chef_packages", "chef", "chef_effortless"))
      end

      # Determine if the node is a docker container.
      #
      # @param [Chef::Node] node the node to check
      # @since 12.11
      #
      # @return [Boolean]
      #
      def docker?(node = __getnode)
        # Using "File.exist?('/.dockerinit') || File.exist?('/.dockerenv')" makes Travis sad,
        # and that makes us sad too.
        !!(node && node.read("virtualization", "systems", "docker") == "guest")
      end

      # Determine if the node uses the systemd init system.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def systemd?(node = __getnode)
        file_exist?("/proc/1/comm") && file_open("/proc/1/comm").gets.chomp == "systemd"
      end

      # Determine if the node is running in Test Kitchen.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def kitchen?(node = __getnode)
        ENV.key?("TEST_KITCHEN")
      end

      # Determine if the node is running in a CI system that sets the CI env var.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def ci?(node = __getnode)
        ENV.key?("CI")
      end

      # Determine if the a systemd service unit is present on the system.
      #
      # @param [String] svc_name
      # @since 15.5
      #
      # @return [Boolean]
      #
      def has_systemd_service_unit?(svc_name)
        %w{ /etc /usr/lib /lib /run }.any? do |load_path|
          file_exist?(
            "#{load_path}/systemd/system/#{svc_name.gsub(/@.*$/, "@")}.service"
          )
        end
      end

      # Determine if the a systemd unit of any type is present on the system.
      #
      # @param [String] svc_name
      # @since 15.5
      #
      # @return [Boolean]
      #
      def has_systemd_unit?(svc_name)
        # TODO: stop supporting non-service units with service resource
        %w{ /etc /usr/lib /lib /run }.any? do |load_path|
          file_exist?("#{load_path}/systemd/system/#{svc_name}")
        end
      end

      # Determine if the current node includes the given recipe name.
      #
      # @param [String] recipe_name
      # @since 15.8
      #
      # @return [Boolean]
      #
      def includes_recipe?(recipe_name, node = __getnode)
        node.recipe?(recipe_name)
      end
      # chef-sugar backcompat method
      alias_method :include_recipe?, :includes_recipe?

      extend self
    end
  end
end
