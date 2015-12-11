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

require 'chef/util/windows/logon_session' if Chef::Platform.windows?
require 'chef/mixin/user_identity'

class Chef
  module Mixin
    module UserContext

      include Chef::Mixin::UserIdentity

      def with_user_context(specified_user, password, specified_domain = nil, &block)
        if ! Chef::Platform.windows?
          raise Exceptions::UnsupportedPlatform, 'User context impersonation is supported only on the Windows platform'
        end

        if ! block_given?
          raise Exceptions::ArgumentError, 'You must supply a block to `with_user_context`'
        end

        validate_identity(specified_user, password, specified_domain)

        identity = qualify_user(specified_user, specified_domain)

        user = identity[:user]
        domain = identity[:domain]

        login_session = nil

        begin
          if user
            logon_session = Chef::Util::Windows::LogonSession.new(user, password, domain)
            logon_session.open
            logon_session.set_user_context
          end
          block.call
        ensure
          logon_session.close if logon_session
        end
      end

      protected(:with_user_context)

    end
  end
end
