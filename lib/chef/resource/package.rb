#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

require 'chef/resource'

class Chef
  class Resource
    class Package < Chef::Resource
      provides :package

      identity_attr :package_name

      state_attrs :version, :options

      def initialize(name, run_context=nil)
        super
        @action = :install
        @allowed_actions.push(:install, :upgrade, :remove, :purge, :reconfig)
        @candidate_version = nil
        @options = nil
        @package_name = name
        @resource_name = :package
        @response_file = nil
        @response_file_variables = Hash.new
        @source = nil
        @version = nil
        @timeout = 900
      end

      def package_name(arg=nil)
        set_or_return(
          :package_name,
          arg,
          :kind_of => [ String, Array ]
        )
      end

      def version(arg=nil)
        set_or_return(
          :version,
          arg,
          :kind_of => [ String, Array ]
        )
      end

      def response_file(arg=nil)
        set_or_return(
          :response_file,
          arg,
          :kind_of => [ String ]
        )
      end

      def response_file_variables(arg=nil)
        set_or_return(
          :response_file_variables,
          arg,
          :kind_of => [ Hash ]
        )
      end

      def source(arg=nil)
        set_or_return(
          :source,
          arg,
          :kind_of => [ String ]
        )
      end

      def options(arg=nil)
        set_or_return(
      	  :options,
      	  arg,
      	  :kind_of => [ String ]
      	)
      end

      def timeout(arg=nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [String, Integer]
        )
      end

    end
  end
end

require 'chef/chef_class'
require 'chef/resource/homebrew_package'

Chef.set_resource_priority_array :package, Chef::Resource::HomebrewPackage, os: "darwin"
