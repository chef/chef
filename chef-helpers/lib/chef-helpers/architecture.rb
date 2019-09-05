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
  module Architecture
    extend self

    # Determine if the current architecture is 64-bit
    #
    # @return [Boolean]
    #
    def _64_bit?(node = Internal.getnode)
      %w{amd64 x86_64 ppc64 ppc64le s390x ia64 sparc64 aarch64 arch64 arm64 sun4v sun4u}
        .include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is 32-bit
    #
    # @return [Boolean]
    #
    def _32_bit?(node = Internal.getnode)
      !_64_bit?(node)
    end

    # Determine if the current architecture is i386
    #
    # @return [Boolean]
    #
    def i386?(node = Internal.getnode)
      _32_bit?(node) && intel?(node)
    end

    # Determine if the current architecture is Intel.
    #
    # @return [Boolean]
    #
    def intel?(node = Internal.getnode)
      %w{i86pc i386 x86_64 amd64 i686}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is SPARC.
    #
    # @return [Boolean]
    #
    def sparc?(node = Internal.getnode)
      %w{sun4u sun4v}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is Powerpc64 Big Endian
    #
    # @return [Boolean]
    #
    def ppc64?(node = Internal.getnode)
      %w{ppc64}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is Powerpc64 Little Endian
    #
    # @return [Boolean]
    #
    def ppc64le?(node = Internal.getnode)
      %w{ppc64le}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is PowerPC.
    #
    # @return [Boolean]
    #
    def powerpc?(node = Internal.getnode)
      %w{powerpc}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is 32-bit ARM
    #
    # @return [Boolean]
    #
    def armhf?(node = Internal.getnode)
      %w{armhf}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is s390x
    #
    # @return [Boolean]
    #
    def s390x?(node = Internal.getnode)
      %w{s390x}.include?(node["kernel"]["machine"])
    end

    # Determine if the current architecture is s390
    #
    # @return [Boolean]
    #
    def s390?(node = Internal.getnode)
      %w{s390}.include?(node["kernel"]["machine"])
    end

  end
end
