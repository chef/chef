#
# Copyright:: Copyright 2018-2018, Chef Software Inc.
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

require 'chef-helpers/internal'

module ChefHelpers
  module PlatformFamily

    extend self

    #
    # NOTE CAREFULLY: Most node['platform_family'] values should not appear in this file at all.
    #
    # For cases where node['os'] == node['platform_family'] == node['platform'] then
    # only the platform helper should be added.
    #
    # For cases where there are more than one platform in the platform family, but the platform_family
    # name duplicates one of the platform names, then it should be added here with the _family? suffix.
    # (e.g. fedora_platform?, debian_platform?, etc).
    #

    # Determine if the current node is a member of the debian family.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def debian_platform?(node)
      node["platform_family"] == "debian"
    end
    # NOTE: debian? matches only the exact platform

    # Determine if the current node is a member of the fedora family.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def fedora_platform?(node)
      node["platform_family"] == "fedora"
    end
    # NOTE: fedora? matches only the exact platform

    # Determine if the current node is a member of the OSX family.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def mac_os_x_family?(node)
      node["platform_family"] == "mac_os_x"
    end
    alias_method :osx?, :mac_os_x_family?
    alias_method :mac?, :mac_os_x_family?
    # NOTE: mac_os_x? matches only the exact platform

    # Determine if the current node is a member of the redhat family.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def rhel?(node)
      node["platform_family"] == "rhel"
    end
    alias_method :el?, :rhel?

    # Determine if the current node is a member of the suse family.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def suse_family?(node)
      node["platform_family"] == "suse"
    end
    # NOTE: suse? matches only the exact platform

    # Determine if the current node is a member of the windows family.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def windows?(node = Internal.getnode)
      # we prefer to use the node object so that chef-sugar can stub the node data with fauxhai, but
      # for contexts where there is no node (e.g. class parsing time) we use RUBY_PLATFORM.
      node ? node["platform_family"] == "windows" : RUBY_PLATFORM =~ /mswin|mingw32|windows/
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
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def rpm_based?(node = Internal.getnode)
      fedora_derived?(node) || node["platform_family"] == "suse"
    end

    # RPM-based distros which are not SuSE and are very loosely similar to fedora, using yum or dnf.  The historical
    # lineage of the distro should have forked off from old redhat fedora distros at some point.  Currently rhel,
    # fedora and amazon.  This is most useful for "smells like redhat, but isn't SuSE".
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def fedora_derived?(node = Internal.getnode)
      redhat_based?(node) || node["platform_family"] == "amazon"
    end

    # RedHat distros -- fedora and rhel platform_families, nothing else.  This is most likely not as useful as the
    # "fedora_dervied?" helper.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def redhat_based?(node = Internal.getnode)
      %w{rhel fedora}.include?(node["platform_family"])
    end

    # All of the Solaris-lineage.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def solaris_based?(node = Internal.getnode)
      %w{solaris2 smartos omnios openindiana opensolaris nexentacore}.include?(node["platform"])
    end

    # All of the BSD-lineage.
    #
    # Note that MacOSX is not included since Mac deviates so significantly from BSD that including it would not be useful.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def bsd_based?(node = Internal.getnode)
      %w{netbsd freebsd openbsd dragonflybsd}.include?(node["platform"])
    end
  end
end
