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

class Chef
  module Mixin
    module ResourceCredential

      def validate_credential(specified_user, specified_domain, password)
        user = specified_user
        domain = specified_domain

        if Chef::Platform.windows?
          if ! user.nil?
            domain, user = canonicalize_credential(specified_domain, specified_user)
          end

          if ! user.nil? && password.nil?
            raise ArgumentError, "No `password` property was specified when the `user` property was specified"
          end
        elsif ! domain.nil? || ! password.nil?
          raise Exceptions::UnsupportedPlatform, "The `domain` and `password` properties are only supported on the Windows platform"
        end

        if ( ! password.nil? || ! domain.nil? ) && user.nil?
          raise ArgumentError, "The `password` or `domain` property was specified without specification of the user property"
        end
      end

      def canonicalize_credential(specified_domain, specified_user)
        domain = specified_domain
        user = specified_user

        if ! specified_user.nil? && specified_domain.nil?
          domain_and_user = user.split('\\')

          if domain_and_user.length == 1
            domain_and_user = user.split('@')
          end

          if domain_and_user.length == 2
            domain = domain_and_user[0]
            user = domain_and_user[1]
          elsif domain_and_user.length != 1
            raise ArgumentError, "The specified user name `#{user}` is not a syntactically valid user name"
          end
        end

        [domain, user]
      end

      private(:validate_credential)
      private(:canonicalize_credential)

    end
  end
end
