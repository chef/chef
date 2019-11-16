#--
# Copyright:: Copyright 2016-2019, Chef Software Inc.
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
    module Mixin
      module ImmutablizeHash
        # allowed methods that MUST NOT mutate the object
        # (if any of these methods mutate the underlying object that is a bug that needs to be fixed)
        ALLOWED_METHODS = %i{
          <
          <=
          >
          >=
          []
          all?
          any?
          assoc
          chain
          chunk
          chunk_while
          collect
          collect_concat
          compact
          compare_by_identity
          compare_by_identity?
          count
          cycle
          default
          default_proc
          detect
          dig
          drop
          drop_while
          each
          each_cons
          each_entry
          each_key
          each_pair
          each_slice
          each_value
          each_with_index
          each_with_object
          empty?
          entries
          fetch
          fetch_values
          filter
          find
          find_all
          find_index
          first
          flat_map
          flatten
          grep
          grep_v
          group_by
          has_key?
          has_value?
          include?
          index
          inject
          invert
          key
          key?
          keys
          lazy
          length
          map
          max
          max_by
          member?
          merge
          min
          min_by
          minmax
          minmax_by
          none?
          normalize_param
          one?
          partition
          rassoc
          reduce
          reject
          reverse_each
          save_plist
          select
          size
          slice
          slice_after
          slice_before
          slice_when
          sort
          sort_by
          sum
          take
          take_while
          to_a
          to_h
          to_hash
          to_plist
          to_proc
          to_set
          to_xml_attributes
          to_yaml
          transform_keys
          transform_values
          uniq
          value?
          values
          values_at
          zip
        }.freeze
        DISALLOWED_MUTATOR_METHODS = %i{
          []=
          clear
          collect!
          compact!
          default=
          default_proc=
          delete
          delete_if
          filter!
          keep_if
          map!
          merge!
          rehash
          reject!
          replace
          select!
          shift
          store
          transform_keys!
          transform_values!
          unlink!
          unlink
          update
          write!
          write
        }.freeze

        # Redefine all of the methods that mutate a Hash to raise an error when called.
        # This is the magic that makes this object "Immutable"
        DISALLOWED_MUTATOR_METHODS.each do |mutator_method_name|
          define_method(mutator_method_name) do |*args, &block|
            raise Exceptions::ImmutableAttributeModification
          end
        end
      end
    end
  end
end
