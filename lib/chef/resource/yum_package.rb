#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008-2015 Chef Software, Inc.
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

require 'chef/resource/package'
require 'chef/provider/package/yum'

class Chef
  class Resource
    class YumPackage < Chef::Resource::Package
      provides :package, os: "linux", platform_family: [ "rhel", "fedora" ]

      def initialize(name, run_context=nil)
        super
        @flush_cache = { :before => false, :after => false }
        @allow_downgrade = false
        @yum_binary = nil
      end

      # override superclass and support arrays
      def package_name(arg=nil)
        set_or_return(
          :package_name,
          arg,
          :kind_of => [ String, Array ]
        )
      end

      # override superclass and support arrays
      def version(arg=nil)
        set_or_return(
          :version,
          arg,
          :kind_of => [ String, Array ]
        )
      end

      # Install a specific arch
      def arch(arg=nil)
        set_or_return(
          :arch,
          arg,
          :kind_of => [ String, Array ]
        )
      end

      def flush_cache(args={})
        if args.is_a? Array
          args.each { |arg| @flush_cache[arg] = true }
        elsif args.any?
          @flush_cache = args
        else
          @flush_cache
        end
      end

      def allow_downgrade(arg=nil)
        set_or_return(
          :allow_downgrade,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def yum_binary(arg=nil)
        set_or_return(
          :yum_binary,
          arg,
          :kind_of => [ String ]
        )
      end

    end
  end
end
