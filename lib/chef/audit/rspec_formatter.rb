#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "rspec/core"

class Chef
  class Audit
    class RspecFormatter < RSpec::Core::Formatters::DocumentationFormatter
      RSpec::Core::Formatters.register self, :close

      # @api public
      #
      # Invoked at the very end, `close` allows the formatter to clean
      # up resources, e.g. open streams, etc.
      #
      # @param _notification [NullNotification] (Ignored)
      def close(_notification)
        # Normally Rspec closes the streams it's given. We don't want it for Chef.
      end
    end
  end
end
