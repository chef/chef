#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
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
require 'chef/provider/package/rpm'

class Chef
  class Resource
    class RpmPackage < Chef::Resource::Package

      resource_name :rpm_package
      provides :rpm_package, os: [ "linux", "aix" ]

      def initialize(name, run_context=nil)
        super
        @allow_downgrade = false
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
