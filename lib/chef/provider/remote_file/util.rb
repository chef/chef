#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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
  class Provider
    class RemoteFile
      class Util
        def self.uri_matches?(u1, u2)
          # we store passwords commented out, so we cannot use passwords in
          # the comparision between two uris
          return false if u1.nil? || u2.nil?
          u1_dup = u1.dup
          u1_dup.password = "********" if u1_dup.userinfo
          u2_dup = u2.dup
          u2_dup.password = "********" if u2_dup.userinfo
          u1_dup == u2_dup
        end
      end
    end
  end
end

