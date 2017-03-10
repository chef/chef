#--
# Copyright:: Copyright 2016, Chef Software, Inc.
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
  class Node
    # shared API between VividMash and ImmutableMash, writer code can be
    # 'shared' to keep it logically in this file by adding them to the
    # block list in ImmutableMash.
    module CommonAPI
      # method-style access to attributes

      def valid_container?(obj, key)
        obj.is_a?(Hash) || (obj.is_a?(Array) && key.is_a?(Integer))
      end

      private :valid_container?

      # - autovivifying / autoreplacing writer
      # - non-container-ey intermediate objects are replaced with hashes
      def write(*args, &block)
        value = block_given? ? yield : args.pop
        last = args.pop
        prev_memo = prev_key = nil
        chain = args.inject(self) do |memo, key|
          if !valid_container?(memo, key)
            prev_memo[prev_key] = {}
            memo = prev_memo[prev_key]
          end
          prev_memo = memo
          prev_key = key
          memo[key]
        end
        if !valid_container?(chain, last)
          prev_memo[prev_key] = {}
          chain = prev_memo[prev_key]
        end
        chain[last] = value
      end

      # this autovivifies, but can throw NoSuchAttribute when trying to access #[] on
      # something that is not a container ("schema violation" issues).
      #
      def write!(*args, &block)
        value = block_given? ? yield : args.pop
        last = args.pop
        obj = args.inject(self) do |memo, key|
          raise Chef::Exceptions::AttributeTypeMismatch unless valid_container?(memo, key)
          memo[key]
        end
        raise Chef::Exceptions::AttributeTypeMismatch unless valid_container?(obj, last)
        obj[last] = value
      end

      # FIXME:(?) does anyone need a non-autovivifying writer for attributes that throws exceptions?

      # return true or false based on if the attribute exists
      def exist?(*path)
        path.inject(self) do |memo, key|
          return false unless valid_container?(memo, key)
          if memo.is_a?(Hash)
            if memo.key?(key)
              memo[key]
            else
              return false
            end
          elsif memo.is_a?(Array)
            if memo.length > key
              memo[key]
            else
              return false
            end
          end
        end
        true
      end

      # this is a safe non-autovivifying reader that returns nil if the attribute does not exist
      def read(*path)
        read!(*path)
      rescue Chef::Exceptions::NoSuchAttribute
        nil
      end

      # non-autovivifying reader that throws an exception if the attribute does not exist
      def read!(*path)
        raise Chef::Exceptions::NoSuchAttribute unless exist?(*path)
        path.inject(self) do |memo, key|
          memo[key]
        end
      end

      # FIXME:(?) does anyone really like the autovivifying reader that we have and wants the same behavior?  readers that write?  ugh...

      def unlink(*path, last)
        hash = path.empty? ? self : read(*path)
        return nil unless hash.is_a?(Hash) || hash.is_a?(Array)
        hash.delete(last)
      end

      def unlink!(*path)
        raise Chef::Exceptions::NoSuchAttribute unless exist?(*path)
        unlink(*path)
      end

    end
  end
end
