#
# Author:: James Casey <james@opscode.com>
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

# == SecureRandom (Patch)
# On ruby 1.9, SecureRandom has a uuid method which generates a v4 UUID.  The
# backport of SecureRandom to 1.8.7 is missing this method

require 'securerandom'

module SecureRandom
  unless respond_to?(:uuid)
    # SecureRandom.uuid generates a v4 random UUID (Universally Unique IDentifier).
    #
    #   p SecureRandom.uuid #=> "2d931510-d99f-494a-8c67-87feb05e1594"
    #   p SecureRandom.uuid #=> "bad85eb9-0713-4da7-8d36-07a8e4b00eab"
    #   p SecureRandom.uuid #=> "62936e70-1815-439b-bf89-8492855a7e6b"
    #
    # The version 4 UUID is purely random (except the version).
    # It doesn't contain meaningful information such as MAC address, time, etc.
    #
    # See RFC 4122 for details of UUID.
    def self.uuid
      ary = self.random_bytes(16).unpack("NnnnnN")
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end
  end
end
