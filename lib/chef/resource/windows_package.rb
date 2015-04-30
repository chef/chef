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

require 'chef/resource/package'
require 'chef/provider/package/windows'
require 'chef/win32/error' if RUBY_PLATFORM =~ /mswin|mingw|windows/

class Chef
  class Resource
    class WindowsPackage < Chef::Resource::Package

      provides :package, os: "windows"
      provides :windows_package, os: "windows"

      def initialize(name, run_context=nil)
        super
        @allowed_actions.push(:install, :remove)
        @resource_name = :windows_package
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
          if is_url?(arg)
            @source = arg
          else
            @source = ::File.absolute_path(arg).gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR)
          end
        end
      end

      private

      def is_url?(source)
        begin
          scheme = URI.split(source).first
          return false unless scheme
          %w(http https ftp file).include?(scheme.downcase)
        rescue URI::InvalidURIError
          return false
        end
      end

    end
  end
end
