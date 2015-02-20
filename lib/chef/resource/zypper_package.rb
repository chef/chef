#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'chef/provider/package/zypper'

class Chef
  class Resource
    class ZypperPackage < Chef::Resource::Package

      provides :zypper_package
      provides :package, os: "linux", platform_family: [ "suse" ]

      def initialize(name, run_context=nil)
        super
        @resource_name = :zypper_package
        @flush_cache = { :before => false, :after => false }
        @allow_downgrade = false
        @timeout = 1800
      end

      def timeout(arg=nil)
        set_or_return(
            :timeout,
            arg,
            :kind_of => [String, Integer]
        )
      end

      # Install a specific arch
      def arch(arg=nil)
        set_or_return(
          :arch,
          arg,
          :kind_of => [ String ]
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

    end
  end
end
