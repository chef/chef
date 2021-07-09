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

require_relative "../internal"

module ChefUtils
  module DSL
    module PlatformFamily
      include Internal

      # Determine if the current node is a member of the 'arch' family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def arch?(node = __getnode)
        node["platform_family"] == "arch"
      end
      # chef-sugar backcompat method
      alias_method :arch_linux?, :arch?

      # Determine if the current node is a member of the 'aix' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def aix?(node = __getnode)
        node["platform_family"] == "aix"
      end

      # Determine if the current node is a member of the 'debian' platform family (Debian, Ubuntu and derivatives).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def debian?(node = __getnode)
        node["platform_family"] == "debian"
      end

      # Determine if the current node is a member of the 'fedora' platform family (Fedora and Arista).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def fedora?(node = __getnode)
        node["platform_family"] == "fedora"
      end

      # Determine if the current node is a member of the 'mac_os_x' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def macos?(node = __getnode)
        node ? node["platform_family"] == "mac_os_x" : macos_ruby?
      end
      # chef-sugar backcompat method
      alias_method :osx?, :macos?
      # chef-sugar backcompat method
      alias_method :mac?, :macos?
      # chef-sugar backcompat method
      alias_method :mac_os_x?, :macos?

      # Determine if the Ruby VM is currently running on a Mac node (This is useful primarily for internal use
      # by Chef Infra Client before the node object exists).
      #
      # @since 17.3
      #
      # @return [Boolean]
      #
      def macos_ruby?
        !!(RUBY_PLATFORM =~ /darwin/)
      end

      # Determine if the current node is a member of the 'rhel' platform family (Red Hat, CentOS, Oracle or Scientific Linux, but NOT Amazon Linux or Fedora).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def rhel?(node = __getnode)
        node["platform_family"] == "rhel"
      end
      # chef-sugar backcompat method
      alias_method :el?, :rhel?

      # Determine if the current node is a rhel6 compatible build (Red Hat, CentOS, Oracle or Scientific Linux).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def rhel6?(node = __getnode)
        node["platform_family"] == "rhel" && node["platform_version"].to_f >= 6.0 && node["platform_version"].to_f < 7.0
      end

      # Determine if the current node is a rhel7 compatible build (Red Hat, CentOS, Oracle or Scientific Linux).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def rhel7?(node = __getnode)
        node["platform_family"] == "rhel" && node["platform_version"].to_f >= 7.0 && node["platform_version"].to_f < 8.0
      end

      # Determine if the current node is a rhel8 compatible build (Red Hat, CentOS, Oracle or Scientific Linux).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def rhel8?(node = __getnode)
        node["platform_family"] == "rhel" && node["platform_version"].to_f >= 8.0 && node["platform_version"].to_f < 9.0
      end

      # Determine if the current node is a member of the 'amazon' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def amazon?(node = __getnode)
        node["platform_family"] == "amazon"
      end
      # chef-sugar backcompat method
      alias_method :amazon_linux?, :amazon?

      # Determine if the current node is a member of the 'solaris2' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def solaris2?(node = __getnode)
        node["platform_family"] == "solaris2"
      end
      # chef-sugar backcompat method
      alias_method :solaris?, :solaris2?

      # Determine if the current node is a member of the 'smartos' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def smartos?(node = __getnode)
        node["platform_family"] == "smartos"
      end

      # Determine if the current node is a member of the 'suse' platform family (openSUSE, SLES, and SLED).
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def suse?(node = __getnode)
        node["platform_family"] == "suse"
      end

      # Determine if the current node is a member of the 'gentoo' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def gentoo?(node = __getnode)
        node["platform_family"] == "gentoo"
      end

      # Determine if the current node is a member of the 'freebsd' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def freebsd?(node = __getnode)
        node["platform_family"] == "freebsd"
      end

      # Determine if the current node is a member of the 'openbsd' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def openbsd?(node = __getnode)
        node["platform_family"] == "openbsd"
      end

      # Determine if the current node is a member of the 'netbsd' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def netbsd?(node = __getnode)
        node["platform_family"] == "netbsd"
      end

      # Determine if the current node is a member of the 'dragonflybsd' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def dragonflybsd?(node = __getnode)
        node["platform_family"] == "dragonflybsd"
      end

      # Determine if the current node is a member of the 'windows' platform family.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def windows?(node = __getnode(true))
        # This is all somewhat complicated.  We prefer to get the node object so that chefspec can
        # stub the node object.  But we also have to deal with class-parsing time where there is
        # no node object, so we have to fall back to RUBY_PLATFORM based detection.  We cannot pull
        # the node object out of the Chef.run_context.node global object here (which is what the
        # false flag to __getnode is about) because some run-time code also cannot run under chefspec
        # on non-windows where the node is stubbed to windows.
        #
        # As a result of this the `windows?` helper and the `ChefUtils.windows?` helper do not behave
        # the same way in that the latter is not stubbable by chefspec.
        #
        node ? node["platform_family"] == "windows" : windows_ruby?
      end

      # Determine if the Ruby VM is currently running on a Windows node (ChefSpec can never stub
      # this behavior, so this is useful for code which can never be parsed on a non-Windows box).
      #
      # @since 15.5
      #
      # @return [Boolean]
      #
      def windows_ruby?
        !!(RUBY_PLATFORM =~ /mswin|mingw32|windows/)
      end

      #
      # Platform-Family-like Helpers
      #
      # These are meta-helpers which address the issue that platform_family is single valued and cannot
      # be an array while a tree-like Taxonomy is what is called for in some cases.
      #

      # If it uses RPM, it goes in here (rhel, fedora, amazon, suse platform_families).  Deliberately does not
      # include AIX because bff is AIX's primary package manager and adding it here would make this substantially
      # less useful since in no way can AIX trace its lineage back to old redhat distros.  This is most useful for
      # "smells like redhat, including SuSE".
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def rpm_based?(node = __getnode)
        fedora_derived?(node) || node["platform_family"] == "suse"
      end

      # RPM-based distros which are not SuSE and are very loosely similar to fedora, using yum or dnf. The historical
      # lineage of the distro should have forked off from old redhat fedora distros at some point. Currently rhel,
      # fedora and amazon. This is most useful for "smells like redhat, but isn't SuSE".
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def fedora_derived?(node = __getnode)
        redhat_based?(node) || node["platform_family"] == "amazon"
      end

      # RedHat distros -- fedora and rhel platform_families, nothing else. This is most likely not as useful as the
      # "fedora_derived?" helper.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def redhat_based?(node = __getnode)
        %w{rhel fedora}.include?(node["platform_family"])
      end

      # All of the Solaris-lineage.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def solaris_based?(node = __getnode)
        %w{solaris2 smartos omnios openindiana}.include?(node["platform"])
      end

      # All of the BSD-lineage.
      #
      # Note that macOS is not included since macOS deviates so significantly from BSD that including it would not be useful.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def bsd_based?(node = __getnode)
        # we could use os, platform_family or platform here equally
        %w{netbsd freebsd openbsd dragonflybsd}.include?(node["platform"])
      end

      extend self
    end
  end
end
