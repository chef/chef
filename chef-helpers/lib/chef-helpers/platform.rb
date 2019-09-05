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

module ChefHelpers
  module Platform
    extend self

    # Determine if the current node is arch linux.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def arch?(node)
      node["platform"] == "arch"
    end
    alias_method :arch_linux?, :arch?

    #
    # Determine if the current node is linux mint.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def linuxmint?(node = Internal.getnode)
      node["platform"] == "linuxmint"
    end
    # chef-sugar backcompat methods
    alias_method :mint?, :linuxmint?
    alias_method :linux_mint?, :linuxmint?

    #
    # Determine if the current node is ubuntu.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def ubuntu?(node = Internal.getnode)
      node["platform"] == "ubuntu"
    end

    #
    # Determine if the current node is amazon linux.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def amazon?(node = Internal.getnode)
      node["platform"] == "amazon"
    end
    # chef-sugar backcompat methods
    alias_method :amazon_linux?, :amazon?

    #
    # Determine if the current node is centos.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def centos?(node = Internal.getnode)
      node["platform"] == "centos"
    end

    #
    # Determine if the current node is oracle linux.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def oracle?(node = Internal.getnode)
      node["platform"] == "oracle"
    end
    # chef-sugar backcompat methods
    alias_method :oracle_linux?, :oracle?

    #
    # Determine if the current node is scientific linux.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def scientific?(node = Internal.getnode)
      node["platform"] == "scientific"
    end
    # chef-sugar backcompat methods
    alias_method :scientific_linux?, :scientific?

    #
    # Determine if the current node is redhat enterprise.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def redhat?(node = Internal.getnode)
      node["platform"] == "redhat"
    end
    # chef-sugar backcompat methods
    alias_method :redhat_enterprise?, :redhat?
    alias_method :redhat_enterprise_linux?, :redhat?

    # Determine if the current node is solaris2
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def solaris2?(node = Internal.getnode)
      node["platform"] == "solaris2"
    end
    # chef-sugar backcompat methods
    alias_method :solaris?, :solaris2?

    # Determine if the current node is smartos
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def smartos?(node = Internal.getnode)
      node["platform"] == "smartos"
    end

    # Determine if the current node is omnios
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def omnios?(node = Internal.getnode)
      node["platform"] == "omnios"
    end

    # Determine if the current node is openindiana
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def openindiana?(node = Internal.getnode)
      node["platform"] == "openindiana"
    end

    # Determine if the current node is opensolaris
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def opensolaris?(node = Internal.getnode)
      node["platform"] == "opensolaris"
    end

    # Determine if the current node is nexentacore
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def nexentacore?(node = Internal.getnode)
      node["platform"] == "nexentacore"
    end

    # Determine if the current node is aix
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def aix?(node = Internal.getnode)
      node["platform"] == "aix"
    end

    # Determine if the current node is freebsd
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def freebsd?(node)
      node["platform"] == "freebsd"
    end

    # Determine if the current node is openbsd
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def openbsd?(node)
      node["platform"] == "openbsd"
    end

    # Determine if the current node is netbsd
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def netbsd?(node)
      node["platform"] == "netbsd"
    end

    # Determine if the current node is dragonflybsd
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def dragonflybsd?(node)
      node["platform"] == "dragonflybsd"
    end

    # Determine if the current node is MacOS.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def mac_os_x?(node)
      node["platform"] == "mac_os_x"
    end

    # Determine if the current node is MacOS.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def mac_os_x_server?(node)
      node["platform"] == "mac_os_x_server"
    end

    # Determine if the current node is gentoo
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def gentoo?(node)
      node["platform"] == "gentoo"
    end

    # Determine if the current node is slackware.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def slackware?(node)
      node["platform"] == "slackware"
    end

    # Determine if the current node is SuSE.
    #
    # @param [Chef::Node] node
    #
    # @return [Boolean]
    #
    def suse?(node)
      node["platform"] == "suse"
    end

    # FIXME FIXME FIXME: all the rest of the platforms
  end
end
