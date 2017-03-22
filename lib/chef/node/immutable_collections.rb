#--
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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

require "chef/node/common_api"
require "chef/node/mixin/state_tracking"
require "chef/node/mixin/immutablize_array"
require "chef/node/mixin/immutablize_hash"

class Chef
  class Node
    module Immutablize
      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      def immutablize(value)
        case value
        when Hash
          ImmutableMash.new(value, __root__, __node__, __precedence__)
        when Array
          ImmutableArray.new(value, __root__, __node__, __precedence__)
        else
          safe_dup(value).freeze
        end
      end
    end

    # == ImmutableArray
    # ImmutableArray is used to implement Array collections when reading node
    # attributes.
    #
    # ImmutableArray acts like an ordinary Array, except:
    # * Methods that mutate the array are overridden to raise an error, making
    #   the collection more or less immutable.
    # * Since this class stores values computed from a parent
    #   Chef::Node::Attribute's values, it overrides all reader methods to
    #   detect staleness and raise an error if accessed when stale.
    class ImmutableArray < Array
      include Immutablize

      alias :internal_push :<<
      private :internal_push

      def initialize(array_data = [])
        array_data.each do |value|
          internal_push(immutablize(value))
        end
      end

      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      def dup
        Array.new(map { |e| safe_dup(e) })
      end

      def to_a
        Array.new(map do |v|
          case v
          when ImmutableArray
            v.to_a
          when ImmutableMash
            v.to_h
          else
            safe_dup(v)
          end
        end)
      end

      alias_method :to_array, :to_a

      # for consistency's sake -- integers 'converted' to integers
      def convert_key(key)
        key
      end

      prepend Chef::Node::Mixin::StateTracking
      prepend Chef::Node::Mixin::ImmutablizeArray
    end

    # == ImmutableMash
    # ImmutableMash implements Hash/Dict behavior for reading values from node
    # attributes.
    #
    # ImmutableMash acts like a Mash (Hash that is indifferent to String or
    # Symbol keys), with some important exceptions:
    # * Methods that mutate state are overridden to raise an error instead.
    # * Methods that read from the collection are overriden so that they check
    #   if the Chef::Node::Attribute has been modified since an instance of
    #   this class was generated. An error is raised if the object detects that
    #   it is stale.
    # * Values can be accessed in attr_reader-like fashion via method_missing.
    class ImmutableMash < Mash
      include Immutablize
      include CommonAPI

      alias :internal_set :[]=
      private :internal_set

      def initialize(mash_data = {})
        mash_data.each do |key, value|
          internal_set(key, immutablize(value))
        end
      end

      def public_method_that_only_deep_merge_should_use(key, value)
        internal_set(key, immutablize(value))
      end

      alias :attribute? :has_key?

      # Mash uses #convert_value to mashify values on input.
      # Since we're handling this ourselves, override it to be a no-op
      #
      # FIXME?  this seems wrong to do and i think is responsible for
      # #dup needing to be more complicated than Mash.new(self)?
      #
      def convert_value(value)
        value
      end

      # NOTE: #default and #default= are likely to be pretty confusing. For a
      # regular ruby Hash, they control what value is returned for, e.g.,
      #   hash[:no_such_key] #=> hash.default
      # Of course, 'default' has a specific meaning in Chef-land

      def dup
        h = Mash.new
        each_pair do |k, v|
          h[k] = safe_dup(v)
        end
        h
      end

      def to_h
        h = Hash.new
        each_pair do |k, v|
          h[k] =
            case v
            when ImmutableMash
              v.to_h
            when ImmutableArray
              v.to_a
            else
              safe_dup(v)
            end
        end
        h
      end

      alias_method :to_hash, :to_h

      # For elements like Fixnums, true, nil...
      def safe_dup(e)
        e.dup
      rescue TypeError
        e
      end

      prepend Chef::Node::Mixin::StateTracking
      prepend Chef::Node::Mixin::ImmutablizeHash
    end
  end
end
