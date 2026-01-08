#--
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
      module ImmutablizeArray
        # Allowed methods that MUST NOT mutate the object
        # (if any of these methods mutate the underlying object that is a bug that needs to be fixed)
        ALLOWED_METHODS = %i{
          &
          *
          +
          -
          []
          abbrev
          all?
          any?
          assoc
          at
          bsearch
          bsearch_index
          chain
          chunk
          chunk_while
          collect
          collect_concat
          combination
          compact
          count
          cycle
          deconstruct
          detect
          difference
          dig
          drop
          drop_while
          each
          each_cons
          each_entry
          each_index
          each_slice
          each_with_index
          each_with_object
          empty?
          entries
          fetch
          fetch_values
          filter
          filter_map
          find
          find_all
          find_index
          first
          flat_map
          flatten
          grep
          grep_v
          group_by
          include?
          index
          inject
          intersect?
          intersection
          join
          last
          lazy
          length
          map
          max
          max_by
          member?
          min
          min_by
          minmax
          minmax_by
          none?
          one?
          pack
          partition
          permutation
          product
          rassoc
          reduce
          reject
          repeated_combination
          repeated_permutation
          reverse
          reverse_each
          rindex
          rotate
          sample
          save_plist
          select
          shelljoin
          shuffle
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
          tally
          to_a
          to_ary
          to_csv
          to_h
          to_plist
          to_set
          to_yaml
          transpose
          union
          uniq
          values_at
          zip
          blank?
          presence
          present?
          to_yaml
          compact_blank
          to_xml
          to_sentence
          to_fs
          to_default_s
          to_formatted_s
          pick
          index_by
          in_order_of
          many?
          sole
          exclude?
          excluding
          minimum
          maximum
          pluck
          including
          without
          index_with
          |
        }.freeze
        # A list of methods that mutate Array. Each of these is overridden to
        # raise an error, making this instances of this class more or less
        # immutable.
        DISALLOWED_MUTATOR_METHODS = %i{
          <<
          []=
          append
          clear
          collect!
          compact!
          concat
          default=
          default_proc=
          delete
          delete_at
          delete_if
          fill
          filter!
          flatten!
          insert
          keep_if
          map!
          merge!
          pop
          prepend
          push
          reject!
          replace
          reverse!
          rotate!
          select!
          shift
          shuffle!
          slice!
          sort!
          sort_by!
          uniq!
          unshift
          compact_blank!
          extract_options!
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
