#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software
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

class Chef
  module Mixin
    module Unformatter

      def write(message)
        data = message.match(/(\[.+?\] )?([\w]+):(.*)$/)
        send(data[2].downcase.chomp.to_sym, data[3].strip)
      rescue NoMethodError
        send(:info, message)
      end

    end
  end
end
