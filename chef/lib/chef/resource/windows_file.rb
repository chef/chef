#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/resource/file'
require 'chef/provider/windows_file'

class Chef
  class Resource
    class WindowsFile < Chef::Resource::File

      provides :file, :on_platforms => ["windows"]

      VALID_RIGHTS = [:read, :write, :execute, :full_control, :deny]

      def initialize(name, run_context=nil)
        super
        @resource_name = :windows_file
        @path = name
        @action = "create"
        @inherits = false
        @provider = Chef::Provider::WindowsFile
      end

      # supports params like this:
      #
      #   rights :read, ["Administrators","Everyone"]
      #   rights :write, "Administrators"
      #
      # should also also allow multiple right declarations
      # in a single resource block as the data will be merged
      # into a single internal hash
      def rights(permission=nil, *args)
        rights = nil
        unless permission == nil
          input = {:permission => permission.to_sym, :principal => args[0] }
          validations = {:permission => { :required => true, :equal_to => VALID_RIGHTS },
                          :principal => { :required => true, :kind_of => [String, Array] }}
          validate(input, validations)

          rights ||= @rights ||= Hash.new

          # builds an internal hash like:
          #   {:write=>"Administrator", :read=>["Administrators", "Everyone"]}
          rights.merge!(input[:permission] => input[:principal])
        end
        set_or_return(
          :rights,
          rights,
          {}
        )
      end

      def inherits(arg=nil)
        set_or_return(
          :inherits,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

    end
  end
end
