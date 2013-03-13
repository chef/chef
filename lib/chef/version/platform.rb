# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

require 'chef/version_class'

class Chef
  class Version
    class Platform < Chef::Version

      protected

      def parse(str="")
        @major, @minor, @patch =
          case str.to_s
          when /^(\d+)\.(\d+)\.(\d+)$/
            [ $1.to_i, $2.to_i, $3.to_i ]
          when /^(\d+)\.(\d+)$/
            [ $1.to_i, $2.to_i, 0 ]
          when /^(\d+)$/
            [ $1.to_i, 0, 0 ]
          else
            msg = "'#{str.to_s}' does not match 'x.y.z', 'x.y' or 'x'"
            raise Chef::Exceptions::InvalidPlatformVersion.new( msg )
          end
      end

    end
  end
end
