#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright 2011 Opscode, Inc.
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

require 'chef/win32/security'
require 'chef/win32/security/ace'
require 'ffi'

class Chef
  module ReservedNames::Win32
    class Security
      class ACL
        include Enumerable

        def initialize(pointer, owner = nil)
          @struct = Chef::ReservedNames::Win32::API::Security::ACLStruct.new pointer
          # Keep a reference to the actual owner of this memory so that it isn't freed out from under us
          # TODO this could be avoided if we could mark a pointer's parent manually
          @owner = owner
        end

        def self.create(aces)
          aces_size = aces.inject(0) { |sum,ace| sum + ace.size }
          acl_size = align_dword(Chef::ReservedNames::Win32::API::Security::ACLStruct.size + aces_size) # What the heck is 94???
          acl = Chef::ReservedNames::Win32::Security.initialize_acl(acl_size)
          aces.each { |ace| Chef::ReservedNames::Win32::Security.add_ace(acl, ace) }
          acl
        end

        attr_reader :struct

        def ==(other)
          return false if length != other.length
          0.upto(length-1) do |i|
            return false if self[i] != other[i]
          end
          return true
        end

        def pointer
          struct.pointer
        end

        def [](index)
          Chef::ReservedNames::Win32::Security.get_ace(self, index)
        end

        def delete_at(index)
          Chef::ReservedNames::Win32::Security.delete_ace(self, index)
        end

        def each
          0.upto(length-1) { |i| yield self[i] }
        end

        def insert(index, *aces)
          aces.reverse_each { |ace| add_ace(self, ace, index) }
        end

        def length
          struct[:AceCount]
        end

        def push(*aces)
          aces.each { |ace| Chef::ReservedNames::Win32::Security.add_ace(self, ace) }
        end

        def unshift(*aces)
          aces.each { |ace| Chef::ReservedNames::Win32::Security.add_ace(self, ace, 0) }
        end

        def valid?
          Chef::ReservedNames::Win32::Security.is_valid_acl(self)
        end

        def to_s
          "[#{self.collect { |ace| ace.to_s }.join(", ")}]"
        end
        private

        def self.align_dword(size)
          (size + 4 - 1) & 0xfffffffc
        end
      end
    end
  end
end
