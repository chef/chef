# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../internal"
require_relative "train_helpers"

module ChefUtils
  module DSL
    # NOTE: these are mixed into the service resource+providers specifically and deliberately not
    # injected into the global namespace
    module Service
      include Internal
      include TrainHelpers
      include Introspection

      # Returns if debian's old rc.d manager is installed (not necessarily the primary init system).
      #
      # @since 15.5
      #
      # @return [Boolean]
      #
      def debianrcd?
        file_exist?("/usr/sbin/update-rc.d")
      end

      # Returns if debian's old invoke rc.d manager is installed (not necessarily the primary init system).
      #
      # @since 15.5
      #
      # @return [Boolean]
      #
      def invokercd?
        file_exist?("/usr/sbin/invoke-rc.d")
      end

      # Returns if upstart is installed (not necessarily the primary init system).
      #
      # @since 15.5
      #
      # @return [Boolean]
      #
      def upstart?
        file_exist?("/sbin/initctl")
      end

      # Returns if insserv is installed (not necessarily the primary init system).
      #
      # @since 15.5
      #
      # @return [Boolean]
      #
      def insserv?
        file_exist?("/sbin/insserv")
      end

      # Returns if redhat's init system is installed (not necessarily the primary init system).
      #
      # @since 15.5
      #
      # @return [Boolean]
      #
      def redhatrcd?
        file_exist?("/sbin/chkconfig")
      end

      #
      # Returns if a particular service exists for a particular service init system. Init systems may be :initd, :upstart, :etc_rcd, :xinetd, and :systemd. Example: service_script_exist?(:systemd, 'ntpd')
      #
      # @param [Symbol] type The type of init system. :initd, :upstart, :xinetd, :etc_rcd, or :systemd
      # @param [String] script The name of the service
      # @since 15.5
      #
      # @return [Boolean]
      #
      def service_script_exist?(type, script)
        case type
        when :initd
          file_exist?("/etc/init.d/#{script}")
        when :upstart
          file_exist?("/etc/init/#{script}.conf")
        when :xinetd
          file_exist?("/etc/xinetd.d/#{script}")
        when :etc_rcd
          file_exist?("/etc/rc.d/#{script}")
        when :systemd
          file_exist?("/etc/init.d/#{script}") ||
            has_systemd_service_unit?(script) ||
            has_systemd_unit?(script)
        else
          raise ArgumentError, "type of service must be one of :initd, :upstart, :xinetd, :etc_rcd, or :systemd"
        end
      end

      extend self
    end
  end
end
