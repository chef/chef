# frozen_string_literal: true
# Copyright 2009-2016, Dan Kubb

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# ---
# ---

# Some portions of blank.rb and mash.rb are verbatim copies of software
# licensed under the MIT license. That license is included below:

# Copyright 2005-2016, David Heinemeier Hansson

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# This class has dubious semantics and we only have it so that people can write
# params[:key] instead of params['key'].
module ChefUtils
  class Mash < Hash

    # @param constructor<Object>
    #   The default value for the mash. Defaults to an empty hash.
    #
    # @details [Alternatives]
    #   If constructor is a Hash, a new mash will be created based on the keys of
    #   the hash and no default value will be set.
    def initialize(constructor = {})
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      else
        super(constructor)
      end
    end

    # @param orig<Object> Mash being copied
    #
    # @return [Object] A new copied Mash
    def initialize_copy(orig)
      super
      # Handle nested values
      each do |k, v|
        if v.is_a?(Mash) || v.is_a?(Array)
          self[k] = v.dup
        end
      end
      self
    end

    # @param key<Object> The default value for the mash. Defaults to nil.
    #
    # @details [Alternatives]
    #   If key is a Symbol and it is a key in the mash, then the default value will
    #   be set to the value matching the key.
    def default(key = nil)
      if key.is_a?(Symbol) && include?(key = key.to_s)
        self[key]
      else
        super
      end
    end

    unless method_defined?(:regular_reader)
      alias_method :regular_reader, :[]
    end

    unless method_defined?(:regular_writer)
      alias_method :regular_writer, :[]=
    end

    unless method_defined?(:regular_update)
      alias_method :regular_update, :update
    end

    # @param key<Object> The key to get.
    def [](key)
      regular_reader(key)
    end

    # @param key<Object> The key to set.
    # @param value<Object>
    #   The value to set the key to.
    #
    # @see Mash#convert_key
    # @see Mash#convert_value
    def []=(key, value)
      regular_writer(convert_key(key), convert_value(value))
    end

    # internal API for use by Chef's deep merge cache
    # @api private
    def internal_get(key)
      regular_reader(key)
    end

    # internal API for use by Chef's deep merge cache
    # @api private
    def internal_set(key, value)
      regular_writer(key, convert_value(value))
    end

    # @param other_hash<Hash>
    #   A hash to update values in the mash with. The keys and the values will be
    #   converted to Mash format.
    #
    # @return [Mash] The updated mash.
    def update(other_hash)
      other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) }
      self
    end

    alias_method :merge!, :update

    # @param key<Object> The key to check for. This will be run through convert_key.
    #
    # @return [Boolean] True if the key exists in the mash.
    def key?(key)
      super(convert_key(key))
    end

    # def include? def has_key? def member?
    alias_method :include?, :key?
    alias_method :has_key?, :key?
    alias_method :member?, :key?

    # @param key<Object> The key to fetch. This will be run through convert_key.
    # @param *extras<Array> Default value.
    #
    # @return [Object] The value at key or the default value.
    def fetch(key, *extras)
      super(convert_key(key), *extras)
    end

    # @param *indices<Array>
    #   The keys to retrieve values for. These will be run through +convert_key+.
    #
    # @return [Array] The values at each of the provided keys
    def values_at(*indices)
      indices.collect { |key| self[convert_key(key)] }
    end

    # @param hash<Hash> The hash to merge with the mash.
    #
    # @return [Mash] A new mash with the hash values merged in.
    def merge(hash)
      dup.update(hash)
    end

    # @param key<Object>
    #   The key to delete from the mash.\
    def delete(key)
      super(convert_key(key))
    end

    # @param *rejected<Array[(String, Symbol)] The mash keys to exclude.
    #
    # @return [Mash] A new mash without the selected keys.
    #
    # @example
    #   { :one => 1, :two => 2, :three => 3 }.except(:one)
    #     #=> { "two" => 2, "three" => 3 }
    def except(*keys)
      super(*keys.map { |k| convert_key(k) })
    end

    # Used to provide the same interface as Hash.
    #
    # @return [Mash] This mash unchanged.
    def stringify_keys!; self end

    # @return [Hash] The mash as a Hash with symbolized keys.
    def symbolize_keys
      h = Hash.new(default)
      each { |key, val| h[key.to_sym] = val }
      h
    end

    # @return [Hash] The mash as a Hash with string keys.
    def to_hash
      Hash.new(default).merge(self)
    end

    # @return [Mash] Convert a Hash into a Mash
    # The input Hash's default value is maintained
    def self.from_hash(hash)
      mash = Mash.new(hash)
      mash.default = hash.default
      mash
    end

    protected

    # @param key<Object> The key to convert.
    #
    # @param [Object]
    #   The converted key. If the key was a symbol, it will be converted to a
    #   string.
    #
    # @api private
    def convert_key(key)
      key.is_a?(Symbol) ? key.to_s : key
    end

    # @param value<Object> The value to convert.
    #
    # @return [Object]
    #   The converted value. A Hash or an Array of hashes, will be converted to
    #   their Mash equivalents.
    #
    # @api private
    def convert_value(value)
      if value.class == Hash
        Mash.from_hash(value)
      elsif value.is_a?(Array)
        value.collect { |e| convert_value(e) }
      else
        value
      end
    end
  end
end
