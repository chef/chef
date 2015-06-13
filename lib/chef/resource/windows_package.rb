#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/mixin/uris'
require 'chef/resource/package'
require 'chef/provider/package/windows'
require 'chef/win32/error' if RUBY_PLATFORM =~ /mswin|mingw|windows/

class Chef
  class Resource
    class WindowsPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      provides :windows_package, os: "windows"
      provides :package, os: "windows"

      allowed_actions :install, :remove

      def initialize(name, run_context=nil)
        super
        @source ||= source(@package_name)

        # Unique to this resource
        @installer_type = nil
        @timeout = 600
        # In the past we accepted return code 127 for an unknown reason and 42 because of a bug
        @returns = [ 0 ]
      end

      def installer_type(arg=nil)
        set_or_return(
          :installer_type,
          arg,
          :kind_of => [ Symbol ]
        )
      end

      def timeout(arg=nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [ String, Integer ]
        )
      end

      def returns(arg=nil)
        set_or_return(
          :returns,
          arg,
          :kind_of => [ String, Integer, Array ]
        )
      end

      def source(arg=nil)
        if arg == nil && self.instance_variable_defined?(:@source) == true
          @source
        else
          raise ArgumentError, "Bad type for WindowsPackage resource, use a String" unless arg.is_a?(String)
          if uri_scheme?(arg)
            @source = arg
          else
            @source = Chef::Util::PathHelper.canonical_path(arg, false)
          end
        end
      end

      def checksum(arg=nil)
        set_or_return(
          :checksum,
          arg,
          :kind_of => [ String ]
        )
      end

      def remote_file_attributes(arg=nil)
        set_or_return(
          :remote_file_attributes,
          arg,
          :kind_of => [ Hash ]
        )
      end

    end
  end
end
