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
        def self.uri_for_cache(uri)
          sanitized_uri(uri).to_s
        end

        def self.uri_matches?(u1, u2)
          # we store sanitiszed uris, so have to compare sanitized uris
          return false if u1.nil? || u2.nil?
          sanitized_uri(u1) == sanitized_uri(u2)
        end

        def self.sanitized_uri(uri)
          uri_dup = uri.dup
          uri_dup.password = "********" if uri_dup.userinfo
          uri_dup
        end
      end
    end
  end
end

