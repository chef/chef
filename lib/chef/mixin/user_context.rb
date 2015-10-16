#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'chef/util/windows/logon_session'

class Chef
  module Mixin
    module UserContext
      def with_user_context(user, domain, password, &block)
        if ! block_given?
          raise Exceptions::ArgumentError, 'You must supply a block to `with_user_context`'
        end

        if ! Chef::Platform.windows?
          raise Exceptions::UnsupportedPlatform,
                  "User context functionality is only supported on the Windows platform"
        end

        begin
          logon_session = Chef::Util::Windows::LogonSession.new(user, domain, password)
          logon_session.open
          logon_session.set_user_context
          block.call
        ensure
          logon_session.close!
        end
      end
    end
  end
end
